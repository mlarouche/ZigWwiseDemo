#pragma once

#ifdef __cplusplus
extern "C" {
#endif

#ifndef __cplusplus
#include <wchar.h> // wchar_t not a built-in type in C
#endif

#include <AK/AkPlatforms.h>

typedef enum ZigAkInitResult
{
    AkInitResult_Success,
    AkInitResult_MemoryManagerFailed,
    AkInitResult_StreamManagerFailed,
    AkInitResult_LowLevelIOFailed,
    AkInitResult_SoundEngineFailed,
    AkInitResult_CommunicationFailed,
} ZigAkInitResult;

/* Initialization */
ZigAkInitResult ZigAk_Init();
void ZigAk_Deinit();

void ZigAk_RenderAudio();

void ZigAk_SetIOBasePath(const AkOSChar* basePath);

#ifdef __cplusplus
}
#endif