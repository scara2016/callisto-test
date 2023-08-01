//+build windows, linux, darwin
package callisto_graphics_vulkan

import "core:log"
import vk "vendor:vulkan"
import "core:strings"
import "../../config"

// Ownership, may support multiple vk instances later.
main_state: State = {}
bound_state: ^State

init :: proc() -> (ok: bool) {
    bound_state = &main_state
    using bound_state

    log.info("Initializing renderer: Vulkan")

    create_instance(&instance) or_return
    defer if !ok do vk.DestroyInstance(instance, nil)
 
    // First "state" pointer is always const. Explicitly pass pointers to mutable data in separate params
    create_debug_messenger(&debug_messenger) or_return
    defer if !ok do vk.DestroyDebugUtilsMessengerEXT(instance, debug_messenger, nil)
    
    create_surface(&surface) or_return
    defer if !ok do vk.DestroySurfaceKHR(instance, surface, nil)

    select_physical_device(&physical_device) or_return
    
    create_logical_device(&device, &queue_family_indices, &queues) or_return
    defer if !ok do vk.DestroyDevice(device, nil)

    create_swapchain(&swapchain, &swapchain_details) or_return
    defer if !ok do vk.DestroySwapchainKHR(device, swapchain, nil)

    get_images(&images)

    create_image_views(&image_views) or_return
    defer if !ok do destroy_image_views(&image_views)
    for image_view in image_views {
        set_debug_name(u64(image_view), .IMAGE_VIEW, "Swapchain Image View")
    }

    create_render_pass(&render_pass) or_return
    defer if !ok do vk.DestroyRenderPass(device, render_pass, nil)

    create_framebuffers(&framebuffers) or_return
    defer if !ok do destroy_framebuffers(&framebuffers)

    create_command_pool(&command_pool) or_return
    defer if !ok do vk.DestroyCommandPool(device, command_pool, nil)

    create_command_buffers(config.RENDERER_FRAMES_IN_FLIGHT, &command_buffers) or_return
    defer if !ok do vk.FreeCommandBuffers(device, command_pool, u32(len(command_buffers)), raw_data(command_buffers))

    create_semaphores(config.RENDERER_FRAMES_IN_FLIGHT, &image_available_semaphores) or_return
    defer if !ok do destroy_semaphores(&image_available_semaphores)
    create_semaphores(config.RENDERER_FRAMES_IN_FLIGHT, &render_finished_semaphores) or_return
    defer if !ok do destroy_semaphores(&render_finished_semaphores)
    create_fences(config.RENDERER_FRAMES_IN_FLIGHT, &in_flight_fences) or_return
    defer if !ok do destroy_fences(&in_flight_fences)

    create_descriptor_pool(&descriptor_pool) or_return
    defer if !ok do vk.DestroyDescriptorPool(device, descriptor_pool, nil)

    return true
}

shutdown :: proc() {
    log.info("Shutting down renderer")
    using bound_state

    vk.DeviceWaitIdle(device)
    // TODO: Move these out of global scope
    defer delete(required_instance_extensions)
    defer delete(required_device_extensions)
    defer delete(dynamic_states)
    // ====================================

    defer destroy_state(bound_state)
    defer vk.DestroyInstance(instance, nil)
    defer destroy_logger(logger)
    defer vk.DestroyDebugUtilsMessengerEXT(instance, debug_messenger, nil)
    defer vk.DestroySurfaceKHR(instance, surface, nil)
    defer vk.DestroyDevice(device, nil)
    defer vk.DestroyCommandPool(device, command_pool, nil)
    defer vk.DestroySwapchainKHR(device, swapchain, nil)
    defer destroy_image_views(&image_views)
    defer vk.DestroyRenderPass(device, render_pass, nil)
    defer destroy_framebuffers(&framebuffers)
    defer vk.FreeCommandBuffers(device, command_pool, u32(len(command_buffers)), raw_data(command_buffers))
    defer destroy_semaphores(&image_available_semaphores)
    defer destroy_semaphores(&render_finished_semaphores)
    defer destroy_fences(&in_flight_fences)
    defer vk.DestroyDescriptorPool(device, descriptor_pool, nil)
}
