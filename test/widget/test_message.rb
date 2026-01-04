# frozen_string_literal: true

# Comprehensive test for Tk::Message widget options.
# Runs in a single subprocess to minimize overhead.
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/message.html

require_relative '../test_helper'
require_relative '../tk_test_helper'

class TestMessageWidget < Minitest::Test
  include TkTestHelper

  def test_message_comprehensive
    assert_tk_app("Message widget comprehensive test", method(:message_app))
  end

  def message_app
    require 'tk'
    require 'tk/message'
    require 'tk/frame'

    root = TkRoot.new { withdraw }
    errors = []

    frame = TkFrame.new(root, padx: 20, pady: 20)
    frame.pack(fill: "both", expand: true)

    # --- Basic message ---
    msg = TkMessage.new(frame,
      text: "This is a long message that will wrap according to the aspect ratio setting. " \
            "The message widget is designed for displaying multi-line text.",
      aspect: 200
    )
    msg.pack(fill: "x", pady: 10)

    # --- Aspect ratio (DSL-declared integer) ---
    errors << "aspect failed" unless msg.cget(:aspect) == 200

    msg.configure(aspect: 300)
    errors << "aspect update failed" unless msg.cget(:aspect) == 300

    # --- Width ---
    msg.configure(width: 250)
    errors << "width failed" unless msg.cget(:width).to_i == 250

    # --- Justify (inherited from Label) ---
    msg.configure(justify: "center")
    errors << "justify failed" unless msg.cget(:justify) == "center"

    # --- Text (inherited) ---
    msg.configure(text: "Updated message text.")
    errors << "text failed" unless msg.cget(:text) == "Updated message text."

    # --- Relief and border (inherited) ---
    msg.configure(relief: "groove", borderwidth: 2)
    errors << "relief failed" unless msg.cget(:relief) == "groove"
    errors << "borderwidth failed" unless msg.cget(:borderwidth).to_i == 2

    # --- Another message with different settings ---
    msg2 = TkMessage.new(frame,
      text: "A shorter message with left justification.",
      justify: "left",
      aspect: 100,
      padx: 10,
      pady: 5
    )
    msg2.pack(fill: "x", pady: 5)

    errors << "msg2 justify failed" unless msg2.cget(:justify) == "left"
    errors << "msg2 aspect failed" unless msg2.cget(:aspect) == 100

    # Check errors before tk_end
    unless errors.empty?
      root.destroy
      raise "Message test failures:\n  " + errors.join("\n  ")
    end

    tk_end(root)
  end
end
