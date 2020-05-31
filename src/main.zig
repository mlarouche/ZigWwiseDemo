const std = @import("std");
const Wwise = @import("wwise.zig").Wwise;
const ImGui = @import("imgui.zig").ImGui;

const win32 = @import("win32.zig");
const windows = std.os.windows;

const dx = @import("d3d11.zig");

const NullDemo = @import("demos/demo_interface.zig").NullDemo;

const DemoData = struct {
    displayName: [:0]const u8,
    instanceType: type,
};

const AllDemos = [_]DemoData{
    .{
        .displayName = "Localization Demo",
        .instanceType = @import("demos/localization_demo.zig").LocalizationDemo,
    },
    .{
        .displayName = "RTPC Demo (Car Engine)",
        .instanceType = @import("demos/rtpc_car_engine_demo.zig").RtpcCarEngineDemo,
    },
    .{
        .displayName = "Footsteps Demo",
        .instanceType = @import("demos/footsteps_demo.zig").FootstepsDemo,
    },
    .{
        .displayName = "Subtitle Demo",
        .instanceType = @import("demos/subtitle_demo.zig").SubtitleDemo,
    },
};

const DxContext = struct {
    device: ?*dx.ID3D11Device = null,
    deviceContext: ?*dx.ID3D11DeviceContext = null,
    swapChain: ?*dx.IDXGISwapChain = null,
    mainRenderTargetView: ?*dx.ID3D11RenderTargetView = null,
};

var dxContext: DxContext = undefined;

fn comFindReturnType(comptime vTableType: type, comptime name: []const u8) type {
    for (@typeInfo(vTableType).Struct.fields) |field| {
        if (std.mem.eql(u8, field.name, name)) {
            const funcType = @typeInfo(@typeInfo(field.field_type).Optional.child);
            return funcType.Fn.return_type.?;
        }
    }
    return void;
}

fn comFindVtableType(comptime parentType: type) type {
    switch (@typeInfo(parentType)) {
        .Struct => |structInfo| {
            for (structInfo.fields) |field| {
                if (std.mem.eql(u8, field.name, "lpVtbl")) {
                    return @typeInfo(field.field_type).Pointer.child;
                }
            }
        },
        .Pointer => |pointerInfo| {
            for (@typeInfo(pointerInfo.child).Struct.fields) |field| {
                if (std.mem.eql(u8, field.name, "lpVtbl")) {
                    return @typeInfo(field.field_type).Pointer.child;
                }
            }
        },
        else => {},
    }

    return void;
}

fn comCall(self: var, comptime name: []const u8, args: var) comFindReturnType(comFindVtableType(@TypeOf(self)), name) {
    if (@field(self.lpVtbl[0], name)) |func| {
        return @call(.{}, func, .{self} ++ args);
    }

    return undefined;
}

fn createDeviceD3D(hWnd: win32.HWND) bool {
    var sd = std.mem.zeroes(dx.DXGI_SWAP_CHAIN_DESC);
    sd.BufferCount = 2;
    sd.BufferDesc.Width = 0;
    sd.BufferDesc.Height = 0;
    sd.BufferDesc.Format = ._R8G8B8A8_UNORM;
    sd.BufferDesc.RefreshRate.Numerator = 60;
    sd.BufferDesc.RefreshRate.Denominator = 1;
    sd.Flags = dx.DXGI_SWAP_CHAIN_FLAG_ALLOW_MODE_SWITCH;
    sd.BufferUsage = dx.DXGI_USAGE_RENDER_TARGET_OUTPUT;
    sd.OutputWindow = @ptrCast(dx.HWND, hWnd);
    sd.SampleDesc.Count = 1;
    sd.SampleDesc.Quality = 0;
    sd.Windowed = win32.TRUE;
    sd.SwapEffect = ._DISCARD;

    var createDeviceFlags: win32.UINT = 0;
    var featureLevel: dx.D3D_FEATURE_LEVEL = undefined;
    const featureLevelArray = &[_]dx.D3D_FEATURE_LEVEL{
        ._11_0,
        ._10_0,
    };
    if (dx.D3D11CreateDeviceAndSwapChain(null, ._HARDWARE, null, createDeviceFlags, featureLevelArray, 2, dx.D3D11_SDK_VERSION, &sd, &dxContext.swapChain, &dxContext.device, &featureLevel, &dxContext.deviceContext) != dx.S_OK)
        return false;

    createRenderTarget();

    return true;
}

