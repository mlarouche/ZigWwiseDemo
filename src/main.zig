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
            }
        }
    };
    defer Wwise.deinit();

    std.debug.warn("Wwise initialized successfully!\n", .{});
}
