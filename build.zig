const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = try std.zig.CrossTarget.parse(.{
        .arch_os_abi = "native-native-msvc",
    });

    const optimize = b.standardOptimizeOption(.{});

    const bindings = b.addStaticLibrary(.{
        .name = "wwiseBindings",
        .target = target,
        .optimize = optimize,
    });

    bindings.linkLibC();
    bindings.linkSystemLibrary("AkSoundEngine");
    bindings.linkSystemLibrary("AkStreamMgr");
    bindings.linkSystemLibrary("AkMusicEngine");
    bindings.linkSystemLibrary("AkMemoryMgr");
    bindings.linkSystemLibrary("CommunicationCentral");
    bindings.linkSystemLibrary("AkRoomVerbFX");
    bindings.linkSystemLibrary("AkStereoDelayFX");
    bindings.linkSystemLibrary("AkVorbisDecoder");
    bindings.linkSystemLibrary("ole32");
    bindings.linkSystemLibrary("user32");
    bindings.linkSystemLibrary("advapi32");
    bindings.linkSystemLibrary("ws2_32");
    bindings.addIncludePath("bindings/IOHook/Win32");
    bindings.addIncludePath("WwiseSDK/include");
    bindings.addLibraryPath("WwiseSDK/x64_vc160/Profile(StaticCRT)/lib");

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

    const imgui = b.addStaticLibrary(.{
        .name = "zigimgui",
        .target = target,
        .optimize = optimize,
    });
    imgui.linkLibC();

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

    const exe = b.addExecutable(.{
        .name = "wwiseZig",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    exe.addPackage(.{
        .name = "zigwin32",
        .source = .{ .path = "zigwin32/win32.zig" },
    });
    exe.addIncludePath("bindings");
    exe.addIncludePath("imgui");
    exe.addIncludePath("WwiseSDK/include");
    exe.addLibraryPath("WwiseSDK/x64_vc160/Profile(StaticCRT)/lib");
    exe.linkLibrary(bindings);
    exe.linkLibrary(imgui);
    exe.linkLibC();
    exe.linkSystemLibrary("D3D11");
    exe.subsystem = .Windows;
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
