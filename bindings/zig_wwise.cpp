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
        return ZigAkInitResultMemoryManagerFailed;
    }

    AkStreamMgrSettings streamSettings;
    AK::StreamMgr::GetDefaultSettings(streamSettings);

    if (!AK::StreamMgr::Create(streamSettings))
    {
        return ZigAkInitResultStreamManagerFailed;
    }

    AkDeviceSettings deviceSettings;
    AK::StreamMgr::GetDefaultDeviceSettings(deviceSettings);

    if (g_IOHook.Init(deviceSettings) != AK_Success)
    {
        return ZigAkInitResultLowLevelIOFailed;
    }

    AkInitSettings initSettings;
    AkPlatformInitSettings platformInitSettings;
    AK::SoundEngine::GetDefaultInitSettings(initSettings);
    AK::SoundEngine::GetDefaultPlatformInitSettings(platformInitSettings);
    if (AK::SoundEngine::Init(&initSettings, &platformInitSettings) != AK_Success)
    {
        return ZigAkInitResultSoundEngineFailed;
    }

#ifndef AK_OPTIMIZED
    AkCommSettings commSettings;
    AK::Comm::GetDefaultInitSettings(commSettings);
    strcpy(commSettings.szAppNetworkName, "Zig Wwise Demo");
    if (AK::Comm::Init(commSettings) != AK_Success)
    {
        return ZigAkInitResultCommunicationFailed;
    }
#endif

    return ZigAkInitResultSuccess;
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

void ZigAk_SetIOBasePath(const AkOSChar *path)
{
    g_IOHook.SetBasePath(path);
}

ZigAKRESULT ZigAk_LoadBankByString(const AkOSChar *bankName, AkUInt32 *out_bankID)
{
    *out_bankID = 0;
    return (ZigAKRESULT)AK::SoundEngine::LoadBank(bankName, *out_bankID);
}

ZigAKRESULT ZigAk_UnloadBankByID(AkUInt32 bankID, const void *inMemoryBankPtr)
{
    return (ZigAKRESULT)AK::SoundEngine::UnloadBank(bankID, inMemoryBankPtr);
}

ZigAKRESULT ZigAk_UnloadBankByString(const AkOSChar *bankName)
{
    return (ZigAKRESULT)AK::SoundEngine::UnloadBank(bankName, nullptr);
}

ZigAKRESULT ZigAk_RegisterGameObj(AkUInt64 gameObjectID, const char *objectName)
{
    if (objectName)
    {
        return (ZigAKRESULT)AK::SoundEngine::RegisterGameObj(gameObjectID, objectName);
    }
    else
    {
        return (ZigAKRESULT)AK::SoundEngine::RegisterGameObj(gameObjectID);
    }
}

ZigAKRESULT ZigAk_UnregisterGameObj(AkUInt64 gameObjectID)
{
    return (ZigAKRESULT)AK::SoundEngine::UnregisterGameObj(gameObjectID);
}

AkUInt32 ZigAk_PostEventByString(const char *eventName, AkUInt64 gameObjectID)
{
    return AK::SoundEngine::PostEvent(eventName, gameObjectID);
}

AkUInt32 ZigAk_PostEventByStringCallback(const char *eventName, AkUInt64 gameObjectID, AkUInt32 callbackType, ZigAkCallbackFunc callbackFunction, void *cookie)
{
    return AK::SoundEngine::PostEvent(eventName, gameObjectID, callbackType, (AkCallbackFunc)callbackFunction, cookie);
}

ZigAKRESULT ZigAk_SetRTPCValueByString(const char *rtpcName, AkReal32 value, AkUInt64 gameObjectID)
{
    return (ZigAKRESULT)AK::SoundEngine::SetRTPCValue(rtpcName, value, gameObjectID);
}

ZigAKRESULT ZigAk_SetRTPCValueByStringInterpolate(const char *rtpcName, AkReal32 value, AkUInt64 gameObjectID, AkInt32 timeMs, ZigAkCurveInterpolation fadeCurve, bool bypassIntervalValueInterpolation)
{
    return (ZigAKRESULT)AK::SoundEngine::SetRTPCValue(rtpcName, value, gameObjectID, timeMs, (AkCurveInterpolation)fadeCurve, bypassIntervalValueInterpolation);
}

ZigAKRESULT ZigAk_SetRTPCValue(AkUInt32 rtpcID, AkReal32 value, AkUInt64 gameObjectID)
{
    return (ZigAKRESULT)AK::SoundEngine::SetRTPCValue(rtpcID, value, gameObjectID);
}

ZigAKRESULT ZigAk_SetRTPCValueInterpolate(AkUInt32 rtpcID, AkReal32 value, AkUInt64 gameObjectID, AkInt32 timeMs, ZigAkCurveInterpolation fadeCurve, bool bypassIntervalValueInterpolation)
{
    return (ZigAKRESULT)AK::SoundEngine::SetRTPCValue(rtpcID, value, gameObjectID, timeMs, (AkCurveInterpolation)fadeCurve, bypassIntervalValueInterpolation);
}

ZigAKRESULT ZigAk_GetSourcePlayPosition(AkUInt32 playingID, AkInt32 *outPosition, bool extrapolate)
{
    return (ZigAKRESULT)AK::SoundEngine::GetSourcePlayPosition(playingID, outPosition, extrapolate);
}

void ZigAk_StopPlayingID(AkUInt32 playingID, AkInt32 transitionDuration, ZigAkCurveInterpolation fadeCurve)
{
    AK::SoundEngine::StopPlayingID(playingID, transitionDuration, (AkCurveInterpolation)fadeCurve);
}

void ZigAk_StopAll(AkUInt64 gameObjectID)
{
    AK::SoundEngine::StopAll(gameObjectID);
}

void ZigAk_SetDefaultListeners(const AkUInt64 *listeners, AkUInt32 listenersSize)
{
    AK::SoundEngine::SetDefaultListeners(listeners, listenersSize);
}

void ZigAk_StreamMgr_SetCurrentLanguage(const AkOSChar *language)
{
    AK::StreamMgr::SetCurrentLanguage(language);
}

AkUInt32 ZigAk_GetIDFromString(const char *name)
{
    return AK::SoundEngine::GetIDFromString(name);
}

void ZigAk_SetSwitchByID(AkUInt32 switchGroup, AkUInt32 switchState, AkUInt64 gameObjectID)
{
    AK::SoundEngine::SetSwitch(switchGroup, switchState, gameObjectID);
}
