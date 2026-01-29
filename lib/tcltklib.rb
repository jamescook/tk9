# frozen_string_literal: true
#
# tcltklib.rb - Load C extension and compatibility layer
#
# This ensures both the native extension and Ruby compatibility
# shims are loaded together.

require "tcltklib.so"       # Load the C extension
require_relative "tcltk_compat"  # Load compatibility layer
