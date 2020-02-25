const std = @import("std");

pub const DemoInterface = struct {
    instance: InstanceType,
    initFn: InitFn,
    deinitFn: DeinitFn,
    onUIFn: OnUIFn,
    isVisibleFn: IsVisibleFn,
    showFn: ShowFn,

    pub const InstanceType = *u8;
    pub const InitFn = fn(instance: InstanceType, allocator: *std.mem.Allocator) void;
    pub const DeinitFn = fn(instance: InstanceType) void;
    pub const OnUIFn = fn(instance: InstanceType) anyerror!void;
    pub const IsVisibleFn = fn(instance: InstanceType) bool;
    pub const ShowFn =  fn(instance: InstanceType) void;

    const Self = @This();

    pub fn init(self: *Self, allocator: *std.mem.Allocator) void {
        self.initFn(self.instance, allocator);
    }

    pub fn deinit(self: *Self) void {
        self.deinitFn(self.instance);
    }

    pub fn onUI(self: *Self) !void {
        return self.onUIFn(self.instance);
    }

    pub fn isVisible(self: *Self) bool {
        return self.isVisibleFn(self.instance);
    }

    pub fn show(self: *Self) void {
        self.showFn(self.instance);
    }
};

pub const NullDemo = struct {
    allocator: *std.mem.Allocator,

    const Self = @This();

    pub fn init(self: *Self, allocator: *std.mem.Allocator) void {
        self.allocator = allocator;
    }

    pub fn deinit(self: *Self) void {
        self.allocator.destroy(self);
    }

    pub fn onUI(self: *Self) !void {
        return error.Nothing;
    }

    pub fn isVisible(self: *Self) bool {
        return false;
    }

    pub fn show(self: *Self) void {
    }

    pub fn getInterface(self: *Self) DemoInterface {
        return DemoInterface {
            .instance = @ptrCast(DemoInterface.InstanceType, self),
            .initFn = @ptrCast(DemoInterface.InitFn, init),
            .deinitFn = @ptrCast(DemoInterface.DeinitFn, deinit),
            .onUIFn = @ptrCast(DemoInterface.OnUIFn, onUI),
            .isVisibleFn = @ptrCast(DemoInterface.IsVisibleFn, isVisible),
            .showFn = @ptrCast(DemoInterface.ShowFn, show),
        };
    }
};