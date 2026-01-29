# frozen_string_literal: true

# Test that method_missing still works for canvas item options
# that aren't explicitly declared with item_option

require_relative 'test_helper'
require_relative 'tk_test_helper'

class TestCanvasMethodMissing < Minitest::Test
  include TkTestHelper

  # fill, outline, etc. are NOT declared with item_option
  # They should work via method_missing -> configure/cget

  def test_fill_via_method_missing
    assert_tk_app("canvas item fill via method_missing", method(:app_fill_method_missing))
  end

  def app_fill_method_missing
    require 'tk'
    require 'tk/canvas'

    canvas = TkCanvas.new(root)
    rect = TkcRectangle.new(canvas, 0, 0, 50, 50)

    # Setter via method_missing
    rect.fill = 'red'

    # Getter via method_missing
    result = rect.fill

    raise "fill getter failed: expected 'red', got #{result.inspect}" unless result == 'red'
  end

  def test_outline_via_method_missing
    assert_tk_app("canvas item outline via method_missing", method(:app_outline_method_missing))
  end

  def app_outline_method_missing
    require 'tk'
    require 'tk/canvas'

    canvas = TkCanvas.new(root)
    rect = TkcRectangle.new(canvas, 0, 0, 50, 50)

    rect.outline = 'blue'
    result = rect.outline

    raise "outline failed: expected 'blue', got #{result.inspect}" unless result == 'blue'
  end

  def test_width_via_method_missing
    assert_tk_app("canvas item width via method_missing", method(:app_width_method_missing))
  end

  def app_width_method_missing
    require 'tk'
    require 'tk/canvas'

    canvas = TkCanvas.new(root)
    line = TkcLine.new(canvas, 0, 0, 100, 100)

    line.width = 5
    result = line.width

    # width comes back as number
    raise "width failed: expected 5, got #{result.inspect}" unless result.to_i == 5
  end

  def test_text_via_method_missing
    assert_tk_app("canvas text item via method_missing", method(:app_text_method_missing))
  end

  def app_text_method_missing
    require 'tk'
    require 'tk/canvas'

    canvas = TkCanvas.new(root)
    text = TkcText.new(canvas, 50, 50, text: 'hello')

    text.text = 'world'
    result = text.text

    raise "text failed: expected 'world', got #{result.inspect}" unless result == 'world'
  end
end
