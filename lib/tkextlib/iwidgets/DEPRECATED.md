# iwidgets Extension - Deprecated

**Status:** Removed from Ruby Tk bindings (January 2025)

## Reason

From [Terma TGSS](https://tgss.terma.com/tcl-packages-itcl-itk-and-iwidgets-are-deprecated/):

> "These packages (Itcl, Itk, and Iwidgets) are not thread-safe and have seen little development over the last decade. Existing code should gradually migrate away from them."

From the [Tcl Wiki](https://wiki.tcl-lang.org/page/Iwidgets):

> "For object-oriented programming, Itcl can be replaced with TclOO, which is better maintained and thread-safe. For GUI widgets, Iwidgets can be replaced with tk/ttk."

## Alternatives

- **GUI widgets:** Use ttk (Tk themed widgets) - already supported in Ruby Tk
- **Object-oriented programming:** TclOO (if needed at Tcl level)

## If You Need iwidgets

The Ruby bindings have been removed. If you must use iwidgets:
1. Use `Tk.tk_call` directly to interact with iwidgets commands
2. Consider migrating to ttk widgets instead
