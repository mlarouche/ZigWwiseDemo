#include "zig_wwise.h"

#include <AK/SoundEngine/Common/AkMemoryMgr.h>
#include <AK/SoundEngine/Common/AkModule.h>
#include <AK/SoundEngine/Common/IAkStreamMgr.h>
#include <AK/SoundEngine/Common/AkSoundEngine.h>
#include <AK/Tools/Common/AkPlatformFuncs.h>

#ifndef AK_OPTIMIZED
#include <AK/Comm/AkCommunication.h>
#endif // AK_OPTIMIZED

#include "IOHook/Win32/AkFilePackageLowLevelIOBlocking.h"

// Plugins
#include <AK/Plugin/AkRoomVerbFXFactory.h>
#include <AK/Plugin/AkStereoDelayFXFactory.h>
#include <AK/Plugin/AkVorbisDecoderFactory.h>

CAkFilePackageLowLevelIOBlocking g_IOHook;

ZigAkInitResult ZigAk_Init()
{
    AkMemSettings memSettings;
    AK::MemoryMgr::GetDefaultSettings(memSettings);

    if (AK::MemoryMgr::Init(&memSettings) != AK_Success)
    {
        return AkInitResult_MemoryManagerFailed;
    }

    AkStreamMgrSettings streamSettings;
    AK::StreamMgr::GetDefaultSettings(streamSettings);

    if (!AK::StreamMgr::Create(streamSettings))
    {
        return AkInitResult_StreamManagerFailed;
    }

    AkDeviceSettings deviceSettings;
    AK::StreamMgr::GetDefaultDeviceSettings(deviceSettings);

    if (g_IOHook.Init(deviceSettings) != AK_Success)
    {
        return AkInitResult_LowLevelIOFailed;
    }

    AkInitSettings initSettings;
    AkPlatformInitSettings platformInitSettings;
    AK::SoundEngine::GetDefaultInitSettings(initSettings);
    AK::SoundEngine::GetDefaultPlatformInitSettings(platformInitSettings);
    if (AK::SoundEngine::Init(&initSettings, &platformInitSettings) != AK_Success)
    {
        return AkInitResult_SoundEngineFailed;
    }

#ifndef AK_OPTIMIZED
    AkCommSettings commSettings;
    AK::Comm::GetDefaultInitSettings(commSettings);
    if ( AK::Comm::Init(commSettings) != AK_Success)
    {
        return AkInitResult_CommunicationFailed;
    }
#endif

    return AkInitResult_Success;
}

void ZigAk_Deinit()
{
#ifndef AK_OPTIMIZED
    AK::Comm::Term();
#endif

    AK::SoundEngine::Term();

    g_IOHook.Term();

    if (AK::IAkStreamMgr::Get())
    {
        AK::IAkStreamMgr::Get()->Destroy();
    }

    AK::MemoryMgr::Term();
}

void ZigAk_RenderAudio()
{
    AK::SoundEngine::RenderAudio();
}

void ZigAk_SetIOBasePath(const AkOSChar* path)
{
    g_IOHook.SetBasePath(path);
}

ZigAkLoadBankResult ZigAk_LoadBankByString(const AkOSChar* bankName, AkUInt32* out_bankID)
{
    *out_bankID = 0;
    auto result = AK::SoundEngine::LoadBank(bankName, *out_bankID);
    switch(result)
    {
        case AK_Success: return AkLoadBankResult_Success;
        case AK_InsufficientMemory: return AkLoadBankResult_InsufficientMemory;
        case AK_BankReadError: return AkLoadBankResult_BankReadError;
        case AK_WrongBankVersion: return AkLoadBankResult_WrongBankVersion;
        case AK_InvalidFile: return AkLoadBankResult_InvalidFile;
        case AK_InvalidParameter: return AkLoadBankResult_InvalidParameter;
        default: return AkLoadBankResult_Fail;
    }

    return AkLoadBankResult_Fail;
}

ZigAkSuccessOrFail ZigAk_UnloadBankByID(AkUInt32 bankID, const void* inMemoryBankPtr)
{
    auto result = AK::SoundEngine::UnloadBank(bankID, inMemoryBankPtr);
    switch (result)
    {
        case AK_Success: return ZigAkSuccess;
        default: return ZigAkFail;
    }
}

ZigAkSuccessOrFail ZigAk_RegisterGameObj(AkUInt64 gameObjectID, const char* objectName)
{
    AKRESULT result;
    if (objectName)
    {
        result = AK::SoundEngine::RegisterGameObj(gameObjectID, objectName);
    }
    else
    {
        result = AK::SoundEngine::RegisterGameObj(gameObjectID);
    }
    switch(result)
    {
        case AK_Success: return ZigAkSuccess;
        default: return ZigAkFail;
    }
}

ZigAkSuccessOrFail ZigAk_UnregisterGameObj(AkUInt64 gameObjectID)
{
    AKRESULT result = AK::SoundEngine::UnregisterGameObj (gameObjectID);

    switch(result)
    {
        case AK_Success: return ZigAkSuccess;
        default: return ZigAkFail;
    }
}

AkUInt32 ZigAk_PostEventByString(const char* eventName, AkUInt64 gameObjectID)
{
    return AK::SoundEngine::PostEvent(eventName, gameObjectID);
}

void ZigAk_SetDefaultListeners(const AkUInt64* listeners, AkUInt32 listenersSize)
{
    AK::SoundEngine::SetDefaultListeners(listeners, listenersSize);
}