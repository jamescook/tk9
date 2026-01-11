# frozen_string_literal: true

# Test for TkNamespace and TkNamespace::Ensemble.
# Runs in a single subprocess to minimize overhead.
#
# Note: Ensemble is NOT a widget - it wraps Tcl's "namespace ensemble" command.
# See: https://www.tcl-lang.org/man/tcl8.6/TclCmd/namespace.htm#M28

require_relative 'test_helper'
require_relative 'tk_test_helper'

class TestNamespace < Minitest::Test
  include TkTestHelper

  def test_namespace_ensemble
    assert_tk_app("Namespace Ensemble test", method(:namespace_app))
  end

  def namespace_app
    require 'tk'
    require 'tk/namespace'

    errors = []

    # --- Create ensemble with explicit command name ---
    # (without -command, it tries to create for :: which fails)
    ensemble = TkNamespace::Ensemble.new(command: "testensemble")

    errors << "ensemble should have path" unless ensemble.path
    errors << "path should be ::testensemble" unless ensemble.path == "::testensemble"

    # --- Test prefixes option (boolean) ---
    ensemble.configure(prefixes: true)
    errors << "prefixes true failed" unless ensemble.cget(:prefixes) == true

    ensemble.configure(prefixes: false)
    errors << "prefixes false failed" unless ensemble.cget(:prefixes) == false

    # --- Test subcommands option (list) ---
    ensemble.configure(subcommands: ["cmd1", "cmd2"])
    subcmds = ensemble.cget(:subcommands)
    errors << "subcommands should be array" unless subcmds.is_a?(Array)
    errors << "subcommands count wrong" unless subcmds.size == 2

    # --- Ensemble.exist? ---
    errors << "exist? should return true" unless TkNamespace::Ensemble.exist?(ensemble.path)
    errors << "exists? should return true" unless ensemble.exists?

    raise "Namespace test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
