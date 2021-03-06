/**
* Copyright: Steinberg.
* License:   To use this file you MUST agree with the Steinberg VST license included in the VST SDK.
* Authors:   D translation by Guillaume Piolat.
*/
module dplug.vst.aeffectx;

public import dplug.vst.aeffect;

align(8):

/// String length limits (in characters excl. 0 byte).
alias int Vst2StringConstants;
enum : Vst2StringConstants
{
    kVstMaxNameLen       = 64,  /// used for #MidiProgramName, #MidiProgramCategory, #MidiKeyName, #VstSpeakerProperties, #VstPinProperties
    kVstMaxLabelLen      = 64,  /// used for #VstParameterProperties->label, #VstPinProperties->label
    kVstMaxShortLabelLen = 8,   /// used for #VstParameterProperties->shortLabel, #VstPinProperties->shortLabel
    kVstMaxCategLabelLen = 24,  /// used for #VstParameterProperties->label
    kVstMaxFileNameLen   = 100  /// used for #VstAudioFile->name
}

/// A generic timestamped event.
struct VstEvent
{
    VstInt32 type;          ///< @see VstEventTypes
    VstInt32 byteSize;      ///< size of this event, excl. type and byteSize
    VstInt32 deltaFrames;   ///< sample frames related to the current block start sample position
    VstInt32 flags;         ///< generic flags, none defined yet

    char[16] data;          ///< data size may vary, depending on event type
}

/// VstEvent Types used by #VstEvent.
alias int VstEventTypes;
enum : VstEventTypes
{
    kVstMidiType = 1,       ///< MIDI event  @see VstMidiEvent
    DEPRECATED_kVstAudioType,       ///< \deprecated unused event type
    DEPRECATED_kVstVideoType,       ///< \deprecated unused event type
    DEPRECATED_kVstParameterType,   ///< \deprecated unused event type
    DEPRECATED_kVstTriggerType, ///< \deprecated unused event type
    kVstSysExType           ///< MIDI system exclusive  @see VstMidiSysexEvent
}

/// A block of events for the current processed audio block.
struct VstEvents
{
    VstInt32 numEvents;     ///< number of Events in array
    VstIntPtr reserved;     ///< zero (Reserved for future use)
    VstEvent*[2] events;    ///< event pointer array, variable size
}

/// MIDI Event (to be casted from VstEvent).
struct VstMidiEvent
{
    VstInt32 type;          ///< #kVstMidiType
    VstInt32 byteSize;      ///< sizeof (VstMidiEvent)
    VstInt32 deltaFrames;   ///< sample frames related to the current block start sample position
    VstInt32 flags;         ///< @see VstMidiEventFlags
    VstInt32 noteLength;    ///< (in sample frames) of entire note, if available, else 0
    VstInt32 noteOffset;    ///< offset (in sample frames) into note from note start if available, else 0
    char[4] midiData;       ///< 1 to 3 MIDI bytes; midiData[3] is reserved (zero)
    char detune;            ///< -64 to +63 cents; for scales other than 'well-tempered' ('microtuning')
    char noteOffVelocity;   ///< Note Off Velocity [0, 127]
    char reserved1;         ///< zero (Reserved for future use)
    char reserved2;         ///< zero (Reserved for future use)
}

/// Flags used in #VstMidiEvent.
alias int VstMidiEventFlags;
enum : VstMidiEventFlags
{
    kVstMidiEventIsRealtime = 1 << 0    ///< means that this event is played life (not in playback from a sequencer track).\n This allows the Plug-In to handle these flagged events with higher priority, especially when the Plug-In has a big latency (AEffect::initialDelay)
}

/// MIDI Sysex Event (to be casted from #VstEvent).
struct VstMidiSysexEvent
{
    VstInt32 type;          ///< #kVstSysexType
    VstInt32 byteSize;      ///< sizeof (VstMidiSysexEvent)
    VstInt32 deltaFrames;   ///< sample frames related to the current block start sample position
    VstInt32 flags;         ///< none defined yet (should be zero)
    VstInt32 dumpBytes;     ///< byte size of sysexDump
    VstIntPtr resvd1;       ///< zero (Reserved for future use)
    char* sysexDump;        ///< sysex dump
    VstIntPtr resvd2;       ///< zero (Reserved for future use)
}

//-------------------------------------------------------------------------------------------------------
// VstTimeInfo
//-------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------
/** VstTimeInfo requested via #audioMasterGetTime.  @see AudioEffectX::getTimeInfo

\note VstTimeInfo::samplePos :Current Position. It must always be valid, and should not cost a lot to ask for. The sample position is ahead of the time displayed to the user. In sequencer stop mode, its value does not change. A 32 bit integer is too small for sample positions, and it's a double to make it easier to convert between ppq and samples.
\note VstTimeInfo::ppqPos : At tempo 120, 1 quarter makes 1/2 second, so 2.0 ppq translates to 48000 samples at 48kHz sample rate.
.25 ppq is one sixteenth note then. if you need something like 480ppq, you simply multiply ppq by that scaler.
\note VstTimeInfo::barStartPos : Say we're at bars/beats readout 3.3.3. That's 2 bars + 2 q + 2 sixteenth, makes 2 * 4 + 2 + .25 = 10.25 ppq. at tempo 120, that's 10.25 * .5 = 5.125 seconds, times 48000 = 246000 samples (if my calculator servers me well :-).
\note VstTimeInfo::samplesToNextClock : MIDI Clock Resolution (24 per Quarter Note), can be negative the distance to the next midi clock (24 ppq, pulses per quarter) in samples. unless samplePos falls precicely on a midi clock, this will either be negative such that the previous MIDI clock is addressed, or positive when referencing the following (future) MIDI clock.
*/
//-------------------------------------------------------------------------------------------------------
struct VstTimeInfo
{
    double samplePos;               ///< current Position in audio samples (always valid)
    double sampleRate;              ///< current Sample Rate in Herz (always valid)
    double nanoSeconds;             ///< System Time in nanoseconds (10^-9 second)
    double ppqPos;                  ///< Musical Position, in Quarter Note (1.0 equals 1 Quarter Note)
    double tempo;                   ///< current Tempo in BPM (Beats Per Minute)
    double barStartPos;             ///< last Bar Start Position, in Quarter Note
    double cycleStartPos;           ///< Cycle Start (left locator), in Quarter Note
    double cycleEndPos;             ///< Cycle End (right locator), in Quarter Note
    VstInt32 timeSigNumerator;      ///< Time Signature Numerator (e.g. 3 for 3/4)
    VstInt32 timeSigDenominator;    ///< Time Signature Denominator (e.g. 4 for 3/4)
    VstInt32 smpteOffset;           ///< SMPTE offset (in SMPTE subframes (bits; 1/80 of a frame)). The current SMPTE position can be calculated using #samplePos, #sampleRate, and #smpteFrameRate.
    VstInt32 smpteFrameRate;        ///< @see VstSmpteFrameRate
    VstInt32 samplesToNextClock;    ///< MIDI Clock Resolution (24 Per Quarter Note), can be negative (nearest clock)
    VstInt32 flags;                 ///< @see VstTimeInfoFlags
}

