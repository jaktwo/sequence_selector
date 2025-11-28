#load "imgui.jai";

main :: () {
    success := SDL_Init(SDL_INIT_VIDEO);

    window  := SDL_CreateWindow("sequence selector 0.0", 800, 600, SDL_WINDOW_RESIZABLE | SDL_WINDOW_HIDDEN);

    SDL_ShowWindow(window);

    has_to_close: bool;

    while !has_to_close {
        event: SDL_Event;
        while(SDL_PollEvent(*event)) {
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
    }
}

#import "Basic";
#import "jai-imgui";
#import "SDL3";
