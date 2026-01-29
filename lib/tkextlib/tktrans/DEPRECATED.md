# TkTrans Extension - Deprecated

**Status:** Removed from Ruby Tk bindings (January 2025)

## Reason

TkTrans was a Windows-only extension for window transparency using color masks. It has been obsolete since Tk 8.4.16 introduced built-in transparency support.

From the [Tcl Wiki](https://wiki.tcl-lang.org/page/tktrans):

> "wm attributes $win -transparentcolor $rgb since 8.4.16 should supersede TkTrans"

The extension was last updated in 2010 and has known compatibility issues with `wm attributes -alpha`.

## Alternatives

Use Tk's built-in window manager attributes:

```ruby
# Set window transparency (0.0 = fully transparent, 1.0 = opaque)
root.wm_attributes(:alpha, 0.8)

# Make a specific color transparent (Windows only)
root.wm_attributes(:transparentcolor, 'magenta')
```

## If You Need TkTrans

The Ruby bindings have been removed. The built-in `wm attributes` should cover all use cases. If you must use TkTrans:
1. Install the tktrans Tcl package separately
2. Use `Tk.tk_call` directly to interact with tktrans commands
