// @file:   build.jai
// @author: jak2 <jak2@clover-work.shop>
//
// from the poet to the lover, the support of clover
//

build :: () {
    defer set_build_options_dc(.{
        do_output           = false,
        write_added_strings = false
    });

    workspace := compiler_create_workspace("sequence Selector");

    if !workspace {
        print("\nworkspace creation failed, something is very wrong\n");
        return;
    }

    build_options := get_build_options(workspace);

    set_working_directory(#filepath);

    build_options.output_executable_name = "sequence_selector";
    build_options.output_type            = .EXECUTABLE;
    build_options.backend                = .LLVM;
    build_options.output_path            = #filepath;

    import_paths: [..] string;

    array_add(*import_paths, ..build_options.import_path);
    array_add(*import_paths, "C:/jai/modules/");
    array_add(*import_paths, tprint("%/modules/", #filepath));

    build_options.import_path = import_paths;

    build_options.additional_linker_arguments = .[
        "user32.lib", "gdi32.lib", "advapi32.lib", "ole32.lib",
		"shell32.lib", "winmm.lib", "setupapi.lib", "version.lib",
		"imm32.lib", "cfgmgr32.lib", "oleaut32.lib", "uuid.lib",
        "msvcrt.lib", "oldnames.lib"
    ];

    arguments := build_options.compile_time_command_line;
    debug := false;

    for arguments {
        if it_index > 1 {
            if it == {
                case "-"; continue;

                case "-Release";   #through;
                case "-release";   #through;
                case "-RELEASE";   #through;
                case "-optimized"; #through;
                case "-Optimized"; #through;
                case "-OPTIMIZED"; #through;
                 case "Release";   #through;
                case "release";    #through;
                case "RELEASE";    #through;
                case "optimized";  #through;
                case "Optimized";  #through;
                case "OPTIMIZED";  
                    set_optimization(*build_options, .OPTIMIZED);

                    print("\noptimization set to optimized\n");

                case "-Debug"; #through;
                case "-debug"; #through;
                case "-DEBUG"; #through;
                case "Debug";  #through;
                case "debug";  #through;
                case "DEBUG";  
                    set_optimization(*build_options, .DEBUG);
                    debug = true;

                    print("\noptimization set to debug\n");

                case "-llvm"; #through;
                case "-LLVM"; #through;
                case "llvm";  #through;
                case "LLVM";
                    print("\ndefault backend is LLVM\n");

                case "-x64"; #through;
                case "-X64"; #through;
                case "x64";  #through;
                case "X64";
                    build_options.backend = .X64;

                    print("\nbackend set to x64\n");
                
                case;
            }
        }
    }

    compiler_begin_intercept(workspace);

    set_build_options(build_options, workspace);

    add_build_string(tprint("DEBUG :: %;", debug), workspace);

    add_build_file("./source_code/main.jai", workspace);
    success: bool;

    while true {
        message := compiler_wait_for_message();

        if !message then break;

        if message.kind == {
            case .COMPLETE;
                message_complete := message.(*Message_Complete);

                success = message_complete.error_code == 0;

                break;
        }
    }

    compiler_end_intercept(workspace);

    os_path_prefix: string;
    if OS == .LINUX then os_path_prefix = "./";

    if success {
        print("\nbuilt sequence Selector\n");
        print("\nrunning project..\n\n");

        run_command(tprint("%1%", os_path_prefix, build_options.output_executable_name));
    }
}

#run build();

#import "Basic";
#import "Compiler";
#import "File";
#import "File_Utilities";
#import "Process";
#import "String";
