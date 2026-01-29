# frozen_string_literal: true

# Test for Tk::BWidget::ButtonBox widget options.
#
# See: https://core.tcl-lang.org/bwidget/doc/bwidget/BWman/ButtonBox.html

require_relative '../../../../test/test_helper'
require_relative '../../../../test/tk_test_helper'

class TestBWidgetButtonBox < Minitest::Test
  include TkTestHelper

  def test_buttonbox_comprehensive
    assert_tk_app("BWidget ButtonBox test", method(:buttonbox_app))
  end

  def buttonbox_app
    require 'tk'
    require 'tkextlib/bwidget'

    errors = []

    # --- Basic buttonbox ---
    bbox = Tk::BWidget::ButtonBox.new(root)
    bbox.pack(fill: 'x')

    # --- Add buttons ---
    btn1 = bbox.add(text: 'OK', name: 'ok')
    btn2 = bbox.add(text: 'Cancel', name: 'cancel')
    btn3 = bbox.add(text: 'Help', name: 'help')

    errors << "add btn1 failed" if btn1.nil?
    errors << "add btn2 failed" if btn2.nil?

    # --- index ---
    idx = bbox.index('ok')
    errors << "index failed: got #{idx.inspect}" unless idx == 0

    idx = bbox.index('cancel')
    errors << "index cancel failed: got #{idx.inspect}" unless idx == 1

    # --- itemconfigure/itemcget for button options ---
    bbox.itemconfigure(0, text: 'Accept')
    text = bbox.itemcget(0, :text)
    errors << "itemcget text failed: got #{text.inspect}" unless text == 'Accept'

    bbox.itemconfigure(0, state: 'disabled')
    state = bbox.itemcget(0, :state)
    errors << "itemcget state failed: got #{state.inspect}" unless state == 'disabled'

    bbox.itemconfigure(0, state: 'normal')

    # --- delete ---
    bbox.delete('help')
    idx = bbox.index('cancel')
    errors << "delete failed: cancel should now be at index 1" unless idx == 1

    raise "BWidget ButtonBox test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
