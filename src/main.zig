const std = @import("std");
const Wwise = @import("wwise.zig").Wwise;

pub fn main() anyerror!void {
    Wwise.init() catch |err| {
        switch (err) {
            error.MemoryManagerFailed => {
                @panic("AK Memory Manager failed to initialized!");
            },
            error.StreamManagerFailed => {
                @panic("AK Stream Manager failed to initialized!");
            },
            error.LowLevelIOFailed => {
                @panic("Low Level I/O failed to initialize!");
            },
            error.SoundEngineFailed => {
                @panic("Could not initialize the Sound Engine!");
            },
            error.CommunicationFailed => {
                @panic("Could not initiliaze Wwise Communication!");
            },
        }
    };
    defer Wwise.deinit();

    std.debug.warn("Wwise initialized successfully!\n", .{});

    const currentDir = try std.fs.path.resolve(std.heap.c_allocator, &[_][]const u8{"."});
    defer std.heap.c_allocator.free(currentDir);
    const soundBanksPath = try std.fs.path.join(std.heap.c_allocator, &[_][]const u8{ currentDir, "WwiseProject\\GeneratedSoundBanks\\Windows" });
    defer std.heap.c_allocator.free(soundBanksPath);

    try Wwise.setIOHookBasePath(soundBanksPath);

    const loadBankID = try Wwise.loadBankByString("Init.bnk");
    defer Wwise.unloadBankByID(loadBankID);

    const markerBankID = try Wwise.loadBankByString("MarkerTest.bnk");
    defer Wwise.unloadBankByID(markerBankID);

    try Wwise.registerGameObj(1, "Listener");
    defer Wwise.unregisterGameObj(1);
    try Wwise.registerGameObj(2, "GlobalSound");
    defer Wwise.unregisterGameObj(2);

    Wwise.setDefaultListeners(&[_]u64{1});

    _ = try Wwise.postEvent("Play_Markers_Test", 2);

    Wwise.renderAudio();
    std.time.sleep(12 * std.time.second);
}
