Import minib3d
Import minib3d.monkeyutility



''NOTES:
''- may need  a method to release main texture memory from LoadImageData(), but keep in videomemory? what if we lose context (on pause)?
'' - need an OnResume() fucntion to reload textures
'' - ReloadAllTextures:: only doing first frame for now until anim_frames get sorted out
'' - textures kept in memory for android OnResume()

'' -- since we are not guaranteed a context outside of OnRender() we use a texture bind stack to bind textures during RenderWorld()

'' -- pushBindTExture: if you Load another texure into an existing texture, will it bind properly?????
'' -- MAJOR CHANGE v34.1: move binding to TPixmap to prevent 1.excessive binds for tex copies, 2.allow loss of original tex object 3. allows entity copies with different texs


Const TEXFLAG_COLOR% = 1
Const TEXFLAG_ALPHA% = 2
Const TEXFLAG_MASKED% = 4 ''deprecated, use ALPHA_TESTING
Const TEXFLAG_ALPHA_TESTING% = 4
Const TEXFLAG_MIPMAP% = 8
Const TEXFLAG_CLAMPU% = 16
Const TEXFLAG_CLAMPV% = 32
Const TEXFLAG_SPHEREMAP% = 64
Const TEXFLAG_CUBEMAP% = 128
Const TEXFLAG_PRESERVE_SIZE% = 256
Const TEXFLAG_512% = 512  ' force high colors?
Const TEXFLAG_NORMALMAP% = 1024



'Interface TextureObjectBase
'
'End

Class TextureStack Extends Stack<TTexture>
	
End
	
