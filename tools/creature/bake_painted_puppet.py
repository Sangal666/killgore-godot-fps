"""Bake the approved painted-puppet surface onto the existing UVs.

Blender background script. Reads the authoring rig; never saves/re-exports it.
Only two new PNG assets are written. No geometry, weights or animation changes.
"""
import bpy
import math
from pathlib import Path
from mathutils import Vector

PROJECT = Path(__file__).resolve().parents[2]
OUTPUT = PROJECT / 'assets/characters/corridor_creature/painted_puppet'
OUTPUT.mkdir(exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(PROJECT / 'tools/creature/authoring/corridor_creature.blend'))
mesh = next(o for o in bpy.context.scene.objects if o.type == 'MESH')
rig = next(o for o in bpy.context.scene.objects if o.type == 'ARMATURE')
rig.data.pose_position = 'REST'
source = next(n.image for n in mesh.data.materials[0].node_tree.nodes
              if n.type == 'TEX_IMAGE' and n.image and 'basecolor' in n.image.name)

def smooth(a, b, x):
    t = max(0.0, min(1.0, (x-a)/(b-a)))
    return t*t*(3.0-2.0*t)

# Masks are derived from the actual anatomical weights, not mesh/node names.
regions = mesh.data.color_attributes.new(name='PuppetRegions', type='FLOAT_COLOR', domain='POINT')
makeup = mesh.data.color_attributes.new(name='PuppetMakeup', type='FLOAT_COLOR', domain='POINT')
leg_bones = [b for b in rig.data.bones if b.name.startswith('Leg')]
for v in mesh.data.vertices:
    weights = {mesh.vertex_groups[g.group].name:g.weight for g in v.groups}
    head = min(1.0, weights.get('Head',0.0)+weights.get('Neck',0.0)*0.4)
    cloth = min(1.0, weights.get('MantleUpper',0.0)+weights.get('MantleLower',0.0))
    leg = sum(w for name,w in weights.items() if name.startswith('Leg'))
    joint_distance = min((v.co-b.head_local).length for b in leg_bones if not b.name.endswith('Upper'))
    joints = (1.0-smooth(0.035,0.063,joint_distance))*smooth(0.35,0.75,leg)
    regions.data[v.index].color = (head,cloth,joints,1.0)
    # Projected blush and small painted mouth; original eye/tear texture survives.
    x,y,z = v.co
    front = 1.0-smooth(-0.49,-0.43,y)
    cheeks = math.exp(-((abs(x)-0.070)/0.025)**2-((z-0.685)/0.028)**2)*front
    lips = math.exp(-(x/0.024)**4-((z-0.639)/0.012)**2)*front
    hair = max(smooth(0.114,0.145,abs(x)),smooth(0.80,0.83,z))
    makeup.data[v.index].color = (cheeks,lips,hair,1.0)

mat = bpy.data.materials.new('PaintedPuppetBake')
mat.use_nodes = True
nodes = mat.node_tree.nodes
nodes.clear()
links = mat.node_tree.links
def node(kind, **props):
    n=nodes.new(kind)
    for k,v in props.items(): setattr(n,k,v)
    return n
def connect(value, socket):
    if isinstance(value, bpy.types.NodeSocket): links.new(value,socket)
    else: socket.default_value=value
def math_node(op,a,b=0):
    n=node('ShaderNodeMath',operation=op)
    connect(a,n.inputs[0]); connect(b,n.inputs[1]); return n.outputs[0]
def ramp(value, points):
    n=node('ShaderNodeValToRGB')
    n.color_ramp.elements.remove(n.color_ramp.elements[1])
    for i,(position,color) in enumerate(points):
        e=n.color_ramp.elements[0] if i==0 else n.color_ramp.elements.new(position)
        e.position=position; e.color=(*color,1)
    connect(value,n.inputs[0]); return n.outputs['Color']
def mix(f,a,b):
    n=node('ShaderNodeMixRGB',blend_type='MIX')
    connect(f,n.inputs[0]);connect(a,n.inputs[1]);connect(b,n.inputs[2]);return n.outputs[0]
def noise(vector,scale,detail=2):
    n=node('ShaderNodeTexNoise'); connect(vector,n.inputs['Vector'])
    n.inputs['Scale'].default_value=scale;n.inputs['Detail'].default_value=detail
    return n.outputs['Fac']
def vector_scale(vector, scale):
    n=node('ShaderNodeVectorMath',operation='MULTIPLY');connect(vector,n.inputs[0]);n.inputs[1].default_value=scale
    return n.outputs[0]
