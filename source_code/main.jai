#load "imgui.jai";

main :: () {
    success := SDL_Init(SDL_INIT_VIDEO);

    window  := SDL_CreateWindow("sequence selector 0.0", 800, 600, SDL_WINDOW_RESIZABLE | SDL_WINDOW_HIDDEN | SDL_WINDOW_HIGH_PIXEL_DENSITY);

    SDL_ShowWindow(window);

    has_to_close: bool;

    gpu_device := SDL_CreateGPUDevice(SDL_GPU_SHADERFORMAT_SPIRV | SDL_GPU_SHADERFORMAT_DXIL | SDL_GPU_SHADERFORMAT_METALLIB, DEBUG, null);

    SDL_ClaimWindowForGPUDevice(gpu_device, window);
    
    SDL_SetGPUSwapchainParameters(gpu_device, window, .SDR, .MAILBOX);

    DebugCheckVersionAndDataLayout(IMGUI_VERSION, size_of(IO), size_of(Style), size_of(ImVec2), size_of(ImVec4), size_of(ImDrawVert), size_of(ImDrawIdx));

    ctx := CreateContext();
    io := GetIO();

    io.ConfigFlags_ |= .ViewportsEnable | .DpiEnableScaleViewports | .DpiEnableScaleFonts | .NavEnableKeyboard;
    StyleColorsDark();

    style := GetStyle();
    if io.ConfigFlags_ & .ViewportsEnable {
        style.WindowRounding = 0;
        style.Colors[Col.WindowBg].w = 1;
    }

    ImplSDL3_InitForSDLGPU(window);

    init_info := ImplSDLGPU3_InitInfo.{
        Device = gpu_device,
        ColorTargetFormat = SDL_GetGPUSwapchainTextureFormat(gpu_device, window),
        MSAASamples = .SDL_GPU_SAMPLECOUNT_1,
    };

    ImplSDLGPU3_Init(*init_info);

    clear_color := SDL_FColor.{ a=1 };

    window_flags: WindowFlags =
        .NoDocking |
        .NoDecoration |
        .NoMove |
        .NoCollapse |
        .NoBringToFrontOnFocus
    ;

    while !has_to_close {
        event: SDL_Event;
        
        while(SDL_PollEvent(*event)) {
            event_consumed := ImplSDL3_ProcessEvent(*event);
            
            if event.type == {

                case xx SDL_EventType.QUIT;
                    has_to_close = true;

                case xx SDL_EventType.KEY_DOWN;
                    if event.key.key == SDLK_ESCAPE then has_to_close = true;

                case xx SDL_EventType.WINDOW_CLOSE_REQUESTED;
                    if event.window.windowID == SDL_GetWindowID(window) then has_to_close = true;
                
                case;
            }
        }

        ImplSDLGPU3_NewFrame();
        ImplSDL3_NewFrame();
        NewFrame();

        // ShowDemoWindow();

        viewport := GetMainViewport();

        SetNextWindowPos(viewport.Pos);
        SetNextWindowSize(viewport.Size);

        active: bool;

        Begin("sequence selector", *active, window_flags);

        End();

        Render();
        draw_data := GetDrawData();
        is_minimized := (draw_data.DisplaySize.x <= 0 || draw_data.DisplaySize.y <= 0);

        cmd_buffer := SDL_AcquireGPUCommandBuffer(gpu_device);

        swapchain_texture: *SDL_GPUTexture;

        SDL_AcquireGPUSwapchainTexture(cmd_buffer, window, *swapchain_texture, null, null);

        if swapchain_texture && !is_minimized {
            ImplSDLGPU3_PrepareDrawData(draw_data, cmd_buffer);

            target_info := SDL_GPUColorTargetInfo.{
                texture = swapchain_texture,
                clear_color = clear_color,
                load_op = .CLEAR,
                store_op = .STORE,
                mip_level = 0,
                layer_or_depth_plane = 0,
                cycle = false,
            };

            render_pass := SDL_BeginGPURenderPass(cmd_buffer, *target_info, 1, null);

            ImplSDLGPU3_RenderDrawData(draw_data, cmd_buffer, render_pass);

            SDL_EndGPURenderPass(render_pass);
        }

        if io.ConfigFlags_ & .ViewportsEnable {
            UpdatePlatformWindows();
            RenderPlatformWindowsDefault();
        }

        SDL_SubmitGPUCommandBuffer(cmd_buffer);
    }

        SDL_WaitForGPUIdle(gpu_device);

    ImplSDL3_Shutdown();
    ImplSDLGPU3_Shutdown();
    DestroyContext(ctx);

    SDL_ReleaseWindowFromGPUDevice(gpu_device, window);
    SDL_DestroyGPUDevice(gpu_device);
    SDL_DestroyWindow(window);
    SDL_Quit();
}

#import "Basic";
#import "jai-imgui";
#import "SDL3";