fn createRenderTarget() void {
    var pBackBuffer: ?*dx.ID3D11Texture2D = null;
    if (dxContext.swapChain) |swapChain| {
        _ = comCall(swapChain, "GetBuffer", .{ 0, &dx.IID_ID3D11Texture2D, @ptrCast([*c]?*c_void, &pBackBuffer) });
    }
    if (dxContext.device) |device| {
        _ = comCall(device, "CreateRenderTargetView", .{ @ptrCast([*c]dx.struct_ID3D11Resource, pBackBuffer), null, @ptrCast([*c][*c]dx.struct_ID3D11RenderTargetView, &dxContext.mainRenderTargetView) });
    }
    if (pBackBuffer) |backBuffer| {
        _ = comCall(backBuffer, "Release", .{});
    }
}

fn cleanupDeviceD3D() void {
    cleanupRenderTarget();
    if (dxContext.swapChain) |swapChain| {
        _ = comCall(swapChain, "Release", .{});
    }
    if (dxContext.deviceContext) |deviceContext| {
        _ = comCall(deviceContext, "Release", .{});
    }
    if (dxContext.device) |device| {
        _ = comCall(device, "Release", .{});
    }
}

fn cleanupRenderTarget() void {
    if (dxContext.mainRenderTargetView) |mainRenderTargetView| {
        _ = comCall(mainRenderTargetView, "Release", .{});
        dxContext.mainRenderTargetView = null;
    }
}

pub fn main() !void {
    const winClass: win32.WNDCLASSEX = .{
        .cbSize = @sizeOf(win32.WNDCLASSEX),
        .style = win32.CS_CLASSDC,
        .lpfnWndProc = WndProc,
        .cbClsExtra = 0,
        .cbWndExtra = 0,
        .hInstance = win32.GetModuleHandle(null),
        .hIcon = null,
        .hCursor = null,
        .hbrBackground = null,
        .lpszMenuName = null,
        .lpszClassName = "WwiseDemo",
        .hIconSm = null,
    };

    _ = win32.RegisterClassEx(&winClass);
    defer _ = win32.UnregisterClass(winClass.lpszClassName, winClass.hInstance);

    const hwnd = win32.CreateWindowEx(0, winClass.lpszClassName, "Zig Wwise Demo", win32.WS_OVERLAPPEDWINDOW, 100, 100, 1200, 800, null, null, winClass.hInstance, null);

    if (hwnd == null) {
        std.debug.warn("Error creating Win32 Window = 0x{x}\n", .{@enumToInt(windows.kernel32.GetLastError())});
        return error.InvalidWin32Window;
    }

    defer _ = win32.DestroyWindow(hwnd);

    const dxResult = createDeviceD3D(hwnd);
    defer cleanupDeviceD3D();

    if (!dxResult) {
        return error.D3DInitError;
    }

    _ = win32.ShowWindow(hwnd, win32.SW_SHOWDEFAULT);
    _ = win32.UpdateWindow(hwnd);

    Wwise.init() catch |err| {
        switch (err) {
            error.MemoryManagerFailed => {
                @panic("AK Memory Manager failed to initialized!");
            },
            error.StreamManagerFailed => {
                @panic("AK Stream Manager failed to initialized!");
            },
            error.LowLevelIOFailed => {
                @panic("Low Level I/O failed to initialize!");
            },
            error.SoundEngineFailed => {
                @panic("Could not initialize the Sound Engine!");
            },
            error.CommunicationFailed => {
                @panic("Could not initiliaze Wwise Communication!");
            },
        }
    };
    defer Wwise.deinit();

    std.debug.warn("Wwise initialized successfully!\n", .{});

    const currentDir = try std.fs.path.resolve(std.heap.c_allocator, &[_][]const u8{"."});
    defer std.heap.c_allocator.free(currentDir);
    const soundBanksPath = try std.fs.path.join(std.heap.c_allocator, &[_][]const u8{ currentDir, "WwiseProject\\GeneratedSoundBanks\\Windows" });
    defer std.heap.c_allocator.free(soundBanksPath);

    try Wwise.setIOHookBasePath(soundBanksPath);

    const loadBankID = try Wwise.loadBankByString("Init.bnk");
    defer {
        _ = Wwise.unloadBankByID(loadBankID);
    }

    try Wwise.registerGameObj(1, "Listener");
    defer Wwise.unregisterGameObj(1);

    Wwise.setDefaultListeners(&[_]u64{1});

    // Setup Dear ImGui context
    const imGuiContext = ImGui.igCreateContext(null);
    defer ImGui.igDestroyContext(imGuiContext);

    const io = ImGui.igGetIO();
    _ = ImGui.ImFontAtlas_AddFontFromFileTTF(io[0].Fonts, "data/SourceSansPro-Semibold.ttf", 28.0, null, null);

    // Setup Dear ImGui style
    ImGui.igStyleColorsDark(null);

    // Setup platform/renderer bindings
    ImGui.igImplWin32_Init(hwnd);
    defer ImGui.igImplWin32_Shutdown();

    ImGui.igImplDX11_Init(@ptrCast(?*ImGui.struct_ID3D11Device, dxContext.device), @ptrCast(?*ImGui.struct_ID3D11DeviceContext, dxContext.deviceContext));
    defer ImGui.igImplDX11_Shutdown();

    const clearColor = ImGui.ImVec4{
        .x = 0.0,
        .y = 0.0,
        .z = 0.0,
        .w = 1.00,
    };

    var defaultInstance = try std.heap.c_allocator.create(NullDemo);
    var currentDemo = defaultInstance.getInterface();

    try currentDemo.init(std.heap.c_allocator);
    defer currentDemo.deinit();

    var msg: win32.MSG = std.mem.zeroes(win32.MSG);
    while (msg.message != win32.WM_QUIT) {
        if (win32.PeekMessage(&msg, null, 0, 0, win32.PM_REMOVE) != 0) {
            _ = win32.TranslateMessage(&msg);
            _ = win32.DispatchMessage(&msg);
            continue;
        }

        ImGui.igImplDX11_NewFrame();
        ImGui.igImplWin32_NewFrame();
        ImGui.igNewFrame();

        var isOpen: bool = true;
        _ = ImGui.igBegin("Zig Wwise", &isOpen, ImGui.ImGuiWindowFlags_AlwaysAutoResize);

        inline for (AllDemos) |demoData| {
            if (ImGui.igButton(demoData.displayName, .{ .x = 0, .y = 0 })) {
                currentDemo.deinit();
                var newDemoInstance = try std.heap.c_allocator.create(demoData.instanceType);
                currentDemo = newDemoInstance.getInterface();
                try currentDemo.init(std.heap.c_allocator);
                currentDemo.show();
            }
        }

        ImGui.igEnd();

        if (currentDemo.isVisible()) {
            try currentDemo.onUI();
        }

        ImGui.igRender();
        if (dxContext.deviceContext) |deviceContext| {
            _ = comCall(deviceContext, "OMSetRenderTargets", .{ 1, &dxContext.mainRenderTargetView, null });
            _ = comCall(deviceContext, "ClearRenderTargetView", .{ dxContext.mainRenderTargetView, @ptrCast(*const f32, &clearColor) });
        }
        ImGui.igImplDX11_RenderDrawData(ImGui.igGetDrawData());

        if (dxContext.swapChain) |swapChain| {
            _ = comCall(swapChain, "Present", .{ 1, 0 });
        }

        Wwise.renderAudio();
    }
}