/// Flags used in #VstTimeInfo.
alias int VstTimeInfoFlags;
enum : VstTimeInfoFlags
{
    kVstTransportChanged     = 1,       ///< indicates that play, cycle or record state has changed
    kVstTransportPlaying     = 1 << 1,  ///< set if Host sequencer is currently playing
    kVstTransportCycleActive = 1 << 2,  ///< set if Host sequencer is in cycle mode
    kVstTransportRecording   = 1 << 3,  ///< set if Host sequencer is in record mode
    kVstAutomationWriting    = 1 << 6,  ///< set if automation write mode active (record parameter changes)
    kVstAutomationReading    = 1 << 7,  ///< set if automation read mode active (play parameter changes)
    kVstNanosValid           = 1 << 8,  ///< VstTimeInfo::nanoSeconds valid
    kVstPpqPosValid          = 1 << 9,  ///< VstTimeInfo::ppqPos valid
    kVstTempoValid           = 1 << 10, ///< VstTimeInfo::tempo valid
    kVstBarsValid            = 1 << 11, ///< VstTimeInfo::barStartPos valid
    kVstCyclePosValid        = 1 << 12, ///< VstTimeInfo::cycleStartPos and VstTimeInfo::cycleEndPos valid
    kVstTimeSigValid         = 1 << 13, ///< VstTimeInfo::timeSigNumerator and VstTimeInfo::timeSigDenominator valid
    kVstSmpteValid           = 1 << 14, ///< VstTimeInfo::smpteOffset and VstTimeInfo::smpteFrameRate valid
    kVstClockValid           = 1 << 15  ///< VstTimeInfo::samplesToNextClock valid
}

//-------------------------------------------------------------------------------------------------------
/** SMPTE Frame Rates. */
//-------------------------------------------------------------------------------------------------------
alias int VstSmpteFrameRate;
enum : VstSmpteFrameRate
{
//-------------------------------------------------------------------------------------------------------
    kVstSmpte24fps    = 0,      ///< 24 fps
    kVstSmpte25fps    = 1,      ///< 25 fps
    kVstSmpte2997fps  = 2,      ///< 29.97 fps
    kVstSmpte30fps    = 3,      ///< 30 fps
    kVstSmpte2997dfps = 4,      ///< 29.97 drop
    kVstSmpte30dfps   = 5,      ///< 30 drop

    kVstSmpteFilm16mm = 6,      ///< Film 16mm
    kVstSmpteFilm35mm = 7,      ///< Film 35mm
    kVstSmpte239fps   = 10,     ///< HDTV: 23.976 fps
    kVstSmpte249fps   = 11,     ///< HDTV: 24.976 fps
    kVstSmpte599fps   = 12,     ///< HDTV: 59.94 fps
    kVstSmpte60fps    = 13      ///< HDTV: 60 fps
//-------------------------------------------------------------------------------------------------------
};

//-------------------------------------------------------------------------------------------------------
/** Variable IO for Offline Processing. */
//-------------------------------------------------------------------------------------------------------
struct VstVariableIo
{
//-------------------------------------------------------------------------------------------------------
    float** inputs;                             ///< input audio buffers
    float** outputs;                            ///< output audio buffers
    VstInt32 numSamplesInput;                   ///< number of incoming samples
    VstInt32 numSamplesOutput;                  ///< number of outgoing samples
    VstInt32* numSamplesInputProcessed;         ///< number of samples actually processed of input
    VstInt32* numSamplesOutputProcessed;        ///< number of samples actually processed of output
//-------------------------------------------------------------------------------------------------------
};

//-------------------------------------------------------------------------------------------------------
/** Language code returned by audioMasterGetLanguage. */
//-------------------------------------------------------------------------------------------------------
alias int VstHostLanguage;
enum : VstHostLanguage
{
//-------------------------------------------------------------------------------------------------------
    kVstLangEnglish = 1,    ///< English
    kVstLangGerman,         ///< German
    kVstLangFrench,         ///< French
    kVstLangItalian,        ///< Italian
    kVstLangSpanish,        ///< Spanish
    kVstLangJapanese        ///< Japanese
//-------------------------------------------------------------------------------------------------------
};

//-------------------------------------------------------------------------------------------------------
/** VST 2.x dispatcher Opcodes (Plug-in to Host). Extension of #AudioMasterOpcodes */
//-------------------------------------------------------------------------------------------------------

alias int AudioMasterOpcodesX;
enum : AudioMasterOpcodesX
{
//-------------------------------------------------------------------------------------------------------
    DEPRECATED_audioMasterWantMidi = DEPRECATED_audioMasterPinConnected + 2,    ///< \deprecated deprecated in VST 2.4

    audioMasterGetTime,             ///< [return value]: #VstTimeInfo* or null if not supported [value]: request mask  @see VstTimeInfoFlags @see AudioEffectX::getTimeInfo
    audioMasterProcessEvents,       ///< [ptr]: pointer to #VstEvents  @see VstEvents @see AudioEffectX::sendVstEventsToHost

    DEPRECATED_audioMasterSetTime,    ///< \deprecated deprecated in VST 2.4
    DEPRECATED_audioMasterTempoAt,    ///< \deprecated deprecated in VST 2.4
    DEPRECATED_audioMasterGetNumAutomatableParameters,    ///< \deprecated deprecated in VST 2.4
    DEPRECATED_audioMasterGetParameterQuantization,       ///< \deprecated deprecated in VST 2.4

    audioMasterIOChanged,           ///< [return value]: 1 if supported  @see AudioEffectX::ioChanged

    DEPRECATED_audioMasterNeedIdle,   ///< \deprecated deprecated in VST 2.4

    audioMasterSizeWindow,          ///< [index]: new width [value]: new height [return value]: 1 if supported  @see AudioEffectX::sizeWindow
    audioMasterGetSampleRate,       ///< [return value]: current sample rate  @see AudioEffectX::updateSampleRate
    audioMasterGetBlockSize,        ///< [return value]: current block size  @see AudioEffectX::updateBlockSize
    audioMasterGetInputLatency,     ///< [return value]: input latency in audio samples  @see AudioEffectX::getInputLatency
    audioMasterGetOutputLatency,    ///< [return value]: output latency in audio samples  @see AudioEffectX::getOutputLatency

    DEPRECATED_audioMasterGetPreviousPlug,            ///< \deprecated deprecated in VST 2.4
    DEPRECATED_audioMasterGetNextPlug,                ///< \deprecated deprecated in VST 2.4
    DEPRECATED_audioMasterWillReplaceOrAccumulate,    ///< \deprecated deprecated in VST 2.4

    audioMasterGetCurrentProcessLevel,  ///< [return value]: current process level  @see VstProcessLevels
    audioMasterGetAutomationState,      ///< [return value]: current automation state  @see VstAutomationStates

    audioMasterOfflineStart,            ///< [index]: numNewAudioFiles [value]: numAudioFiles [ptr]: #VstAudioFile*  @see AudioEffectX::offlineStart
    audioMasterOfflineRead,             ///< [index]: bool readSource [value]: #VstOfflineOption* @see VstOfflineOption [ptr]: #VstOfflineTask*  @see VstOfflineTask @see AudioEffectX::offlineRead
    audioMasterOfflineWrite,            ///< @see audioMasterOfflineRead @see AudioEffectX::offlineRead
    audioMasterOfflineGetCurrentPass,   ///< @see AudioEffectX::offlineGetCurrentPass
    audioMasterOfflineGetCurrentMetaPass,   ///< @see AudioEffectX::offlineGetCurrentMetaPass

    DEPRECATED_audioMasterSetOutputSampleRate,            ///< \deprecated deprecated in VST 2.4
    DEPRECATED_audioMasterGetOutputSpeakerArrangement,    ///< \deprecated deprecated in VST 2.4

