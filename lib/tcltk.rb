# frozen_string_literal: true

# tcltk.rb - Legacy low-level Tcl/Tk API (REMOVED)
#
# This file previously contained a direct, low-level wrapper around tcltklib
# dating from 1997. It has been removed as it was unmaintained and duplicated
# functionality provided by the modern tk.rb API.
#
# Migration: Use 'require "tk"' instead of 'require "tcltk"'
#
# The modern API provides:
#   - TkRoot, TkLabel, TkButton, etc. for widgets
#   - Tk.mainloop for the event loop
#   - Block-based callbacks instead of manual TclTkCallback management
#
# Example:
#   require 'tk'
#   root = TkRoot.new { title "Hello" }
#   TkLabel.new(root) { text "Hello, World!" }.pack
#   Tk.mainloop

warn "tcltk.rb is deprecated and has been removed. Use 'require \"tk\"' instead.", uplevel: 1
