"""Reproducible Blender rig for the supplied, previously unskinned Tripo mesh.
Run in Blender 5.2 background. Outputs stay in staging until visual QA passes.
Original source mesh and textures are never overwritten.
"""
import bpy
import os
import math
from pathlib import Path
from mathutils import Vector, Matrix, Quaternion

SOURCE = os.environ.get('KILLGORE_CREATURE_SOURCE', '')
if not SOURCE or not Path(SOURCE).is_file():
    raise SystemExit('Set KILLGORE_CREATURE_SOURCE to the original input GLB (not bundled; provenance pending).')
OUTPUT = Path(__file__).resolve().parents[2] / 'builds/creature_rig'
SCALE = 1.7
OUTPUT.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=SOURCE)
mesh = next(o for o in bpy.context.scene.objects if o.type == 'MESH')
mesh.name = 'CreatureSkin'
for v in mesh.data.vertices:
    v.co *= SCALE

# Measured independent left/right joint landmarks, in Blender's Z-up space.
legs = {
 'L1': [(-.045,-.155,.43),(-.155,-.215,.610),(-.290,-.310,.405),(-.370,-.360,.012)],
 'L2': [(-.060,-.085,.44),(-.210,-.090,.595),(-.380,-.115,.380),(-.453,-.133,.005)],
 'L3': [(-.065,-.025,.45),(-.230,.020,.552),(-.350,.090,.355),(-.370,.110,.009)],
 'L4': [(-.065,.035,.46),(-.200,.120,.592),(-.335,.270,.386),(-.405,.362,.008)],
 'R1': [(.045,-.155,.43),(.185,-.300,.505),(.340,-.445,.315),(.380,-.498,.008)],
 'R2': [(.060,-.105,.44),(.270,-.185,.518),(.395,-.250,.323),(.450,-.305,.010)],
 'R3': [(.070,-.055,.45),(.280,-.055,.538),(.400,-.025,.350),(.440,.020,.007)],
 'R4': [(.075,.015,.46),(.250,.100,.571),(.350,.210,.418),(.414,.251,.008)],
}
legs = {name:[Vector(p)*SCALE for p in points] for name,points in legs.items()}
# Below the abdomen the eight toes are separate connected components, while
# the hanging garment occupies different components. Use that topology to
# distinguish cloth from legs rather than letting a nearby leg drag the skirt.
low={v.index for v in mesh.data.vertices if v.co.z<.25*SCALE}
component_parent={i:i for i in low}
def component_root(i):
    while component_parent[i]!=i:
        component_parent[i]=component_parent[component_parent[i]]
        i=component_parent[i]
    return i
def component_join(a,b): component_parent[component_root(a)]=component_root(b)
for edge in mesh.data.edges:
    a,b=edge.vertices
    if a in low and b in low: component_join(a,b)
low_twins={}
for i in low:
    key=tuple(round(c,5) for c in mesh.data.vertices[i].co)
    if key in low_twins: component_join(i,low_twins[key])
    else: low_twins[key]=i
low_components={}
for i in low: low_components.setdefault(component_root(i),[]).append(i)
lower_leg_vertices={}
for name,points in legs.items():
    nearest=min(low,key=lambda i:(mesh.data.vertices[i].co-points[-1]).length_squared)
    ids=low_components[component_root(nearest)]
    assert len(ids)<500, 'Foot landmark resolved to garment rather than leg'
    tip=min(ids,key=lambda i:mesh.data.vertices[i].co.z)
    points[-1]=mesh.data.vertices[tip].co.copy()
    for i in ids: lower_leg_vertices[i]=name
arm_data = bpy.data.armatures.new('CorridorCreatureRig')
rig = bpy.data.objects.new('CorridorCreatureRig',arm_data)
bpy.context.collection.objects.link(rig)
bpy.context.view_layer.objects.active=rig
rig.select_set(True); mesh.select_set(False)
bpy.ops.object.mode_set(mode='EDIT')
def bone(name,head,tail,parent=None):
    b=arm_data.edit_bones.new(name)
    b.head=head; b.tail=tail
    if parent: b.parent=arm_data.edit_bones[parent]
    return b
