# frozen_string_literal: true

# Test for Tk::BWidget::DropSite module.
# DropSite provides drag-and-drop target functionality.
# Note: Actual DnD operations require user interaction.
#
# See: https://core.tcl-lang.org/bwidget/doc/bwidget/BWman/DropSite.html

require_relative '../../../../test/test_helper'
require_relative '../../../../test/tk_test_helper'

class TestBWidgetDropSite < Minitest::Test
  include TkTestHelper

  def test_dropsite_comprehensive
    assert_tk_app("BWidget DropSite test", method(:dropsite_app))
  end

  def dropsite_app
    require 'tk'
    require 'tkextlib/bwidget'
    require 'tkextlib/bwidget/dropsite'

    errors = []

    # --- Create a widget to register as drop target ---
    label = TkLabel.new(root, text: "Drop here")
    label.pack

    # --- Register as drop target ---
    Tk::BWidget::DropSite.register(
      label,
      droptypes: ['TEXT'],
      dropcmd: proc { |data| puts "Dropped: #{data}" }
    )

    # --- Module should exist ---
    errors << "DropSite module not defined" unless defined?(Tk::BWidget::DropSite)

    raise "BWidget DropSite test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
