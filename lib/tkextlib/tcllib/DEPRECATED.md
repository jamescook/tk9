# tcllib/tklib Extension - Removed

**Status:** Removed (January 2026)

## Reason

The Ruby wrappers for Tcl's tklib widgets have been removed:

1. **Cannot be installed** - tklib is not in Homebrew and the official installer is broken with Tcl 9
2. **Broken code** - The wrappers relied on `__*_optkeys` methods that were removed during the config system cleanup
3. **Known bugs** - Some wrappers had issues (e.g., `WidgetClassNames` not accessible in modules that `extend TkCore`)
4. **No tests** - Could never be tested, so breakage went undetected

## Widgets Removed

All widgets from this directory: tooltip, tablelist, ctext, plotchart, calendar, autoscroll, cursor, datefield, getstring, history, ico, ip_entry, khim, ntext, ruler, screenruler, scrollwin, statusbar, style, swaplist, tkpiechart, toolbar, validator, widget, etc.

## Alternative

If you need tklib widgets, consider:
- Using Tcl/Tk directly via `TkCore::INTERP._eval()`
- Contributing fixes upstream to tklib to support modern Tcl 9
