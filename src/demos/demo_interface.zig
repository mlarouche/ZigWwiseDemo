const std = @import("std");

pub const DemoInterface = struct {
    instance: *c_void,
    initFn: InitFn,
    deinitFn: DeinitFn,
    onUIFn: OnUIFn,
    isVisibleFn: IsVisibleFn,
    showFn: ShowFn,

    pub const InitFn = fn(instance: *c_void, allocator: *std.mem.Allocator) void;
    pub const DeinitFn = fn(instance: *c_void) void;
    pub const OnUIFn = fn(instance: *c_void) anyerror!void;
    pub const IsVisibleFn = fn(instance: *c_void) bool;
    pub const ShowFn =  fn(instance: *c_void) void;

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
            .instance = @ptrCast(*c_void, self),
            .initFn = @ptrCast(DemoInterface.InitFn, init),
            .deinitFn = @ptrCast(DemoInterface.DeinitFn, deinit),
            .onUIFn = @ptrCast(DemoInterface.OnUIFn, onUI),
            .isVisibleFn = @ptrCast(DemoInterface.IsVisibleFn, isVisible),
            .showFn = @ptrCast(DemoInterface.ShowFn, show),
        };
    }
};