    audioMasterGetVendorString,         ///< [ptr]: char buffer for vendor string, limited to #kVstMaxVendorStrLen  @see AudioEffectX::getHostVendorString
    audioMasterGetProductString,        ///< [ptr]: char buffer for vendor string, limited to #kVstMaxProductStrLen  @see AudioEffectX::getHostProductString
    audioMasterGetVendorVersion,        ///< [return value]: vendor-specific version  @see AudioEffectX::getHostVendorVersion
    audioMasterVendorSpecific,          ///< no definition, vendor specific handling  @see AudioEffectX::hostVendorSpecific

    DEPRECATED_audioMasterSetIcon,        ///< \deprecated deprecated in VST 2.4

    audioMasterCanDo,                   ///< [ptr]: "can do" string [return value]: 1 for supported
    audioMasterGetLanguage,             ///< [return value]: language code  @see VstHostLanguage

    DEPRECATED_audioMasterOpenWindow,     ///< \deprecated deprecated in VST 2.4
    DEPRECATED_audioMasterCloseWindow,    ///< \deprecated deprecated in VST 2.4

    audioMasterGetDirectory,            ///< [return value]: FSSpec on MAC, else char*  @see AudioEffectX::getDirectory
    audioMasterUpdateDisplay,           ///< no arguments
    audioMasterBeginEdit,               ///< [index]: parameter index  @see AudioEffectX::beginEdit
    audioMasterEndEdit,                 ///< [index]: parameter index  @see AudioEffectX::endEdit
    audioMasterOpenFileSelector,        ///< [ptr]: VstFileSelect* [return value]: 1 if supported  @see AudioEffectX::openFileSelector
    audioMasterCloseFileSelector,       ///< [ptr]: VstFileSelect*  @see AudioEffectX::closeFileSelector

    DEPRECATED_audioMasterEditFile,       ///< \deprecated deprecated in VST 2.4

    DEPRECATED_audioMasterGetChunkFile,   ///< \deprecated deprecated in VST 2.4 [ptr]: char[2048] or sizeof (FSSpec) [return value]: 1 if supported  @see AudioEffectX::getChunkFile

    DEPRECATED_audioMasterGetInputSpeakerArrangement  ///< \deprecated deprecated in VST 2.4
}

//-------------------------------------------------------------------------------------------------------
/** VST 2.x dispatcher Opcodes (Host to Plug-in). Extension of #AEffectOpcodes */
//-------------------------------------------------------------------------------------------------------
alias int AEffectXOpcodes;
enum : AEffectXOpcodes
{
//-------------------------------------------------------------------------------------------------------
    effProcessEvents = effSetChunk + 1      ///< [ptr]: #VstEvents*  @see AudioEffectX::processEvents

    , effCanBeAutomated                     ///< [index]: parameter index [return value]: 1=true, 0=false  @see AudioEffectX::canParameterBeAutomated
    , effString2Parameter                   ///< [index]: parameter index [ptr]: parameter string [return value]: true for success  @see AudioEffectX::string2parameter

    , DEPRECATED_effGetNumProgramCategories   ///< \deprecated deprecated in VST 2.4

    , effGetProgramNameIndexed              ///< [index]: program index [ptr]: buffer for program name, limited to #kVstMaxProgNameLen [return value]: true for success  @see AudioEffectX::getProgramNameIndexed

    , DEPRECATED_effCopyProgram   ///< \deprecated deprecated in VST 2.4
    , DEPRECATED_effConnectInput  ///< \deprecated deprecated in VST 2.4
    , DEPRECATED_effConnectOutput ///< \deprecated deprecated in VST 2.4

    , effGetInputProperties                 ///< [index]: input index [ptr]: #VstPinProperties* [return value]: 1 if supported  @see AudioEffectX::getInputProperties
    , effGetOutputProperties                ///< [index]: output index [ptr]: #VstPinProperties* [return value]: 1 if supported  @see AudioEffectX::getOutputProperties
    , effGetPlugCategory                    ///< [return value]: category  @see VstPlugCategory @see AudioEffectX::getPlugCategory

    , DEPRECATED_effGetCurrentPosition    ///< \deprecated deprecated in VST 2.4
    , DEPRECATED_effGetDestinationBuffer  ///< \deprecated deprecated in VST 2.4

    , effOfflineNotify                      ///< [ptr]: #VstAudioFile array [value]: count [index]: start flag  @see AudioEffectX::offlineNotify
    , effOfflinePrepare                     ///< [ptr]: #VstOfflineTask array [value]: count  @see AudioEffectX::offlinePrepare
    , effOfflineRun                         ///< [ptr]: #VstOfflineTask array [value]: count  @see AudioEffectX::offlineRun

    , effProcessVarIo                       ///< [ptr]: #VstVariableIo*  @see AudioEffectX::processVariableIo
    , effSetSpeakerArrangement              ///< [value]: input #VstSpeakerArrangement* [ptr]: output #VstSpeakerArrangement*  @see AudioEffectX::setSpeakerArrangement

    , DEPRECATED_effSetBlockSizeAndSampleRate ///< \deprecated deprecated in VST 2.4

    , effSetBypass                          ///< [value]: 1 = bypass, 0 = no bypass  @see AudioEffectX::setBypass
    , effGetEffectName                      ///< [ptr]: buffer for effect name, limited to #kVstMaxEffectNameLen  @see AudioEffectX::getEffectName

    , DEPRECATED_effGetErrorText  ///< \deprecated deprecated in VST 2.4

    , effGetVendorString                    ///< [ptr]: buffer for effect vendor string, limited to #kVstMaxVendorStrLen  @see AudioEffectX::getVendorString
    , effGetProductString                   ///< [ptr]: buffer for effect vendor string, limited to #kVstMaxProductStrLen  @see AudioEffectX::getProductString
    , effGetVendorVersion                   ///< [return value]: vendor-specific version  @see AudioEffectX::getVendorVersion
    , effVendorSpecific                     ///< no definition, vendor specific handling  @see AudioEffectX::vendorSpecific
    , effCanDo                              ///< [ptr]: "can do" string [return value]: 0: "don't know" -1: "no" 1: "yes"  @see AudioEffectX::canDo
    , effGetTailSize                        ///< [return value]: tail size (for example the reverb time of a reverb plug-in); 0 is default (return 1 for 'no tail')

    , DEPRECATED_effIdle              ///< \deprecated deprecated in VST 2.4
    , DEPRECATED_effGetIcon           ///< \deprecated deprecated in VST 2.4
    , DEPRECATED_effSetViewPosition   ///< \deprecated deprecated in VST 2.4

    , effGetParameterProperties             ///< [index]: parameter index [ptr]: #VstParameterProperties* [return value]: 1 if supported  @see AudioEffectX::getParameterProperties

    , DEPRECATED_effKeysRequired  ///< \deprecated deprecated in VST 2.4

    , effGetVstVersion                      ///< [return value]: VST version  @see AudioEffectX::getVstVersion

    // VST 2.1
    , effEditKeyDown                        ///< [index]: ASCII character [value]: virtual key [opt]: modifiers [return value]: 1 if key used  @see AEffEditor::onKeyDown
    , effEditKeyUp                          ///< [index]: ASCII character [value]: virtual key [opt]: modifiers [return value]: 1 if key used  @see AEffEditor::onKeyUp
    , effSetEditKnobMode                    ///< [value]: knob mode 0: circular, 1: circular relativ, 2: linear (CKnobMode in VSTGUI)  @see AEffEditor::setKnobMode

