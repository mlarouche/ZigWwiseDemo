#include "wwise_init.h"

#include <AK/SoundEngine/Common/AkMemoryMgr.h>
#include <AK/SoundEngine/Common/AkModule.h>

ZigAkInitResult ZigAk_Init()
{
    AkMemSettings memSettings;
    AK::MemoryMgr::GetDefaultSettings(memSettings);

    if (AK::MemoryMgr::Init(&memSettings) != AK_Success)
    {
        return AkInitResult_MemoryManagerFailed;
    }

    return AkInitResult_Success;
}
