# frozen_string_literal: true

# Test for Tk::BWidget::ProgressDlg widget options.

require_relative '../../../../test/test_helper'
require_relative '../../../../test/tk_test_helper'

class TestBWidgetProgressDlg < Minitest::Test
  include TkTestHelper

  def test_progressdlg_comprehensive
    assert_tk_app("BWidget ProgressDlg test", method(:progressdlg_app))
  end

  def progressdlg_app
    require 'tk'
    require 'tkextlib/bwidget'

    errors = []

    # --- Create progress dialog (don't show it) ---
    pd = Tk::BWidget::ProgressDlg.new(root, title: "Progress", maximum: 100)

    # --- Test textvariable ---
    tv = pd.textvariable
    errors << "textvariable failed" if tv.nil?

    # --- Test text getter/setter ---
    pd.text = "Processing..."
    errors << "text setter failed" unless pd.text == "Processing..."

    # --- Test variable ---
    v = pd.variable
    errors << "variable failed" if v.nil?

    # --- Test value getter/setter ---
    pd.value = 50
    errors << "value setter failed" unless pd.value.to_i == 50

    raise "BWidget ProgressDlg test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
