# itk Extension - Deprecated

**Status:** Removed from Ruby Tk bindings (January 2025)

## Reason

From [Terma TGSS](https://tgss.terma.com/tcl-packages-itcl-itk-and-iwidgets-are-deprecated/):

> "These packages (Itcl, Itk, and Iwidgets) are not thread-safe and have seen little development over the last decade. Existing code should gradually migrate away from them."

[incr Tk] (itk) was a mega-widget framework built on itcl. Both have been superseded by TclOO and ttk.

## Alternatives

- **Mega-widgets:** Use ttk (Tk themed widgets)
- **Object-oriented Tk:** TclOO + ttk
