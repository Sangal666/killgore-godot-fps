"""Anatomically map authored surface paintings into the unchanged game UVs.

Source images are versioned in authoring/painted_puppet_v2. The original rig,
animations, topology, normals and UVs are never saved or re-exported.
"""
import bpy
import math
from pathlib import Path
from mathutils import Vector

PROJECT=Path(__file__).resolve().parents[2]
SOURCE=PROJECT/'tools/creature/authoring/painted_puppet_v2'
OUT=PROJECT/'assets/characters/corridor_creature/painted_puppet_v2'
OUT.mkdir(exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(PROJECT/'tools/creature/authoring/corridor_creature.blend'))
mesh=next(o for o in bpy.context.scene.objects if o.type=='MESH')
rig=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
rig.data.pose_position='REST'
original_material=mesh.data.materials[0]
original_color=next(n.image for n in original_material.node_tree.nodes if n.type=='TEX_IMAGE' and n.image and 'basecolor' in n.image.name)
original_normal=next(n.image for n in original_material.node_tree.nodes if n.type=='TEX_IMAGE' and n.image and 'normal' in n.image.name)
names={g.index:g.name for g in mesh.vertex_groups}
weights=[{names[g.group]:g.weight for g in v.groups} for v in mesh.data.vertices]
leg_bones=[b for b in rig.data.bones if b.name.startswith('Leg')]
wood_uv=mesh.data.uv_layers.new(name='PuppetWood')
face_uv=mesh.data.uv_layers.new(name='PuppetFace')
cloth_uv=mesh.data.uv_layers.new(name='PuppetCloth')
regions=mesh.data.color_attributes.new(name='AuthoredRegions',type='FLOAT_COLOR',domain='CORNER')
front_attr=mesh.data.color_attributes.new(name='AuthoredFaceFront',type='FLOAT_COLOR',domain='CORNER')

def smooth(a,b,x):
    t=max(0,min(1,(x-a)/(b-a)))
    return t*t*(3-2*t)

for poly in mesh.data.polygons:
    group_scores={b.name:sum(weights[i].get(b.name,0) for i in poly.vertices) for b in leg_bones}
    bone_name=max(group_scores,key=group_scores.get)
    bone=rig.data.bones[bone_name]
    axis=bone.tail_local-bone.head_local
    length=axis.length;axis.normalize()
    ref=Vector((0,0,1)) if abs(axis.z)<.9 else Vector((0,1,0))
    across=axis.cross(ref).normalized();other=axis.cross(across).normalized()
    us=[]
    for li in poly.loop_indices:
        vertex=mesh.data.vertices[mesh.data.loops[li].vertex_index]
        q=vertex.co;w=weights[vertex.index]
        head=min(1,w.get('Head',0)+w.get('Neck',0)*.25)
        cloth=min(1,w.get('MantleUpper',0)+w.get('MantleLower',0))
        leg=sum(value for name,value in w.items() if name.startswith('Leg'))
        if group_scores[bone_name]>.65:
            delta=q-bone.head_local
            t=delta.dot(axis)/length
            radial=delta-axis*delta.dot(axis)
            u=math.atan2(radial.dot(other),radial.dot(across))/math.tau+.5
            v=.08+t*.84
            # A thin ring slightly away from the joint, not a red spherical blob.
            stripe_dist=min(abs(t*length-.030),abs((1-t)*length-.030))
            stripe=(1-smooth(.004,.010,stripe_dist))*smooth(.4,.8,leg)
            wood_uv.data[li].uv=(u,v)
        else:
            # Planar carving direction on the shell: cylindrical projection
            # pinched every brush mark into a starburst at the upper pole.
            u=(q.x+.35)/.70
            wood_uv.data[li].uv=(u,(q.z-.35)/1.05)
            stripe=0
        us.append(wood_uv.data[li].uv.x)
        face_uv.data[li].uv=((q.x+.18)/.44,(q.z-.49)/.44)
        cloth_uv.data[li].uv=((q.x+.4)/.8,(q.z-.03)/1.0)
        regions.data[li].color=(head,cloth,leg,length)
        facing=1-smooth(-.45,-.10,poly.normal.y)
        front=(1-smooth(-.48,-.40,q.y))*facing
        front_attr.data[li].color=(front,front,front,1)
    if group_scores[bone_name]>.65 and max(us)-min(us)>.5:
        for li in poly.loop_indices:
            if wood_uv.data[li].uv.x<.5: wood_uv.data[li].uv.x+=1

