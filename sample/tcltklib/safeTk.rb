#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Safe Interpreter Tk Loading - NOT SUPPORTED
#
# This sample demonstrated loading Tk into a safe (sandboxed) interpreter
# using ::safe::loadTk. However, this functionality is not available with
# stub-enabled Tcl/Tk builds.
#
# From the Tcl documentation:
#
#   "Tcl_StaticLibrary can not be used in stub-enabled extensions.
#    Its symbol entry in the stub table is deprecated and it will
#    be removed in Tcl 9.0."
#
# See: https://www.tcl-lang.org/man/tcl8.7/TclLib/StaticLibrary.html
#
# The ::safe::loadTk command requires Tk to be registered via
# Tcl_StaticLibrary, which is incompatible with stub-enabled builds.
# Since Ruby/Tk uses stubs for version flexibility, safe interpreter
# Tk loading cannot be supported.

warn <<~MESSAGE
  safeTk.rb: Safe interpreter Tk loading is not supported.

  This sample requires Tcl_StaticLibrary which cannot be used with
  stub-enabled extensions (like Ruby/Tk). This limitation is documented
  and the function is deprecated - it will be removed in Tcl 9.0.

  See: https://www.tcl-lang.org/man/tcl8.7/TclLib/StaticLibrary.html
MESSAGE
