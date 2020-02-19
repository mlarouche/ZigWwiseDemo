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

typedef enum ZigAkLoadBankResult
{
    AkLoadBankResult_Success,
    AkLoadBankResult_InsufficientMemory,
    AkLoadBankResult_BankReadError,
    AkLoadBankResult_WrongBankVersion,
    AkLoadBankResult_InvalidFile,
    AkLoadBankResult_InvalidParameter,
    AkLoadBankResult_Fail,
} ZigAkLoadBankResult;

typedef enum ZigAkSuccessOrFail
{
    ZigAkSuccess,
    ZigAkFail
} ZigAkSuccessOrFail;

/* Initialization */
ZigAkInitResult ZigAk_Init();
void ZigAk_Deinit();

void ZigAk_RenderAudio();

void ZigAk_SetIOBasePath(const AkOSChar* basePath);

ZigAkLoadBankResult ZigAk_LoadBankByString(const AkOSChar* bankName, AkUInt32* out_bankID);
ZigAkSuccessOrFail ZigAk_UnloadBankByID(AkUInt32 bankID, const void* inMemoryBankPtr);

ZigAkSuccessOrFail ZigAk_RegisterGameObj(AkUInt64 gameObjectID, const char* objectName);
ZigAkSuccessOrFail ZigAk_UnregisterGameObj(AkUInt64 gameObjectID);

AkUInt32 ZigAk_PostEventByString(const char* eventName, AkUInt64 gameObjectID);

void ZigAk_SetDefaultListeners(const AkUInt64* listeners, AkUInt32 listenersSize);

#ifdef __cplusplus
}
#endif