    , effGetMidiProgramName                 ///< [index]: MIDI channel [ptr]: #MidiProgramName* [return value]: number of used programs, 0 if unsupported  @see AudioEffectX::getMidiProgramName
    , effGetCurrentMidiProgram              ///< [index]: MIDI channel [ptr]: #MidiProgramName* [return value]: index of current program  @see AudioEffectX::getCurrentMidiProgram
    , effGetMidiProgramCategory             ///< [index]: MIDI channel [ptr]: #MidiProgramCategory* [return value]: number of used categories, 0 if unsupported  @see AudioEffectX::getMidiProgramCategory
    , effHasMidiProgramsChanged             ///< [index]: MIDI channel [return value]: 1 if the #MidiProgramName(s) or #MidiKeyName(s) have changed  @see AudioEffectX::hasMidiProgramsChanged
    , effGetMidiKeyName                     ///< [index]: MIDI channel [ptr]: #MidiKeyName* [return value]: true if supported, false otherwise  @see AudioEffectX::getMidiKeyName

    , effBeginSetProgram                    ///< no arguments  @see AudioEffectX::beginSetProgram
    , effEndSetProgram                      ///< no arguments  @see AudioEffectX::endSetProgram

    // VST 2.3
    , effGetSpeakerArrangement              ///< [value]: input #VstSpeakerArrangement* [ptr]: output #VstSpeakerArrangement*  @see AudioEffectX::getSpeakerArrangement
    , effShellGetNextPlugin                 ///< [ptr]: buffer for plug-in name, limited to #kVstMaxProductStrLen [return value]: next plugin's uniqueID  @see AudioEffectX::getNextShellPlugin

    , effStartProcess                       ///< no arguments  @see AudioEffectX::startProcess
    , effStopProcess                        ///< no arguments  @see AudioEffectX::stopProcess
    , effSetTotalSampleToProcess            ///< [value]: number of samples to process, offline only!  @see AudioEffectX::setTotalSampleToProcess
    , effSetPanLaw                          ///< [value]: pan law [opt]: gain  @see VstPanLawType @see AudioEffectX::setPanLaw

    , effBeginLoadBank                      ///< [ptr]: #VstPatchChunkInfo* [return value]: -1: bank can't be loaded, 1: bank can be loaded, 0: unsupported  @see AudioEffectX::beginLoadBank
    , effBeginLoadProgram                   ///< [ptr]: #VstPatchChunkInfo* [return value]: -1: prog can't be loaded, 1: prog can be loaded, 0: unsupported  @see AudioEffectX::beginLoadProgram

    // VST 2.4
    , effSetProcessPrecision                ///< [value]: @see VstProcessPrecision  @see AudioEffectX::setProcessPrecision
    , effGetNumMidiInputChannels            ///< [return value]: number of used MIDI input channels (1-15)  @see AudioEffectX::getNumMidiInputChannels
    , effGetNumMidiOutputChannels           ///< [return value]: number of used MIDI output channels (1-15)  @see AudioEffectX::getNumMidiOutputChannels
}

//-------------------------------------------------------------------------------------------------------
/** Symbolic precision constants used for effSetProcessPrecision. */
//-------------------------------------------------------------------------------------------------------
alias int VstProcessPrecision;
enum : VstProcessPrecision
{
    kVstProcessPrecision32 = 0,     ///< single precision float (32bits)
    kVstProcessPrecision64          ///< double precision (64bits)
}

//-------------------------------------------------------------------------------------------------------
/** Parameter Properties used in #effGetParameterProperties. */
//-------------------------------------------------------------------------------------------------------
struct VstParameterProperties
{
//-------------------------------------------------------------------------------------------------------
    float stepFloat;            ///< float step
    float smallStepFloat;       ///< small float step
    float largeStepFloat;       ///< large float step
    char[kVstMaxLabelLen] label;///< parameter label
    VstInt32 flags;             ///< @see VstParameterFlags
    VstInt32 minInteger;        ///< integer minimum
    VstInt32 maxInteger;        ///< integer maximum
    VstInt32 stepInteger;       ///< integer step
    VstInt32 largeStepInteger;  ///< large integer step
    char[kVstMaxShortLabelLen] shortLabel;  ///< short label, recommended: 6 + delimiter

    // The following are for remote controller display purposes.
    // Note that the kVstParameterSupportsDisplayIndex flag must be set.
    // Host can scan all parameters, and find out in what order
    // to display them:

    VstInt16 displayIndex;      ///< index where this parameter should be displayed (starting with 0)

    // Host can also possibly display the parameter group (category), such as...
    // ---------------------------
    // Osc 1
    // Wave  Detune  Octave  Mod
    // ---------------------------
    // ...if the plug-in supports it (flag #kVstParameterSupportsDisplayCategory)

    VstInt16 category;          ///< 0: no category, else group index + 1
    VstInt16 numParametersInCategory;           ///< number of parameters in category
    VstInt16 reserved;          ///< zero
    char[kVstMaxCategLabelLen] categoryLabel;   ///< category label, e.g. "Osc 1"

    char[16] future;            ///< reserved for future use
//-------------------------------------------------------------------------------------------------------
}

//-------------------------------------------------------------------------------------------------------
/** Flags used in #VstParameterProperties. */
//-------------------------------------------------------------------------------------------------------
alias int VstParameterFlags;
enum : VstParameterFlags
{
//-------------------------------------------------------------------------------------------------------
    kVstParameterIsSwitch                = 1 << 0,  ///< parameter is a switch (on/off)
    kVstParameterUsesIntegerMinMax       = 1 << 1,  ///< minInteger, maxInteger valid
    kVstParameterUsesFloatStep           = 1 << 2,  ///< stepFloat, smallStepFloat, largeStepFloat valid
    kVstParameterUsesIntStep             = 1 << 3,  ///< stepInteger, largeStepInteger valid
    kVstParameterSupportsDisplayIndex    = 1 << 4,  ///< displayIndex valid
    kVstParameterSupportsDisplayCategory = 1 << 5,  ///< category, etc. valid
    kVstParameterCanRamp                 = 1 << 6   ///< set if parameter value can ramp up/down
//-------------------------------------------------------------------------------------------------------
}

//-------------------------------------------------------------------------------------------------------
/** Pin Properties used in #effGetInputProperties and #effGetOutputProperties. */
//-------------------------------------------------------------------------------------------------------
struct VstPinProperties
{
//-------------------------------------------------------------------------------------------------------
    char[kVstMaxLabelLen] label;    ///< pin name
    VstInt32 flags;                 ///< @see VstPinPropertiesFlags
    VstInt32 arrangementType;       ///< @see VstSpeakerArrangementType
    char[kVstMaxShortLabelLen] shortLabel;  ///< short name (recommended: 6 + delimiter)

    char[48] future;                ///< reserved for future use
//-------------------------------------------------------------------------------------------------------
}

//-------------------------------------------------------------------------------------------------------
/** Flags used in #VstPinProperties. */
//-------------------------------------------------------------------------------------------------------
alias int VstPinPropertiesFlags;
enum : VstPinPropertiesFlags
{
//-------------------------------------------------------------------------------------------------------
    kVstPinIsActive   = 1 << 0,     ///< pin is active, ignored by Host
    kVstPinIsStereo   = 1 << 1,     ///< pin is first of a stereo pair
    kVstPinUseSpeaker = 1 << 2      ///< #VstPinProperties::arrangementType is valid and can be used to get the wanted arrangement
//-------------------------------------------------------------------------------------------------------
}

