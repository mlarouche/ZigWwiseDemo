#pragma once

#ifdef __cplusplus
extern "C" {
#endif

typedef enum ZigAkInitResult
{
    AkInitResult_Success,
    AkInitResult_MemoryManagerFailed,
} ZigAkInitResult;

ZigAkInitResult ZigAk_Init();

#ifdef __cplusplus
}
#endif