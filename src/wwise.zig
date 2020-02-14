pub const cWwise = @cImport({
    @cInclude("wwise_init.h");
});

pub const Wwise = struct {
    pub const InitError = error{
        MemoryManagerFailed,
        StreamManagerFailed,
        LowLevelIOFailed,
        SoundEngineFailed,
    };

    pub fn init() InitError!void {
        switch (cWwise.ZigAk_Init()) {
            .AkInitResult_Success => return,
            .AkInitResult_MemoryManagerFailed => return InitError.MemoryManagerFailed,
            .AkInitResult_StreamManagerFailed => return InitError.StreamManagerFailed,
            .AkInitResult_LowLevelIOFailed => return InitError.LowLevelIOFailed,
            .AkInitResult_SoundEngineFailed => return InitError.SoundEngineFailed,
            else => {},
        }
    }
};
