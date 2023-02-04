const Wwise = @import("../wwise.zig").Wwise;
const ImGui = @import("../imgui.zig").ImGui;
const DemoInterface = @import("demo_interface.zig").DemoInterface;
const std = @import("std");

const SurfaceInfo = struct {
    bank_name: []const u8,
    switch_id: u32,

    const Self = @This();

    pub fn init(bank_name: []const u8) !Self {
        const dotPosition = std.mem.lastIndexOfScalar(u8, bank_name, '.');
        const bank_name_without_ext = if (dotPosition) |pos| bank_name[0..pos] else bank_name;

        return Self{
            .bank_name = bank_name,
            .switch_id = try Wwise.getIDFromString(bank_name_without_ext),
        };
    }
};

var Surfaces: [4]SurfaceInfo = undefined;

pub const FootstepsDemo = struct {
    allocator: std.mem.Allocator = undefined,
    isVisibleState: bool = false,
    bankID: u32 = 0,
    posX: f32 = 0,
    posY: f32 = 0,
    lastX: f32 = 0,
    lastY: f32 = 0,
    weight: f32 = 0,
    surface: usize = 0,
    current_banks: u32 = 0,
    tick_count: isize = 0,
    last_tick_count: isize = 0,

    const Self = @This();

    const DemoGameObjectID = 5;
    const CursorSpeed = 5.0;
    const BufferZone: f32 = 20.0;
    const DistanceToSpeed = 10 / CursorSpeed;
    const WalkPeriod = 30;

    var SurfaceGroup: u32 = undefined;

    pub fn init(self: *Self, allocator: std.mem.Allocator) !void {
        self.allocator = allocator;

        self.bankID = 0;
        self.posX = 300;
        self.posY = 240;
        self.lastX = 300;
        self.lastY = 240;
        self.surface = std.math.maxInt(@TypeOf(self.surface));
        self.current_banks = 0;
        self.weight = 25.0;
        self.tick_count = 0;
        self.last_tick_count = 0;

        try Wwise.registerGameObj(DemoGameObjectID, "Human");

        Surfaces = [_]SurfaceInfo{
            try SurfaceInfo.init("Dirt.bnk"),
            try SurfaceInfo.init("Wood.bnk"),
            try SurfaceInfo.init("Metal.bnk"),
            try SurfaceInfo.init("Gravel.bnk"),
        };

        SurfaceGroup = try Wwise.getIDFromString("Surface");
    }

    pub fn deinit(self: *Self) void {
        _ = Wwise.unloadBankByID(self.bankID);

        Wwise.unregisterGameObj(DemoGameObjectID);

        for (Surfaces) |surface| {
            Wwise.unloadBankByString(surface.bank_name) catch {};
        }

        self.allocator.destroy(self);
    }

    pub fn onUI(self: *Self) !void {
        self.tick_count += 1;
        if (ImGui.igBegin("Footsteps Demo", &self.isVisibleState, ImGui.ImGuiWindowFlags_None)) {
            var draw_list = ImGui.igGetWindowDrawList();

            _ = ImGui.igSliderFloat("Weight", &self.weight, 0.0, 100.0, "%.3f", 1.0);

            const whiteColor = ImGui.igGetColorU32Vec4(.{ .x = 1.0, .y = 1.0, .z = 1.0, .w = 1.0 });
            const redColor = ImGui.igGetColorU32Vec4(.{ .x = 1.0, .y = 0.0, .z = 0.0, .w = 1.0 });

            if (ImGui.igIsKeyDown(ImGui.igGetKeyIndex(ImGui.ImGuiKey_UpArrow))) {
                self.posY -= CursorSpeed;
            } else if (ImGui.igIsKeyDown(ImGui.igGetKeyIndex(ImGui.ImGuiKey_DownArrow))) {
                self.posY += CursorSpeed;
            } else if (ImGui.igIsKeyDown(ImGui.igGetKeyIndex(ImGui.ImGuiKey_LeftArrow))) {
                self.posX -= CursorSpeed;
            } else if (ImGui.igIsKeyDown(ImGui.igGetKeyIndex(ImGui.ImGuiKey_RightArrow))) {
                self.posX += CursorSpeed;
            }

            var window_pos: ImGui.ImVec2 = undefined;
            ImGui.igGetCursorScreenPos_nonUDT(&window_pos);

            var window_size: ImGui.ImVec2 = undefined;
            ImGui.igGetContentRegionAvail_nonUDT(&window_size);

            if (self.posX < 7) {
                self.posX = 7;
            } else if (self.posX >= window_size.x - 7) {
                self.posX = window_size.x - 7;
            }

            if (self.posY < 7) {
                self.posY = 7;
            } else if (self.posY >= window_size.y - 7) {
                self.posY = window_size.y - 7;
            }

            ImGui.ImDrawList_AddRect(draw_list, window_pos, .{ .x = window_pos.x + window_size.x, .y = window_pos.y + window_size.y }, whiteColor, 0.0, ImGui.ImDrawCornerFlags_All, 1.0);

            const half_width: f32 = window_size.x / 2.0;
            const half_height: f32 = window_size.y / 2.0;

            const text_width: f32 = 40.0;
            const text_height: f32 = 36.0;

            ImGui.ImDrawList_AddText(draw_list, .{ .x = window_pos.x + (half_width - BufferZone - text_width), .y = window_pos.y + (half_height - BufferZone - text_height) }, whiteColor, "Dirt", null);

            ImGui.ImDrawList_AddText(draw_list, .{ .x = window_pos.x + (half_width + BufferZone), .y = window_pos.y + (half_height - BufferZone - text_height) }, whiteColor, "Wood", null);

            ImGui.ImDrawList_AddText(draw_list, .{ .x = window_pos.x + (half_width - BufferZone - text_width), .y = window_pos.y + (half_height + BufferZone) }, whiteColor, "Metal", null);

            ImGui.ImDrawList_AddText(draw_list, .{ .x = window_pos.x + (half_width + BufferZone), .y = window_pos.y + (half_height + BufferZone) }, whiteColor, "Gravel", null);

            ImGui.ImDrawList_AddCircle(draw_list, .{ .x = window_pos.x + self.posX, .y = window_pos.y + self.posY }, 7.0, redColor, 8, 2.0);

            ImGui.igEnd();

            self.manageSurfaces(window_size);
            try self.playFootstep();
        }

        if (!self.isVisibleState) {
            Wwise.stopAllOnGameObject(DemoGameObjectID);
        }
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
            .initFn = @ptrCast(DemoInterface.InitFn, &init),
            .deinitFn = @ptrCast(DemoInterface.DeinitFn, &deinit),
            .onUIFn = @ptrCast(DemoInterface.OnUIFn, &onUI),
            .isVisibleFn = @ptrCast(DemoInterface.IsVisibleFn, &isVisible),
            .showFn = @ptrCast(DemoInterface.ShowFn, &show),
        };
    }

    fn manageSurfaces(self: *Self, window_size: ImGui.ImVec2) void {
        var bankMasks: u32 = self.computeUsedBankMask(window_size);

        var i: usize = 0;
        while (i < Surfaces.len) : (i += 1) {
            const bit = @as(u32, 1) << @intCast(u5, i);

            if ((bankMasks & bit) == bit and (self.current_banks & bit) != bit) {
                _ = Wwise.loadBankByString(Surfaces[i].bank_name) catch {
                    bankMasks &= ~bit;
                };
            }

            if ((bankMasks & bit) != bit and ((self.current_banks & bit) == bit)) {
                Wwise.unloadBankByString(Surfaces[i].bank_name) catch {
                    bankMasks |= bit;
                };
            }
        }

        self.current_banks = bankMasks;

        const half_width = @floatToInt(usize, window_size.x / 2.0);
        const half_height = @floatToInt(usize, window_size.y / 2.0);
        const index_surface = @boolToInt(@floatToInt(usize, self.posX) > half_width) | (@as(usize, @boolToInt(@floatToInt(usize, self.posY) > half_height)) << @as(u6, 1));
        if (self.surface != index_surface) {
            Wwise.setSwitchByID(SurfaceGroup, Surfaces[index_surface].switch_id, DemoGameObjectID);
            self.surface = index_surface;
        }
    }

    fn computeUsedBankMask(self: Self, window_size: ImGui.ImVec2) u32 {
        const half_width = @floatToInt(i32, window_size.x / 2);
        const half_height = @floatToInt(i32, window_size.y / 2);
        const buffer_zone = @floatToInt(i32, BufferZone * 2);

        const left_div = @as(i32, @boolToInt(@floatToInt(i32, self.posX) > (half_width - buffer_zone)));
        const right_div = @as(i32, @boolToInt(@floatToInt(i32, self.posX) < (half_width + buffer_zone)));
        const top_div = @as(i32, @boolToInt(@floatToInt(i32, self.posY) > (half_height - buffer_zone)));
        const bottom_div = @as(i32, @boolToInt(@floatToInt(i32, self.posY) < (half_height + buffer_zone)));

        return @bitCast(u32, ((right_div & bottom_div) << 0) | ((left_div & bottom_div) << 1) | ((right_div & top_div) << 2) | ((left_div & top_div) << 3)) & 0x0F;
    }

    fn playFootstep(self: *Self) !void {
        const dx = self.posX - self.lastX;
        const dy = self.posY - self.lastY;
        const distance = std.math.sqrt(dx * dx + dy * dy);

        const speed = distance * DistanceToSpeed;
        try Wwise.setRTPCValueByString("Footstep_Speed", speed, DemoGameObjectID);

        const period = @floatToInt(isize, WalkPeriod - speed);
        if (distance < 0.1 and self.last_tick_count != -1) {
            try Wwise.setRTPCValueByString("Footstep_Weight", self.weight / 2.0, DemoGameObjectID);
            _ = try Wwise.postEvent("Play_Footsteps", DemoGameObjectID);

            self.last_tick_count = -1;
        } else if (distance > 0.1 and (self.tick_count - self.last_tick_count) > period) {
            try Wwise.setRTPCValueByString("Footstep_Weight", self.weight, DemoGameObjectID);
            _ = try Wwise.postEvent("Play_Footsteps", DemoGameObjectID);

            self.last_tick_count = self.tick_count;
        }

        self.lastX = self.posX;
        self.lastY = self.posY;
    }
};
