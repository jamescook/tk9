# tktable Extension - REMOVED

**Status:** Removed (January 2026)

## Reason for Removal

The tktable (TkTable) extension has been removed from this project because:

1. **Abandoned upstream** - Version 2.10 released in 2008 (16+ years ago)
2. **No package manager support** - Not available in Homebrew or standard package managers
3. **Untestable** - Cannot be easily installed for CI testing
4. **Superseded** - Modern approaches use ttk::treeview or custom canvas-based solutions

## Alternative

For tabular data display, consider:
- `Tk::Tile::Treeview` (ttk::treeview) - Built into Tk 8.5+, supports columns
- Canvas-based table implementations
- BWidget's tablelist (if using BWidget)

## Historical Reference

The original code wrapped the TkTable widget from:
- Project: http://tktable.sourceforge.net/
- Last release: 2.10 (2008)

If you need this functionality, consider using ttk::treeview or maintaining your own fork of the tktable bindings.