pub fn WndProc(hWnd: win32.HWND, msg: win32.UINT, wParam: win32.WPARAM, lParam: win32.LPARAM) callconv(.C) win32.LRESULT {
    if (ImGui.igImplWin32_WndProcHandler(hWnd, msg, wParam, lParam) != 0) {
        return 1;
    }

    switch (msg) {
        win32.WM_SIZE => {
            if (wParam != win32.SIZE_MINIMIZED) {
                if (dxContext.swapChain) |swapChain| {
                    cleanupRenderTarget();
                    _ = comCall(swapChain, "ResizeBuffers", .{ 0, @intCast(win32.UINT, lParam & 0xFFFF), @intCast(win32.UINT, (lParam >> 16) & 0xFFFF), dx.DXGI_FORMAT._UNKNOWN, 0 });
                    createRenderTarget();
                }
            }
            return 0;
        },
        win32.WM_SYSCOMMAND => {
            if ((wParam & 0xfff0) == win32.SC_KEYMENU) {
                return 0;
            }
        },
        win32.WM_DESTROY => {
            _ = win32.PostQuitMessage(0);
            return 0;
        },
        else => {},
    }

    return win32.DefWindowProc(hWnd, msg, wParam, lParam);
}

pub export fn WinMain(hInstance: ?win32.HINSTANCE, hPrevInstance: ?win32.HINSTANCE, lpCmdLine: ?win32.LPWSTR, nShowCmd: win32.INT) callconv(.Stdcall) win32.INT {
    main() catch unreachable;

    return 0;
}
