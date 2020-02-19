pub const c = @cImport({
    @cInclude("zig_wwise.h");
});

const std = @import("std");
const builtin = std.builtin;
const FixedBufferAllocator = std.heap.FixedBufferAllocator;

pub const Wwise = struct {
    pub const InitError = error{
        MemoryManagerFailed,
        StreamManagerFailed,
        LowLevelIOFailed,
        SoundEngineFailed,
        CommunicationFailed,
    };

    pub const LoadBankError = error{
        InsufficientMemory,
        BankReadError,
        WrongBankVersion,
        InvalidFile,
        InvalidParameter,
        Fail,
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
        var stackString = StackString.init();
        const nativePath = try stackString.toOSChar(path);
        c.ZigAk_SetIOBasePath(nativePath);
    }

    pub fn loadBankByString(bankName: []const u8) !u32 {
        var stackString = StackString.init();
        const nativeBankName = try stackString.toOSChar(bankName);
        var bankID: u32 = 0;
        const result = c.ZigAk_LoadBankByString(nativeBankName, &bankID);
        switch (result) {
            .AkLoadBankResult_Success => return bankID,
            .AkLoadBankResult_InsufficientMemory => return LoadBankError.InsufficientMemory,
            .AkLoadBankResult_BankReadError => return LoadBankError.BankReadError,
            .AkLoadBankResult_WrongBankVersion => return LoadBankError.WrongBankVersion,
            .AkLoadBankResult_InvalidFile => return LoadBankError.InvalidFile,
            .AkLoadBankResult_InvalidParameter => return LoadBankError.InvalidParameter,
            .AkLoadBankResult_Fail => return LoadBankError.Fail,
            else => return LoadBankError.Fail,
        }
    }

    pub fn unloadBankByID(bankID: u32) void {
        _ = c.ZigAk_UnloadBankByID(bankID, null);
    }

    pub fn registerGameObj(gameObjectID: u64, objectName: ?[]const u8) !void {
        if (objectName) |name| {
            var stackString = StackString.init();
            const nativeObjectName = try stackString.toCString(name);
            return switch (c.ZigAk_RegisterGameObj(gameObjectID, nativeObjectName)) {
                .ZigAkSuccess => return,
                else => error.Fail,
            };
        } else {
            return switch (c.ZigAk_RegisterGameObj(gameObjectID, null)) {
                .ZigAkSuccess => return,
                else => error.Fail,
            };
        }
    }

    pub fn unregisterGameObj(gameObjectID: u64) void {
        _ = c.ZigAk_UnregisterGameObj(gameObjectID);
    }

    pub fn postEvent(eventName: []const u8, gameObjectID: u64) !u32 {
        var stackString = StackString.init();
        const nativeEventName = try stackString.toCString(eventName);
        return c.ZigAk_PostEventByString(nativeEventName, gameObjectID);
    }

    pub fn setDefaultListeners(listeners: []const u64) void {
        c.ZigAk_SetDefaultListeners(&listeners[0], @intCast(c_ulong, listeners.len));
    }

    pub const toOSChar = comptime blk: {
        if (builtin.os == .windows) {
            break :blk utf16ToOsChar;
        } else {
            break :blk utf8ToOsChar;
        }
    };

    pub fn utf16ToOsChar(allocator: *std.mem.Allocator, value: []const u8) ![:0]u16 {
        return std.unicode.utf8ToUtf16LeWithNull(allocator, value);
    }

    pub fn utf8ToOsChar(allocator: *std.mem.Allocator, value: []const u8) ![:0]u8 {
        return std.cstr.addNullByte(allocator, value);
    }

    const StackString = struct {
        buffer: [4 * 1024]u8 = undefined,
        fixedAlloc: FixedBufferAllocator = undefined,

        const Self = @This();

        pub fn init() Self {
            var result = Self{};
            result.fixedAlloc = FixedBufferAllocator.init(&result.buffer);
            return result;
        }

        pub fn toOSChar(self: *Self, value: []const u8) @typeInfo(@TypeOf(Wwise.toOSChar)).Fn.return_type.? {
            return Wwise.toOSChar(&self.fixedAlloc.allocator, value);
        }

        pub fn toCString(self: *Self, value: []const u8) ![:0]u8 {
            return Wwise.utf8ToOsChar(&self.fixedAlloc.allocator, value);
        }
    };
};