//-------------------------------------------------------------------------------------------------------
/** Plug-in Categories. */
//-------------------------------------------------------------------------------------------------------
alias int VstPlugCategory;
enum : VstPlugCategory
{
//-------------------------------------------------------------------------------------------------------
    kPlugCategUnknown = 0,      ///< Unknown, category not implemented
    kPlugCategEffect,           ///< Simple Effect
    kPlugCategSynth,            ///< VST Instrument (Synths, samplers,...)
    kPlugCategAnalysis,         ///< Scope, Tuner, ...
    kPlugCategMastering,        ///< Dynamics, ...
    kPlugCategSpacializer,      ///< Panners, ...
    kPlugCategRoomFx,           ///< Delays and Reverbs
    kPlugSurroundFx,            ///< Dedicated surround processor
    kPlugCategRestoration,      ///< Denoiser, ...
    kPlugCategOfflineProcess,   ///< Offline Process
    kPlugCategShell,            ///< Plug-in is container of other plug-ins  @see effShellGetNextPlugin
    kPlugCategGenerator,        ///< ToneGenerator, ...

    kPlugCategMaxCount          ///< Marker to count the categories
//-------------------------------------------------------------------------------------------------------
}

//-------------------------------------------------------------------------------------------------------
// MIDI Programs
//-------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------
/** MIDI Program Description. */
//-------------------------------------------------------------------------------------------------------
struct MidiProgramName
{
//-------------------------------------------------------------------------------------------------------
    VstInt32 thisProgramIndex;      ///< 0 or greater: fill struct for this program index
    char[kVstMaxNameLen] name;      ///< program name
    char midiProgram;               ///< -1:off, 0-127
    char midiBankMsb;               ///< -1:off, 0-127
    char midiBankLsb;               ///< -1:off, 0-127
    char reserved;                  ///< zero
    VstInt32 parentCategoryIndex;   ///< -1:no parent category
    VstInt32 flags;                 ///< omni etc. @see VstMidiProgramNameFlags
//-------------------------------------------------------------------------------------------------------
}

//-------------------------------------------------------------------------------------------------------
/** Flags used in MidiProgramName. */
//-------------------------------------------------------------------------------------------------------
alias int VstMidiProgramNameFlags;
enum : VstMidiProgramNameFlags
{
//-------------------------------------------------------------------------------------------------------
    kMidiIsOmni = 1 ///< default is multi. for omni mode, channel 0 is used for inquiries and program changes
//-------------------------------------------------------------------------------------------------------
}

//-------------------------------------------------------------------------------------------------------
/** MIDI Program Category. */
//-------------------------------------------------------------------------------------------------------
struct MidiProgramCategory
{
//-------------------------------------------------------------------------------------------------------
    VstInt32 thisCategoryIndex;     ///< 0 or greater:  fill struct for this category index.
    char[kVstMaxNameLen] name;      ///< name
    VstInt32 parentCategoryIndex;   ///< -1:no parent category
    VstInt32 flags;                 ///< reserved, none defined yet, zero.
//-------------------------------------------------------------------------------------------------------
}

//-------------------------------------------------------------------------------------------------------
/** MIDI Key Description. */
//-------------------------------------------------------------------------------------------------------
struct MidiKeyName
{
//-------------------------------------------------------------------------------------------------------
    VstInt32 thisProgramIndex;      ///< 0 or greater:  fill struct for this program index.
    VstInt32 thisKeyNumber;         ///< 0 - 127. fill struct for this key number.
    char[kVstMaxNameLen] keyName;   ///< key name, empty means regular key names
    VstInt32 reserved;              ///< zero
    VstInt32 flags;                 ///< reserved, none defined yet, zero.
//-------------------------------------------------------------------------------------------------------
}

//-------------------------------------------------------------------------------------------------------
// Surround Setup
//-------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------
/** Speaker Properties.
    The origin for azimuth is right (as by math conventions dealing with radians).
    The elevation origin is also right, visualizing a rotation of a circle across the
    -pi/pi axis of the horizontal circle. Thus, an elevation of -pi/2 corresponds
    to bottom, and a speaker standing on the left, and 'beaming' upwards would have
    an azimuth of -pi, and an elevation of pi/2.
    For user interface representation, grads are more likely to be used, and the
    origins will obviously 'shift' accordingly. */
//-------------------------------------------------------------------------------------------------------
struct VstSpeakerProperties
{
//-------------------------------------------------------------------------------------------------------
    float azimuth;      ///< unit: rad, range: -PI...PI, exception: 10.f for LFE channel
    float elevation;    ///< unit: rad, range: -PI/2...PI/2, exception: 10.f for LFE channel
    float radius;       ///< unit: meter, exception: 0.f for LFE channel
    float reserved;     ///< zero (reserved for future use)
    char[kVstMaxNameLen] name;  ///< for new setups, new names should be given (L/R/C... won't do)
    VstInt32 type;      ///< @see VstSpeakerType

    char[28] future;    ///< reserved for future use
//-------------------------------------------------------------------------------------------------------
}

//-------------------------------------------------------------------------------------------------------
/** Speaker Arrangement. */
//-------------------------------------------------------------------------------------------------------
struct VstSpeakerArrangement
{
//-------------------------------------------------------------------------------------------------------
    VstInt32 type;                      ///< e.g. #kSpeakerArr51 for 5.1  @see VstSpeakerArrangementType
    VstInt32 numChannels;               ///< number of channels in this speaker arrangement
    VstSpeakerProperties[8] speakers;   ///< variable sized speaker array
//-------------------------------------------------------------------------------------------------------
}

//-------------------------------------------------------------------------------------------------------
/** Speaker Types. */
//-------------------------------------------------------------------------------------------------------
alias int VstSpeakerType;
enum : VstSpeakerType
{
//-------------------------------------------------------------------------------------------------------
    kSpeakerUndefined = 0x7fffffff, ///< Undefined
    kSpeakerM = 0,                  ///< Mono (M)
    kSpeakerL,                      ///< Left (L)
    kSpeakerR,                      ///< Right (R)
    kSpeakerC,                      ///< Center (C)
    kSpeakerLfe,                    ///< Subbass (Lfe)
    kSpeakerLs,                     ///< Left Surround (Ls)
    kSpeakerRs,                     ///< Right Surround (Rs)
    kSpeakerLc,                     ///< Left of Center (Lc)
    kSpeakerRc,                     ///< Right of Center (Rc)
    kSpeakerS,                      ///< Surround (S)
    kSpeakerCs = kSpeakerS,         ///< Center of Surround (Cs) = Surround (S)
    kSpeakerSl,                     ///< Side Left (Sl)
    kSpeakerSr,                     ///< Side Right (Sr)
    kSpeakerTm,                     ///< Top Middle (Tm)
    kSpeakerTfl,                    ///< Top Front Left (Tfl)
    kSpeakerTfc,                    ///< Top Front Center (Tfc)
    kSpeakerTfr,                    ///< Top Front Right (Tfr)
    kSpeakerTrl,                    ///< Top Rear Left (Trl)
    kSpeakerTrc,                    ///< Top Rear Center (Trc)
    kSpeakerTrr,                    ///< Top Rear Right (Trr)
    kSpeakerLfe2                    ///< Subbass 2 (Lfe2)
//-------------------------------------------------------------------------------------------------------
}

