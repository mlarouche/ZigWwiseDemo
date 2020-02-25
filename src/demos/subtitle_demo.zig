const Wwise = @import("../wwise.zig").Wwise;
const ImGui = @import("../imgui.zig").ImGui;
const DemoInterface = @import("demo_interface.zig").DemoInterface;
const std = @import("std");

pub const SubtitleDemo = struct {
    subtitleText: [:0]const u8 = undefined,
    subtitleIndex: u32 = 0,
    subtitlePosition: u32 = 0,
    playingID: u32 = 0,
    allocator: *std.mem.Allocator = undefined,
    isVisibleState: bool = false,
    gameObjectID: u64 = 0,
    bankID: u32 = 0,

    const Self = @This();
    const DemoGameObjectID = 2;

    pub fn init(self: *Self, allocator: *std.mem.Allocator) void {
        self.allocator = allocator;
        self.subtitleText = std.mem.dupeZ(self.allocator, u8, "") catch unreachable;

        self.bankID = Wwise.loadBankByString("MarkerTest.bnk") catch unreachable;
        Wwise.registerGameObj(DemoGameObjectID, "SubtitleDemo") catch unreachable;
    }

    pub fn deinit(self: *Self) void {
        Wwise.unloadBankByID(self.bankID);

        Wwise.unregisterGameObj(DemoGameObjectID);

        self.allocator.free(self.subtitleText);

        self.allocator.destroy(self);
    }

    pub fn onUI(self: *Self) !void {
        _ = ImGui.igBegin("Subtitle Demo", &self.isVisibleState, ImGui.ImGuiWindowFlags_AlwaysAutoResize);

        if (ImGui.igButton("Play", .{ .x = 120, .y = 0 })) {
            self.playingID = try Wwise.postEventWithCallback("Play_Markers_Test", DemoGameObjectID, Wwise.AkCallbackType.Marker | Wwise.AkCallbackType.EndOfEvent | Wwise.AkCallbackType.EnableGetSourcePlayPosition, WwiseSubtitleCallback, self);
        }

        if (!std.mem.eql(u8, self.subtitleText, "")) {
            const cuePosText = try std.fmt.allocPrint0(self.allocator, "Cue #{}, Sample #{}", .{ self.subtitleIndex, self.subtitlePosition });
            defer self.allocator.free(cuePosText);

            const playPosition = try Wwise.getSourcePlayPosition(self.playingID, true);
            const playPositionText = try std.fmt.allocPrint0(self.allocator, "Time: {} ms", .{playPosition});
            defer self.allocator.free(playPositionText);

            ImGui.igText(cuePosText);
            ImGui.igText(playPositionText);
            ImGui.igText(self.subtitleText);
        }

        ImGui.igEnd();
    }

    pub fn isVisible(self: *Self) bool {
        return self.isVisibleState;
    }

    pub fn show(self: *Self) void {
        self.isVisibleState = true;
    }

    pub fn getInterface(self: *Self) DemoInterface {
        return DemoInterface{
            .instance = @ptrCast(DemoInterface.InstanceType, self),
            .initFn = @ptrCast(DemoInterface.InitFn, init),
            .deinitFn = @ptrCast(DemoInterface.DeinitFn, deinit),
            .onUIFn = @ptrCast(DemoInterface.OnUIFn, onUI),
            .isVisibleFn = @ptrCast(DemoInterface.IsVisibleFn, isVisible),
            .showFn = @ptrCast(DemoInterface.ShowFn, show),
        };
    }

    pub fn setSubtitleText(self: *Self, text: [:0]const u8) void {
        self.allocator.free(self.subtitleText);
        self.subtitleText = std.mem.dupeZ(self.allocator, u8, text) catch unreachable;
    }

    fn WwiseSubtitleCallback(callbackType: u32, callbackInfo: [*c]Wwise.AkCallbackInfo) callconv(.C) void {
        if (callbackType == Wwise.AkCallbackType.Marker) {
            if (callbackInfo[0].pCookie) |cookie| {
                var subtitleDemo = @ptrCast(*SubtitleDemo, @alignCast(8, cookie));
                var markerCallback = @ptrCast(*Wwise.AkMarkerCallbackInfo, callbackInfo);

                subtitleDemo.setSubtitleText(std.mem.toSliceConst(u8, markerCallback.strLabel));
                subtitleDemo.subtitleIndex = markerCallback.uIdentifier;
                subtitleDemo.subtitlePosition = markerCallback.uPosition;
            }
        } else if (callbackType == Wwise.AkCallbackType.EndOfEvent) {
            if (callbackInfo[0].pCookie) |cookie| {
                var subtitleDemo = @ptrCast(*SubtitleDemo, @alignCast(8, cookie));

                subtitleDemo.setSubtitleText("");
                subtitleDemo.subtitleIndex = 0;
                subtitleDemo.subtitlePosition = 0;
            }
        }
    }
};