Class TTexture

	Global render:TTextureDriver '' reserved for future use for target extendability
	
	Global tex_bind_stack:TextureStack = New TextureStack ''texture bind stack, runs in OnRender()
	
	Global tex_list:List<TTexture> = New List<TTexture>
	Field tex_link:list.Node<TTexture>

	'Field tex_obj:TextureObjectBase 'used by TRender Drivers
	
	Field width:Int,height:Int ' returned by Name/Width/Height commands
	
	Field pixmap:TPixmap
	Field file$
	
	Field coords:Int ''0 or 1 coord set
	Field blend:Int=2
	Field u_scale#=1.0,v_scale#=1.0,u_pos#,v_pos#,angle#
	Field flags:Int, bind_flags:Int = -1
	Field freeMemoryAfterBind:Bool = false
	Global default_texflags:Int=9
	
	Field tex_smooth:Bool =True ''smooths texture via graphics driver
	Field resize_smooth:Bool ''smooth resize (used for mipmap reducing/ power of two enlarging)
	Field orig_width:Int, orig_height:Int
	Global useGlobalResizeSmooth:Bool = True
		
	Field no_frames:Int=1
	Field frame_ustep:Float=1.0,frame_vstep:Float=1.0, frame_xstep:Int, frame_ystep:Int
	Field tex_frame:Int=0
	Field frame_startx:Int, frame_starty:Int
	
	Field gltex:Int[] = New Int[1]
	Field tex_id:Int '' for target implementations to use instead of gltex[]
	Field no_mipmaps:Int
	
	Field cube_pixmap:TPixmap[] 
	Field cube_face:Int=0,cube_mode:Int=1
	
	Field is_font:Bool = False
	

	Method New()
		
		''set this here, this way it is retained for lost contexts
		resize_smooth = useGlobalResizeSmooth
		
	End 

	'' DeleteTexture and BindTexture in TRender
	
	Method FreeTexture()
		
		PushBindTexture(Self, -255)
	
	End
	
	Method FreeTexture_()
		'TRender.render.DeleteTexture(gltex)
		tex_link.Remove()
		If pixmap
		
			''remove all bindings
			pixmap.DecBind()
			If pixmap.GetBindCount()=0
				TPixmap.preloader.RemoveFromStack(file) ''remove from preloader
				pixmap.FreePixmap()
			Endif
			
		Endif
		'cube_pixmap=New TPixmap[7]
		gltex[0]=0
	End
	
	Method FreeTextureMemory:Void()
		freeMemoryAfterBind = true
	End
	
	'' Copy:TTexture()
	'' will keep the same pixmap in video memory
	Method Copy:TTexture()
		
		Local tex:TTexture = New TTexture
		
		tex.tex_link = tex_list.AddLast(tex) ''why add again? how to handle instances?
		
		tex.width = width
		tex.height = height
	
		tex.pixmap = pixmap ''pointer
		
		tex.file = file
		tex.blend = blend
		tex.coords = coords
		tex.u_scale = u_scale
		tex.v_scale = v_scale
		tex.u_pos = u_pos
		tex.v_pos = v_pos
		tex.angle = angle
		tex.flags = flags
		tex.bind_flags = bind_flags

		tex.tex_smooth = tex_smooth
		tex.resize_smooth = resize_smooth
		tex.orig_width = orig_width
		tex.orig_height = orig_height
			
		tex.no_frames = no_frames
		tex.frame_ustep = frame_ustep
		tex.frame_vstep = frame_vstep
		tex.frame_xstep = frame_xstep
		tex.frame_ystep = frame_ystep
		tex.tex_frame = tex_frame
		tex.frame_startx = frame_startx
		tex.frame_starty = frame_starty
		
		tex.gltex = gltex ''pointer for texture
		tex.tex_id = tex_id
		tex.no_mipmaps = no_mipmaps
		
		tex.cube_pixmap = cube_pixmap 
		tex.cube_face = cube_face
		tex.cube_mode = cube_mode
		
		tex.is_font = is_font
		
		'' does not need binding, since the original already does
		If tex.bind_flags <> -1
			PushBindTexture(tex,tex.bind_flags)
		Endif
		
		Return tex
	End
	
	''CreateTexture()
	'' -- frames disabled
	Function CreateTexture:TTexture(width,height,flags=9,frames=1,tex:TTexture=Null)
	
		'If flags&128 Then Return CreateCubeMapTexture(width,height,flags,tex)
		
		If tex=Null
			tex=New TTexture
			tex.tex_link = tex_list.AddLast(tex)
		Endif
		
		width = Pow2Size(width)
		height = Pow2Size(height)
		tex.pixmap=TPixmap.CreatePixmap(width*frames,height,PF_RGBA8888)
		
		tex.flags=flags
		'tex.FilterFlags() ' not needed in CreateTexture
				
		tex.no_frames=frames
		tex.gltex=tex.gltex[..tex.no_frames]
			
	
		Local pixmap:TPixmap = tex.pixmap
		
		If tex.flags & TEXFLAG_PRESERVE_SIZE = 0 Then 
			pixmap=AdjustPixmap(pixmap, tex.resize_smooth, tex)
		End
		tex.width=pixmap.width
		tex.height=pixmap.height
		tex.orig_width=tex.width
		tex.orig_height=tex.height
		
		PushBindTexture(tex,flags)
		
		Return tex

	End 


	Function LoadTexture:TTexture(file$,flags:Int=-1,tex:TTexture=Null)
				
		Return LoadAnimTexture(file,flags,0,0,0,1,tex)
	
	End
	
	''use this LoadTexture(pixmap) for lost context
	Function LoadTexture:TTexture(pixmap:TPixmap,flags:Int=-1, tex:TTexture = Null)
		
		If Not tex
			tex =New TTexture
			tex.tex_link = tex_list.AddLast(tex)
		Endif

		tex.FilterFlags()
		If flags>-1 Then tex.flags = flags ''overwrites filterflags
		
		''check for no pixmap, but file exists, reload file
		If (pixmap = Null) Return tex
		tex.pixmap = pixmap
		If tex.pixmap.height = 0 Then Return tex

		
		''poweroftwo
		If tex.flags & TEXFLAG_PRESERVE_SIZE = 0 Then 
			tex.pixmap=AdjustPixmap(tex.pixmap, tex.resize_smooth, tex)
		End 
		
		tex.width=tex.pixmap.width
		tex.height=tex.pixmap.height
		
		PushBindTexture(tex,flags)
		
		Return tex
	
	End
	
	
	Function LoadNewTexture:TTexture(file$,flags=-1,tex:TTexture=Null)
		''
		'' will force a new texture to be loaded instead of reusing, uses memory
		''
				
		Return LoadAnimTexture(file,flags,0,0,0,1,tex, True)
	
	End
	
	Function LoadAnimTexture:TTexture(file$,flags%=-1,frame_width%,frame_height%,first_frame%=0,frame_count%=-1,tex:TTexture=Null,force_new:Int=False)
	
		If tex=Null Then tex=New TTexture
		
		tex.file=file
		
		' set tex.flags before TexInList
		tex.FilterFlags()
		If flags>-1 Then tex.flags = flags ''overwrites filterflags
		
		
		' check to see if texture with same properties exists already, if so return existing texture
		Local old_tex:TTexture = Null
		If Not force_new Then old_tex=tex.TexInList()
		
		If old_tex<>Null And old_tex<>tex
			'Dprint "TTexture: return old_tex"					
			Return old_tex
		Else
			If old_tex<>tex
				tex.tex_link = tex_list.AddLast(tex)
			Endif
		Endif

		' load pixmap
		Local new_scx:Float=1.0, new_scy:Float=1.0, oldw:Int=0, oldh:Int=0
		
		tex.pixmap=TPixmap.LoadPixmap(file)
		If tex.pixmap.height = 0 Then Return tex
	
		oldw = tex.pixmap.width; oldh=tex.pixmap.height
		tex.orig_width = oldw; tex.orig_height = oldh
		
		If tex.flags & TEXFLAG_PRESERVE_SIZE = 0 Then 
			tex.pixmap=AdjustPixmap(tex.pixmap, tex.resize_smooth, tex)
		End 
		
		tex.width=tex.pixmap.width
		tex.height=tex.pixmap.height
	
		If oldw<>tex.width Or oldh<>tex.height
			new_scx = tex.width/Float(oldw)
			new_scy = tex.height/Float(oldh)
		Endif
		
		' if tex not anim tex, get frame width and height
		If frame_width=0 And frame_height=0
			frame_width=tex.pixmap.width
			frame_height=tex.pixmap.height
		Else
			'' scale frames to new power-of-two
			frame_width = frame_width*new_scx
			frame_height = frame_height*new_scy
		Endif

		tex.SetAnimationFrames(first_frame, frame_count, frame_width, frame_height)
		
	
		PushBindTexture(tex, flags)
		
		Return tex
	
	End
	
	
	Method SetAnimationFrames:Void(first_frame:Int, frame_count:Int, frame_width:Int, frame_height:Int)
	
		frame_xstep = pixmap.width/frame_width
		frame_ystep = pixmap.height/frame_height
			
		frame_startx=first_frame Mod frame_xstep
		frame_starty=( first_frame/frame_ystep) Mod frame_ystep
		
		If frame_count <0
			frame_count = Int(frame_xstep) * Int(frame_ystep)
		Endif
	
		no_frames=frame_count
		If no_frames > 1
			'tex.gltex=tex.gltex.Resize(tex.no_frames+1)
			'tex.frame_u = tex.frame_u.Resize(tex.no_frames+1)
			'tex.frame_v = tex.frame_v.Resize(tex.no_frames+1)
			frame_ustep = 1.0/frame_xstep
			frame_vstep = 1.0/frame_ystep
			
			'' move texture
			u_scale = frame_ustep
			v_scale = frame_vstep
			u_pos = frame_startx*frame_ustep
			v_pos = frame_starty*frame_vstep
		Endif
		
	End
	
	
	''due to openGL context begin available only guaranteed in OnRender(), use this to queue texture binds
	Function PushBindTexture(tex:TTexture, flags:Int)
		
		tex.bind_flags =flags
		tex_bind_stack.Push(tex)
		
	End
	