//-------------------------------------------------------------------------------------------------------
/** User-defined speaker types, to be extended in the negative range.
    Will be handled as their corresponding speaker types with abs values:
    e.g abs(#kSpeakerU1) == #kSpeakerL, abs(#kSpeakerU2) == #kSpeakerR) */
//-------------------------------------------------------------------------------------------------------
alias int VstUserSpeakerType;
enum : VstUserSpeakerType
{
//-------------------------------------------------------------------------------------------------------
    kSpeakerU32 = -32,
    kSpeakerU31,
    kSpeakerU30,
    kSpeakerU29,
    kSpeakerU28,
    kSpeakerU27,
    kSpeakerU26,
    kSpeakerU25,
    kSpeakerU24,
    kSpeakerU23,
    kSpeakerU22,
    kSpeakerU21,
    kSpeakerU20,            ///< == #kSpeakerLfe2
    kSpeakerU19,            ///< == #kSpeakerTrr
    kSpeakerU18,            ///< == #kSpeakerTrc
    kSpeakerU17,            ///< == #kSpeakerTrl
    kSpeakerU16,            ///< == #kSpeakerTfr
    kSpeakerU15,            ///< == #kSpeakerTfc
    kSpeakerU14,            ///< == #kSpeakerTfl
    kSpeakerU13,            ///< == #kSpeakerTm
    kSpeakerU12,            ///< == #kSpeakerSr
    kSpeakerU11,            ///< == #kSpeakerSl
    kSpeakerU10,            ///< == #kSpeakerCs
    kSpeakerU9,             ///< == #kSpeakerS
    kSpeakerU8,             ///< == #kSpeakerRc
    kSpeakerU7,             ///< == #kSpeakerLc
    kSpeakerU6,             ///< == #kSpeakerRs
    kSpeakerU5,             ///< == #kSpeakerLs
    kSpeakerU4,             ///< == #kSpeakerLfe
    kSpeakerU3,             ///< == #kSpeakerC
    kSpeakerU2,             ///< == #kSpeakerR
    kSpeakerU1              ///< == #kSpeakerL
//-------------------------------------------------------------------------------------------------------
}

//-------------------------------------------------------------------------------------------------------
/** Speaker Arrangement Types*/
//-------------------------------------------------------------------------------------------------------
alias int VstSpeakerArrangementType;
enum : VstSpeakerArrangementType
{
//-------------------------------------------------------------------------------------------------------
    kSpeakerArrUserDefined = -2,///< user defined
    kSpeakerArrEmpty = -1,      ///< empty arrangement
    kSpeakerArrMono  =  0,      ///< M
    kSpeakerArrStereo,          ///< L R
    kSpeakerArrStereoSurround,  ///< Ls Rs
    kSpeakerArrStereoCenter,    ///< Lc Rc
    kSpeakerArrStereoSide,      ///< Sl Sr
    kSpeakerArrStereoCLfe,      ///< C Lfe
    kSpeakerArr30Cine,          ///< L R C
    kSpeakerArr30Music,         ///< L R S
    kSpeakerArr31Cine,          ///< L R C Lfe
    kSpeakerArr31Music,         ///< L R Lfe S
    kSpeakerArr40Cine,          ///< L R C   S (LCRS)
    kSpeakerArr40Music,         ///< L R Ls  Rs (Quadro)
    kSpeakerArr41Cine,          ///< L R C   Lfe S (LCRS+Lfe)
    kSpeakerArr41Music,         ///< L R Lfe Ls Rs (Quadro+Lfe)
    kSpeakerArr50,              ///< L R C Ls  Rs
    kSpeakerArr51,              ///< L R C Lfe Ls Rs
    kSpeakerArr60Cine,          ///< L R C   Ls  Rs Cs
    kSpeakerArr60Music,         ///< L R Ls  Rs  Sl Sr
    kSpeakerArr61Cine,          ///< L R C   Lfe Ls Rs Cs
    kSpeakerArr61Music,         ///< L R Lfe Ls  Rs Sl Sr
    kSpeakerArr70Cine,          ///< L R C Ls  Rs Lc Rc
    kSpeakerArr70Music,         ///< L R C Ls  Rs Sl Sr
    kSpeakerArr71Cine,          ///< L R C Lfe Ls Rs Lc Rc
    kSpeakerArr71Music,         ///< L R C Lfe Ls Rs Sl Sr
    kSpeakerArr80Cine,          ///< L R C Ls  Rs Lc Rc Cs
    kSpeakerArr80Music,         ///< L R C Ls  Rs Cs Sl Sr
    kSpeakerArr81Cine,          ///< L R C Lfe Ls Rs Lc Rc Cs
    kSpeakerArr81Music,         ///< L R C Lfe Ls Rs Cs Sl Sr
    kSpeakerArr102,             ///< L R C Lfe Ls Rs Tfl Tfc Tfr Trl Trr Lfe2
    kNumSpeakerArr
//-------------------------------------------------------------------------------------------------------
}

//-------------------------------------------------------------------------------------------------------
// Offline Processing
//-------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------
/** Offline Task Description. */
//-------------------------------------------------------------------------------------------------------
struct VstOfflineTask
{
//-------------------------------------------------------------------------------------------------------
    char[96] processName;           ///< set by plug-in

    // audio access
    double readPosition;            ///< set by plug-in/Host
    double writePosition;           ///< set by plug-in/Host
    VstInt32 readCount;             ///< set by plug-in/Host
    VstInt32 writeCount;            ///< set by plug-in
    VstInt32 sizeInputBuffer;       ///< set by Host
    VstInt32 sizeOutputBuffer;      ///< set by Host
    void* inputBuffer;              ///< set by Host
    void* outputBuffer;             ///< set by Host
    double positionToProcessFrom;   ///< set by Host
    double numFramesToProcess;      ///< set by Host
    double maxFramesToWrite;        ///< set by plug-in

    // other data access
    void* extraBuffer;              ///< set by plug-in
    VstInt32 value;                 ///< set by Host or plug-in
    VstInt32 index;                 ///< set by Host or plug-in

    // file attributes
    double numFramesInSourceFile;   ///< set by Host
    double sourceSampleRate;        ///< set by Host or plug-in
    double destinationSampleRate;   ///< set by Host or plug-in
    VstInt32 numSourceChannels;     ///< set by Host or plug-in
    VstInt32 numDestinationChannels;///< set by Host or plug-in
    VstInt32 sourceFormat;          ///< set by Host
    VstInt32 destinationFormat;     ///< set by plug-in
    char[512] outputText;           ///< set by plug-in or Host

    // progress notification
    double progress;                ///< set by plug-in
    VstInt32 progressMode;          ///< Reserved for future use
    char[100] progressText;         ///< set by plug-in

    VstInt32 flags;                 ///< set by Host and plug-in; see enum #VstOfflineTaskFlags
    VstInt32 returnValue;           ///< Reserved for future use
    void* hostOwned;                ///< set by Host
    void* plugOwned;                ///< set by plug-in

    char[1024] future;              ///< Reserved for future use
//-------------------------------------------------------------------------------------------------------
}

//-------------------------------------------------------------------------------------------------------
/** Flags used in #VstOfflineTask. */
//-------------------------------------------------------------------------------------------------------
alias int VstOfflineTaskFlags;
enum : VstOfflineTaskFlags
{
//-------------------------------------------------------------------------------------------------------
    kVstOfflineUnvalidParameter = 1 << 0,   ///< set by Host
    kVstOfflineNewFile          = 1 << 1,   ///< set by Host

