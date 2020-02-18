pub const c = @cImport({
    @cInclude("zig_wwise.h");
});

const std = @import("std");
const builtin = std.builtin;
const c_allocator = std.heap.c_allocator;

pub const Wwise = struct {
    pub const InitError = error{
        MemoryManagerFailed,
        StreamManagerFailed,
        LowLevelIOFailed,
        SoundEngineFailed,
        CommunicationFailed,
    };

    pub fn init() InitError!void {
        switch (c.ZigAk_Init()) {
            .AkInitResult_Success => return,
            .AkInitResult_MemoryManagerFailed => return InitError.MemoryManagerFailed,
            .AkInitResult_StreamManagerFailed => return InitError.StreamManagerFailed,
            .AkInitResult_LowLevelIOFailed => return InitError.LowLevelIOFailed,
            .AkInitResult_SoundEngineFailed => return InitError.SoundEngineFailed,
            .AkInitResult_CommunicationFailed => return InitError.CommunicationFailed,
            else => {},
        }
    }

    pub fn deinit() void {
        c.ZigAk_Deinit();
    }

    pub fn renderAudio() void {
        c.ZigAk_RenderAudio();
    }

    pub fn setIOHookBasePath(path: []const u8) !void {
        const nativePath = try toOSChar(path);
        defer c_allocator.free(nativePath);
        c.ZigAk_SetIOBasePath(nativePath);
    }

    pub const toOSChar = comptime blk: {
        if (builtin.os == .windows) {
            break :blk utf16ToOsChar;
        } else {
            break :blk utf8ToOsChar;
        }
    };

    pub fn utf16ToOsChar(value: []const u8) ![:0]u16 {
        return std.unicode.utf8ToUtf16LeWithNull(c_allocator, value);
    }

    pub fn utf8ToOsChar(value: []const u8) ![:0]u8 {
        return std.cstr.addNullByte(c_allocator, value);
    }
};
