Import minib3d


''Notes

'' - anim_surf now connnect to surface with surf_id
'' -- pre-bake animations which converts bone animation to vertex animation
'' - separated update() and render()
'' -- render() now in TRender.monkey

Class TMesh Extends TEntity
	
	Field min_x#,min_y#,min_z#,max_x#,max_y#,max_z#

	Field no_surfs:Int=0
	Field surf_list:List<TSurface>= New List<TSurface>
	
	Field anim_surf:TSurface[] ' contains animated vertex coords set; connected to surf by surf_id
	
	Field no_bones=0
	Field bones:TBone[]

		
	Field col_tree:TColTree=New TColTree

	' reset flags - these are set when mesh shape is changed by various commands in TMesh
	Field reset_bounds=True
	Field center_x:Float,center_y:Float,center_z:Float
	Field bounds_radius:Float
	'Field reset_col_tree=True
		
	Field is_sprite:Bool = False '' used for sprites
	Field is_update:Bool = False ''used for batching, etc.


	Private
	

	
	Public

	Method New()

	
	End 
	
	Method Delete()

	
	End 
	
	Method CopyEntity:TEntity(parent_ent:TEntity=Null)

		' new mesh
		Local mesh:TMesh=New TMesh
		
		' copy contents of child list before adding parent
		For Local ent:TEntity=Eachin child_list
			ent.CopyEntity(mesh)
		Next
		
		' lists
			
		' add parent, add to list
		mesh.AddParent(parent_ent)
		mesh.entity_link = entity_list.EntityListAdd(mesh)

	
		' add to collision entity list
		If collision_type<>0
			TCollisionPair.ent_lists[collision_type].AddLast(mesh)
		Endif
		
		' add to pick entity list
		If pick_mode<>0
			mesh.pick_link = TPick.ent_list.AddLast(mesh)
		Endif

	
		' update matrix
		If mesh.parent<>Null
			mesh.mat.Overwrite(mesh.parent.mat)
		Else
			mesh.mat.LoadIdentity()
		Endif
		
		' copy entity info
				
		mesh.mat.Multiply(mat)
		
		mesh.px=px
		mesh.py=py
		mesh.pz=pz
		mesh.sx=sx
		mesh.sy=sy
		mesh.sz=sz
		mesh.rx=rx
		mesh.ry=ry
		mesh.rz=rz
		mesh.qw=qw
		mesh.qx=qx
		mesh.qy=qy
		mesh.qz=qz
		
		mesh.name=name
		mesh.classname=classname
		mesh.order=order
		mesh.hide=False
		mesh.auto_fade=auto_fade
		mesh.fade_near=fade_near
		mesh.fade_far=fade_far
		
		mesh.brush=Null
		mesh.brush=brush.Copy()
		
		mesh.anim=anim
		mesh.anim_render=anim_render
		mesh.anim_mode=anim_mode
		mesh.anim_time=anim_time
		mesh.anim_speed=anim_speed
		mesh.anim_seq=anim_seq
		mesh.anim_trans=anim_trans
		mesh.anim_dir=anim_dir
		mesh.anim_seqs_first=anim_seqs_first[..]
		mesh.anim_seqs_last=anim_seqs_last[..]
		mesh.no_seqs=no_seqs
		mesh.anim_update=anim_update
	
		mesh.cull_radius=cull_radius
		mesh.radius_x=radius_x
		mesh.radius_y=radius_y
		mesh.box_x=box_x
		mesh.box_y=box_y
		mesh.box_z=box_z
		mesh.box_w=box_w
		mesh.box_h=box_h
		mesh.box_d=box_d
		mesh.collision_type=collision_type
		mesh.pick_mode=pick_mode
		mesh.obscurer=obscurer
	
		' copy mesh info
		
		mesh.min_x=min_x
		mesh.min_y=min_y
		mesh.min_z=min_z
		mesh.max_x=max_x
		mesh.max_y=max_y
		mesh.max_z=max_z
		
		mesh.no_surfs=no_surfs
		
		' pointer to surf list
		mesh.surf_list=surf_list
		
		' copy anim surf list
		If anim=1
		
			mesh.anim_surf = New TSurface[no_surfs]
			
			For Local surf:TSurface=Eachin surf_list
				'Local new_surf:TSurface=New TSurface
				Local anim_surf2:TSurface = anim_surf[surf.surf_id] ''original anim_surf
					
				mesh.anim_surf[surf.surf_id] = anim_surf2.Copy()
				Local new_surf:TSurface = mesh.anim_surf[surf.surf_id]
				
				new_surf.no_verts=anim_surf2.no_verts
				
				' copy vertex
				'' dont need below, since Copy() method does this
				'new_surf.vert_coords = CopyFloatBuffer(anim_surf2.vert_coords, FloatBuffer.Create(anim_surf2.no_verts*3) )
	
				' pointers to arrays, don't need separate copies
				new_surf.tris = anim_surf2.tris
				
				new_surf.vert_bone1_no=anim_surf2.vert_bone1_no
				new_surf.vert_bone2_no=anim_surf2.vert_bone2_no
				new_surf.vert_bone3_no=anim_surf2.vert_bone3_no
				new_surf.vert_bone4_no=anim_surf2.vert_bone4_no
				new_surf.vert_weight1=anim_surf2.vert_weight1
				new_surf.vert_weight2=anim_surf2.vert_weight2
				new_surf.vert_weight3=anim_surf2.vert_weight3
				new_surf.vert_weight4=anim_surf2.vert_weight4
				
				new_surf.vert_array_size=anim_surf2.vert_array_size
				new_surf.tri_array_size=anim_surf2.tri_array_size
				new_surf.vmin=anim_surf2.vmin
				new_surf.vmax=anim_surf2.vmax
				
				new_surf.reset_vbo=-1 ' (-1 = all)
				
			Next
		
		Elseif anim=2
			
			mesh.anim_surf = New TSurface[no_surfs]
			For Local surf:TSurface=Eachin surf_list
				'Local new_surf:TSurface=New TSurface
				Local anim_surf2:TSurface = anim_surf[surf.surf_id] ''original anim_surf
					
				mesh.anim_surf[surf.surf_id] = anim_surf2.Copy()
				Local new_surf:TSurface = mesh.anim_surf[surf.surf_id]
				
				new_surf.no_verts=anim_surf2.no_verts
				
				new_surf.vert_anim = anim_surf2.vert_anim
								
				new_surf.vert_array_size=anim_surf2.vert_array_size
				new_surf.tri_array_size=anim_surf2.tri_array_size
				new_surf.vmin=anim_surf2.vmin
				new_surf.vmax=anim_surf2.vmax
				
				new_surf.reset_vbo=-1 ' (-1 = all)
				
			Next

			
		Endif
		
		mesh.col_tree=col_tree
	
		mesh.reset_bounds=reset_bounds

		
		mesh.bones = CopyBonesList(Self, New List<TBone>, 0).ToArray()
	
		Return mesh

	End 
	
	Method FreeEntity()

		''dont clear surf_list or will clear all entities
		'Print "free mesh "+classname		
		
		anim_surf = New TSurface[0]
		
		bones = New TBone[0]
		
		Super.FreeEntity() 
		
	End 
	
	Function CreateMesh:TMesh(parent_ent:TEntity=Null)

		Local mesh:TMesh=New TMesh

		mesh.classname="Mesh"
	
		mesh.AddParent(parent_ent)
		mesh.entity_link = entity_list.EntityListAdd(mesh)

		' update matrix
		If mesh.parent<>Null
			mesh.mat.Overwrite(mesh.parent.mat)
			mesh.UpdateMat()
		Else
			mesh.UpdateMat(True)
		Endif
	
		Return mesh

	End 
	
	Function LoadMesh:TMesh(file$,parent_ent:TEntity=Null)
	
		Local xmesh:TMesh=LoadAnimMesh(file)
		Local mesh:TMesh = New TMesh
		'' -- decided not to do this, I need a test B3D file to see how to handle this.
		xmesh.HideEntity()
		CollapseChildren(xmesh,mesh) 'CollapseAnimMesh()
		xmesh.FreeEntity()
		
		mesh.classname="Model"

		mesh.AddParent(parent_ent)
		mesh.entity_link = entity_list.EntityListAdd(mesh)

		' update matrix
		If mesh.parent<>Null
			mesh.mat.Overwrite(mesh.parent.mat)
			mesh.UpdateMat()
		Else
			mesh.UpdateMat(True)
		Endif
		
		Return TMesh(mesh)
	
	End 

	Function LoadAnimMesh:TMesh(file$,parent_ent:TEntity=Null)
	
		Local mesh:TMesh
		If file.EndsWith(".obj") Or file.EndsWith(".obj.txt")
			mesh = TModelObj.LoadMesh(file)
		Else
			mesh = TModelB3D.LoadAnimB3D(file,parent_ent)
		Endif
		
		If Not mesh Then Return TMesh.CreateCube()
		
		Return mesh

	End 



	Method CreateSurface:TSurface(bru:TBrush=Null)
	
		Local surf:TSurface=New TSurface
		surf_list.AddLast(surf)
		
		no_surfs=no_surfs+1
		
		If bru<>Null
			surf.brush=bru.Copy()
		Endif
		
		'' anim surf pointer
		surf.surf_id = no_surfs-1
		anim_surf = anim_surf.Resize(no_surfs)
		
		' new mesh surface - update reset flags
		reset_bounds=True
		col_tree.reset_col_tree=True

		Return surf
		
	End



	Function CreateCube:TMesh(parent_ent:TEntity=Null)
	
		Local mesh:TMesh=TMesh.CreateMesh(parent_ent)
	
		Local surf:TSurface=mesh.CreateSurface()
			
		surf.AddVertex(-1.0,-1.0,-1.0)
		surf.AddVertex(-1.0, 1.0,-1.0)
		surf.AddVertex( 1.0, 1.0,-1.0)
		surf.AddVertex( 1.0,-1.0,-1.0)
		
		surf.AddVertex(-1.0,-1.0, 1.0)
		surf.AddVertex(-1.0, 1.0, 1.0)
		surf.AddVertex( 1.0, 1.0, 1.0)
		surf.AddVertex( 1.0,-1.0, 1.0)
			
		surf.AddVertex(-1.0,-1.0, 1.0)
		surf.AddVertex(-1.0, 1.0, 1.0)
		surf.AddVertex( 1.0, 1.0, 1.0)
		surf.AddVertex( 1.0,-1.0, 1.0)
		
		surf.AddVertex(-1.0,-1.0,-1.0)
		surf.AddVertex(-1.0, 1.0,-1.0)
		surf.AddVertex( 1.0, 1.0,-1.0)
		surf.AddVertex( 1.0,-1.0,-1.0)

		surf.AddVertex(-1.0,-1.0, 1.0)
		surf.AddVertex(-1.0, 1.0, 1.0)
		surf.AddVertex( 1.0, 1.0, 1.0)
		surf.AddVertex( 1.0,-1.0, 1.0)
		
		surf.AddVertex(-1.0,-1.0,-1.0)
		surf.AddVertex(-1.0, 1.0,-1.0)
		surf.AddVertex( 1.0, 1.0,-1.0)
		surf.AddVertex( 1.0,-1.0,-1.0)

		surf.VertexNormal(0,0.0,0.0,-1.0)
		surf.VertexNormal(1,0.0,0.0,-1.0)
		surf.VertexNormal(2,0.0,0.0,-1.0)
		surf.VertexNormal(3,0.0,0.0,-1.0)
	
		surf.VertexNormal(4,0.0,0.0,1.0)
		surf.VertexNormal(5,0.0,0.0,1.0)
		surf.VertexNormal(6,0.0,0.0,1.0)
		surf.VertexNormal(7,0.0,0.0,1.0)
		
		surf.VertexNormal(8,0.0,-1.0,0.0)
		surf.VertexNormal(9,0.0,1.0,0.0)
		surf.VertexNormal(10,0.0,1.0,0.0)
		surf.VertexNormal(11,0.0,-1.0,0.0)
				
		surf.VertexNormal(12,0.0,-1.0,0.0)
		surf.VertexNormal(13,0.0,1.0,0.0)
		surf.VertexNormal(14,0.0,1.0,0.0)
		surf.VertexNormal(15,0.0,-1.0,0.0)
	
		surf.VertexNormal(16,-1.0,0.0,0.0)
		surf.VertexNormal(17,-1.0,0.0,0.0)
		surf.VertexNormal(18,1.0,0.0,0.0)
		surf.VertexNormal(19,1.0,0.0,0.0)
				
		surf.VertexNormal(20,-1.0,0.0,0.0)
		surf.VertexNormal(21,-1.0,0.0,0.0)
		surf.VertexNormal(22,1.0,0.0,0.0)
		surf.VertexNormal(23,1.0,0.0,0.0)

		surf.VertexTexCoords(0,0.0,1.0)
		surf.VertexTexCoords(1,0.0,0.0)
		surf.VertexTexCoords(2,1.0,0.0)
		surf.VertexTexCoords(3,1.0,1.0)
		
		surf.VertexTexCoords(4,1.0,1.0)
		surf.VertexTexCoords(5,1.0,0.0)
		surf.VertexTexCoords(6,0.0,0.0)
		surf.VertexTexCoords(7,0.0,1.0)
		
		surf.VertexTexCoords(8,0.0,1.0)
		surf.VertexTexCoords(9,0.0,0.0)
		surf.VertexTexCoords(10,1.0,0.0)
		surf.VertexTexCoords(11,1.0,1.0)
			
		surf.VertexTexCoords(12,0.0,0.0)
		surf.VertexTexCoords(13,0.0,1.0)
		surf.VertexTexCoords(14,1.0,1.0)
		surf.VertexTexCoords(15,1.0,0.0)
	
		surf.VertexTexCoords(16,0.0,1.0)
		surf.VertexTexCoords(17,0.0,0.0)
		surf.VertexTexCoords(18,1.0,0.0)
		surf.VertexTexCoords(19,1.0,1.0)
				
		surf.VertexTexCoords(20,1.0,1.0)
		surf.VertexTexCoords(21,1.0,0.0)
		surf.VertexTexCoords(22,0.0,0.0)
		surf.VertexTexCoords(23,0.0,1.0)

		surf.VertexTexCoords(0,0.0,1.0,0.0,1)
		surf.VertexTexCoords(1,0.0,0.0,0.0,1)
		surf.VertexTexCoords(2,1.0,0.0,0.0,1)
		surf.VertexTexCoords(3,1.0,1.0,0.0,1)
		
		surf.VertexTexCoords(4,1.0,1.0,0.0,1)
		surf.VertexTexCoords(5,1.0,0.0,0.0,1)
		surf.VertexTexCoords(6,0.0,0.0,0.0,1)
		surf.VertexTexCoords(7,0.0,1.0,0.0,1)
		
		surf.VertexTexCoords(8,0.0,1.0,0.0,1)
		surf.VertexTexCoords(9,0.0,0.0,0.0,1)
		surf.VertexTexCoords(10,1.0,0.0,0.0,1)
		surf.VertexTexCoords(11,1.0,1.0,0.0,1)
			
		surf.VertexTexCoords(12,0.0,0.0,0.0,1)
		surf.VertexTexCoords(13,0.0,1.0,0.0,1)
		surf.VertexTexCoords(14,1.0,1.0,0.0,1)
		surf.VertexTexCoords(15,1.0,0.0,0.0,1)
	
		surf.VertexTexCoords(16,0.0,1.0,0.0,1)
		surf.VertexTexCoords(17,0.0,0.0,0.0,1)
		surf.VertexTexCoords(18,1.0,0.0,0.0,1)
		surf.VertexTexCoords(19,1.0,1.0,0.0,1)
				
		surf.VertexTexCoords(20,1.0,1.0,0.0,1)
		surf.VertexTexCoords(21,1.0,0.0,0.0,1)
		surf.VertexTexCoords(22,0.0,0.0,0.0,1)
		surf.VertexTexCoords(23,0.0,1.0,0.0,1)
				
		surf.AddTriangle(0,1,2) ' front
		surf.AddTriangle(0,2,3)
		surf.AddTriangle(6,5,4) ' back
		surf.AddTriangle(7,6,4)
		surf.AddTriangle(6+8,5+8,1+8) ' top
		surf.AddTriangle(2+8,6+8,1+8)
		surf.AddTriangle(0+8,4+8,7+8) ' bottom
		surf.AddTriangle(0+8,7+8,3+8)
		surf.AddTriangle(6+16,2+16,3+16) ' right
		surf.AddTriangle(7+16,6+16,3+16)
		surf.AddTriangle(0+16,1+16,5+16) ' left
		surf.AddTriangle(0+16,5+16,4+16)

		surf.CropSurfaceBuffers()
		
		Return mesh
	
	End 
	
	' Function by Coyote
	Function CreateSphere:TMesh(segments:Int=8,parent_ent:TEntity=Null)

		If segments<2 Or segments>100 Then Return Null
		
		Local thissphere:TMesh=TMesh.CreateMesh(parent_ent)
		Local thissurf:TSurface=thissphere.CreateSurface()

		Local div#=Float(360.0/(segments*2))
		Local height#=1.0
		Local upos#=1.0
		Local udiv#=Float(1.0/(segments*2))
		Local vdiv#=Float(1.0/segments)
		Local RotAngle#=90	
	
		If segments=2 ' diamond shape - no center strips
		
			For Local i=1 To (segments*2)
				Local np=thissurf.AddVertex(0.0,height,0.0,upos-(udiv/2.0),0)'northpole
				Local sp=thissurf.AddVertex(0.0,-height,0.0,upos-(udiv/2.0),1)'southpole
				Local XPos#=-Cos(RotAngle)
				Local ZPos#=Sin(RotAngle)
				Local v0=thissurf.AddVertex(XPos,0,ZPos,upos,0.5)
				RotAngle=RotAngle+div
				If RotAngle>=360.0 Then RotAngle=RotAngle-360.0
				XPos=-Cos(RotAngle)
				ZPos=Sin(RotAngle)
				upos=upos-udiv
				Local v1=thissurf.AddVertex(XPos,0,ZPos,upos,0.5)
				thissurf.AddTriangle(np,v0,v1)
				thissurf.AddTriangle(v1,v0,sp)	
			Next
			
		Else ' have center strips now
		
			' poles first
			For Local i=1 To (segments*2)
			
				Local np=thissurf.AddVertex(0.0,height,0.0,upos-(udiv/2.0),0.0)'northpole
				Local sp=thissurf.AddVertex(0.0,-height,0.0,upos-(udiv/2.0),1.0)'southpole
				
				Local YPos#=Cos(div)
				
				Local XPos#=-Cos(RotAngle)*(Sin(div))
				Local ZPos#=Sin(RotAngle)*(Sin(div))
				
				Local v0t=thissurf.AddVertex(XPos,YPos,ZPos,upos,vdiv)
				Local v0b=thissurf.AddVertex(XPos,-YPos,ZPos,upos,1.0-vdiv)
	
				RotAngle=RotAngle+div
				
				XPos=-Cos(RotAngle)*(Sin(div))
				ZPos=Sin(RotAngle)*(Sin(div))
				
				upos=upos-udiv
	
				Local v1t=thissurf.AddVertex(XPos,YPos,ZPos,upos,vdiv)
				Local v1b=thissurf.AddVertex(XPos,-YPos,ZPos,upos,1.0-vdiv)
		
				thissurf.AddTriangle(np,v0t,v1t)
				thissurf.AddTriangle(v1b,v0b,sp)	
				
			Next

			' then center strips
	
			upos=1.0
			RotAngle=90
			For Local i=1 To (segments*2)
			
				Local mult#=1
				Local YPos#=Cos(div*(mult))
				Local YPos2#=Cos(div*(mult+1.0))
				Local Thisvdiv#=vdiv
				For Local j=1 To (segments-2)
	
					
					Local XPos#=-Cos(RotAngle)*(Sin(div*(mult)))
					Local ZPos#=Sin(RotAngle)*(Sin(div*(mult)))
	
					Local XPos2#=-Cos(RotAngle)*(Sin(div*(mult+1.0)))
					Local ZPos2#=Sin(RotAngle)*(Sin(div*(mult+1.0)))
								
					Local v0t=thissurf.AddVertex(XPos,YPos,ZPos,upos,Thisvdiv)
					Local v0b=thissurf.AddVertex(XPos2,YPos2,ZPos2,upos,Thisvdiv+vdiv)
				
					' 2nd tex coord set
					thissurf.VertexTexCoords(v0t,upos,Thisvdiv,0.0,1)
					thissurf.VertexTexCoords(v0b,upos,Thisvdiv+vdiv,0.0,1)
				
					Local tempRotAngle#=RotAngle+div
				
					XPos=-Cos(tempRotAngle)*(Sin(div*(mult)))
					ZPos=Sin(tempRotAngle)*(Sin(div*(mult)))
					
					XPos2=-Cos(tempRotAngle)*(Sin(div*(mult+1.0)))
					ZPos2=Sin(tempRotAngle)*(Sin(div*(mult+1.0)))				
				
					Local temp_upos#=upos-udiv
	
					Local v1t=thissurf.AddVertex(XPos,YPos,ZPos,temp_upos,Thisvdiv)
					Local v1b=thissurf.AddVertex(XPos2,YPos2,ZPos2,temp_upos,Thisvdiv+vdiv)
					
					' 2nd tex coord set
					thissurf.VertexTexCoords(v1t,temp_upos,Thisvdiv,0.0,1)
					thissurf.VertexTexCoords(v1b,temp_upos,Thisvdiv+vdiv,0.0,1)
					
					thissurf.AddTriangle(v1t,v0t,v0b)
					thissurf.AddTriangle(v1b,v1t,v0b)
					
					Thisvdiv=Thisvdiv+vdiv			
					mult=mult+1
					YPos=Cos(div*(mult))
					YPos2=Cos(div*(mult+1.0))
				
				Next
				upos=upos-udiv
				RotAngle=RotAngle+div
			Next
	
		Endif
		
		thissurf.CropSurfaceBuffers()
		
		'thissphere.UpdateNormals() ''slow
		thissurf.SnapVerts()
		thissurf.UpdateNormals()
			
		' mesh state has changed - update reset flags
		thissurf.reset_vbo = thissurf.reset_vbo|4
		
		Return thissphere 

	End 

	' Function by Coyote
	Function CreateCylinder:TMesh(verticalsegments=8,solid=True,parent_ent:TEntity=Null)
	
		Local ringsegments=0 ' default?
	
		Local tr,tl,br,bl' 		side of cylinder
		Local ts0,ts1,newts' 	top side vertexs
		Local bs0,bs1,newbs' 	bottom side vertexs
		If verticalsegments<3 Or verticalsegments>100 Then Return Null
		If ringsegments<0 Or ringsegments>100 Then Return Null
		
		Local thiscylinder:TMesh=TMesh.CreateMesh(parent_ent)
		Local thissurf:TSurface=thiscylinder.CreateSurface()
		Local thissidesurf:TSurface
		If solid=True
			thissidesurf=thiscylinder.CreateSurface()
		Endif
		Local div#=Float(360.0/(verticalsegments))
	
		Local height#=1.0
		Local ringSegmentHeight#=(height*2.0)/(ringsegments+1)
		Local upos#=1.0
		Local udiv#=Float(1.0/(verticalsegments))
		Local vpos#=1.0
		Local vdiv#=Float(1.0/(ringsegments+1))
	
		Local SideRotAngle#=90
	
		' re-diminsion arrays to hold needed memory.
		' this is used just for helping to build the ring segments...
		Local tRing[verticalsegments+1]
		Local bRing[verticalsegments+1]
		
		' render end caps if solid
		If solid=True
			Local XPos#=-Cos(SideRotAngle)
			Local ZPos#=Sin(SideRotAngle)
	
			ts0=thissidesurf.AddVertex(XPos,height,ZPos,XPos/2.0+0.5,ZPos/2.0+0.5)
			bs0=thissidesurf.AddVertex(XPos,-height,ZPos,XPos/2.0+0.5,ZPos/2.0+0.5)
			
			' 2nd tex coord set
			thissidesurf.VertexTexCoords(ts0,XPos/2.0+0.5,ZPos/2.0+0.5,0.0,1)
			thissidesurf.VertexTexCoords(bs0,XPos/2.0+0.5,ZPos/2.0+0.5,0.0,1)
	
			SideRotAngle=SideRotAngle+div
	
			XPos=-Cos(SideRotAngle)
			ZPos=Sin(SideRotAngle)
			
			ts1=thissidesurf.AddVertex(XPos,height,ZPos,XPos/2.0+0.5,ZPos/2.0+0.5)
			bs1=thissidesurf.AddVertex(XPos,-height,ZPos,XPos/2.0+0.5,ZPos/2.0+0.5)
		
			' 2nd tex coord set
			thissidesurf.VertexTexCoords(ts1,XPos/2.0+0.5,ZPos/2.0+0.5,0.0,1)
			thissidesurf.VertexTexCoords(bs1,XPos/2.0+0.5,ZPos/2.0+0.5,0.0,1)
			
			For Local i=1 To (verticalsegments-2)
				SideRotAngle=SideRotAngle+div
	
				XPos=-Cos(SideRotAngle)
				ZPos=Sin(SideRotAngle)
				
				newts=thissidesurf.AddVertex(XPos,height,ZPos,XPos/2.0+0.5,ZPos/2.0+0.5)
				newbs=thissidesurf.AddVertex(XPos,-height,ZPos,XPos/2.0+0.5,ZPos/2.0+0.5)
				
				' 2nd tex coord set
				thissidesurf.VertexTexCoords(newts,XPos/2.0+0.5,ZPos/2.0+0.5,0.0,1)
				thissidesurf.VertexTexCoords(newbs,XPos/2.0+0.5,ZPos/2.0+0.5,0.0,1)
				
				thissidesurf.AddTriangle(ts0,ts1,newts)
				thissidesurf.AddTriangle(newbs,bs1,bs0)
			
				If i<(verticalsegments-2)
					ts1=newts
					bs1=newbs
				Endif
			Next
		Endif
		
		' -----------------------
		' middle part of cylinder
		Local thisHeight#=height
		
		' top ring first		
		SideRotAngle=90
		Local XPos#=-Cos(SideRotAngle)
		Local ZPos#=Sin(SideRotAngle)
		Local thisUPos#=upos
		Local thisVPos#=0
		tRing[0]=thissurf.AddVertex(XPos,thisHeight,ZPos,thisUPos,thisVPos)		
		thissurf.VertexTexCoords(tRing[0],thisUPos,thisVPos,0.0,1) ' 2nd tex coord set
		For Local i=0 To (verticalsegments-1)
			SideRotAngle=SideRotAngle+div
			XPos=-Cos(SideRotAngle)
			ZPos=Sin(SideRotAngle)
			thisUPos=thisUPos-udiv
			tRing[i+1]=thissurf.AddVertex(XPos,thisHeight,ZPos,thisUPos,thisVPos)
			thissurf.VertexTexCoords(tRing[i+1],thisUPos,thisVPos,0.0,1) ' 2nd tex coord set
		Next	
		
		For Local ring=0 To ringsegments
	
			' decrement vertical segment
			Local thisHeight=thisHeight-ringSegmentHeight
			
			' now bottom ring
			SideRotAngle=90
			XPos=-Cos(SideRotAngle)
			ZPos=Sin(SideRotAngle)
			thisUPos=upos
			thisVPos=thisVPos+vdiv
			bRing[0]=thissurf.AddVertex(XPos,thisHeight,ZPos,thisUPos,thisVPos)
			thissurf.VertexTexCoords(bRing[0],thisUPos,thisVPos,0.0,1) ' 2nd tex coord set
			For Local i=0 To (verticalsegments-1)
				SideRotAngle=SideRotAngle+div
				XPos=-Cos(SideRotAngle)
				ZPos=Sin(SideRotAngle)
				thisUPos=thisUPos-udiv
				bRing[i+1]=thissurf.AddVertex(XPos,thisHeight,ZPos,thisUPos,thisVPos)
				thissurf.VertexTexCoords(bRing[i+1],thisUPos,thisVPos,0.0,1) ' 2nd tex coord set
			Next
			
			' Fill in ring segment sides with triangles
			For Local v=1 To (verticalsegments)
				tl=tRing[v]
				tr=tRing[v-1]
				bl=bRing[v]
				br=bRing[v-1]
				
				thissurf.AddTriangle(tl,tr,br)
				thissurf.AddTriangle(bl,tl,br)
			Next
			
			' make bottom ring segmentthe top ring segment for the next loop.
			For Local v=0 To (verticalsegments)
				tRing[v]=bRing[v]
			Next		
		Next
		
		thissurf.CropSurfaceBuffers()
		
		thiscylinder.UpdateNormals()
		Return thiscylinder 
		
	End 
	
	' Function by Coyote
	Function CreateCone:TMesh(segments=8,solid=True,parent_ent:TEntity=Null)
	
		Local top,br,bl' 		side of cone
		Local bs0,bs1,newbs' 	bottom side vertices
		
		If segments<3 Or segments>100 Then Return Null
		
		Local thiscone:TMesh=TMesh.CreateMesh(parent_ent)
		Local thissurf:TSurface=thiscone.CreateSurface()
		Local thissidesurf:TSurface
		If solid=True
			thissidesurf=thiscone.CreateSurface()
		Endif
		Local div#=Float(360.0/(segments))
	
		Local height#=1.0
		Local upos#=1.0
		Local udiv#=Float(1.0/(segments))
		Local RotAngle#=90	
	
		' first side
		Local XPos#=-Cos(RotAngle)
		Local ZPos#=Sin(RotAngle)
	
		top=thissurf.AddVertex(0.0,height,0.0,upos-(udiv/2.0),0)
		br=thissurf.AddVertex(XPos,-height,ZPos,upos,1)
		
		' 2nd tex coord set
		thissurf.VertexTexCoords(top,upos-(udiv/2.0),0,0.0,1)
		thissurf.VertexTexCoords(br,upos,1,0.0,1)
	
		If solid=True Then bs0=thissidesurf.AddVertex(XPos,-height,ZPos,XPos/2.0+0.5,ZPos/2.0+0.5)
		If solid=True Then thissidesurf.VertexTexCoords(bs0,XPos/2.0+0.5,ZPos/2.0+0.5,0.0,1) ' 2nd tex coord set
	
		RotAngle= RotAngle+div
	
		XPos= -Cos(RotAngle)
		ZPos= Sin(RotAngle)
					
		bl=thissurf.AddVertex(XPos,-height,ZPos,upos-udiv,1)
		thissurf.VertexTexCoords(bl,upos-udiv,1,0.0,1) ' 2nd tex coord set	
	
		If solid=True Then bs1=thissidesurf.AddVertex(XPos,-height,ZPos,XPos/2.0+0.5,ZPos/2.0+0.5)
		If solid=True Then thissidesurf.VertexTexCoords(bs1,XPos/2.0+0.5,ZPos/2.0+0.5,0.0,1) ' 2nd tex coord set
		
		thissurf.AddTriangle(bl,top,br)
	
		' rest of sides
		For Local i=1 To (segments-1)
			br=bl
			upos=upos-udiv
			top=thissurf.AddVertex(0.0,height,0.0,upos-(udiv/2.0),0)
			thissurf.VertexTexCoords(top,upos-(udiv/2.0),0,0.0,1) ' 2nd tex coord set
		
			RotAngle=RotAngle+div
	
			XPos=-Cos(RotAngle)
			ZPos=Sin(RotAngle)
			
			bl=thissurf.AddVertex(XPos,-height,ZPos,upos-udiv,1)
			thissurf.VertexTexCoords(bl,upos-udiv,1,0.0,1) ' 2nd tex coord set
	
			If solid=True Then newbs=thissidesurf.AddVertex(XPos,-height,ZPos,XPos/2.0+0.5,ZPos/2.0+0.5)
			If solid=True Then thissidesurf.VertexTexCoords(newbs,XPos/2.0+0.5,ZPos/2.0+0.5,0.0,1) ' 2nd tex coord set
		
			thissurf.AddTriangle(bl,top,br)
			
			If solid=True
				thissidesurf.AddTriangle(newbs,bs1,bs0)
			
				If i<(segments-1)
					bs1=newbs
				Endif
			Endif
		Next
		
		thissurf.CropSurfaceBuffers()
		thissidesurf.CropSurfaceBuffers()
		
		thiscone.UpdateNormals()
		Return thiscone
		
	End 
	
	Method CopyMesh:TMesh(parent_ent:TEntity=Null)
	
		Local mesh:TMesh=TMesh.CreateMesh(parent_ent)
		Self.AddMesh(mesh)
		Return mesh
	
	End 
	
	''AddMesh()
	'' -- add self mesh to mesh2
	''
	Method AddMesh(mesh2:TMesh)
		
		If Not mesh2 Then Return
		
		For Local surf1:TSurface=Eachin surf_list
			
			'Local surf1:TSurface= Self.GetSurface(s1)

			' if surface is empty, don't add it
			If surf1.CountVertices()=0 And surf1.CountTriangles()=0 Then Continue
				
			Local new_surf:Bool=True
			Local tri_offset:Int = 0
			Local surf:TSurface = Null
			Local stest:TSurface
			
			For stest= Eachin mesh2.surf_list '1 To mesh2.CountSurfaces()	

				' if brushes properties are the same, add surf1 verts and tris to surf2
				If (TBrush.CompareBrushes(surf1.brush,stest.brush)=True)
					
					tri_offset = stest.CountVertices()
					new_surf=False
					surf = stest
					
					Exit
			
				Endif
				
			Next
			
			' add new surface
			
			
			If new_surf=True
			
				surf=mesh2.CreateSurface()
				
			Endif	
			
			
			' add vertices
			Local s1v:Int = surf1.CountVertices()		
			For Local v:Int=0 To s1v-1

				Local vx#=surf1.VertexX(v)
				Local vy#=surf1.VertexY(v)
				Local vz#=surf1.VertexZ(v)
				Local vr#=surf1.VertexRed(v)
				Local vg#=surf1.VertexGreen(v)
				Local vb#=surf1.VertexBlue(v)
				Local va#=surf1.VertexAlpha(v)
				Local vnx#=surf1.VertexNX(v)
				Local vny#=surf1.VertexNY(v)
				Local vnz#=surf1.VertexNZ(v)
				Local vu0#=surf1.VertexU(v,0)
				Local vv0#=surf1.VertexV(v,0)
				Local vw0#=surf1.VertexW(v,0)
				Local vu1#=surf1.VertexU(v,1)
				Local vv1#=surf1.VertexV(v,1)
				Local vw1#=surf1.VertexW(v,1)
					
				Local v2:Int = surf.AddVertex(vx,vy,vz)
				surf.VertexColor(v2,vr,vg,vb,va)
				surf.VertexNormal(v2,vnx,vny,vnz)
				surf.VertexTexCoords(v2,vu0,vv0,vw0,0)
				surf.VertexTexCoords(v2,vu1,vv1,vw1,1)

			Next
	
			' add triangles
	
			For Local t=0 To surf1.CountTriangles()-1

				Local v0=surf1.TriangleVertex(t,0) + tri_offset
				Local v1=surf1.TriangleVertex(t,1) + tri_offset
				Local v2=surf1.TriangleVertex(t,2) + tri_offset
				
				surf.AddTriangle(v0,v1,v2)

			Next
			
			surf.CropSurfaceBuffers()
			
			' copy brush
			
			If surf1.brush<>Null
			
				surf.brush=surf1.brush.Copy()
				
			Endif
			
			' mesh shape has changed - update reset flags
			surf.reset_vbo=-1 ' (-1 = all)
				
			'Endif
							
		Next
		
		' mesh shape has changed - update reset flags
		mesh2.reset_bounds=True
		mesh2.col_tree.reset_col_tree=True
		
	End 
	
	Method FlipMesh()
	
		For Local surf:TSurface=Eachin surf_list
		
			' flip triangle vertex order
			For Local t=1 To surf.no_tris
			
				Local i0=t*3-3
				Local i1=t*3-2
				Local i2=t*3-1
			
				Local v0=surf.tris.Peek(i0)
				Local v1=surf.tris.Peek(i1)
				Local v2=surf.tris.Peek(i2)
		
				surf.tris.Poke(i0,v2)
				'surf.tris[i1]
				surf.tris.Poke(i2,v0)
		
			Next
			
			' flip vertex normals
			For Local v=0 To surf.no_verts-1
			
				surf.vert_norm.Poke(v*3, -surf.vert_norm.Peek(v*3) )' x
				surf.vert_norm.Poke((v*3)+1, -surf.vert_norm.Peek((v*3)+1) )' y
				surf.vert_norm.Poke((v*3)+2, -surf.vert_norm.Peek((v*3)+2) )' z

			Next
			
			' mesh shape has changed - update reset flag
			surf.reset_vbo = surf.reset_vbo|4|16
		
		Next
		
		' mesh shape has changed - update reset flag
		col_tree.reset_col_tree=True
		
	End
	
	Method PaintMesh(bru:TBrush)

		For Local surf:TSurface=Eachin surf_list

			If surf.brush=Null Then surf.brush=New TBrush
			
			surf.brush.no_texs=bru.no_texs
			surf.brush.name=bru.name
			surf.brush.red=bru.red
			surf.brush.green=bru.green
			surf.brush.blue=bru.blue
			surf.brush.alpha=bru.alpha
			surf.brush.shine=bru.shine
			surf.brush.blend=bru.blend
			surf.brush.fx=bru.fx
			surf.brush.tex_frame = bru.tex_frame
			For Local i=0 To 7
				surf.brush.tex[i]=bru.tex[i]
			Next

		Next

	End 
	
	Method FitMesh(x#,y#,z#,width#,height#,depth#,uniform=False)
	
		' if uniform=true than adjust fitmesh dimensions
		
		If uniform=True
						
			Local wr#=MeshWidth()/width
			Local hr#=MeshHeight()/height
			Local dr#=MeshDepth()/depth
		
			If wr>=hr And wr>=dr
	
				y=y+((height-(MeshHeight()/wr))/2.0)
				z=z+((depth-(MeshDepth()/wr))/2.0)
				
				height=MeshHeight()/wr
				depth=MeshDepth()/wr
			
			Else If hr>dr
			
				x=x+((width-(MeshWidth()/hr))/2.0)
				z=z+((depth-(MeshDepth()/hr))/2.0)
			
				width=MeshWidth()/hr
				depth=MeshDepth()/hr
						
			Else
			
				x=x+((width-(MeshWidth()/dr))/2.0)
				y=y+((height-(MeshHeight()/dr))/2.0)
			
				width=MeshWidth()/dr
				height=MeshHeight()/dr
								
			Endif

		Endif
		
		' old to new dimensions ratio, used to update mesh normals
		Local wr#=MeshWidth()/width
		Local hr#=MeshHeight()/height
		Local dr#=MeshDepth()/depth
		
		' find min/max dimensions
	
		Local minx#=9999999999
		Local miny#=9999999999
		Local minz#=9999999999
		Local maxx#=-9999999999
		Local maxy#=-9999999999
		Local maxz#=-9999999999
	
		For Local s=1 To CountSurfaces()
			
			Local surf:TSurface=GetSurface(s)
				
			For Local v=0 To surf.CountVertices()-1
		
				Local vx#=surf.VertexX(v)
				Local vy#=surf.VertexY(v)
				Local vz#=surf.VertexZ(v)
				
				If vx<minx Then minx=vx
				If vy<miny Then miny=vy
				If vz<minz Then minz=vz
				
				If vx>maxx Then maxx=vx
				If vy>maxy Then maxy=vy
				If vz>maxz Then maxz=vz

			Next
							
		Next
		
		For Local s=1 To CountSurfaces()
			
			Local surf:TSurface=GetSurface(s)
				
			For Local v=0 To surf.CountVertices()-1
		
				' update vertex positions
		
				Local vx#=surf.VertexX(v)
				Local vy#=surf.VertexY(v)
				Local vz#=surf.VertexZ(v)
								
				Local mx#=maxx-minx
				Local my#=maxy-miny
				Local mz#=maxz-minz
				
				Local ux#,uy#,uz#
				
				If mx<0.0001 And mx>-0.0001 Then ux=0.0 Else ux=(vx-minx)/mx ' 0-1
				If my<0.0001 And my>-0.0001 Then uy=0.0 Else uy=(vy-miny)/my ' 0-1
				If mz<0.0001 And mz>-0.0001 Then uz=0.0 Else uz=(vz-minz)/mz ' 0-1
										
				vx=x+(ux*width)
				vy=y+(uy*height)
				vz=z+(uz*depth)
				
				surf.VertexCoords(v,vx,vy,vz)
				
				' update normals
				
				Local nx#=surf.VertexNX(v)
				Local ny#=surf.VertexNY(v)
				Local nz#=surf.VertexNZ(v)
				
				nx=nx*wr
				ny=ny*hr
				nz=nz*dr
				
				surf.VertexNormal(v,nx,ny,nz)

			Next
			
			' mesh shape has changed - update reset flag
			surf.reset_vbo = surf.reset_vbo|1|4

		Next
		
		' mesh shape has changed - update reset flags
		reset_bounds=True
		col_tree.reset_col_tree=True
		
	End 
	
	Method ScaleMesh(sx#,sy#,sz#)
	
		For Local s=1 To no_surfs
	
			Local surf:TSurface=GetSurface(s)
				
			For Local v=0 To surf.no_verts-1
		
				surf.vert_coords.Poke(v*3, surf.vert_coords.Peek(v*3)*sx)
				surf.vert_coords.Poke(v*3+1, surf.vert_coords.Peek(v*3+1)*sy)
				surf.vert_coords.Poke(v*3+2, surf.vert_coords.Peek(v*3+2)*sz) 'surf.vert_coords[v*3+2] *= sz

			Next
			
			' mesh shape has changed - update reset flag
			surf.reset_vbo = surf.reset_vbo|1
				
		Next
		
		' mesh shape has changed - update reset flags
		reset_bounds=True
		col_tree.reset_col_tree=True

	End 
	
	Method RotateMesh(pitch#,yaw#,roll#)
	
		pitch= -pitch
		
		Local mat:Matrix=New Matrix
		mat.LoadIdentity()
		mat.Rotate(pitch,yaw,roll)

		For Local s=1 To no_surfs
	
			Local surf:TSurface=GetSurface(s)
				
			For Local v=0 To surf.no_verts-1
		
				Local vx#=surf.vert_coords.Peek(v*3)
				Local vy#=surf.vert_coords.Peek(v*3+1)
				Local vz#=surf.vert_coords.Peek(v*3+2)
	
				surf.vert_coords.Poke(v*3, mat.grid[0][0]*vx + mat.grid[1][0]*vy + mat.grid[2][0]*vz + mat.grid[3][0] )
				surf.vert_coords.Poke(v*3+1, mat.grid[0][1]*vx + mat.grid[1][1]*vy + mat.grid[2][1]*vz + mat.grid[3][1] )
				surf.vert_coords.Poke(v*3+2, mat.grid[0][2]*vx + mat.grid[1][2]*vy + mat.grid[2][2]*vz + mat.grid[3][2] )

				Local nx#=surf.vert_norm.Peek(v*3)
				Local ny#=surf.vert_norm.Peek(v*3+1)
				Local nz#=surf.vert_norm.Peek(v*3+2)
	
				surf.vert_norm.Poke(v*3, mat.grid[0][0]*nx + mat.grid[1][0]*ny + mat.grid[2][0]*nz + mat.grid[3][0] )
				surf.vert_norm.Poke(v*3+1, mat.grid[0][1]*nx + mat.grid[1][1]*ny + mat.grid[2][1]*nz + mat.grid[3][1] )
				surf.vert_norm.Poke(v*3+2, mat.grid[0][2]*nx + mat.grid[1][2]*ny + mat.grid[2][2]*nz + mat.grid[3][2] )

			Next
			
			' mesh shape has changed - update reset flag
			surf.reset_vbo = surf.reset_vbo|1|4
							
		Next
		
		' mesh shape has changed - update reset flag
		reset_bounds=True
		col_tree.reset_col_tree=True
				
	End 
	
	Method PositionMesh(px#,py#,pz#)

		pz=-pz
	
		For Local s=1 To no_surfs
	
			Local surf:TSurface=GetSurface(s)
				
			For Local v=0 To surf.no_verts-1
		
				surf.vert_coords.Poke(v*3, surf.vert_coords.Peek(v*3) + px )
				surf.vert_coords.Poke(v*3+1, surf.vert_coords.Peek(v*3+1) + py )
				surf.vert_coords.Poke(v*3+2, surf.vert_coords.Peek(v*3+2) + pz ) 'surf.vert_coords[v*3+2] += pz

			Next
			
			' mesh shape has changed - update reset flag
			surf.reset_vbo = surf.reset_vbo|1
						
		Next
		
		' mesh shape has changed - update reset flags
		reset_bounds=True
		col_tree.reset_col_tree=True
		
	End 

	Method UpdateNormals()

		For Local s=1 To CountSurfaces()

			Local surf:TSurface=GetSurface( s )

			surf.SnapVerts()
			surf.UpdateNormals()
			
			' mesh state has changed - update reset flags
			surf.reset_vbo = surf.reset_vbo|4

		Next
	
	End 
	
	Method RemoveVerts()

		For Local s=1 To CountSurfaces()

			Local surf:TSurface=GetSurface( s )

			TSurface.RemoveVerts(surf)
			
			' mesh state has changed - update reset flags
			surf.reset_vbo = surf.reset_vbo|4

		Next
	
	End
	
	Method WeldVerts()

		For Local s=1 To CountSurfaces()

			Local surf:TSurface=GetSurface( s )
			surf.WeldVerts()
			
		Next
	
	End 
	
	Method MeshWidth#()

		GetBounds()

		Return max_x-min_x
		
	End 
	
	Method MeshHeight#()

		GetBounds()

		Return max_y-min_y
		
	End 
	
	Method MeshDepth#()

		GetBounds()

		Return max_z-min_z
		
	End 

	Method CountSurfaces()
	
		Return no_surfs
	
	End 
	
	Method GetSurface:TSurface(surf_no_get:Int)
		
		Local surf_no=0
	
		For Local surf:TSurface=Eachin surf_list
		
			surf_no=surf_no+1
			
			If surf_no_get=surf_no Then Return surf
		
		Next
	
		Return Null
	
	End 
	
	Method FindSurface:TSurface(brush:TBrush)
	
		' ***note*** unlike B3D version, this will find a surface with no brush, if a null brush is supplied
	
		For Local surf:TSurface=Eachin surf_list
		
			If TBrush.CompareBrushes(brush,surf.brush)=True
				Return surf
			Endif
		
		Next
		
		Return Null
	
	End 
		
	' returns total no. of vertices in mesh
	Method CountVertices()
	
		Local verts=0
	
		For Local s=1 To CountSurfaces()
		
			Local surf:TSurface=GetSurface(s)	
		
			verts=verts+surf.CountVertices()
		
		Next
	
		Return verts
	
	End 
	
	' returns total no. of triangles in mesh
	Method CountTriangles()
	
		Local tris=0
	
		For Local s=1 To CountSurfaces()
		
			Local surf:TSurface=GetSurface(s)	
		
			tris=tris+surf.CountTriangles()
		
		Next
	
		Return tris
	
	End 
		
	' used by CopyEntity
	' recursive, returns number of bones
	Function CopyBonesList:List<TBone>(ent:TEntity, bone_list:List<TBone>, no_bones:Int=0)
		
		For Local ent:TEntity=Eachin ent.child_list
			If TBone(ent)<>Null

				bone_list.AddLast(TBone(ent))
				
			Endif
			CopyBonesList(ent,bone_list,no_bones)
		Next
		
		Return bone_list
		
	End 
	
	 ' used by LoadMesh
	Method CollapseAnimMesh:TMesh(mesh:TMesh=Null)
	
		If mesh=Null Then mesh=New TMesh
		
		If TMesh(Self)<>Null
			'Local new_mesh:TMesh=New TMesh 'TMesh(ent).CopyMesh() ' don't use copymesh, uses CreateMesh and adds to entity list
			'TMesh(Self).AddMesh(new_mesh)
			'new_mesh.TransformMesh(Self.mat)
			'new_mesh.AddMesh(mesh)
			TransformMesh(Self.mat)
			AddMesh(mesh)
		Endif
		
		mesh=CollapseChildren(Self,mesh)

		Return mesh

	End 
	
	' used by LoadMesh
	' has to be function as we need to use this function with all entities and not just meshes
	Function CollapseChildren:TMesh(ent0:TEntity,mesh:TMesh=Null)

		For Local ent:TEntity=Eachin ent0.child_list
			If TMesh(ent)<>Null
				'Local new_mesh:TMesh=New TMesh 'TMesh(ent).CopyMesh() ' don't use copymesh, uses CreateMesh and adds to entity list
				'TMesh(ent).AddMesh(new_mesh)
				'new_mesh.TransformMesh(ent.mat)
				'new_mesh.AddMesh(mesh)
				TMesh(ent).TransformMesh(ent.mat)
				TMesh(ent).AddMesh(mesh)
			Endif
			mesh=CollapseChildren(ent,mesh)
		Next
		
		Return mesh
		
	End 

	' used by LoadMesh
	Method TransformMesh(mat:Matrix)

		For Local s=1 To no_surfs
	
			Local surf:TSurface=GetSurface(s)
			
			If Not surf Then Continue
				
			For Local v=0 To surf.no_verts-1
		
				Local vx#=surf.vert_coords.Peek(v*3)
				Local vy#=surf.vert_coords.Peek(v*3+1)
				Local vz#=surf.vert_coords.Peek(v*3+2)
	
				surf.vert_coords.Poke(v*3, mat.grid[0][0]*vx + mat.grid[1][0]*vy + mat.grid[2][0]*vz + mat.grid[3][0] )
				surf.vert_coords.Poke(v*3+1, mat.grid[0][1]*vx + mat.grid[1][1]*vy + mat.grid[2][1]*vz + mat.grid[3][1] )
				surf.vert_coords.Poke(v*3+2, mat.grid[0][2]*vx + mat.grid[1][2]*vy + mat.grid[2][2]*vz + mat.grid[3][2] )

				Local nx#=surf.vert_norm.Peek(v*3)
				Local ny#=surf.vert_norm.Peek(v*3+1)
				Local nz#=surf.vert_norm.Peek(v*3+2)
	
				surf.vert_norm.Poke(v*3, mat.grid[0][0]*nx + mat.grid[1][0]*ny + mat.grid[2][0]*nz )
				surf.vert_norm.Poke(v*3+1, mat.grid[0][1]*nx + mat.grid[1][1]*ny + mat.grid[2][1]*nz )
				surf.vert_norm.Poke(v*3+2, mat.grid[0][2]*nx + mat.grid[1][2]*ny + mat.grid[2][2]*nz )

			Next
							
		Next

	End 
	
	
	Method MeshesIntersect:Bool( mesh2:TMesh)
		
		If mesh2 = Null Then Return False
		
		Local tree2:MeshCollider, hit:Bool = False
		Local vec1:Vector, vec2:Vector, vec3:Vector, vec4:Vector
		
		vec1 = New Vector(mesh2.mat.grid[0][0],mesh2.mat.grid[0][1],-mesh2.mat.grid[0][2])
		vec2 = New Vector(mesh2.mat.grid[1][0],mesh2.mat.grid[1][1],-mesh2.mat.grid[1][2])
		vec3 = New Vector(-mesh2.mat.grid[2][0],-mesh2.mat.grid[2][1],mesh2.mat.grid[2][2])
		vec4 = New Vector(mesh2.mat.grid[3][0],mesh2.mat.grid[3][1],-mesh2.mat.grid[3][2])
		
		Local mat1:Matrix = New Matrix(vec1,vec2,vec3)
		Local tform:Transform = New Transform(mat1,vec4)
		
		col_tree.CreateMeshTree(Self)	
		mesh2.col_tree.CreateMeshTree(mesh2) ' create collision tree for mesh if necessary
		tree2 = mesh2.col_tree.c_col_tree

		Local coll_obj:CollisionObject = New CollisionObject()
		hit = col_info.CollisionDetect(coll_obj, tform, tree2 ,COLLISION_METHOD_POLYGON)
		
		Return hit
		
	End
	
	
	Method AutoFade(cam:TCamera)

		Local dist#=cam.EntityDistance(Self)
		
		If dist>fade_near And dist<fade_far
		
			' fade_alpha will be in the range 0 (near) to 1 (far)
			fade_alpha=(dist-fade_near)/(fade_far-fade_near)
	
		Else
		
			' if entity outside near, far range then set min/max values
			If dist<fade_near Then fade_alpha=0.0 Else fade_alpha=1.0
			
		Endif

	End
	
	
	' used by MeshWidth, MeshHeight, MeshDepth, RenderWorld
	Method GetBounds()
	
		' only get new bounds if we have to
		' mesh.reset_bounds=True for all new meshes, plus set to True by various Mesh commands
		If reset_bounds=True
		
			reset_bounds=False
	
			min_x=999999999
			max_x=-999999999
			min_y=999999999
			max_y=-999999999
			min_z=999999999
			max_z=-999999999
			
			For Local surf:TSurface=Eachin surf_list
		
				For Local v=0 Until surf.no_verts
				
					Local x#=surf.vert_coords.Peek(v*3) ' surf.VertexX(v)
					If x<min_x Then min_x=x
					If x>max_x Then max_x=x
					
					Local y#=surf.vert_coords.Peek((v*3)+1) ' surf.VertexY(v)
					If y<min_y Then min_y=y
					If y>max_y Then max_y=y
					
					Local z#=-surf.vert_coords.Peek((v*3)+2) ' surf.VertexZ(v)
					If z<min_z Then min_z=z
					If z>max_z Then max_z=z
				
				Next
			
			Next
		
			' get mesh width, height, depth
			Local width#=max_x-min_x
			Local height#=max_y-min_y
			Local depth#=max_z-min_z

			' get bounding sphere (cull_radius#) from AABB
			' only get cull radius (auto cull), if cull radius hasn't been set to a negative no. by TEntity.MeshCullRadius (manual cull)
			If cull_radius>=0
				If width>=height And width>=depth
					cull_radius=width
				Else
					If height>=width And height>=depth
						cull_radius=height
					Else
						cull_radius=depth
					Endif
				Endif

				cull_radius=cull_radius * 0.5
				Local crs#=cull_radius*cull_radius
				cull_radius=Sqrt(crs+crs)'+crs)
				
			Endif
			
			' mesh centre
			center_x=min_x+(max_x-min_x)*0.5
			center_y=min_y+(max_y-min_y)*0.5
			center_z=min_z+(max_z-min_z)*0.5
		
		Endif

	End 

	' returns true if mesh is to be drawn with alpha, i.e alpha<1.0.
	' this func is used to see whether entity should be manually depth sorted (if alpha=true then yes).
	' alpha_enable true/false is also set for surfaces - this is used to sort alpha surfaces and enable/disable alpha blending 
	'
	Method Alpha:Bool()
	
		' ***note*** func doesn't taken into account fact that surf brush blend modes override master brush blend mode
		' when rendering. shouldn't be a problem, as will only incorrectly return true if master brush blend is 2 or 3,
		' while surf blend is 1. won't crop up often, and if it does, will only result in blending being enabled when it
		' shouldn't (may cause interference if surf tex is masked?).

		Local alpha:Bool=False

		' check master brush (check alpha value, blend value, force vertex alpha flag)
		If (brush.alpha<1.0) Or brush.blend=2 Or brush.blend=3 Or brush.fx&32
			
			alpha=True
			''cut out early if the whole thing is alpha??
			
		Else
		
			' tex 0 alpha flag
			If brush.tex[0]<>Null
				If brush.tex[0].flags&2<>0
					alpha=True
					
				Endif
			Endif
			
		Endif

		' check surf brushes
		For Local surf:TSurface=Eachin surf_list
		
			surf.alpha_enable=False
			
			If surf.brush<>Null
			
				If surf.brush.alpha<1.0 Or surf.brush.blend=2 Or surf.brush.blend=3 Or surf.brush.fx&32
				
					alpha=True
		
				Else
				
					If surf.brush.tex[0]<>Null
						If surf.brush.tex[0].flags&2<>0
							alpha=True
						Endif
					Endif
					
				Endif
			
			Endif
			
			' entity auto fade
			If fade_alpha<>0.0
				alpha=True
			Endif
			
			' set surf alpha_enable flag to true if mesh or surface has alpha properties
			If alpha=True
				surf.alpha_enable=True
			Endif
			
		Next
		
		Return alpha


	End 
	
	Method Update(cam:TCamera)
		
		''legacy use: may want to call Render()
		Print "TMesh update"
		
	End
	
End


	