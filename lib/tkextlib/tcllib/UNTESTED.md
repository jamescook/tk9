# tcllib/tklib Extension - Untested

**Status:** Untested and excluded from coverage (January 2026)

## Reason

These Ruby wrappers for Tcl's tklib widgets cannot be properly tested:

1. **tklib not in Homebrew** - No easy local installation on macOS
2. **Known bugs** - Some wrappers have issues (e.g., `WidgetClassNames` not accessible in modules that `extend TkCore`)

## Widgets Affected

All widgets in this directory: tooltip, tablelist, ctext, plotchart, calendar, etc.