geo=node('ShaderNodeNewGeometry')
pos=geo.outputs['Position']
attr=node('ShaderNodeVertexColor',layer_name='PuppetRegions')
sep=node('ShaderNodeSeparateColor');connect(attr.outputs['Color'],sep.inputs[0])
head,cloth,joints=[sep.outputs[i] for i in range(3)]
make=node('ShaderNodeVertexColor',layer_name='PuppetMakeup')
make_sep=node('ShaderNodeSeparateColor');connect(make.outputs['Color'],make_sep.inputs[0])
original=node('ShaderNodeTexImage');original.image=source
luma=node('ShaderNodeRGBToBW');connect(original.outputs['Color'],luma.inputs[0])

# Long grain under broad chipped mint paint: colour changes have a physical cause.
grain=noise(vector_scale(pos,(32,32,1.2)),3,2)
wood=ramp(grain,[(0.20,(0.018,0.006,0.003)),(0.47,(0.055,0.017,0.007)),(0.70,(0.11,0.040,0.015)),(0.83,(0.18,0.080,0.027))])
wear=noise(pos,9,2)
chips=ramp(wear,[(0.37,(0,0,0)),(0.475,(0,0,0)),(0.51,(1,1,1))])
paint=ramp(noise(pos,5,2),[(0.20,(0.025,0.075,0.042)),(0.52,(0.070,0.18,0.105)),(0.80,(0.16,0.29,0.18))])
surface=mix(chips,wood,paint)
surface=mix(joints,surface,(0.23,0.018,0.012,1))
# Fabric remains fabric, not painted wood; dark water-stained ochre folds.
fabric=ramp(luma.outputs[0],[(0.0,(0.012,0.008,0.003)),(0.035,(0.045,0.026,0.008)),(0.14,(0.18,0.115,0.034)),(0.42,(0.32,0.235,0.095))])
surface=mix(cloth,surface,fabric)
# Keep source eye sockets/tears/hair dark; ivory paint only on light face areas.
face=ramp(luma.outputs[0],[(0.015,(0.006,0.004,0.002)),(0.055,(0.025,0.012,0.005)),(0.13,(0.12,0.075,0.035)),(0.24,(0.28,0.235,0.15)),(0.60,(0.39,0.34,0.24))])
face=mix(math_node('MULTIPLY',make_sep.outputs[0],0.80),face,(0.31,0.022,0.018,1))
face=mix(make_sep.outputs[1],face,(0.16,0.004,0.006,1))
hair_color=ramp(grain,[(0.2,(0.006,0.004,0.002)),(0.65,(0.045,0.022,0.007)),(0.85,(0.13,0.07,0.020))])
face=mix(make_sep.outputs[2],face,hair_color)
# Fine crazing baked once: no animated shader noise or distant aliasing.
cracks=node('ShaderNodeTexVoronoi',feature='DISTANCE_TO_EDGE')
connect(pos,cracks.inputs['Vector']);cracks.inputs['Scale'].default_value=46
crack_mask=math_node('LESS_THAN',cracks.outputs['Distance'],0.013)
face=mix(math_node('MULTIPLY',crack_mask,0.48),face,(0.045,0.024,0.009,1))
surface=mix(head,surface,face)
roughness=mix(cloth,mix(chips,(0.68,0.68,0.68,1),(0.77,0.77,0.77,1)),(0.96,0.96,0.96,1))
roughness=mix(head,roughness,(0.80,0.80,0.80,1))

emission=node('ShaderNodeEmission');connect(surface,emission.inputs['Color'])
output=node('ShaderNodeOutputMaterial');connect(emission.outputs[0],output.inputs['Surface'])
mesh.data.materials.clear();mesh.data.materials.append(mat)
bpy.ops.object.select_all(action='DESELECT')
mesh.select_set(True);bpy.context.view_layer.objects.active=mesh
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=1
scene.render.bake.margin=12
scene.render.bake.use_clear=True
target=node('ShaderNodeTexImage')
for name,color in [('puppet_albedo',surface),('puppet_roughness',roughness)]:
    image=bpy.data.images.new(name,width=2048,height=2048,alpha=False)
    image.colorspace_settings.name='sRGB' if name.endswith('albedo') else 'Non-Color'
    target.image=image;nodes.active=target
    connect(color,emission.inputs['Color'])
    bpy.ops.object.bake(type='EMIT')
    image.filepath_raw=str(OUTPUT/(name+'.png'));image.file_format='PNG';image.save()
    print('PUPPET_BAKED',image.filepath_raw)
print('PUPPET_BAKE_OK original rig and materials untouched')