#rem
	''no cube maps in gl es 1.x
	'' could try to replicate
	
	Function CreateCubeMapTexture:TTexture(width,height,flags,tex:TTexture=Null)
		
		If tex=Null
			tex=New TTexture
			tex.tex_link = tex_list.AddLast(tex)
		Endif
		
		tex.pixmap=CreatePixmap(width*6,height,PF_RGBA8888)
		
		' ---
		
		tex.flags=flags
		'tex.FilterFlags() ' not needed in CreateCubeMapTexture
				
		tex.no_frames=1'frame_count
		'tex.gltex=tex.gltex[..tex.no_frames]

		' ---
		
		' pixmap -> tex
				
		Local name
		glGenTextures 1,Varptr name
		glBindtexture GL_TEXTURE_CUBE_MAP,name
	
		Local pixmap:TPixmap
	
		For Local i=0 To 5
		
			pixmap=tex.pixmap.Window(width*i,0,width,height)

			' ---
		
			pixmap=AdjustPixmap(pixmap)
			tex.width=pixmap.width
			tex.height=pixmap.height
			Local width=pixmap.width
			Local height=pixmap.height

			Local mipmap
			'If tex.flags&8 Then mipmap=True ***note*** prevent mipmaps being created for cubemaps - they are not used by TMesh.Update, so we don't need to create them
			Local mip_level=0
			Repeat
				glPixelStorei GL_UNPACK_ROW_LENGTH,pixmap.pitch/BytesPerPixel[pixmap.format]
				Select i
					Case 0 glTexImage2D GL_TEXTURE_CUBE_MAP_NEGATIVE_X,mip_level,GL_RGBA8,width,height,0,GL_RGBA,GL_UNSIGNED_BYTE,pixmap.pixels
					Case 1 glTexImage2D GL_TEXTURE_CUBE_MAP_POSITIVE_Z,mip_level,GL_RGBA8,width,height,0,GL_RGBA,GL_UNSIGNED_BYTE,pixmap.pixels
					Case 2 glTexImage2D GL_TEXTURE_CUBE_MAP_POSITIVE_X,mip_level,GL_RGBA8,width,height,0,GL_RGBA,GL_UNSIGNED_BYTE,pixmap.pixels
					Case 3 glTexImage2D GL_TEXTURE_CUBE_MAP_NEGATIVE_Z,mip_level,GL_RGBA8,width,height,0,GL_RGBA,GL_UNSIGNED_BYTE,pixmap.pixels
					Case 4 glTexImage2D GL_TEXTURE_CUBE_MAP_POSITIVE_Y,mip_level,GL_RGBA8,width,height,0,GL_RGBA,GL_UNSIGNED_BYTE,pixmap.pixels
					Case 5 glTexImage2D GL_TEXTURE_CUBE_MAP_NEGATIVE_Y,mip_level,GL_RGBA8,width,height,0,GL_RGBA,GL_UNSIGNED_BYTE,pixmap.pixels
				End Select
				If Not mipmap Then Exit
				If width=1 And height=1 Exit
				If width>1 width /=2
				If height>1 height /=2

				pixmap=ResizePixmap(pixmap,width,height)
				mip_level+=1
			Forever
			tex.no_mipmaps=mip_level
			
		Next
		
		tex.gltex[0]=name
		
		Return tex
		
	End 

	Function LoadCubeMapTexture:TTexture(file,flags=1,tex:TTexture=Null)
		
		If tex=Null Then tex=New TTexture
		
		If FileFind(file)=False Then Return Null
		
		tex.file=file
		tex.file_abs=FileAbs(file)
		
		' set tex.flags before TexInList
		tex.flags=flags
		tex.FilterFlags()
		
		' check to see if texture with same properties exists already, if so return existing texture
		Local old_tex:TTexture
		old_tex=tex.TexInList()
		If old_tex<>Null And old_tex<>tex
			Return old_tex
		Else
			If old_tex<>tex
				tex.tex_link = tex_list.AddLast(tex)
			Endif
		Endif

		' load pixmap
		tex.pixmap=LoadPixmap(file)
		
		' check to see if pixmap contain alpha layer, set alpha_present to true if so (do this before converting)
		Local alpha_present=False
		If tex.pixmap.format=PF_RGBA8888 Or tex.pixmap.format=PF_BGRA8888 Or tex.pixmap.format=PF_A8 Then alpha_present=True

		' convert pixmap to appropriate format
		If tex.pixmap.format<>PF_RGBA8888
			tex.pixmap=tex.pixmap.Convert(PF_RGBA8888)
		Endif
		
		' if alpha flag is true and pixmap doesn't contain alpha info, apply alpha based on color values
		If tex.flags&2 And alpha_present=False
			tex.pixmap=ApplyAlpha(tex.pixmap)
		Endif		

		' if mask flag is true, mask pixmap
		If tex.flags&4
			tex.pixmap=MaskPixmap(tex.pixmap,0,0,0)
		Endif
		
		' ---
						
		tex.no_frames=1'frame_count
		'tex.gltex=tex.gltex[..tex.no_frames]
		
		' ---
		
		' pixmap -> tex
			
		Local name
		glGenTextures 1,Varptr name
		glBindtexture GL_TEXTURE_CUBE_MAP,name
	
		Local pixmap:TPixmap
	
		For Local i=0 To 5
		
			pixmap=tex.pixmap.Window((tex.pixmap.width/6)*i,0,tex.pixmap.width/6,tex.pixmap.height)

			' ---
		
			pixmap=AdjustPixmap(pixmap)
			tex.width=pixmap.width
			tex.height=pixmap.height
			Local width=pixmap.width
			Local height=pixmap.height

			Local mipmap
			'If tex.flags&8 Then mipmap=True ***note*** prevent mipmaps being created for cubemaps - they are not used by TMesh.Update, so we don't need to create them
			Local mip_level=0
			Repeat
				glPixelStorei GL_UNPACK_ROW_LENGTH,pixmap.pitch/BytesPerPixel[pixmap.format]
				Select i
					Case 0 glTexImage2D GL_TEXTURE_CUBE_MAP_NEGATIVE_X,mip_level,GL_RGBA8,width,height,0,GL_RGBA,GL_UNSIGNED_BYTE,pixmap.pixels
					Case 1 glTexImage2D GL_TEXTURE_CUBE_MAP_POSITIVE_Z,mip_level,GL_RGBA8,width,height,0,GL_RGBA,GL_UNSIGNED_BYTE,pixmap.pixels
					Case 2 glTexImage2D GL_TEXTURE_CUBE_MAP_POSITIVE_X,mip_level,GL_RGBA8,width,height,0,GL_RGBA,GL_UNSIGNED_BYTE,pixmap.pixels
					Case 3 glTexImage2D GL_TEXTURE_CUBE_MAP_NEGATIVE_Z,mip_level,GL_RGBA8,width,height,0,GL_RGBA,GL_UNSIGNED_BYTE,pixmap.pixels
					Case 4 glTexImage2D GL_TEXTURE_CUBE_MAP_POSITIVE_Y,mip_level,GL_RGBA8,width,height,0,GL_RGBA,GL_UNSIGNED_BYTE,pixmap.pixels
					Case 5 glTexImage2D GL_TEXTURE_CUBE_MAP_NEGATIVE_Y,mip_level,GL_RGBA8,width,height,0,GL_RGBA,GL_UNSIGNED_BYTE,pixmap.pixels
				End Select
				If Not mipmap Then Exit
				If width=1 And height=1 Exit
				If width>1 width /=2
				If height>1 height /=2

				pixmap=ResizePixmap(pixmap,width,height)
				mip_level+=1
			Forever
			tex.no_mipmaps=mip_level
			
		Next
		
		tex.gltex[0]=name
	
		Return tex

	End 
