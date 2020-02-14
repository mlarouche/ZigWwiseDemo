#pragma once

#ifdef __cplusplus
extern "C" {
#endif

typedef enum ZigAkInitResult
{
    AkInitResult_Success,
    AkInitResult_MemoryManagerFailed,
    AkInitResult_StreamManagerFailed,
    AkInitResult_LowLevelIOFailed,
    AkInitResult_SoundEngineFailed,
    AkInitResult_CommunicationFailed,
} ZigAkInitResult;

ZigAkInitResult ZigAk_Init();
void ZigAk_Deinit();

#ifdef __cplusplus
}
#endif