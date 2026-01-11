# ICONS Extension - REMOVED

**Status:** Removed (January 2026)

## Reason for Removal

The ICONS extension has been removed from this project because:

1. **Abandoned upstream** - Last updated July 2013 (12+ years ago)
2. **No package manager support** - Not available in apt, Homebrew, or standard package managers
3. **Niche use case** - Designed primarily for GRIDPLUS (another SATiSOFT package)
4. **Untestable** - Cannot be easily installed for CI testing

## Historical Reference

The original code wrapped the ICONS package from:
- Project: http://www.satisoft.com/tcltk/icons/
- Author: Adrian Davis (SATiSOFT)
- Last version: 2.0 (July 2013)
- Purpose: Cross-platform icon/image library support for Tcl/Tk

## Alternative

For icon support in modern Tk applications:
- Use `TkPhotoImage` with PNG/GIF files directly
- Use TkImg extension for additional format support
- Bundle icons as assets in your application
