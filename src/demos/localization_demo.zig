const Wwise = @import("../wwise.zig").Wwise;
const ImGui = @import("../imgui.zig").ImGui;
const DemoInterface = @import("demo_interface.zig").DemoInterface;
const std = @import("std");

pub const LocalizationDemo = struct {
    allocator: *std.mem.Allocator = undefined,
    isVisibleState: bool = false,
    bankID: u32 = 0,
    currentSelectedLanguage: usize = 0,

    const Self = @This();
    const DemoGameObjectID = 3;

    const Languages = &[_][]const u8{ "English(US)", "French(Canada)" };

    pub fn init(self: *Self, allocator: *std.mem.Allocator) !void {
        self.allocator = allocator;

        self.currentSelectedLanguage = 0;

        try Wwise.setCurrentLanguage(Languages[0]);

        self.bankID = try Wwise.loadBankByString("Human.bnk");
        try Wwise.registerGameObj(DemoGameObjectID, "LocalizationDemo");
    }

    pub fn deinit(self: *Self) void {
        Wwise.unloadBankByID(self.bankID);

        Wwise.unregisterGameObj(DemoGameObjectID);

        self.allocator.destroy(self);
    }

    pub fn onUI(self: *Self) !void {
        _ = ImGui.igBegin("Localization Demo", &self.isVisibleState, ImGui.ImGuiWindowFlags_AlwaysAutoResize);

        if (ImGui.igButton("Say \"Hello\"", .{ .x = 0, .y = 0 })) {
            _ = try Wwise.postEvent("Play_Hello", DemoGameObjectID);
        }

        const firstLanguage = try std.cstr.addNullByte(self.allocator, Languages[self.currentSelectedLanguage]);
        defer self.allocator.free(firstLanguage);

        if (ImGui.igBeginCombo("Language", firstLanguage, 0)) {
            for (Languages) |lang, i| {
                const is_selected = (self.currentSelectedLanguage == i);

                const cLang = try std.cstr.addNullByte(self.allocator, lang);
                defer self.allocator.free(cLang);

                if (ImGui.igSelectable(cLang, is_selected, 0, .{ .x = 0, .y = 0 })) {
                    self.currentSelectedLanguage = i;

                    try Wwise.setCurrentLanguage(Languages[self.currentSelectedLanguage]);

                    Wwise.unloadBankByID(self.bankID);
                    self.bankID = try Wwise.loadBankByString("Human.bnk");
                }

                if (is_selected) {
                    ImGui.igSetItemDefaultFocus();
                }
            }

            ImGui.igEndCombo();
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
