# Jarvis Voice - Features & Enhancement TODO List
# File: FEATURES_TODO.md
# Purpose: Track planned features for future implementation
# Note: Ask user which feature to implement before making changes

## Feature Implementation Priority Queue

### Feature 1: 3-Minute Recording Limit with FIFO Buffer
**Status:** PLANNED (Not Implemented)
**Priority:** HIGH
**User Requested:** Yes (Feb 9, 2026)

#### Description
Implement a maximum 3-minute recording limit with automatic FIFO (First-In-First-Out) buffer management.

#### Requirements
- Maximum recording duration: 3 minutes (180 seconds)
- FIFO buffer: Keep only last 3 minutes of audio
- If user records 5 minutes → process only minutes 2-5 (last 3 minutes)
- Audio older than 3 minutes gets automatically discarded

#### Implementation Details
**Files to Modify:**
- `src/main.py` - AudioRecorder class
- `whisper_cpp_wrapper.py` - Process only last 3 minutes

**Technical Approach:**
1. Track total recording duration
2. Maintain rolling buffer of last 180 seconds
3. When stopping recording:
   - Calculate total duration
   - If > 180s: trim from beginning
   - Process only last 180 seconds

**Memory Calculation:**
- 3 minutes @ 16kHz = ~5.4MB in RAM
- WAV file ~110MB (conservative estimate)
- Total memory: ~120MB (acceptable)

#### User Benefits
- Prevents memory issues
- Keeps UI responsive
- Sensible limit for voice dictation use case
- Fair processing time (~30-45 seconds for 3 min audio)

---

### Feature 2: Audio Notifications Instead of Visual Cues
**Status:** PLANNED (Not Implemented)
**Priority:** HIGH
**User Requested:** Yes (Feb 9, 2026)

#### Description
Replace visual floating window with audio notifications to prevent focus shift when working in full-screen applications.

#### Requirements
- Remove floating window (red pill) completely
- Add sound notification when recording starts (Right Option key pressed)
- Add sound notification when recording stops (Right Option key released)
- Menu option to select/customize start recording sound
- Menu option to select/customize stop recording sound
- Focus remains on user's typing location (no UI elements steal focus)
- Default system sounds for notifications

#### Implementation Details
**Files to Modify:**
- `src/main.py` - Remove FloatingWindow class, add audio playback
- `whisper_cpp_wrapper.py` - No changes needed
- Config files for sound preferences

**Technical Approach:**
1. Remove FloatingWindow class and all related code
2. Remove PyQt6 dependency for floating window
3. Import AVFoundation (NSSound) for macOS audio playback
4. Add menu items for sound selection
5. Store sound preferences in config.json
6. Play sounds in _start_recording() and _stop_recording()

**Audio Options:**
- System default sounds (Glass, Hero, Sosumi, etc.)
- Custom sound files (.wav, .mp3, .aiff)
- Menu: "Recording Sound" → submenu with options
- Menu: "Stop Recording Sound" → submenu with options

#### User Benefits
- No focus shift from typing location
- Works perfectly in full-screen applications
- Audio feedback is less distracting than visual popup
- Customizable sounds for personal preference
- Better for accessibility (users with visual impairments)

---

### Feature 3: Fix Menu Quit Functionality
**Status:** PLANNED (Not Implemented)
**Priority:** HIGH
**User Requested:** Yes (Feb 9, 2026)

#### Description
Fix the bug where selecting "Quit" from the menu bar does not work, while right-clicking the Python dock icon and selecting "Quit" does work.

#### Current Behavior
- ✅ Right-click Python in dock → Quit → **Works**
- ❌ Menu bar → Quit → **Does NOT work**

#### Requirements
- Fix menu bar "Quit" functionality to properly quit the application
- Ensure all resources are cleaned up (hotkey listener, Qt app, rumps)
- Maintain working dock quit functionality
- Clean shutdown without errors

#### Implementation Details
**Files to Modify:**
- `src/main.py` - _quit_app() method

**Technical Approach:**
1. Debug why menu quit doesn't trigger properly
2. Check rumps.App quit callback
3. Ensure proper cleanup sequence:
   - Stop hotkey listener
   - Quit Qt application
   - Allow rumps to exit
4. May need to override quit behavior in rumps

**Possible Causes:**
- rumps quit_button=None setting
- _quit_app() return value
- Signal handling
- Event loop issues

#### User Benefits
- Consistent quit behavior across all methods
- Proper application cleanup
- Better user experience

---

## Template for Future Features

### Feature #: [Feature Name]
**Status:** PLANNED (Not Implemented)
**Priority:** [LOW/MEDIUM/HIGH]
**User Requested:** [Yes/No - Date]

#### Description
[Detailed description of the feature]

#### Requirements
- [List specific requirements]

#### Implementation Details
**Files to Modify:**
- [List files]

**Technical Approach:**
1. [Step 1]
2. [Step 2]

#### User Benefits
[Explain why this feature is valuable]

---

## Instructions for Implementation

### Before Implementing ANY Feature:
1. Ask user: "Which feature would you like me to implement?"
2. User will specify feature number or name
3. Review this file together
4. Confirm implementation approach
5. Only then make code changes

### After Implementation:
1. Update feature status to "IMPLEMENTED"
2. Add implementation date
3. Add any notes or limitations discovered
4. Commit changes with clear message

---

## Version History

### Current Version: 3.0
**Release Date:** Feb 9, 2026
**Features Included:**
- Self-contained DMG installer
- whisper.cpp with Metal GPU acceleration
- Custom app icon
- 3-4x faster than Python implementation
- Real-time transcription (1.75s for 11s audio)

### Planned for Next Version (3.1):
- Feature 1: 3-minute recording limit with FIFO
- Feature 2: Audio notifications instead of visual cues
- Feature 3: Fix menu quit functionality

---

## Notes
- All features require explicit user confirmation before implementation
- Maintain backwards compatibility when possible
- Test on Apple Silicon before release
- Update README.md with new features
- Update release notes for each version

**Last Updated:** Feb 9, 2026
**Next Review:** When user requests feature implementation