def p(x,y,z): return Vector((x,y,z))*SCALE
bone('Root',p(0,0,0),p(0,0,.1))
bone('Body',p(0,.04,.43),p(0,.04,.53),'Root')
bone('SpineRear',p(0,.04,.48),p(0,.24,.58),'Body')
bone('Abdomen',p(0,.24,.58),p(0,.36,.68),'SpineRear')
bone('SpineFront',p(0,.04,.44),p(0,-.14,.42),'Body')
bone('Neck',p(0,-.14,.42),p(0,-.23,.41),'SpineFront')
bone('Head',p(0,-.23,.41),p(0,-.35,.38),'Neck')
bone('MantleUpper',p(0,.31,.58),p(0,.31,.33),'Abdomen')
bone('MantleLower',p(0,.31,.33),p(0,.31,.045),'MantleUpper')
for name,points in legs.items():
    for i,label in enumerate(('Upper','Lower','Tip')):
        bone('Leg'+name+'_'+label,points[i],points[i+1], 'SpineFront' if i==0 else 'Leg'+name+'_'+('Upper','Lower')[i-1])
    bone('Foot'+name,points[-1],points[-1]+p(0,0,.025),'Leg'+name+'_Tip')
bpy.ops.object.mode_set(mode='OBJECT')
mesh.parent=rig
modifier=mesh.modifiers.new('CreatureArmature','ARMATURE'); modifier.object=rig
for b in rig.data.bones: mesh.vertex_groups.new(name=b.name)

def distance_segment(point,a,b):
    t=max(0,min(1,(point-a).dot(b-a)/max((b-a).length_squared,1e-8)))
    return (point-(a+(b-a)*t)).length,t

# Bone-proximity weights with anatomical exclusion volumes. Preserve all UVs,
# normals and disconnected cloth islands; no remesh or destructive auto-weld.
for vertex in mesh.data.vertices:
    q=vertex.co; native=q/SCALE
    ranked=[]
    for name,points in legs.items():
        if vertex.index in lower_leg_vertices and lower_leg_vertices[vertex.index]!=name:
            continue
        for i,label in enumerate(('Upper','Lower','Tip')):
            d,t=distance_segment(q,points[i],points[i+1])
            ranked.append((d,'Leg'+name+'_'+label,name,i,t))
    ranked.sort()
    closest=ranked[0]
    body_core=abs(native.x)<.082 and -.19<native.y<.065
    head_core=abs(native.x)<.14 and native.y<-.245 and native.z>.26
    abdomen_core=native.y>.14 and native.z>.46 and abs(native.x)<.21
    cloth=native.y>.06 and native.z<.20
    threshold=(.100 if abs(native.x)>.29 else (.025 if cloth else .055))*SCALE
    lower_cloth=vertex.index in low and vertex.index not in lower_leg_vertices
    if not lower_cloth and (vertex.index in lower_leg_vertices or (closest[0]<threshold and not (body_core or head_core or abdomen_core))):
        chain=[item for item in ranked if item[2]==closest[2]][:2]
        weights={item[1]:math.exp(-((item[0]-closest[0])/(.017*SCALE))**2*2) for item in chain}
        if closest[3]==0 and closest[4]<.2:
            weights['SpineFront']=(1-closest[4]/.2)*.6
    else:
        if lower_cloth:
            t=max(0,min(1,(native.z-.15)/.28))
            weights={'MantleLower':1-t,'MantleUpper':t}
        elif native.y<-.235:
            weights={'Head':1.0}
        elif native.y<-.14:
            t=max(0,min(1,(-native.y-.14)/.095))
            weights={'Neck':1-t,'Head':t}
        elif native.y<.065:
            weights={'SpineFront':1.0}
        elif native.z<.48:
            t=max(0,min(1,(native.z-.15)/.28))
            weights={'MantleLower':1-t,'MantleUpper':t}
        else:
            weights={'Abdomen':1.0}
    total=sum(weights.values())
    for name,w in weights.items():
        if w>1e-5: mesh.vertex_groups[name].add([vertex.index],w/total,'REPLACE')

# Smooth across actual topology, including UV-split twins. Avoid abrupt
# leg/cloth assignments at a single polygon (the first QA caught these).
neighbors=[set() for _ in mesh.data.vertices]
twins={}
for v in mesh.data.vertices:
    key=tuple(round(c,5) for c in v.co)
    twins.setdefault(key,[]).append(v.index)
