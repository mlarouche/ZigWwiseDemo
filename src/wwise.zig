pub const c = @cImport({
    @cInclude("wwise_init.h");
});

pub const Wwise = struct {
    pub const InitError = error{
        MemoryManagerFailed,
        StreamManagerFailed,
        LowLevelIOFailed,
        SoundEngineFailed,
        CommunicationFailed,
    };

    pub fn init() InitError!void {
        switch (c.ZigAk_Init()) {
            .AkInitResult_Success => return,
            .AkInitResult_MemoryManagerFailed => return InitError.MemoryManagerFailed,
            .AkInitResult_StreamManagerFailed => return InitError.StreamManagerFailed,
            .AkInitResult_LowLevelIOFailed => return InitError.LowLevelIOFailed,
            .AkInitResult_SoundEngineFailed => return InitError.SoundEngineFailed,
            .AkInitResult_CommunicationFailed => return InitError.CommunicationFailed,
            else => {},
        }
    }

    pub fn deinit() void {
        c.ZigAk_Deinit();
    }
};
