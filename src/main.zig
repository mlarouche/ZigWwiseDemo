const std = @import("std");
const Wwise = @import("wwise.zig").Wwise;
const ImGui = @import("imgui.zig").ImGui;

const zigwin32 = @import("zigwin32");
const win32 = zigwin32.everything;

const d3d = zigwin32.graphics.direct3d;
const d3d11 = zigwin32.graphics.direct3d11;
const dxgi = zigwin32.graphics.dxgi;

const NullDemo = @import("demos/demo_interface.zig").NullDemo;

const L = std.unicode.utf8ToUtf16LeStringLiteral;

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
    device: ?*d3d11.ID3D11Device = null,
    deviceContext: ?*d3d11.ID3D11DeviceContext = null,
    swapChain: ?*dxgi.IDXGISwapChain = null,
    mainRenderTargetView: ?*d3d11.ID3D11RenderTargetView = null,
};

var dxContext: DxContext = undefined;

fn createDeviceD3D(hWnd: ?win32.HWND) bool {
    var sd = std.mem.zeroes(dxgi.DXGI_SWAP_CHAIN_DESC);
    sd.BufferCount = 2;
    sd.BufferDesc.Width = 0;
    sd.BufferDesc.Height = 0;
    sd.BufferDesc.Format = .R8G8B8A8_UNORM;
    sd.BufferDesc.RefreshRate.Numerator = 60;
    sd.BufferDesc.RefreshRate.Denominator = 1;
    sd.Flags = @enumToInt(dxgi.DXGI_SWAP_CHAIN_FLAG_ALLOW_MODE_SWITCH);
    sd.BufferUsage = dxgi.DXGI_USAGE_RENDER_TARGET_OUTPUT;
    sd.OutputWindow = hWnd;
    sd.SampleDesc.Count = 1;
    sd.SampleDesc.Quality = 0;
    sd.Windowed = @boolToInt(true);
    sd.SwapEffect = .DISCARD;

    var featureLevel: d3d.D3D_FEATURE_LEVEL = undefined;
    const featureLevelArray = &[_]d3d.D3D_FEATURE_LEVEL{
        .@"11_0",
        .@"10_0",
    };
    if (d3d11.D3D11CreateDeviceAndSwapChain(null, .HARDWARE, null, d3d11.D3D11_CREATE_DEVICE_FLAG.initFlags(.{}), featureLevelArray, 2, d3d11.D3D11_SDK_VERSION, &sd, &dxContext.swapChain, &dxContext.device, &featureLevel, &dxContext.deviceContext) != win32.S_OK)
        return false;

    createRenderTarget();

    return true;
}

fn createRenderTarget() void {
    var pBackBuffer: ?*d3d11.ID3D11Texture2D = null;
    if (dxContext.swapChain) |swapChain| {
        _ = swapChain.IDXGISwapChain_GetBuffer(0, d3d11.IID_ID3D11Texture2D, @ptrCast(?*?*c_void, &pBackBuffer));
    }
    if (dxContext.device) |device| {
        _ = device.ID3D11Device_CreateRenderTargetView(@ptrCast(?*d3d11.ID3D11Resource, pBackBuffer), null, @ptrCast(?*?*d3d11.ID3D11RenderTargetView, &dxContext.mainRenderTargetView));
    }
    if (pBackBuffer) |backBuffer| {
        _ = backBuffer.IUnknown_Release();
    }
}

fn cleanupDeviceD3D() void {
    cleanupRenderTarget();
    if (dxContext.swapChain) |swapChain| {
        _ = swapChain.IUnknown_Release();
    }
    if (dxContext.deviceContext) |deviceContext| {
        _ = deviceContext.IUnknown_Release();
    }
    if (dxContext.device) |device| {
        _ = device.IUnknown_Release();
    }
}

fn cleanupRenderTarget() void {
    if (dxContext.mainRenderTargetView) |mainRenderTargetView| {
        _ = mainRenderTargetView.IUnknown_Release();
        dxContext.mainRenderTargetView = null;
    }
}

pub fn main() !void {
    const winClass: win32.WNDCLASSEXW = .{
        .cbSize = @sizeOf(win32.WNDCLASSEXW),
        .style = win32.CS_CLASSDC,
        .lpfnWndProc = WndProc,
        .cbClsExtra = 0,
        .cbWndExtra = 0,
        .hInstance = win32.GetModuleHandleW(null),
        .hIcon = null,
        .hCursor = null,
        .hbrBackground = null,
        .lpszMenuName = null,
        .lpszClassName = L("WwiseDemo"),
        .hIconSm = null,
    };

    _ = win32.RegisterClassExW(&winClass);
    defer _ = win32.UnregisterClassW(winClass.lpszClassName, winClass.hInstance);

    const hwnd = win32.CreateWindowExW(win32.WINDOW_EX_STYLE.initFlags(.{}), winClass.lpszClassName, L("Zig Wwise Demo"), win32.WS_OVERLAPPEDWINDOW, 100, 100, 1200, 800, null, null, winClass.hInstance, null);

    if (hwnd == null) {
        std.log.warn("Error creating Win32 Window = 0x{x}\n", .{@enumToInt(win32.GetLastError())});
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

    std.log.info("Wwise initialized successfully!\n", .{});

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
        if (win32.PeekMessageW(&msg, null, 0, 0, win32.PM_REMOVE) != 0) {
            _ = win32.TranslateMessage(&msg);
            _ = win32.DispatchMessageW(&msg);
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
            _ = deviceContext.ID3D11DeviceContext_OMSetRenderTargets(1, @ptrCast(?[*]?*d3d11.ID3D11RenderTargetView, &dxContext.mainRenderTargetView), null);
            _ = deviceContext.ID3D11DeviceContext_ClearRenderTargetView(dxContext.mainRenderTargetView, @ptrCast(*const f32, &clearColor));
        }
        ImGui.igImplDX11_RenderDrawData(ImGui.igGetDrawData());

        if (dxContext.swapChain) |swapChain| {
            _ = swapChain.IDXGISwapChain_Present(1, 0);
        }

        Wwise.renderAudio();
    }
}

pub fn WndProc(hWnd: win32.HWND, msg: u32, wParam: win32.WPARAM, lParam: win32.LPARAM) callconv(.C) win32.LRESULT {
    if (ImGui.igImplWin32_WndProcHandler(hWnd, msg, wParam, lParam) != 0) {
        return 1;
    }

    switch (msg) {
        win32.WM_SIZE => {
            if (wParam != win32.SIZE_MINIMIZED) {
                if (dxContext.swapChain) |swapChain| {
                    cleanupRenderTarget();
                    _ = swapChain.IDXGISwapChain_ResizeBuffers(0, @intCast(u32, lParam) & 0xFFFF, (@intCast(u32, lParam) >> 16) & 0xFFFF, .UNKNOWN, 0);
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

    return win32.DefWindowProcW(hWnd, msg, wParam, lParam);
}

pub export fn WinMain(hInstance: ?win32.HINSTANCE, hPrevInstance: ?win32.HINSTANCE, lpCmdLine: ?std.os.windows.LPWSTR, nShowCmd: i32) i32 {
    _ = hInstance;
    _ = hPrevInstance;
    _ = lpCmdLine;
    _ = nShowCmd;

    main() catch unreachable;

    return 0;
}
