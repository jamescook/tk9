# frozen_string_literal: true

# Test for Tk::BWidget::PasswdDlg widget options.
# Note: create() blocks waiting for user input, so we only test configuration.
#
# See: https://core.tcl-lang.org/bwidget/doc/bwidget/BWman/PasswdDlg.html

require_relative '../../../../test/test_helper'
require_relative '../../../../test/tk_test_helper'

class TestBWidgetPasswdDlg < Minitest::Test
  include TkTestHelper

  def test_passwddlg_comprehensive
    assert_tk_app("BWidget PasswdDlg test", method(:passwddlg_app))
  end

  def passwddlg_app
    require 'tk'
    require 'tkextlib/bwidget'
    require 'tkextlib/bwidget/passwddlg'

    errors = []

    # --- Create PasswdDlg with options (don't call create - it blocks) ---
    login_var = TkVariable.new("default_user")
    passwd_var = TkVariable.new("")

    dlg = Tk::BWidget::PasswdDlg.new(
      root,
      title: "Login",
      logintextvariable: login_var,
      passwdtextvariable: passwd_var
    )

    # --- Verify it's a PasswdDlg instance (subclass of MessageDlg) ---
    errors << "not a PasswdDlg" unless dlg.is_a?(Tk::BWidget::PasswdDlg)
    errors << "not a MessageDlg subclass" unless dlg.is_a?(Tk::BWidget::MessageDlg)

    # --- Test cget ---
    title = dlg.cget(:title)
    errors << "cget title failed: #{title.inspect}" unless title == "Login"

    # --- Test configure ---
    dlg.configure(title: "Authentication")
    title = dlg.cget(:title)
    errors << "configure title failed: #{title.inspect}" unless title == "Authentication"

    raise "BWidget PasswdDlg test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
