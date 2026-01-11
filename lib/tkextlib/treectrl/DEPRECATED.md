# treectrl Extension - REMOVED

**Status:** Removed (January 2026)

## Reason for Removal

The treectrl (TkTreeCtrl) extension has been removed from this project because:

1. **Abandoned upstream** - Last release was version 2.4.1 in August 2011 (13+ years ago)
2. **No package manager support** - Not available in Homebrew or standard package managers
3. **Untestable** - Cannot be easily installed for CI testing
4. **Superseded** - Modern Tk has ttk::treeview which covers most tree widget use cases

## Alternative

Use `Tk::Tile::Treeview` (ttk::treeview) instead, which is built into Tk 8.5+ and fully supported.

## Historical Reference

The original code wrapped the TkTreeCtrl widget from:
- Project: http://tktreectrl.sourceforge.net/
- Last release: 2.4.1 (August 2011)

If you need this functionality, consider using the ttk::treeview widget or maintaining your own fork of the treectrl bindings.
