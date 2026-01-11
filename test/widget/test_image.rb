# frozen_string_literal: true

# Test for TkImage and TkBitmapImage.
# Runs in a single subprocess to minimize overhead.
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/image.html
# See: https://www.tcl-lang.org/man/tcl/TkCmd/bitmap.html

require_relative '../test_helper'
require_relative '../tk_test_helper'

class TestImageWidget < Minitest::Test
  include TkTestHelper

  def test_image_comprehensive
    assert_tk_app("Image comprehensive test", method(:image_app))
  end

  def image_app
    require 'tk'
    require 'tk/image'

    errors = []

    # --- TkImage.types ---
    types = TkImage.types
    errors << "types should return array" unless types.is_a?(Array)
    errors << "types should include bitmap" unless types.include?("bitmap")
    errors << "types should include photo" unless types.include?("photo")

    # --- TkBitmapImage basic creation ---
    # Create a simple bitmap using inline data (XBM format)
    xbm_data = "#define test_width 8\n#define test_height 8\nstatic unsigned char test_bits[] = {\n   0xff, 0x81, 0x81, 0x81, 0x81, 0x81, 0x81, 0xff };"

    bitmap = TkBitmapImage.new(data: xbm_data)
    errors << "bitmap should have path" unless bitmap.path
    errors << "bitmap width failed" unless bitmap.width == 8
    errors << "bitmap height failed" unless bitmap.height == 8
    errors << "bitmap itemtype failed" unless bitmap.itemtype == "bitmap"

    # --- TkBitmapImage maskdata option (DSL-declared string) ---
    mask_data = "#define mask_width 8\n#define mask_height 8\nstatic unsigned char mask_bits[] = {\n   0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff };"

    bitmap2 = TkBitmapImage.new(data: xbm_data, maskdata: mask_data)
    errors << "maskdata should be set" if bitmap2.cget(:maskdata).to_s.empty?

    # --- TkBitmapImage configure maskdata ---
    bitmap.configure(maskdata: mask_data)
    errors << "configure maskdata failed" if bitmap.cget(:maskdata).to_s.empty?

    # --- TkPhotoImage basic creation ---
    photo = TkPhotoImage.new(width: 100, height: 100)
    errors << "photo should have path" unless photo.path
    errors << "photo width failed" unless photo.width == 100
    errors << "photo height failed" unless photo.height == 100
    errors << "photo itemtype failed" unless photo.itemtype == "photo"

    # --- TkImage.names ---
    names = TkImage.names
    errors << "names should return array" unless names.is_a?(Array)
    errors << "names should include our images" unless names.size >= 3

    # --- Image deletion ---
    bitmap2.delete
    # After deletion, the image should not be in names
    names_after = TkImage.names
    errors << "delete should remove image" if names_after.any? { |n| n.respond_to?(:path) && n.path == bitmap2.path }

    # Clean up
    bitmap.delete
    photo.delete

    # Check errors before tk_end
    unless errors.empty?
      raise "Image test failures:\n  " + errors.join("\n  ")
    end

  end
end