mat=bpy.data.materials.new('AuthoredPaintedPuppetBake');mat.use_nodes=True
nodes=mat.node_tree.nodes;nodes.clear();links=mat.node_tree.links
def node(kind,**props):
    n=nodes.new(kind)
    for k,v in props.items():setattr(n,k,v)
    return n
def connect(value,socket):
    if isinstance(value,bpy.types.NodeSocket):links.new(value,socket)
    else:socket.default_value=value
def mix(f,a,b,kind='MIX'):
    n=node('ShaderNodeMixRGB',blend_type=kind)
    connect(f,n.inputs[0]);connect(a,n.inputs[1]);connect(b,n.inputs[2]);return n.outputs[0]
def math_node(op,a,b):
    n=node('ShaderNodeMath',operation=op);connect(a,n.inputs[0]);connect(b,n.inputs[1]);return n.outputs[0]
def texture(path,uv,extension='REPEAT'):
    n=node('ShaderNodeTexImage',extension=extension)
    n.image=bpy.data.images.load(str(path))
    u=node('ShaderNodeUVMap',uv_map=uv);connect(u.outputs[0],n.inputs[0])
    return n.outputs['Color']
def box_texture(path):
    # Blend three projections so side/back surfaces cannot collapse to one
    # image column. This exists only during baking, never in the game shader.
    n=node('ShaderNodeTexImage',projection='BOX',projection_blend=.25)
    n.image=bpy.data.images.load(str(path))
    coord=node('ShaderNodeTexCoord')
    connect(coord.outputs['Generated'],n.inputs[0])
    return n.outputs['Color']
def bw(color):
    n=node('ShaderNodeRGBToBW');connect(color,n.inputs[0]);return n.outputs[0]
def ramp(value,points):
    n=node('ShaderNodeValToRGB');n.color_ramp.elements.remove(n.color_ramp.elements[1])
    for i,(pos,color) in enumerate(points):
        e=n.color_ramp.elements[0] if i==0 else n.color_ramp.elements.new(pos)
        e.position=pos;e.color=(*color,1)
    connect(value,n.inputs[0]);return n.outputs[0]