for e in mesh.data.edges:
    a,b=e.vertices;neighbors[a].add(b);neighbors[b].add(a)
for indices in twins.values():
    for a in indices: neighbors[a].update(i for i in indices if i!=a)
weights=[{g.group:g.weight for g in v.groups} for v in mesh.data.vertices]
for iteration in range(96):
    updated=[]
    for i,own in enumerate(weights):
        combined={g:w*.65 for g,w in own.items()}
        adjacent=neighbors[i]
        if adjacent:
            for j in adjacent:
                for g,w in weights[j].items(): combined[g]=combined.get(g,0)+w*.35/len(adjacent)
        kept=sorted(combined.items(),key=lambda item:item[1],reverse=True)[:4]
        total=sum(w for _,w in kept)
        updated.append({g:w/total for g,w in kept})
    weights=updated
# UV seams are duplicate vertices, not anatomical cuts. Enforce identical
# final influences so the skin cannot open a crack along a texture seam.
for indices in twins.values():
    if len(indices)<2: continue
    averaged={}
    for i in indices:
        for group,weight in weights[i].items():
            averaged[group]=averaged.get(group,0)+weight/len(indices)
    kept=sorted(averaged.items(),key=lambda item:item[1],reverse=True)[:4]
    total=sum(w for _,w in kept)
    for i in indices: weights[i]={g:w/total for g,w in kept}
for group in mesh.vertex_groups: group.remove(range(len(mesh.data.vertices)))
for i,values in enumerate(weights):
    for group,weight in values.items(): mesh.vertex_groups[group].add([i],weight,'REPLACE')

for pb in rig.pose.bones:
    pb.rotation_mode='QUATERNION'
    limit=100 if pb.name.startswith('Leg') else 28
    pb['angular_limit_degrees']=limit
    if pb.name!='Root':
        constraint=pb.constraints.new('LIMIT_ROTATION')
        constraint.name='AnatomicalLocalLimit'
        constraint.owner_space='LOCAL'
        for axis in ('x','y','z'):
            setattr(constraint,'use_limit_'+axis,True)
            setattr(constraint,'min_'+axis,-math.radians(limit))
            setattr(constraint,'max_'+axis,math.radians(limit))

rest={b.name:b.matrix_local.copy() for b in rig.data.bones}
def align(name,head,tail):
    b=rig.data.bones[name]
    rotation=(b.tail_local-b.head_local).rotation_difference(tail-head).to_matrix().to_4x4()
    rig.pose.bones[name].matrix=Matrix.Translation(head) @ rotation @ rest[name].to_3x3().to_4x4()
    # A child's matrix setter converts through its evaluated parent pose.
    # Flush the parent change before solving the next joint in the chain.
    bpy.context.view_layer.update()

def leg_pose(name,foot):
    hip,knee,ankle,end=[point.copy() for point in legs[name]]
    body_delta=rig.pose.bones['SpineFront'].matrix @ rest['SpineFront'].inverted()
    hip=body_delta @ hip
    # Solve all three segments. A two-link solve plus an aimed toe can leave
    # the actual mesh tip airborne when the ankle target is out of reach.
    points=[hip,knee,ankle,end]
    lengths=[(legs[name][i+1]-legs[name][i]).length for i in range(3)]
    if (foot-hip).length>sum(lengths)-.0001:
        foot=hip+(foot-hip).normalized()*(sum(lengths)-.0001)
    for _ in range(24):
        points[3]=foot.copy()
        for i in (2,1,0):
            points[i]=points[i+1]+(points[i]-points[i+1]).normalized()*lengths[i]
        points[0]=hip.copy()
        for i in range(3):
            points[i+1]=points[i]+(points[i+1]-points[i]).normalized()*lengths[i]
        if (points[3]-foot).length<.00001: break
    for i,label in enumerate(('Upper','Lower','Tip')):
        align('Leg'+name+'_'+label,points[i],points[i+1])

clips={'Idle':(2.4,0),'Alert':(.72,0),'Walk':(.9,.22),'Run':(.48,.36),
       'TurnLeft':(.8,.07),'TurnRight':(.8,.07),'LightStop':(.65,0),
       'Retreat':(.8,-.18),'WindUp':(.56,0),'Attack':(.28,0),
       'Recovery':(.65,0),'Blocked':(1.1,0)}
