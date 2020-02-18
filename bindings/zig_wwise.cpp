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