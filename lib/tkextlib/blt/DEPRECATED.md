# BLT Extension - Deprecated

**Status:** Removed from Ruby Tk bindings (January 2025)

## Reason

From the [Tcl Wiki](https://wiki.tcl-lang.org/page/BLT):

> "As of 2016, BLT the official version is 2.4z, which is not compatible with Tk 8.5 or 8.6."

The original BLT project has been unmaintained since 2016 and is incompatible with modern Tcl/Tk versions (8.5+). While community forks exist ([apnadkarni/blt](https://github.com/apnadkarni/blt), [TkBLT](https://github.com/wjoye/tkblt)), they have different APIs and levels of completeness.

## Alternatives

- **Graphing:** TkBLT fork includes Graph and Barchart widgets
- **Vectors:** Consider native Ruby arrays or specialized gems
- **General widgets:** ttk provides modern replacements

## If You Need BLT

If you have a working BLT installation with one of the forks, the Ruby bindings have been removed. You would need to:
1. Use `Tk.tk_call` directly to interact with BLT commands
2. Or create custom Ruby wrappers for the specific BLT features you need
