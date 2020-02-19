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
    
    pub const LoadBankError = error {
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
        var localString = LocalOSString.init();
        const nativePath = try localString.toOSChar(path);
        c.ZigAk_SetIOBasePath(nativePath);
    }

    pub fn loadBankByString(bankName: []const u8) !u32 {
        var localString = LocalOSString.init();
        const nativeBankName = try localString.toOSChar(bankName);
        var bankID: u32 = 0;
        const result = c.ZigAk_LoadBankByString(nativeBankName, &bankID);
        switch(result) {
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
        _  = c.ZigAk_UnloadBankByID(bankID, null);
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

    pub fn utf8ToOsChar(value: []const u8) ![:0]u8 {
        return std.cstr.addNullByte(allocator, value);
    }

    const LocalOSString = struct {
        buffer: [4 * 1024]u8 = undefined,
        fixedAlloc: FixedBufferAllocator = undefined,

        const Self = @This();

        pub fn init() Self {
            var result = Self {};
            result.fixedAlloc = FixedBufferAllocator.init(&result.buffer);
            return result;
        }

        pub fn toOSChar(self: *Self, value: []const u8) @typeInfo(@TypeOf(Wwise.toOSChar)).Fn.return_type.? {
            return Wwise.toOSChar(&self.fixedAlloc.allocator, value);
        }
    };
};
