"""Blender-side structural/deformation QA, independent of game integration.
Checks every exported clip at 13 points, including both ends of each cycle.
The report is evidence, not a substitute for visual review.
"""
import bpy
import json
import hashlib
from pathlib import Path

staging=Path(__file__).resolve().parents[2] / 'builds/creature_rig'
bpy.ops.wm.open_mainfile(filepath=str(staging/'corridor_creature.blend'))
rig=bpy.data.objects['CorridorCreatureRig']
mesh=bpy.data.objects['CreatureSkin']
assert len(rig.data.bones)==41
assert len(bpy.data.actions)==12
assert all(abs(sum(g.weight for g in v.groups)-1)<1e-4 for v in mesh.data.vertices)
assert all(1<=len(v.groups)<=4 for v in mesh.data.vertices)
edges=[]
for edge in mesh.data.edges:
    a,b=edge.vertices
    length=(mesh.data.vertices[a].co-mesh.data.vertices[b].co).length
    if length>=.003: edges.append((a,b,length))
report={'bones':41,'vertices':len(mesh.data.vertices),'glb_sha256':hashlib.sha256((staging/'corridor_creature.glb').read_bytes()).hexdigest(),'clips':{}}
for action in bpy.data.actions:
    rig.animation_data.action=action
    first,last=action.frame_range
    summary={'max_edge_stretch':1.0,'max_stretched_edges':0,'minimum_z':0.0}
    for sample in range(13):
        bpy.context.scene.frame_set(int(round(first+(last-first)*sample/12)))
        bpy.context.view_layer.update()
        obj=mesh.evaluated_get(bpy.context.evaluated_depsgraph_get())
        evaluated=obj.to_mesh()
        ratios=[(evaluated.vertices[a].co-evaluated.vertices[b].co).length/length for a,b,length in edges]
        summary['max_edge_stretch']=max(summary['max_edge_stretch'],max(ratios))
        summary['max_stretched_edges']=max(summary['max_stretched_edges'],sum(r>2 for r in ratios))
        summary['minimum_z']=min(summary['minimum_z'],min(v.co.z for v in evaluated.vertices))
        obj.to_mesh_clear()
    report['clips'][action.name]=summary
    print('RIG_CLIP_AUDIT',action.name,json.dumps(summary),flush=True)
(staging/'rig_qa.json').write_text(json.dumps(report,indent=2))
print('RIG_STRUCTURAL_CHECKS_OK')
