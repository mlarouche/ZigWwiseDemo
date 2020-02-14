const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    b.addNativeSystemIncludeDir("WwiseSDK/include");
    b.addNativeSystemLibPath("WwiseSDK/x64_vc150/Profile(StaticCRT)/lib");

    const mode = b.standardReleaseOptions();

    const lib_cflags = &[_][]const u8{"-std=c++17"};

    const bindings = b.addStaticLibrary("wwiseBindings", null);
    bindings.linkSystemLibrary("c");
    bindings.linkSystemLibrary("AkSoundEngine");
    bindings.linkSystemLibrary("AkStreamMgr");
    bindings.linkSystemLibrary("AkMemoryMgr");
    bindings.linkSystemLibrary("CommunicationCentral");
    bindings.linkSystemLibrary("ole32");
    bindings.linkSystemLibrary("user32");
    bindings.linkSystemLibrary("advapi32");
    bindings.linkSystemLibrary("ws2_32");
    bindings.addCSourceFile("bindings/wwise_init.cpp", lib_cflags);

    const exe = b.addExecutable("wwiseZig", "src/main.zig");
    exe.setBuildMode(mode);
    exe.addIncludeDir("bindings");
    exe.linkLibrary(bindings);
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