#end
	
	'TextureBlend(n)
	'0: Do not blend
	'1: No blend, or Alpha (alpha when texture loaded with alpha flag)
	'2: Multiply (default)
	'3: Add
	'4: Dot3
	'5: Multiply 2
	Method TextureBlend(blend_no:Int)
		
		blend=blend_no
		
	End 
	
	Method TextureCoords(coords_no:Int)
	
		coords=coords_no
	
	End 
	
	Method ScaleTexture(u_s#,v_s#) ''need to keep in case of a texture by texture manipulation
	
		u_scale=1.0/u_s
		v_scale=1.0/v_s
	
	End 
	
	Method PositionTexture(u_p#,v_p#) 
	
		u_pos=-u_p
		v_pos=-v_p
	
	End 
	
	Method RotateTexture(ang#) 
	
		angle=ang
	
	End 
	
	Method TextureWidth:Int()

		Return width
	
	End 
	
	Method TextureHeight:Int()

		Return height
	
	End 
	
	Method TextureName$()
	
		Return file
	
	End 
	
	Function GetBrushTexture:TTexture(brush:TBrush,index=0)
	
		Return brush.tex[index]
	
	End 
	
	Function ClearTextureFilters()
		
		TTextureFilter.last_filter_list = TTextureFilter.CopyList()
		TTextureFilter.ClearFilters()
	
	End 
	
	Function RestoreTextureFilters()
		
		If TTextureFilter.last_filter_list Then TTextureFilter.filter_list = TTextureFilter.last_filter_list
		
	End
	
	Function TextureFilter(match_text$,flags)
	
		Local filter:TTextureFilter=New TTextureFilter
		filter.text=match_text
		filter.flags=flags
		
		TTextureFilter.filter_list.AddLast(filter)
	
	End 
	
	Method SetCubeFace(face)
		cube_face=face
	End 
	
	Method SetCubeMode(mode)
		cube_mode=mode
	End 
	
	Method BackBufferToTex(mipmap_no=0,frame=0)
	
		TRender.render.BackBufferToTex(Self, mipmap,frame)

	End 
		
	Method CountMipmaps:Int()
	
		Return no_mipmaps
		
	End 
	
	Method MipmapWidth:Int(mipmap_no)
	
		If mipmap_no>=0 And mipmap_no<=no_mipmaps
			Return width/(mipmap_no+1)
		Else
			Return 0
		Endif
		
	End 
	
	Method MipmapHeight:Int(mipmap_no)
	
		If mipmap_no>=0 And mipmap_no<=no_mipmaps
			Return height/(mipmap_no+1)
		Else
			Return 0
		Endif
		
	End 
	
	
		
	Method TexInList:TTexture()

		' check if tex already exists in list and if so return it

		For Local tex:TTexture=Eachin tex_list
			If file=tex.file And flags=tex.flags 'And blend=tex.blend
				'If u_scale=tex.u_scale And v_scale=tex.v_scale And u_pos=tex.u_pos And v_pos=tex.v_pos And angle=tex.angle
					Return tex
				'Endif
			Endif
		Next
	
		Return Null
	
	End 
	
	Method FilterFlags()
	
		' combine specifieds flag with texture filter flags
		For Local filter:TTextureFilter=Eachin TTextureFilter.filter_list
			Local len1:Int = filter.text.Length()
			Local len2:Int = file.Length()-len1
			Local file2:String = file[len2..]
			If file2 = filter.text Then flags=flags|filter.flags
		Next
	
	End 
		
	Function AdjustPixmap:TPixmap(pixmap:TPixmap, resize_smooth:Bool = True, tex:TTexture=Null)
		
		' adjust width and height size to next biggest power of 2 size
		Local width=Pow2Size(pixmap.width)
		Local height=Pow2Size(pixmap.height)
		
		
		' if width or height have changed then resize pixmap
		If width<>pixmap.width Or height<>pixmap.height
			
			''----- MOVED: ok to delete
			'' save original width/height
			'If tex
				'tex.orig_width = pixmap.width; tex.orig_height = pixmap.height
			'Endif
			
			If resize_smooth Then pixmap=pixmap.ResizePixmap(width,height) Else pixmap=pixmap.ResizePixmapNoSmooth(width,height)
			
		Endif

		Return pixmap
		
	End 
	
	Function Pow2Size:Int( n )
		Local t:Int=1
		While t<n
			t = t Shl 1
		Wend
		Return t
	End 



	Method ResizeNoSmooth()
		''does not smooth on resize
		resize_smooth = False
	End
	
	Method ResizeSmooth()
		''does smooth on resize
		resize_smooth = True
	End
	
	Method NoSmooth()
		''does not smooth texture
		tex_smooth = False
	End
	
	Method Smooth()
		''smooth texture
		tex_smooth = True
	End
	
	Function ReloadAllTextures()
		
		Local name:Int[1]
		Local arr:TTexture[] = tex_list.ToArray() ''need to make a copy first
		''used when GL loses context
		For Local i:=0 To arr.Length()-1
			Local tex:TTexture = arr[i] 
			
			If Not tex.pixmap Then Continue
			
			''** only doing first frame for now until anim_frames get sorted out
			'For local i:=0 To tex.no_frames-1

				TRender.render.DeleteTexture(tex) ''unbind, keep textures

				If (tex.pixmap<>Null) 
					LoadTexture(tex.pixmap, tex.flags, tex) ''rebind
				Elseif (tex.file<>"")
					''reload pixmap if it exists
#If CONFIG="debug"
					Print "..Reload texture "+tex.file
#endif
					LoadTexture(tex.file, tex.flags, tex)
				Endif
			'Next
			
		Next
		
	End
	
	
End 



Class TTextureFilter

	Global filter_list:List<TTextureFilter>=New List<TTextureFilter>
	Global last_filter_list:List<TTextureFilter>
	
	Field text$
	Field flags
	
	Function ClearFilters()
		filter_list.Clear()
		Return
	End
	
	Function CopyList:List<TTextureFilter>()
		
		Local newlist:List<TTextureFilter> = New List<TTextureFilter>
		For Local f:TTextureFilter = Eachin filter_list
			newlist.AddLast(f)
		
		Next
		Return newlist
	End
	
End 
