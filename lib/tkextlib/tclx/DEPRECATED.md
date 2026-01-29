# TclX Extension - Deprecated

**Status:** Removed from Ruby Tk bindings (January 2025)

## Reason

TclX (Extended Tcl) is a compiled C extension that provides POSIX system APIs to Tcl. The Ruby wrapper only provided partial support for:
- `infox` command (system info)
- `signal` command (with warnings to use Ruby's `Signal.trap` instead)
- XPG/3 message catalogs

For Ruby applications:
- **Signals:** Use Ruby's `Signal.trap` - mixing Tcl and Ruby signal handling causes conflicts
- **System info:** Use Ruby's built-in facilities (`RUBY_PLATFORM`, `RbConfig`, etc.)
- **Message catalogs:** Use Ruby i18n gems

The extension has seen minimal usage and requires compilation, adding complexity for little benefit.

## TclX Forks (if needed)

- FlightAware: https://github.com/flightaware/tclx (v8.6.3, Jan 2024)
- Community: https://github.com/tcltk-depot/tclx (Tcl 9 work in progress)

## If You Need TclX

The Ruby bindings have been removed. If you must use TclX:
1. Install TclX from one of the forks above
2. Use `Tk.tk_call` directly to interact with TclX commands
