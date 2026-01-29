# vu Extension - Deprecated

**Status:** Removed from Ruby Tk bindings (January 2025)

## Reason

The vu widget set (dial, pie, bargraph, spinbox, stripchart) is a legacy extension that has been superseded by modern Tk themed widgets (ttk).

From the [Tcl Wiki](https://wiki.tcl-lang.org/page/Extensions+for+Tcl+and+Tk):

The vu extension was part of older Tk widget collections but has not seen active development in many years.

## Alternatives

- **Progressbar:** Use `Tk::Tile::TProgressbar` (ttk::progressbar)
- **Spinbox:** Use `Tk::Tile::TSpinbox` (ttk::spinbox)
- **Charts/Graphs:** Consider external charting libraries or canvas-based solutions
- **Dial/Meter:** Custom canvas widgets or third-party solutions

## If You Need vu Widgets

The Ruby bindings have been removed. If you must use vu widgets:
1. Install the vu Tcl package separately
2. Use `Tk.tk_call` directly to interact with vu commands
