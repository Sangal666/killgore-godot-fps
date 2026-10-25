"""Render an unlit, orthographic head projection for aligned texture painting.
Temporary inspection scene only; original authoring file is never saved.
"""
import bpy
from pathlib import Path
from mathutils import Vector
PROJECT=Path(__file__).resolve().parents[2]
OUT=Path('/private/tmp/killgore_puppet_v2')
OUT.mkdir(exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(PROJECT/'tools/creature/authoring/corridor_creature.blend'))
mesh=next(o for o in bpy.context.scene.objects if o.type=='MESH')
rig=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
rig.data.pose_position='REST'
names={g.index:g.name for g in mesh.vertex_groups}
head_vertices={v.index for v in mesh.data.vertices if sum(g.weight for g in v.groups if names[g.group]=='Head')>.5}
# Hide all non-head triangles in this disposable scene.
for poly in mesh.data.polygons:
    poly.material_index=0
source=next(n.image for n in mesh.data.materials[0].node_tree.nodes if n.type=='TEX_IMAGE' and n.image and 'basecolor' in n.image.name)
material=bpy.data.materials.new('UnlitHeadReference');material.use_nodes=True
n=material.node_tree.nodes;n.clear();links=material.node_tree.links
tex=n.new('ShaderNodeTexImage');tex.image=source
em=n.new('ShaderNodeEmission');links.new(tex.outputs['Color'],em.inputs[0])
out=n.new('ShaderNodeOutputMaterial');links.new(em.outputs[0],out.inputs['Surface'])
mesh.data.materials.clear();mesh.data.materials.append(material)
# Remove non-head geometry from a temporary copy, never from the source file.
import bmesh
bm=bmesh.new();bm.from_mesh(mesh.data)
bm.verts.ensure_lookup_table()
bmesh.ops.delete(bm,geom=[v for v in bm.verts if v.index not in head_vertices],context='VERTS')
bm.to_mesh(mesh.data);bm.free()
camera_data=bpy.data.cameras.new('Projection')
camera=bpy.data.objects.new('Projection',camera_data);bpy.context.collection.objects.link(camera)
# Exact bounds reused by the texture projection bake: x [-.18,.26], z [.49,.93].
camera.location=(.04,-3,.71)
camera.rotation_euler=(Vector((.04,0,.71))-camera.location).to_track_quat('-Z','Y').to_euler()
camera_data.type='ORTHO';camera_data.ortho_scale=.44
scene=bpy.context.scene;scene.camera=camera
scene.render.engine='CYCLES';scene.cycles.samples=1
scene.world=bpy.data.worlds.new('BlackBackground');scene.world.color=(0,0,0)
scene.render.resolution_x=1024;scene.render.resolution_y=1024;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG';scene.render.film_transparent=False
scene.view_settings.view_transform='Standard'
scene.render.filepath=str(OUT/'head_projection_original.png')
bpy.ops.render.render(write_still=True)
print('PUPPET_HEAD_PROJECTION_OK',scene.render.filepath)