attr=node('ShaderNodeVertexColor',layer_name='AuthoredRegions')
sep=node('ShaderNodeSeparateColor');connect(attr.outputs[0],sep.inputs[0])
head,cloth,leg=[sep.outputs[i] for i in range(3)]
front=node('ShaderNodeVertexColor',layer_name='AuthoredFaceFront').outputs[0]
wood=texture(SOURCE/'painted_wood.png','PuppetWood')
shell=box_texture(SOURCE/'shell_paint.png')
fabric=box_texture(SOURCE/'stained_linen.png')
face=texture(SOURCE/'face_projection.png','PuppetFace','EXTEND')
# The source painting is unlit ivory. Keep its albedo below paper-white so the
# actual gameplay flashlight retains cracks/makeup instead of clipping them.
face=mix(1,face,(.60,.60,.60,1),'MULTIPLY')
# Actual painted narrow bands acquire their own chipped paint/grain, not flat red.
band=ramp(bw(wood),[(.005,(.022,.006,.003)),(.04,(.075,.007,.004)),(.12,(.26,.025,.012)),(.35,(.32,.030,.013))])
# Evaluate the thin stripe per texel, not just at sparse joint vertices.
leg_uv_node=node('ShaderNodeUVMap',uv_map='PuppetWood')
leg_uv_sep=node('ShaderNodeSeparateXYZ');connect(leg_uv_node.outputs[0],leg_uv_sep.inputs[0])
t=math_node('DIVIDE',math_node('SUBTRACT',leg_uv_sep.outputs['Y'],.08),.84)
near_end=math_node('MINIMUM',t,math_node('SUBTRACT',1,t))
metres=math_node('MULTIPLY',near_end,attr.outputs['Alpha'])
distance=math_node('ABSOLUTE',math_node('SUBTRACT',metres,.030),0)
stripe=math_node('MULTIPLY',math_node('LESS_THAN',distance,.010),leg)
surface=mix(stripe,mix(leg,shell,wood),band)
surface=mix(cloth,surface,fabric)
# Back/sides of the hair stay dark wood; never duplicate the face around the skull.
hair=ramp(bw(wood),[(0,(.004,.003,.001)),(.2,(.018,.010,.004)),(.6,(.065,.033,.009))])
head_color=mix(front,hair,face)
surface=mix(head,surface,head_color)
# Preserve subtle sculpted source surface shading without retaining old colors.
old=node('ShaderNodeTexImage');old.image=original_color
shade=ramp(bw(old.outputs[0]),[(0,(.70,.70,.70)),(.25,(1,1,1))])
surface=mix(.35,surface,mix(1,surface,shade,'MULTIPLY'))
rough=ramp(bw(wood),[(0,(.78,.78,.78)),(.28,(.68,.68,.68)),(.65,(.83,.83,.83))])
rough=mix(cloth,rough,(.96,.96,.96,1));rough=mix(head,rough,(.82,.82,.82,1))

em=node('ShaderNodeEmission')
out=node('ShaderNodeOutputMaterial');connect(em.outputs[0],out.inputs['Surface'])
target=node('ShaderNodeTexImage')
mesh.data.materials.clear();mesh.data.materials.append(mat)
bpy.ops.object.select_all(action='DESELECT');mesh.select_set(True);bpy.context.view_layer.objects.active=mesh
mesh.data.uv_layers.active=mesh.data.uv_layers[0]
mesh.data.uv_layers[0].active_render=True
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=1;scene.cycles.device='CPU'
scene.render.bake.margin=16;scene.render.bake.use_clear=True
def bake(name,kind,size,color=None):
    image=bpy.data.images.new(name,width=size,height=size,alpha=False)
    image.colorspace_settings.name='sRGB' if name=='puppet_albedo' else 'Non-Color'
    target.image=image;nodes.active=target
    if color is not None:connect(color,em.inputs['Color'])
    bpy.ops.object.bake(type=kind)
    image.filepath_raw=str(OUT/(name+'.png'));image.file_format='PNG';image.save()
    print('AUTHORED_PUPPET_BAKED',image.filepath_raw)
bake('puppet_albedo','EMIT',4096,surface)
bake('puppet_roughness','EMIT',2048,rough)
# Tactile small-scale paint cracks/fibres over the original tangent-space normals.
normal_tex=node('ShaderNodeTexImage');normal_tex.image=original_normal
normal_tex.image.colorspace_settings.name='Non-Color'
normal=node('ShaderNodeNormalMap');connect(normal_tex.outputs[0],normal.inputs['Color'])
bump=node('ShaderNodeBump');bump.inputs['Strength'].default_value=.22;bump.inputs['Distance'].default_value=.0015
connect(bw(surface),bump.inputs['Height']);connect(normal.outputs[0],bump.inputs['Normal'])
bsdf=node('ShaderNodeBsdfPrincipled');connect(bump.outputs[0],bsdf.inputs['Normal']);connect(surface,bsdf.inputs['Base Color'])
connect(bsdf.outputs[0],out.inputs['Surface'])
bake('puppet_normal','NORMAL',2048)
print('AUTHORED_PUPPET_OK unchanged rig/UV/animation; generated images projected and baked')
