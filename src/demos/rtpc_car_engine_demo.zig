const Wwise = @import("../wwise.zig").Wwise;
const ImGui = @import("../imgui.zig").ImGui;
const DemoInterface = @import("demo_interface.zig").DemoInterface;
const std = @import("std");

pub const RtpcCarEngineDemo = struct {
    allocator: *std.mem.Allocator = undefined,
    isVisibleState: bool = false,
    bankID: u32 = 0,
    isPlaying: bool = false,
    rpmValue: i32 = 0,

    const Self = @This();
    const DemoGameObjectID = 4;
    const MinRPMValue = 1000;
    const MaxRPMValue = 10000;

    pub fn init(self: *Self, allocator: *std.mem.Allocator) void {
        self.allocator = allocator;

        self.rpmValue = MinRPMValue;

        self.bankID = Wwise.loadBankByString("Car.bnk") catch unreachable;
        Wwise.registerGameObj(DemoGameObjectID, "Car") catch unreachable;

        Wwise.setRTPCValueByString("RPM", @intToFloat(f32, self.rpmValue), DemoGameObjectID) catch unreachable;
    }

    pub fn deinit(self: *Self) void {
        Wwise.unloadBankByID(self.bankID);

        Wwise.unregisterGameObj(DemoGameObjectID);

        self.allocator.destroy(self);
    }

    pub fn onUI(self: *Self) !void {
        _ = ImGui.igBegin("RTPC Demo (Car Engine)", &self.isVisibleState, ImGui.ImGuiWindowFlags_AlwaysAutoResize);

        const buttonText = if (self.isPlaying) "Stop Engine" else "Start Engine";

        if (ImGui.igButton(buttonText, .{ .x = 0, .y = 0 })) {
            if (self.isPlaying) {
                _ = try Wwise.postEvent("Stop_Engine", DemoGameObjectID);
                self.isPlaying = false;
            } else {
                _ = try Wwise.postEvent("Play_Engine", DemoGameObjectID);
                self.isPlaying = true;
            }
        }

        if (ImGui.igSliderInt("RPM", &self.rpmValue, MinRPMValue, MaxRPMValue, "%u")) {
            try Wwise.setRTPCValueByString("RPM", @intToFloat(f32, self.rpmValue), DemoGameObjectID);
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
};
