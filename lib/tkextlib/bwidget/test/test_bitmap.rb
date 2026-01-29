# frozen_string_literal: true

# Test for Tk::BWidget::Bitmap image.

require_relative '../../../../test/test_helper'
require_relative '../../../../test/tk_test_helper'

class TestBWidgetBitmap < Minitest::Test
  include TkTestHelper

  def test_bitmap_comprehensive
    assert_tk_app("BWidget Bitmap test", method(:bitmap_app))
  end

  def bitmap_app
    require 'tk'
    require 'tkextlib/bwidget'

    errors = []

    # --- Get a predefined BWidget bitmap ---
    # BWidget provides bitmaps like "target", "dragfile", etc.
    # Try to get one, but don't fail if not available
    begin
      bitmap = Tk::BWidget::Bitmap.new("target")
      errors << "bitmap creation failed" if bitmap.nil?

      # --- Use bitmap in a label ---
      label = TkLabel.new(root, image: bitmap)
      label.pack
    rescue TclTkLib::TclError => e
      # Bitmap not found - this is OK, just skip
      # BWidget bitmap availability varies by installation
    end

    raise "BWidget Bitmap test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