    kVstOfflinePlugError        = 1 << 10,  ///< set by plug-in
    kVstOfflineInterleavedAudio = 1 << 11,  ///< set by plug-in
    kVstOfflineTempOutputFile   = 1 << 12,  ///< set by plug-in
    kVstOfflineFloatOutputFile  = 1 << 13,  ///< set by plug-in
    kVstOfflineRandomWrite      = 1 << 14,  ///< set by plug-in
    kVstOfflineStretch          = 1 << 15,  ///< set by plug-in
    kVstOfflineNoThread         = 1 << 16   ///< set by plug-in
//-------------------------------------------------------------------------------------------------------
}

//-------------------------------------------------------------------------------------------------------
/** Option passed to #offlineRead/#offlineWrite. */
//-------------------------------------------------------------------------------------------------------
alias int VstOfflineOption;
enum : VstOfflineOption
{
//-------------------------------------------------------------------------------------------------------
   kVstOfflineAudio,        ///< reading/writing audio samples
   kVstOfflinePeaks,        ///< reading graphic representation
   kVstOfflineParameter,    ///< reading/writing parameters
   kVstOfflineMarker,       ///< reading/writing marker
   kVstOfflineCursor,       ///< reading/moving edit cursor
   kVstOfflineSelection,    ///< reading/changing selection
   kVstOfflineQueryFiles    ///< to request the Host to call asynchronously #offlineNotify
//-------------------------------------------------------------------------------------------------------
}

//-------------------------------------------------------------------------------------------------------
/** Structure passed to #offlineNotify and #offlineStart */
//-------------------------------------------------------------------------------------------------------
struct VstAudioFile
{
//-------------------------------------------------------------------------------------------------------
    VstInt32 flags;                 ///< see enum #VstAudioFileFlags
    void* hostOwned;                ///< any data private to Host
    void* plugOwned;                ///< any data private to plug-in
    char[kVstMaxFileNameLen] name;  ///< file title
    VstInt32 uniqueId;              ///< uniquely identify a file during a session
    double sampleRate;              ///< file sample rate
    VstInt32 numChannels;           ///< number of channels (1 for mono, 2 for stereo...)
    double numFrames;               ///< number of frames in the audio file
    VstInt32 format;                ///< Reserved for future use
    double editCursorPosition;      ///< -1 if no such cursor
    double selectionStart;          ///< frame index of first selected frame, or -1
    double selectionSize;           ///< number of frames in selection, or 0
    VstInt32 selectedChannelsMask;  ///< 1 bit per channel
    VstInt32 numMarkers;            ///< number of markers in the file
    VstInt32 timeRulerUnit;         ///< see doc for possible values
    double timeRulerOffset;         ///< offset in time ruler (positive or negative)
    double tempo;                   ///< as BPM (Beats Per Minute)
    VstInt32 timeSigNumerator;      ///< time signature numerator
    VstInt32 timeSigDenominator;    ///< time signature denominator
    VstInt32 ticksPerBlackNote;     ///< resolution
    VstInt32 smpteFrameRate;        ///< SMPTE rate (set as in #VstTimeInfo)

    char[64] future;                ///< Reserved for future use
//-------------------------------------------------------------------------------------------------------
}

//-------------------------------------------------------------------------------------------------------
/** Flags used in #VstAudioFile. */
//-------------------------------------------------------------------------------------------------------
alias int VstAudioFileFlags;
enum : VstAudioFileFlags
{
//-------------------------------------------------------------------------------------------------------
    kVstOfflineReadOnly             = 1 << 0,   ///< set by Host (in call #offlineNotify)
    kVstOfflineNoRateConversion     = 1 << 1,   ///< set by Host (in call #offlineNotify)
    kVstOfflineNoChannelChange      = 1 << 2,   ///< set by Host (in call #offlineNotify)

    kVstOfflineCanProcessSelection  = 1 << 10,  ///< set by plug-in (in call #offlineStart)
    kVstOfflineNoCrossfade          = 1 << 11,  ///< set by plug-in (in call #offlineStart)
    kVstOfflineWantRead             = 1 << 12,  ///< set by plug-in (in call #offlineStart)
    kVstOfflineWantWrite            = 1 << 13,  ///< set by plug-in (in call #offlineStart)
    kVstOfflineWantWriteMarker      = 1 << 14,  ///< set by plug-in (in call #offlineStart)
    kVstOfflineWantMoveCursor       = 1 << 15,  ///< set by plug-in (in call #offlineStart)
    kVstOfflineWantSelect           = 1 << 16   ///< set by plug-in (in call #offlineStart)
//-------------------------------------------------------------------------------------------------------
}

//-------------------------------------------------------------------------------------------------------
/** Audio file marker. */
//-------------------------------------------------------------------------------------------------------
struct VstAudioFileMarker
{
//-------------------------------------------------------------------------------------------------------
    double position;        ///< marker position
    char[32] name;          ///< marker name
    VstInt32 type;          ///< marker type
    VstInt32 id;            ///< marker identifier
    VstInt32 reserved;      ///< reserved for future use
//-------------------------------------------------------------------------------------------------------
}

//-------------------------------------------------------------------------------------------------------
// Others
//-------------------------------------------------------------------------------------------------------

//-------------------------------------------------------------------------------------------------------
/** \deprecated Structure used for #openWindow and #closeWindow (deprecated in VST 2.4). */
//-------------------------------------------------------------------------------------------------------
struct DEPRECATED_VstWindow
{
//-------------------------------------------------------------------------------------------------------
    char[128] title;
    VstInt16 xPos;
    VstInt16 yPos;
    VstInt16 width;
    VstInt16 height;
    VstInt32 style;
    void* parent;
    void* userHandle;
    void* winHandle;

    char[104] future;
//-------------------------------------------------------------------------------------------------------
}

//-------------------------------------------------------------------------------------------------------
/** Structure used for keyUp/keyDown. */
//-------------------------------------------------------------------------------------------------------
struct VstKeyCode
{
//-------------------------------------------------------------------------------------------------------
    VstInt32 character;     ///< ASCII character
    ubyte virt;     ///< @see VstVirtualKey
    ubyte modifier; ///< @see VstModifierKey
//-------------------------------------------------------------------------------------------------------
}

//-------------------------------------------------------------------------------------------------------
/** Platform-independent definition of Virtual Keys (used in #VstKeyCode). */
//-------------------------------------------------------------------------------------------------------
alias int VstVirtualKey;
enum : VstVirtualKey
{
//-------------------------------------------------------------------------------------------------------
    VKEY_BACK = 1,
    VKEY_TAB,
    VKEY_CLEAR,
    VKEY_RETURN,
    VKEY_PAUSE,
    VKEY_ESCAPE,
    VKEY_SPACE,
    VKEY_NEXT,
    VKEY_END,
    VKEY_HOME,
    VKEY_LEFT,
    VKEY_UP,
    VKEY_RIGHT,
    VKEY_DOWN,
    VKEY_PAGEUP,
    VKEY_PAGEDOWN,
    VKEY_SELECT,
    VKEY_PRINT,
    VKEY_ENTER,
    VKEY_SNAPSHOT,
    VKEY_INSERT,
    VKEY_DELETE,
    VKEY_HELP,
    VKEY_NUMPAD0,
    VKEY_NUMPAD1,
    VKEY_NUMPAD2,
    VKEY_NUMPAD3,
    VKEY_NUMPAD4,
    VKEY_NUMPAD5,
    VKEY_NUMPAD6,
    VKEY_NUMPAD7,
    VKEY_NUMPAD8,
    VKEY_NUMPAD9,
    VKEY_MULTIPLY,
    VKEY_ADD,
    VKEY_SEPARATOR,
    VKEY_SUBTRACT,
    VKEY_DECIMAL,
    VKEY_DIVIDE,
    VKEY_F1,
    VKEY_F2,
    VKEY_F3,
    VKEY_F4,
    VKEY_F5,
    VKEY_F6,
    VKEY_F7,
    VKEY_F8,
    VKEY_F9,
    VKEY_F10,
    VKEY_F11,
    VKEY_F12,
    VKEY_NUMLOCK,
    VKEY_SCROLL,
    VKEY_SHIFT,
    VKEY_CONTROL,
    VKEY_ALT,
    VKEY_EQUALS
//-------------------------------------------------------------------------------------------------------
}

