package callisto_graphics

import "../asset"
import "../platform"
import cc "../common"

bind_context : proc(^Graphics_Context)

init : proc(^Graphics_Context, ^platform.Window_Context) -> (ok: bool) 

shutdown : proc(^Graphics_Context)

wait_until_idle : proc() 

create_shader : proc(shader_description: ^Shader_Description) -> (shader: Shader, ok: bool)

destroy_shader : proc(shader: Shader) 

create_material_from_shader : proc(shader: Shader) -> (material: Material, ok: bool)

destroy_material : proc(material: Material)

create_static_mesh : proc(mesh_asset: ^asset.Mesh) -> (mesh: Mesh, ok: bool)

destroy_static_mesh : proc(mesh: Mesh) 

create_texture : proc(texture_asset: ^asset.Texture) -> (texture: ^Texture, ok: bool)

destroy_texture : proc(texture: Texture) 

set_clear_color : proc(color: [4]f32)

// upload_uniforms_scene : proc(scene: Scene, uniforms: Scene_Uniforms)
upload_uniforms_render_pass : proc(/*render_pass: Render_Pass,*/ uniforms: ^cc.Render_Pass_Uniforms)
// upload_uniforms_material : proc(material: Material, uniforms: Material_Uniforms)
// upload_uniforms_instance : proc(instance: Instance, uniforms: Instance_Uniforms)

// ==============================================================================

cmd_begin_graphics : proc()
cmd_end_graphics : proc()
cmd_submit_graphics : proc()

cmd_begin_transfer : proc()
cmd_end_transfer : proc()
cmd_submit_transfer : proc()

cmd_begin_compute : proc()
cmd_end_compute : proc()
cmd_submit_compute : proc()

cmd_begin_render_pass : proc() 
cmd_end_render_pass : proc() 

cmd_bind_shader: proc(shader: Shader)

cmd_bind_uniforms_scene : proc()
cmd_bind_uniforms_render_pass : proc()
cmd_bind_uniforms_material : proc(material: Material) 
cmd_bind_uniforms_instance : proc()

cmd_draw_mesh : proc(mesh: Mesh) 
cmd_draw_model : proc(model: Model)
cmd_draw_model_immediate : proc(model: Model)

cmd_present : proc()

