# tkHTML Extension - Deprecated

**Status:** Removed from Ruby Tk bindings (January 2025)

## Reason

From the [Tcl Wiki](https://wiki.tcl-lang.org/page/tkhtml3):

> "Tkhtml is a discontinued open-source browser engine written in C using the Tk widget toolkit."

The original tkhtml3 project is discontinued. While derivative projects like TkinterWeb exist for Python, the original Tcl/Tk widget is no longer maintained.

## Alternatives

- **TkinterWeb** (Python only): Bindings to a modified tkhtml3
- **Web content:** Consider external browser integration or simpler markup rendering

## If You Need tkHTML

The Ruby bindings have been removed. If you must use tkHTML:
1. Use `Tk.tk_call` directly to interact with tkHTML commands
2. Consider whether your use case can be addressed with simpler widgets
