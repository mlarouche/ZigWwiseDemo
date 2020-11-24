const std = @import("std");
const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) !void {
    const target = try std.zig.CrossTarget.parse(.{
        .arch_os_abi = "native-native-msvc",
    });

    const mode = b.standardReleaseOptions();

    const bindings = b.addStaticLibrary("wwiseBindings", null);
    bindings.linkLibC();
    bindings.linkSystemLibrary("AkSoundEngine");
    bindings.linkSystemLibrary("AkStreamMgr");
    bindings.linkSystemLibrary("AkMemoryMgr");
    bindings.linkSystemLibrary("CommunicationCentral");
    bindings.linkSystemLibrary("AkRoomVerbFX");
    bindings.linkSystemLibrary("AkStereoDelayFX");
    bindings.linkSystemLibrary("AkVorbisDecoder");
    bindings.linkSystemLibrary("ole32");
    bindings.linkSystemLibrary("user32");
    bindings.linkSystemLibrary("advapi32");
    bindings.linkSystemLibrary("ws2_32");
    bindings.addIncludeDir("bindings/IOHook/Win32");
    bindings.addIncludeDir("WwiseSDK/include");
    bindings.addLibPath("WwiseSDK/x64_vc150/Profile(StaticCRT)/lib");
    bindings.setTarget(target);

    const bindingsSources = &[_][]const u8{
        "bindings/zig_wwise.cpp",
        "bindings/IOHook/Common/AkFilePackage.cpp",
        "bindings/IOHook/Common/AkFilePackageLUT.cpp",
        "bindings/IOHook/Common/AkMultipleFileLocation.cpp",
        "bindings/IOHook/Win32/AkDefaultIOHookBlocking.cpp",
    };
    for (bindingsSources) |src| {
        bindings.addCSourceFile(src, &[_][]const u8{ "-std=c++17", "-DUNICODE" });
    }

    const imgui = b.addStaticLibrary("zigimgui", null);
    imgui.linkLibC();
    imgui.setTarget(target);

    const imguiSources = &[_][]const u8{
        "imgui/cimgui.cpp",
        "imgui/imgui/imgui.cpp",
        "imgui/imgui/imgui_demo.cpp",
        "imgui/imgui/imgui_draw.cpp",
        "imgui/imgui/imgui_impl_dx11.cpp",
        "imgui/imgui/imgui_impl_win32.cpp",
        "imgui/imgui/imgui_widgets.cpp",
    };
    for (imguiSources) |src| {
        imgui.addCSourceFile(src, &[_][]const u8{"-std=c++17"});
    }

    const exe = b.addExecutable("wwiseZig", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.addIncludeDir("bindings");
    exe.addIncludeDir("imgui");
    exe.addIncludeDir("WwiseSDK/include");
    exe.addLibPath("WwiseSDK/x64_vc150/Profile(StaticCRT)/lib");
    exe.linkLibrary(bindings);
    exe.linkLibrary(imgui);
    exe.linkLibC();
    exe.linkSystemLibrary("D3D11");
    exe.linkSystemLibrary("dxguid");
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