scene=bpy.context.scene; scene.render.fps=60
rig.animation_data_create()
for clip,(duration,stride) in clips.items():
    action=bpy.data.actions.new(clip); rig.animation_data.action=action
    count=round(duration*60)
    for frame in range(count+1):
        u=frame/count; phase=u*math.tau
        scene.frame_set(frame)
        for pb in rig.pose.bones: pb.matrix_basis=Matrix.Identity(4)
        breath=math.sin(phase)
        body=rig.pose.bones['Body']
        body_offset=Vector((0,0,(.0025 if stride==0 else .0035)*SCALE*breath))
        lean=0.0
        if clip in ('TurnLeft','TurnRight'): lean=(1 if clip=='TurnLeft' else -1)*.06*math.sin(math.pi*u)
        charge=math.sin(math.pi*u)
        if clip in ('WindUp','LightStop','Blocked'): body_offset.z-=.012*SCALE*charge
        if clip=='Attack': body_offset.y-=.025*SCALE*charge
        body.location=rest['Body'].to_3x3().inverted() @ body_offset
        rig.pose.bones['MantleLower'].location=rest['MantleLower'].to_3x3().inverted() @ Vector((0,0,-body_offset.z))
        for name,angle in [('SpineFront',lean),('Abdomen',-lean*.6),('Neck',lean*.6)]:
            local_axis=rest[name].to_3x3().inverted() @ Vector((0,0,1))
            rig.pose.bones[name].rotation_quaternion=Quaternion(local_axis.normalized(),angle)
        head=rig.pose.bones['Head']
        tilt=(.06*charge if clip=='Alert' else (-.11*charge if clip=='WindUp' else .018*breath))
        head.rotation_quaternion=Quaternion((rest['Head'].to_3x3().inverted() @ Vector((1,0,0))).normalized(),tilt)
        bpy.context.view_layer.update()
        for j,(name,points) in enumerate(legs.items()):
            foot=points[-1].copy()
            # The source has several hovering toes. Plant their actual mesh
            # endpoints, not the guessed end of an oversized virtual bone.
            foot.z=.003*SCALE
            offset=((j%4)*.25+(.5 if name.startswith('R') else 0))%1
            t=(u+offset)%1
            if stride:
                if t<.64:
                    travel=(t/.64-.5)*stride
                    lift=0
                else:
                    swing=(t-.64)/.36
                    travel=(.5-swing)*stride
                    lift=math.sin(math.pi*swing)*(.10 if clip=='Run' else .075)
                if clip in ('TurnLeft','TurnRight'):
                    angle=travel/stride*.8*.64*(-1 if clip=='TurnLeft' else 1)
                    foot=Matrix.Rotation(angle,3,'Z') @ foot
                else:
                    foot.y+=travel*SCALE
                foot.z+=lift*SCALE
            if clip in ('WindUp','Attack') and name.endswith('1'):
                if clip=='WindUp':
                    foot.z+=.10*SCALE*charge
                    foot.y+=.045*SCALE*charge
                else:
                    foot.x*=1-.75*charge
                    foot.z+=.20*SCALE*charge
                    foot.y-=.24*SCALE*charge
            leg_pose(name,foot)
        for pb in rig.pose.bones:
            pb.keyframe_insert('location',frame=frame,group=pb.name)
            pb.keyframe_insert('rotation_quaternion',frame=frame,group=pb.name)
            pb.keyframe_insert('scale',frame=frame,group=pb.name)
    track=rig.animation_data.nla_tracks.new();track.name=clip
    strip=track.strips.new(clip,0,action);strip.name=clip
    track.mute=True
    action.use_fake_user=True
    print('BAKED_CLIP',clip,count+1)
rig.animation_data.action=None
scene.frame_set(0)
for pb in rig.pose.bones: pb.matrix_basis=Matrix.Identity(4)
bpy.ops.wm.save_as_mainfile(filepath=str(OUTPUT/'corridor_creature.blend'))
bpy.ops.export_scene.gltf(filepath=str(OUTPUT/'corridor_creature.glb'),export_format='GLB',export_animations=True,export_animation_mode='ACTIONS',export_force_sampling=True,export_skins=True,export_yup=True)
print('CREATURE_RIG_STAGED',len(rig.data.bones),len(mesh.data.vertices),len(clips))
