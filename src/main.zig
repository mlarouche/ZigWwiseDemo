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
}
