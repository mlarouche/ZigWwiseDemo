const std = @import("std");
const Wwise = @import("wwise.zig").Wwise;

pub fn main() anyerror!void {
    Wwise.init() catch |err| {
        switch (err) {
            error.MemoryManagerFailed => std.debug.warn("AK Memory Manager failed to initialized!\n", .{}),
        }
    };
}
