package callisto_graphics_vulkan

import vk "vendor:vulkan"

State :: struct {
	debug_messenger:            vk.DebugUtilsMessengerEXT,
	instance:                   vk.Instance,
	surface:                    vk.SurfaceKHR,
	physical_device:            vk.PhysicalDevice,
	device:                     vk.Device,
	queue_family_indices:       Queue_Family_Indices,
	queues:                     Queue_Handles,
	swapchain:                  vk.SwapchainKHR,
	swapchain_details:          Swapchain_Details,
	target_image_index:         u32,
	images:                     [dynamic]vk.Image,
	image_views:                [dynamic]vk.ImageView,
	render_pass:                vk.RenderPass,
	pipeline:                   vk.Pipeline,
	pipeline_layout:            vk.PipelineLayout,
	framebuffers:               [dynamic]vk.Framebuffer,
	command_pool:               vk.CommandPool,
    flight_frame:               u32,
	command_buffers:            [dynamic]vk.CommandBuffer,
	image_available_semaphores: [dynamic]vk.Semaphore,
	render_finished_semaphores: [dynamic]vk.Semaphore,
	in_flight_fences:           [dynamic]vk.Fence,
    descriptor_pool:            vk.DescriptorPool,
    texture_sampler_default:    vk.Sampler,
}

Queue_Family_Indices :: struct {
	graphics: Maybe(u32),
	present:  Maybe(u32),
}

Queue_Handles :: struct {
	graphics: vk.Queue,
	present:  vk.Queue,
}

Swapchain_Details :: struct {
	capabilities: vk.SurfaceCapabilitiesKHR,
	format:       vk.SurfaceFormatKHR,
	present_mode: vk.PresentModeKHR,
	extent:       vk.Extent2D,
}

destroy_state :: proc(using state: ^State) {
	delete(images)
	delete(image_views)
	delete(framebuffers)
	delete(command_buffers)
	delete(image_available_semaphores)
	delete(render_finished_semaphores)
	delete(in_flight_fences)
}