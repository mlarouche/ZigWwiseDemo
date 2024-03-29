pub const c = @cImport({
    @cInclude("zig_wwise.h");
});

const std = @import("std");
const builtin = @import("builtin");
const FixedBufferAllocator = std.heap.FixedBufferAllocator;

pub const Wwise = struct {
    pub const AkCallbackFunction = c.ZigAkCallbackFunc;
    pub const AkCallbackInfo = c.ZigAkCallbackInfo;
    pub const AkEventCallbackInfo = c.ZigAkEventCallbackInfo;
    pub const AkMarkerCallbackInfo = c.ZigAkMarkerCallbackInfo;

    pub const AkCurveInterpolation = c.ZigAkCurveInterpolation;

    pub const InvalidGameObject = @bitCast(u64, @as(i64, -1));

    pub const InitError = error{
        MemoryManagerFailed,
        StreamManagerFailed,
        LowLevelIOFailed,
        SoundEngineFailed,
        CommunicationFailed,
    };

    pub const AkCallbackType = struct {
        pub const EndOfEvent = 0x0001;
        pub const EndOfDynamicSequenceItem = 0x0002;
        pub const Marker = 0x0004;
        pub const Duration = 0x0008;
        pub const SpeakerVolumeMatrix = 0x0010;
        pub const Starvation = 0x0020;
        pub const MusicPlaylistSelect = 0x0040;
        pub const MusicPlayStarted = 0x0080;
        pub const MusicSyncBeat = 0x0100;
        pub const MusicSyncBar = 0x0200;
        pub const MusicSyncEntry = 0x0400;
        pub const MusicSyncExit = 0x0800;
        pub const MusicSyncGrid = 0x1000;
        pub const MusicSyncUserCue = 0x2000;
        pub const MusicSyncPoint = 0x4000;
        pub const MusicSyncAll = 0x7f00;
        pub const MIDIEvent = 0x10000;
        pub const CallbackBits = 0xfffff;
        pub const EnableGetSourcePlayPosition = 0x100000;
        pub const EnableGetMusicPlayPosition = 0x200000;
        pub const EnableGetSourceStreamBuffering = 0x400000;
    };

    pub fn init() InitError!void {
        switch (c.ZigAk_Init()) {
            c.ZigAkInitResultSuccess => return,
            c.ZigAkInitResultMemoryManagerFailed => return InitError.MemoryManagerFailed,
            c.ZigAkInitResultStreamManagerFailed => return InitError.StreamManagerFailed,
            c.ZigAkInitResultLowLevelIOFailed => return InitError.LowLevelIOFailed,
            c.ZigAkInitResultSoundEngineFailed => return InitError.SoundEngineFailed,
            c.ZigAkInitResultCommunicationFailed => return InitError.CommunicationFailed,
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
            c.ZigAKRESULTSuccess => return bankID,
            c.ZigAKRESULTInsufficientMemory => return error.InsufficientMemory,
            c.ZigAKRESULTBankReadError => return error.BankReadError,
            c.ZigAKRESULTWrongBankVersion => return error.WrongBankVersion,
            c.ZigAKRESULTInvalidFile => return error.InvalidFile,
            c.ZigAKRESULTInvalidParameter => return error.InvalidParameter,
            else => return error.Fail,
        }
    }

    pub fn unloadBankByID(bankID: u32) bool {
        const result = c.ZigAk_UnloadBankByID(bankID, null);
        return switch (result) {
            c.ZigAKRESULTSuccess => return true,
            else => return false,
        };
    }

    pub fn unloadBankByString(bankName: []const u8) !void {
        var stackString = StackString.init();
        const nativeBankName = try stackString.toOSChar(bankName);
        const result = c.ZigAk_UnloadBankByString(nativeBankName);
        switch (result) {
            c.ZigAKRESULTSuccess => return,
            else => return error.Fail,
        }
    }

    pub fn registerGameObj(gameObjectID: u64, objectName: ?[]const u8) !void {
        if (objectName) |name| {
            var stackString = StackString.init();
            const nativeObjectName = try stackString.toCString(name);
            return switch (c.ZigAk_RegisterGameObj(gameObjectID, nativeObjectName)) {
                c.ZigAKRESULTSuccess => return,
                else => error.Fail,
            };
        } else {
            return switch (c.ZigAk_RegisterGameObj(gameObjectID, null)) {
                c.ZigAKRESULTSuccess => return,
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

    pub fn postEventWithCallback(eventName: []const u8, gameObjectID: u64, callbackType: u32, callback: AkCallbackFunction, cookie: ?*anyopaque) !u32 {
        var stackString = StackString.init();
        const nativeEventName = try stackString.toCString(eventName);
        return c.ZigAk_PostEventByStringCallback(nativeEventName, gameObjectID, callbackType, callback, cookie);
    }

    pub fn setRTPCValueByString(rtpcName: []const u8, value: f32, gameObjectID: u64) !void {
        var stackString = StackString.init();
        const nativeRtpcName = try stackString.toCString(rtpcName);
        return switch (c.ZigAk_SetRTPCValueByString(nativeRtpcName, value, gameObjectID)) {
            c.ZigAKRESULTSuccess => {},
            c.ZigAKRESULTInvalidFloatValue => error.InvalidFloatValue,
            else => error.Fail,
        };
    }

    pub fn setRTPCValueByStringInterpolate(rtpcName: []const u8, value: f32, gameObjectID: u64, timeMs: i32, fadeCurve: AkCurveInterpolation, bypassIntervalValueInterpolation: bool) !void {
        var stackString = StackString.init();
        const nativeRtpcName = try stackString.toCString(rtpcName);
        return switch (c.ZigAk_SetRTPCValueByStringInterpolate(nativeRtpcName, value, gameObjectID, timeMs, fadeCurve, bypassIntervalValueInterpolation)) {
            c.ZigAKRESULTSuccess => {},
            c.ZigAKRESULTInvalidFloatValue => error.InvalidFloatValue,
            else => error.Fail,
        };
    }

    pub fn setRTPCValue(rtpcID: u32, value: f32, gameObjectID: u64) !void {
        return switch (c.ZigAk_SetRTPCValue(rtpcID, value, gameObjectID)) {
            c.ZigAKRESULTSuccess => {},
            c.ZigAKRESULTInvalidFloatValue => error.InvalidFloatValue,
            else => error.Fail,
        };
    }

    pub fn setRTPCValueInterpolate(rtpcID: u32, value: f32, gameObjectID: u64, timeMs: i32, fadeCurve: AkCurveInterpolation, bypassIntervalValueInterpolation: bool) !void {
        return switch (c.ZigAk_SetRTPCValueInterpolate(rtpcID, value, gameObjectID, timeMs, fadeCurve, bypassIntervalValueInterpolation)) {
            c.ZigAKRESULTSuccess => {},
            c.ZigAKRESULTInvalidFloatValue => error.InvalidFloatValue,
            else => error.Fail,
        };
    }

    pub fn getSourcePlayPosition(playingId: u32, extrapolate: bool) !i32 {
        var result: i32 = 0;
        var akResult = c.ZigAk_GetSourcePlayPosition(playingId, &result, extrapolate);
        return switch (akResult) {
            c.ZigAKRESULTSuccess => return result,
            c.ZigAKRESULTInvalidParameter => return error.InvalidParameter,
            else => return error.Fail,
        };
    }

    pub fn stopPlayingID(playingId: u32) void {
        stopPlayingIDWithTransition(playingId, 0, AkCurveInterpolation.Linear);
    }

    pub fn stopPlayingIDWithTransition(playingId: u32, timeMs: i32, fadeCurve: AkCurveInterpolation) void {
        c.ZigAk_StopPlayingID(playingId, timeMs, fadeCurve);
    }

    pub fn stopAllOnGameObject(gameObjectID: u64) void {
        c.ZigAk_StopAll(gameObjectID);
    }

    pub fn stopAll() void {
        c.ZigAk_StopAll(InvalidGameObject);
    }

    pub fn setDefaultListeners(listeners: []const u64) void {
        c.ZigAk_SetDefaultListeners(&listeners[0], @intCast(c_ulong, listeners.len));
    }

    pub fn setCurrentLanguage(language: []const u8) !void {
        var stackString = StackString.init();
        const nativeLanguage = try stackString.toOSChar(language);
        c.ZigAk_StreamMgr_SetCurrentLanguage(nativeLanguage);
    }

    pub fn setSwitchByID(group: u32, value: u32, game_object: u64) void {
        c.ZigAk_SetSwitchByID(group, value, game_object);
    }

    pub fn getIDFromString(input: []const u8) !u32 {
        var stackString = StackString.init();
        const nativeInput = try stackString.toCString(input);
        return c.ZigAk_GetIDFromString(nativeInput);
    }

    pub const toOSChar = blk: {
        if (builtin.os.tag == .windows) {
            break :blk utf16ToOsChar;
        } else {
            break :blk utf8ToOsChar;
        }
    };

    pub fn utf16ToOsChar(allocator: std.mem.Allocator, value: []const u8) ![:0]u16 {
        return std.unicode.utf8ToUtf16LeWithNull(allocator, value);
    }

    pub fn utf8ToOsChar(allocator: std.mem.Allocator, value: []const u8) ![:0]u8 {
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
            return Wwise.toOSChar(self.fixedAlloc.allocator(), value);
        }

        pub fn toCString(self: *Self, value: []const u8) ![:0]u8 {
            return Wwise.utf8ToOsChar(self.fixedAlloc.allocator(), value);
        }
    };
};
