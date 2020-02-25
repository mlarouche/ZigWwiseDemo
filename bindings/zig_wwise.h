#pragma once

#ifdef __cplusplus
extern "C" {
#endif

#ifndef __cplusplus
#include <wchar.h> // wchar_t not a built-in type in C
#include <stdbool.h>
#endif

#include <AK/AkPlatforms.h>

typedef enum ZigAkInitResult
{
    ZigAkInitResultSuccess,
    ZigAkInitResultMemoryManagerFailed,
    ZigAkInitResultStreamManagerFailed,
    ZigAkInitResultLowLevelIOFailed,
    ZigAkInitResultSoundEngineFailed,
    ZigAkInitResultCommunicationFailed,
} ZigAkInitResult;

typedef enum ZigAKRESULT
{
    ZigAKRESULTNotImplemented			= 0,	///< This feature is not implemented.
    ZigAKRESULTSuccess					= 1,	///< The operation was successful.
    ZigAKRESULTFail						= 2,	///< The operation failed.
    ZigAKRESULTPartialSuccess			= 3,	///< The operation succeeded partially.
    ZigAKRESULTNotCompatible			= 4,	///< Incompatible formats
    ZigAKRESULTAlreadyConnected			= 5,	///< The stream is already connected to another node.
    ZigAKRESULTInvalidFile				= 7,	///< An unexpected value causes the file to be invalid.
    ZigAKRESULTAudioFileHeaderTooLarge	= 8,	///< The file header is too large.
    ZigAKRESULTMaxReached				= 9,	///< The maximum was reached.
    ZigAKRESULTInvalidID				= 14,	///< The ID is invalid.
    ZigAKRESULTIDNotFound				= 15,	///< The ID was not found.
    ZigAKRESULTInvalidInstanceID		= 16,	///< The InstanceID is invalid.
    ZigAKRESULTNoMoreData				= 17,	///< No more data is available from the source.
    ZigAKRESULTInvalidStateGroup		= 20,	///< The StateGroup is not a valid channel.
    ZigAKRESULTChildAlreadyHasAParent	= 21,	///< The child already has a parent.
    ZigAKRESULTInvalidLanguage			= 22,	///< The language is invalid (applies to the Low-Level I/O).
    ZigAKRESULTCannotAddItseflAsAChild	= 23,	///< It is not possible to add itself as its own child.
    ZigAKRESULTInvalidParameter			= 31,	///< Something is not within bounds.
    ZigAKRESULTElementAlreadyInList		= 35,	///< The item could not be added because it was already in the list.
    ZigAKRESULTPathNotFound				= 36,	///< This path is not known.
    ZigAKRESULTPathNoVertices			= 37,	///< Stuff in vertices before trying to start it
    ZigAKRESULTPathNotRunning			= 38,	///< Only a running path can be paused.
    ZigAKRESULTPathNotPaused			= 39,	///< Only a paused path can be resumed.
    ZigAKRESULTPathNodeAlreadyInList	= 40,	///< This path is already there.
    ZigAKRESULTPathNodeNotInList		= 41,	///< This path is not there.
    ZigAKRESULTDataNeeded				= 43,	///< The consumer needs more.
    ZigAKRESULTNoDataNeeded				= 44,	///< The consumer does not need more.
    ZigAKRESULTDataReady				= 45,	///< The provider has available data.
    ZigAKRESULTNoDataReady				= 46,	///< The provider does not have available data.
    ZigAKRESULTInsufficientMemory		= 52,	///< Memory error.
    ZigAKRESULTCancelled				= 53,	///< The requested action was cancelled (not an error).
    ZigAKRESULTUnknownBankID			= 54,	///< Trying to load a bank using an ID which is not defined.
    ZigAKRESULTBankReadError			= 56,	///< Error while reading a bank.
    ZigAKRESULTInvalidSwitchType		= 57,	///< Invalid switch type (used with the switch container)
    ZigAKRESULTFormatNotReady           = 63,   ///< Source format not known yet.
    ZigAKRESULTWrongBankVersion			= 64,	///< The bank version is not compatible with the current bank reader.
    ZigAKRESULTFileNotFound             = 66,   ///< File not found.
    ZigAKRESULTDeviceNotReady           = 67,   ///< Specified ID doesn't match a valid hardware device: either the device doesn't exist or is disabled.
    ZigAKRESULTBankAlreadyLoaded		= 69,	///< The bank load failed because the bank is already loaded.
    ZigAKRESULTRenderedFX				= 71,	///< The effect on the node is rendered.
    ZigAKRESULTProcessNeeded			= 72,	///< A routine needs to be executed on some CPU.
    ZigAKRESULTProcessDone				= 73,	///< The executed routine has finished its execution.
    ZigAKRESULTMemManagerNotInitialized	= 74,	///< The memory manager should have been initialized at this point.
    ZigAKRESULTStreamMgrNotInitialized	= 75,	///< The stream manager should have been initialized at this point.
    ZigAKRESULTSSEInstructionsNotSupported = 76,///< The machine does not support SSE instructions (required on PC).
    ZigAKRESULTBusy						= 77,	///< The system is busy and could not process the request.
    ZigAKRESULTUnsupportedChannelConfig = 78,	///< Channel configuration is not supported in the current execution context.
    ZigAKRESULTPluginMediaNotAvailable  = 79,	///< Plugin media is not available for effect.
    ZigAKRESULTMustBeVirtualized		= 80,	///< Sound was Not Allowed to play.
    ZigAKRESULTCommandTooLarge			= 81,	///< SDK command is too large to fit in the command queue.
    ZigAKRESULTRejectedByFilter			= 82,	///< A play request was rejected due to the MIDI filter parameters.
    ZigAKRESULTInvalidCustomPlatformName= 83,	///< Detecting incompatibility between Custom platform of banks and custom platform of connected application
    ZigAKRESULTDLLCannotLoad			= 84,	///< Plugin DLL could not be loaded, either because it is not found or one dependency is missing.
    ZigAKRESULTDLLPathNotFound			= 85,	///< Plugin DLL search path could not be found.
    ZigAKRESULTNoJavaVM					= 86,	///< No Java VM provided in AkInitSettings.
    ZigAKRESULTOpenSLError				= 87,	///< OpenSL returned an error.  Check error log for more details.
    ZigAKRESULTPluginNotRegistered		= 88,	///< Plugin is not registered.  Make sure to implement a AK::PluginRegistration class for it and use AK_STATIC_LINK_PLUGIN in the game binary.
    ZigAKRESULTDataAlignmentError		= 89,	///< A pointer to audio data was not aligned to the platform's required alignment (check AkTypes.h in the platform-specific folder)
    ZigAKRESULTDeviceNotCompatible		= 90,	///< Incompatible Audio device.
    ZigAKRESULTDuplicateUniqueID		= 91,	///< Two Wwise objects share the same ID.
    ZigAKRESULTInitBankNotLoaded		= 92,	///< The Init bank was not loaded yet, the sound engine isn't completely ready yet.
    ZigAKRESULTDeviceNotFound			= 93,	///< The specified device ID does not match with any of the output devices that the sound engine is currently using.
    ZigAKRESULTPlayingIDNotFound		= 94,	///< Calling a function with a playing ID that is not known.
    ZigAKRESULTInvalidFloatValue		= 95,	///< One parameter has a invalid float value such as NaN, INF or FLT_MAX.
} ZigAKRESULT;

typedef struct ZigAkCallbackInfo
{
	void *			pCookie;		///< User data, passed to PostEvent()
	AkUInt64	gameObjID;		///< Game object ID
} ZigAkCallbackInfo;

/// Callback information structure corresponding to \ref AK_EndOfEvent, \ref AK_MusicPlayStarted and \ref AK_Starvation.
/// \sa 
/// - AK::SoundEngine::PostEvent()
/// - \ref soundengine_events
typedef struct ZigAkEventCallbackInfo
{
    ZigAkCallbackInfo base;
	AkUInt32		playingID;		///< Playing ID of Event, returned by PostEvent()
	AkUInt32		eventID;		///< Unique ID of Event, passed to PostEvent()
} ZigAkEventCallbackInfo;

// typedef struct ZigAkMIDIEventCallbackInfo
// {
//     ZigAkEventCallbackInfo base;
// 	AkMIDIEvent		midiEvent;		///< MIDI event triggered by event.
// } ZigAkMIDIEventCallbackInfo;

typedef struct ZigAkMarkerCallbackInfo
{
    ZigAkEventCallbackInfo base;
	AkUInt32	uIdentifier;		///< Cue point identifier
	AkUInt32	uPosition;			///< Position in the cue point (unit: sample frames)
	const char*	strLabel;			///< Label of the marker, read from the file
} ZigAkMarkerCallbackInfo;

typedef struct ZigAkDurationCallbackInfo
{
    ZigAkEventCallbackInfo base;
	AkReal32	fDuration;				///< Duration of the sound (unit: milliseconds)
	AkReal32	fEstimatedDuration;		///< Estimated duration of the sound depending on source settings such as pitch. (unit: milliseconds)
	AkUInt32	audioNodeID;			///< Audio Node ID of playing item
	AkUInt32  mediaID;				///< Media ID of playing item. (corresponds to 'ID' attribute of 'File' element in SoundBank metadata file)
	bool		bStreaming;				///< True if source is streaming, false otherwise.
} ZigAkDurationCallbackInfo;

typedef struct ZigAkDynamicSequenceItemCallbackInfo
{
    ZigAkCallbackInfo base;
	AkUInt32 playingID;			///< Playing ID of Dynamic Sequence, returned by AK::SoundEngine:DynamicSequence::Open()
	AkUInt32	audioNodeID;		///< Audio Node ID of finished item
	void*		pCustomInfo;		///< Custom info passed to the DynamicSequence::Open function
} ZigAkDynamicSequenceItemCallbackInfo;

// typedef struct ZigAkSpeakerVolumeMatrixCallbackInfo
// {
//     ZigAkEventCallbackInfo base;
// 	AK::SpeakerVolumes::MatrixPtr pVolumes;		///< Pointer to volume matrix describing the contribution of each source channel to destination channels. Use methods of AK::SpeakerVolumes::Matrix to interpret them. 
// 	AkChannelConfig inputConfig;				///< Channel configuration of the voice/bus.
// 	AkChannelConfig outputConfig;				///< Channel configuration of the output bus.
// 	AkReal32 * pfBaseVolume;					///< Base volume, common to all channels.
// 	AkReal32 * pfEmitterListenerVolume;			///< Emitter-listener pair-specific gain. When there are multiple emitter-listener pairs, this volume is set to that of the loudest pair, and the relative gain of other pairs is applied directly on the channel volume matrix pVolumes.
// 	AK::IAkMixerInputContext * pContext;		///< Context of the current voice/bus about to be mixed into the output bus with specified base volume and volume matrix.
// 	AK::IAkMixerPluginContext * pMixerContext;	///< Output mixing bus context. Use it to access a few useful panning and mixing services, as well as the ID of the output bus. NULL if pContext is the master audio bus.
// } ZigAkSpeakerVolumeMatrixCallbackInfo;

typedef struct ZigAkMusicPlaylistCallbackInfo
{
    ZigAkEventCallbackInfo base;
	AkUInt32 playlistID;			///< ID of playlist node
	AkUInt32 uNumPlaylistItems;		///< Number of items in playlist node (may be segments or other playlists)
	AkUInt32 uPlaylistSelection;	///< Selection: set by sound engine, modified by callback function (if not in range 0 <= uPlaylistSelection < uNumPlaylistItems then ignored).
	AkUInt32 uPlaylistItemDone;		///< Playlist node done: set by sound engine, modified by callback function (if set to anything but 0 then the current playlist item is done, and uPlaylistSelection is ignored)
} ZigAkMusicPlaylistCallbackInfo;

typedef void(*ZigAkCallbackFunc) (AkUInt32 in_eType, ZigAkCallbackInfo *in_pCallbackInfo);

/* Initialization */
ZigAkInitResult ZigAk_Init();
void ZigAk_Deinit();

void ZigAk_RenderAudio();

void ZigAk_SetIOBasePath(const AkOSChar* basePath);

ZigAKRESULT ZigAk_LoadBankByString(const AkOSChar* bankName, AkUInt32* out_bankID);
ZigAKRESULT ZigAk_UnloadBankByID(AkUInt32 bankID, const void* inMemoryBankPtr);

ZigAKRESULT ZigAk_RegisterGameObj(AkUInt64 gameObjectID, const char* objectName);
ZigAKRESULT ZigAk_UnregisterGameObj(AkUInt64 gameObjectID);

AkUInt32 ZigAk_PostEventByString(const char* eventName, AkUInt64 gameObjectID);
AkUInt32 ZigAk_PostEventByStringCallback(const char* eventName, AkUInt64 gameObjectID, AkUInt32 callbackType, ZigAkCallbackFunc callbackFunction, void* cookie);

ZigAKRESULT ZigAk_GetSourcePlayPosition(AkUInt32 playingID, AkInt32* outPosition, bool extrapolate);

void ZigAk_SetDefaultListeners(const AkUInt64* listeners, AkUInt32 listenersSize);

void ZigAk_StreamMgr_SetCurrentLanguage(const AkOSChar* language);

#ifdef __cplusplus
}
#endif