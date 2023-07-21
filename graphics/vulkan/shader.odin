package callisto_graphics_vulkan

import "core:os"
import "core:log"
import "core:mem"
import vk "vendor:vulkan"
// Graphics common
import "../common"

create_shader :: proc(shader_description: ^common.Shader_Description, shader: ^common.Shader) -> (ok: bool) {
    state := bound_state
    cvk_shader, err := mem.new(CVK_Shader); if err != nil {
        log.error("Failed to create shader:", err)
        return false
    }
    defer if !ok do mem.free(cvk_shader)

    vert_file, err1 := os.open(shader_description.vertex_shader_path)
    if err1 != os.ERROR_NONE {
        log.error("Failed to open file", shader_description.vertex_shader_path, ":", err1)
        return false
    }
    defer os.close(vert_file)

    frag_file, err2 := os.open(shader_description.fragment_shader_path)
    if err2 != os.ERROR_NONE {
        log.error("Failed to open file", shader_description.fragment_shader_path, ":", err2)
        return false
    }
    defer os.close(frag_file)

    vert_module := create_shader_module(state.device, vert_file) or_return
    defer vk.DestroyShaderModule(state.device, vert_module, nil)
    frag_module := create_shader_module(state.device, frag_file) or_return
    defer vk.DestroyShaderModule(state.device, frag_module, nil)

    shader_stages := [?]vk.PipelineShaderStageCreateInfo {
        // Vertex
        {
            sType = .PIPELINE_SHADER_STAGE_CREATE_INFO,
            stage = {.VERTEX},
            module = vert_module,
            pName = "main",
        },
        // Fragment
        {
            sType = .PIPELINE_SHADER_STAGE_CREATE_INFO,
            stage = {.FRAGMENT},
            module = frag_module,
            pName = "main",
        },
    }

    dynamic_state_create_info: vk.PipelineDynamicStateCreateInfo = {
        sType             = .PIPELINE_DYNAMIC_STATE_CREATE_INFO,
        dynamicStateCount = u32(len(dynamic_states)),
        pDynamicStates    = raw_data(dynamic_states),
    }

    binding_desc := get_vertex_binding_description(shader_description.vertex_typeid)
    attribute_descs: [dynamic]vk.VertexInputAttributeDescription
    defer delete(attribute_descs)
    ok = get_vertex_attribute_descriptions(shader_description.vertex_typeid, &attribute_descs); if !ok {
        log.fatal("Failed to get vertex attribute descriptions")
        return
    }

    vertex_input_state_create_info: vk.PipelineVertexInputStateCreateInfo = {
        sType                           = .PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO,
        vertexBindingDescriptionCount   = 1,
        pVertexBindingDescriptions      = &binding_desc,
        vertexAttributeDescriptionCount = u32(len(attribute_descs)),
        pVertexAttributeDescriptions    = raw_data(attribute_descs),
    }

    input_assembly_state_create_info: vk.PipelineInputAssemblyStateCreateInfo = {
        sType                  = .PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO,
        topology               = .TRIANGLE_LIST,
        primitiveRestartEnable = false,
    }

    viewport: vk.Viewport = {
        x        = 0,
        y        = 0,
        width    = f32(state.swapchain_details.extent.width),
        height   = f32(state.swapchain_details.extent.height),
        minDepth = 0,
        maxDepth = 1,
    }

    scissor: vk.Rect2D = {
        offset = {0, 0},
        extent = state.swapchain_details.extent,
    }

    viewport_state_create_info: vk.PipelineViewportStateCreateInfo = {
        sType         = .PIPELINE_VIEWPORT_STATE_CREATE_INFO,
        viewportCount = 1,
        pViewports    = &viewport,
        scissorCount  = 1,
        pScissors     = &scissor,
    }

    rasterizer_state_create_info: vk.PipelineRasterizationStateCreateInfo = {
        sType = .PIPELINE_RASTERIZATION_STATE_CREATE_INFO,
        depthClampEnable = false,
        rasterizerDiscardEnable = false,
        lineWidth = 1,
        cullMode = {.BACK},
        frontFace = .COUNTER_CLOCKWISE,
        depthBiasEnable = false,
    }

    multisample_state_create_info: vk.PipelineMultisampleStateCreateInfo = {
        sType = .PIPELINE_MULTISAMPLE_STATE_CREATE_INFO,
        rasterizationSamples = {._1},
        sampleShadingEnable = false,
    }

    color_blend_attachment_state: vk.PipelineColorBlendAttachmentState = {
        blendEnable = false,
        colorWriteMask = {.R, .G, .B, .A},
    }

    color_blend_state_create_info: vk.PipelineColorBlendStateCreateInfo = {
        sType           = .PIPELINE_COLOR_BLEND_STATE_CREATE_INFO,
        logicOpEnable   = false,
        logicOp         = .COPY,
        attachmentCount = 1,
        pAttachments    = &color_blend_attachment_state,
    }

    pipeline_layout_create_info: vk.PipelineLayoutCreateInfo = {
        sType = .PIPELINE_LAYOUT_CREATE_INFO,
    }

    res := vk.CreatePipelineLayout(state.device, &pipeline_layout_create_info, nil, &cvk_shader.pipeline_layout); if res != .SUCCESS {
        log.fatal("Error creating pipeline layout:", res)
        return false
    }
    defer if !ok do vk.DestroyPipelineLayout(state.device, cvk_shader.pipeline_layout, nil)

    pipeline_create_info: vk.GraphicsPipelineCreateInfo = {
        sType               = .GRAPHICS_PIPELINE_CREATE_INFO,
        stageCount          = 2,
        pStages             = &shader_stages[0],
        pVertexInputState   = &vertex_input_state_create_info,
        pInputAssemblyState = &input_assembly_state_create_info,
        pViewportState      = &viewport_state_create_info,
        pRasterizationState = &rasterizer_state_create_info,
        pMultisampleState   = &multisample_state_create_info,
        pDepthStencilState  = nil,
        pColorBlendState    = &color_blend_state_create_info,
        pDynamicState       = &dynamic_state_create_info,
        layout              = cvk_shader.pipeline_layout,
        renderPass          = state.render_pass,
        subpass             = 0,
    }

    pipeline: vk.Pipeline
    res = vk.CreateGraphicsPipelines(state.device, 0, 1, &pipeline_create_info, nil, &pipeline); if res != .SUCCESS {
        log.fatal("Error creating graphics pipeline:", res)
        return false
    }
    cvk_shader.pipeline = pipeline

    shader^ = transmute(common.Shader)cvk_shader
    return true
}

create_shader_module :: proc(device: vk.Device, file: os.Handle) -> (module: vk.ShaderModule, ok: bool) {
    module_source, ok1 := os.read_entire_file(file); if !ok1 {
        log.error("Failed to create shader module: Could not read file")
        return {}, false
    }
    defer delete(module_source)

    module_info: vk.ShaderModuleCreateInfo = {
        sType    = .SHADER_MODULE_CREATE_INFO,
        codeSize = len(module_source),
        pCode    = transmute(^u32)raw_data(module_source), // yuck
    }

    res := vk.CreateShaderModule(device, &module_info, nil, &module); if res != .SUCCESS {
        log.error("Failed to create shader module")
        return {}, false
    }

    ok = true
    return
}

destroy_shader :: proc(shader: common.Shader) {
    using bound_state
    cvk_shader := transmute(^CVK_Shader)shader

    vk.DeviceWaitIdle(device)
    vk.DestroyPipeline(device, cvk_shader.pipeline, nil)    
    vk.DestroyPipelineLayout(device, cvk_shader.pipeline_layout, nil)
    // mem.free_with_size(cvk_shader, size_of(CVK_Shader))
    mem.free(cvk_shader)
}