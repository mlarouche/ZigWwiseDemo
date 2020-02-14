pub const cWwise = @cImport({
    @cInclude("wwise_init.h");
});

pub const Wwise = struct {
    pub const InitError = error{MemoryManagerFailed};

    pub fn init() InitError!void {
        switch (cWwise.ZigAk_Init()) {
            .AkInitResult_Success => return,
            .AkInitResult_MemoryManagerFailed => return InitError.MemoryManagerFailed,
            else => {},
        }
    }
};