//-------------------------------------------------------------------------------------------------------
/** Modifier flags used in #VstKeyCode. */
//-------------------------------------------------------------------------------------------------------
alias int VstModifierKey;
enum : VstModifierKey
{
//-------------------------------------------------------------------------------------------------------
    MODIFIER_SHIFT     = 1<<0, ///< Shift
    MODIFIER_ALTERNATE = 1<<1, ///< Alt
    MODIFIER_COMMAND   = 1<<2, ///< Control on Mac
    MODIFIER_CONTROL   = 1<<3  ///< Ctrl on PC, Apple on Mac
//-------------------------------------------------------------------------------------------------------
}

//-------------------------------------------------------------------------------------------------------
/** File filter used in #VstFileSelect. */
//-------------------------------------------------------------------------------------------------------
struct VstFileType
{
//-------------------------------------------------------------------------------------------------------
    char[128] name;             ///< display name
    char[8] macType;            ///< MacOS type
    char[8] dosType;            ///< Windows file extension
    char[8] unixType;           ///< Unix file extension
    char[128] mimeType1;        ///< MIME type
    char[128] mimeType2;        ///< additional MIME type

    this(const char* _name, const char* _macType, const char* _dosType,
         const char* _unixType, const char* _mimeType1, const char* _mimeType2)
    {
        vst_strncpy (name.ptr, _name ? _name : "", 127);
        vst_strncpy (macType.ptr, _macType ? _macType : "", 7);
        vst_strncpy (dosType.ptr, _dosType ? _dosType : "", 7);
        vst_strncpy (unixType.ptr, _unixType ? _unixType : "", 7);
        vst_strncpy (mimeType1.ptr, _mimeType1 ? _mimeType1 : "", 127);
        vst_strncpy (mimeType2.ptr, _mimeType2 ? _mimeType2 : "", 127);
    }
//-------------------------------------------------------------------------------------------------------
}

//-------------------------------------------------------------------------------------------------------
/** File Selector Description used in #audioMasterOpenFileSelector. */
//-------------------------------------------------------------------------------------------------------
struct VstFileSelect
{
//-------------------------------------------------------------------------------------------------------
    VstInt32 command;           ///< @see VstFileSelectCommand
    VstInt32 type;              ///< @see VstFileSelectType
    VstInt32 macCreator;        ///< optional: 0 = no creator
    VstInt32 nbFileTypes;       ///< number of fileTypes
    VstFileType* fileTypes;     ///< list of fileTypes  @see VstFileType
    char[1024] title;           ///< text to display in file selector's title
    char* initialPath;          ///< initial path
    char* returnPath;           ///< use with #kVstFileLoad and #kVstDirectorySelect. null: Host allocates memory, plug-in must call #closeOpenFileSelector!
    VstInt32 sizeReturnPath;    ///< size of allocated memory for return paths
    char** returnMultiplePaths; ///< use with kVstMultipleFilesLoad. Host allocates memory, plug-in must call #closeOpenFileSelector!
    VstInt32 nbReturnPath;      ///< number of selected paths
    VstIntPtr reserved;         ///< reserved for Host application

    char[116] future;           ///< reserved for future use
//-------------------------------------------------------------------------------------------------------
}

//-------------------------------------------------------------------------------------------------------
/** Command constants used in #VstFileSelect structure. */
//-------------------------------------------------------------------------------------------------------
alias int VstFileSelectCommand;
enum : VstFileSelectCommand
{
//-------------------------------------------------------------------------------------------------------
    kVstFileLoad = 0,       ///< for loading a file
    kVstFileSave,           ///< for saving a file
    kVstMultipleFilesLoad,  ///< for loading multiple files
    kVstDirectorySelect     ///< for selecting a directory/folder
//-------------------------------------------------------------------------------------------------------
}

//-------------------------------------------------------------------------------------------------------
/** Types used in #VstFileSelect structure. */
//-------------------------------------------------------------------------------------------------------
alias int VstFileSelectType;
enum : VstFileSelectType
{
//-------------------------------------------------------------------------------------------------------
    kVstFileType = 0        ///< regular file selector
//-------------------------------------------------------------------------------------------------------
}

//-------------------------------------------------------------------------------------------------------
/** Structure used for #effBeginLoadBank/#effBeginLoadProgram. */
//-------------------------------------------------------------------------------------------------------
struct VstPatchChunkInfo
{
//-------------------------------------------------------------------------------------------------------
    VstInt32 version_;           ///< Format Version (should be 1)
    VstInt32 pluginUniqueID;    ///< UniqueID of the plug-in
    VstInt32 pluginVersion;     ///< Plug-in Version
    VstInt32 numElements;       ///< Number of Programs (Bank) or Parameters (Program)

    char[48] future;            ///< Reserved for future use
//-------------------------------------------------------------------------------------------------------
}

//-------------------------------------------------------------------------------------------------------
/** PanLaw Type. */
//-------------------------------------------------------------------------------------------------------
alias int VstPanLawType;
enum : VstPanLawType
{
//-------------------------------------------------------------------------------------------------------
    kLinearPanLaw = 0,  ///< L = pan * M; R = (1 - pan) * M;
    kEqualPowerPanLaw   ///< L = pow (pan, 0.5) * M; R = pow ((1 - pan), 0.5) * M;
//-------------------------------------------------------------------------------------------------------
}

//-------------------------------------------------------------------------------------------------------
/** Process Levels returned by #audioMasterGetCurrentProcessLevel. */
//-------------------------------------------------------------------------------------------------------
alias int VstProcessLevels;
enum : VstProcessLevels
{
//-------------------------------------------------------------------------------------------------------
    kVstProcessLevelUnknown = 0,    ///< not supported by Host
    kVstProcessLevelUser,           ///< 1: currently in user thread (GUI)
    kVstProcessLevelRealtime,       ///< 2: currently in audio thread (where process is called)
    kVstProcessLevelPrefetch,       ///< 3: currently in 'sequencer' thread (MIDI, timer etc)
    kVstProcessLevelOffline         ///< 4: currently offline processing and thus in user thread
//-------------------------------------------------------------------------------------------------------
}

//-------------------------------------------------------------------------------------------------------
/** Automation States returned by #audioMasterGetAutomationState. */
//-------------------------------------------------------------------------------------------------------
alias int VstAutomationStates;
enum : VstAutomationStates
{
//-------------------------------------------------------------------------------------------------------
    kVstAutomationUnsupported = 0,  ///< not supported by Host
    kVstAutomationOff,              ///< off
    kVstAutomationRead,             ///< read
    kVstAutomationWrite,            ///< write
    kVstAutomationReadWrite         ///< read and write
//-------------------------------------------------------------------------------------------------------
}
