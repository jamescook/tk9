# itcl Extension - Deprecated

**Status:** Removed from Ruby Tk bindings (January 2025)

## Reason

From [Terma TGSS](https://tgss.terma.com/tcl-packages-itcl-itk-and-iwidgets-are-deprecated/):

> "These packages (Itcl, Itk, and Iwidgets) are not thread-safe and have seen little development over the last decade. Existing code should gradually migrate away from them."

[incr Tcl] (itcl) was an object-oriented extension for Tcl that has been superseded by TclOO, which is built into Tcl 8.6+.

## Alternatives

- **Object-oriented Tcl:** TclOO (built into Tcl 8.6+)
- **Ruby side:** Use Ruby's native OOP instead of Tcl-level OOP
