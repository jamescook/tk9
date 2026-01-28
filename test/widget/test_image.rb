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

  # --- TkPhotoImage operations ---

  def test_photo_blank
    assert_tk_app("TkPhotoImage blank", method(:app_photo_blank))
  end

  def app_photo_blank
    require 'tk'
    require 'tk/image'

    errors = []

    photo = TkPhotoImage.new(width: 10, height: 10)
    # Put some data first
    photo.put("{red red red} {red red red} {red red red}", to: [0, 0])

    result = photo.blank
    errors << "blank should return self" unless result == photo

    # After blank, pixel should be transparent (get returns {0 0 0} or similar for transparent)
    # Actually checking transparency is better
    errors << "pixel should be transparent after blank" unless photo.get_transparency(0, 0)

    photo.delete
    raise errors.join("\n") unless errors.empty?
  end

  def test_photo_get_put
    assert_tk_app("TkPhotoImage get/put", method(:app_photo_get_put))
  end

  def app_photo_get_put
    require 'tk'
    require 'tk/image'

    errors = []

    photo = TkPhotoImage.new(width: 10, height: 10)

    # Put a red pixel at 0,0
    photo.put("#ff0000", to: [0, 0, 1, 1])

    # Get the pixel
    rgb = photo.get(0, 0)
    errors << "get should return array" unless rgb.is_a?(Array)
    errors << "get should return 3 values, got #{rgb.size}" unless rgb.size == 3
    errors << "red component should be 255, got #{rgb[0]}" unless rgb[0] == 255
    errors << "green component should be 0, got #{rgb[1]}" unless rgb[1] == 0
    errors << "blue component should be 0, got #{rgb[2]}" unless rgb[2] == 0

    photo.delete
    raise errors.join("\n") unless errors.empty?
  end

  def test_photo_transparency
    assert_tk_app("TkPhotoImage transparency", method(:app_photo_transparency))
  end

  def app_photo_transparency
    require 'tk'
    require 'tk/image'

    errors = []

    photo = TkPhotoImage.new(width: 10, height: 10)

    # New photo pixels are transparent by default
    errors << "new pixel should be transparent" unless photo.get_transparency(0, 0)

    # Make it opaque
    photo.set_transparency(0, 0, false)
    errors << "pixel should be opaque after set_transparency(false)" if photo.get_transparency(0, 0)

    # Make it transparent again
    result = photo.set_transparency(0, 0, true)
    errors << "set_transparency should return self" unless result == photo
    errors << "pixel should be transparent after set_transparency(true)" unless photo.get_transparency(0, 0)

    photo.delete
    raise errors.join("\n") unless errors.empty?
  end

  def test_photo_copy
    assert_tk_app("TkPhotoImage copy", method(:app_photo_copy))
  end

  def app_photo_copy
    require 'tk'
    require 'tk/image'

    errors = []

    src = TkPhotoImage.new(width: 10, height: 10)
    src.put("#00ff00", to: [0, 0, 10, 10])  # Fill with green

    dst = TkPhotoImage.new(width: 20, height: 20)

    # Copy src to dst
    result = dst.copy(src)
    errors << "copy should return self" unless result == dst

    # Check that dst has green at 0,0
    rgb = dst.get(0, 0)
    errors << "copied pixel should be green, got #{rgb.inspect}" unless rgb[1] == 255

    # Copy with options
    dst2 = TkPhotoImage.new(width: 20, height: 20)
    dst2.copy(src, from: [0, 0, 5, 5], to: [5, 5])
    rgb2 = dst2.get(5, 5)
    errors << "copy with from/to should work" unless rgb2[1] == 255

    src.delete
    dst.delete
    dst2.delete
    raise errors.join("\n") unless errors.empty?
  end

  def test_photo_data
    assert_tk_app("TkPhotoImage data", method(:app_photo_data))
  end

  def app_photo_data
    require 'tk'
    require 'tk/image'

    errors = []

    photo = TkPhotoImage.new(width: 2, height: 2)
    photo.put("#ff0000", to: [0, 0, 2, 2])  # Fill with red

    data = photo.data
    errors << "data should return array" unless data.is_a?(Array)
    errors << "data should have rows" unless data.size > 0

    # Data with grayscale option
    gray_data = photo.data(grayscale: true)
    errors << "grayscale data should return array" unless gray_data.is_a?(Array)

    photo.delete
    raise errors.join("\n") unless errors.empty?
  end

  def test_photo_inuse
    assert_tk_app("TkPhotoImage inuse", method(:app_photo_inuse))
  end

  def app_photo_inuse
    require 'tk'
    require 'tk/image'

    errors = []

    photo = TkPhotoImage.new(width: 10, height: 10)

    # Not in use yet
    errors << "inuse should return boolean" unless [true, false].include?(photo.inuse)

    # Put it in a label to make it "in use"
    label = TkLabel.new(root, image: photo)
    label.pack

    # Now it should be in use
    errors << "inuse should be true when displayed" unless photo.inuse

    label.destroy
    photo.delete
    raise errors.join("\n") unless errors.empty?
  end

  def test_photo_redither
    assert_tk_app("TkPhotoImage redither", method(:app_photo_redither))
  end

  def app_photo_redither
    require 'tk'
    require 'tk/image'

    errors = []

    photo = TkPhotoImage.new(width: 10, height: 10)
    photo.put("#808080", to: [0, 0, 10, 10])

    result = photo.redither
    errors << "redither should return self" unless result == photo

    photo.delete
    raise errors.join("\n") unless errors.empty?
  end

  def test_photo_cget
    assert_tk_app("TkPhotoImage cget", method(:app_photo_cget))
  end

  def app_photo_cget
    require 'tk'
    require 'tk/image'

    errors = []

    photo = TkPhotoImage.new(width: 50, height: 30, gamma: 1.5)

    w = photo.cget(:width)
    errors << "cget width should be 50, got #{w}" unless w == 50

    h = photo.cget(:height)
    errors << "cget height should be 30, got #{h}" unless h == 30

    g = photo.cget(:gamma)
    errors << "cget gamma should be ~1.5, got #{g}" unless (g.to_f - 1.5).abs < 0.01

    photo.delete
    raise errors.join("\n") unless errors.empty?
  end

  def test_photo_base64_tkimg_warning
    assert_tk_app("TkPhotoImage base64 tkimg warning", method(:app_photo_base64_warning))
  end

  def app_photo_base64_warning
    require 'tk'
    require 'tk/image'
    require 'base64'

    errors = []

    # Load real BMP fixture and base64 encode it
    bmp_path = File.expand_path('test/fixtures/sample.bmp')
    bmp_data = Base64.strict_encode64(File.binread(bmp_path))

    # Verify signature detection works
    errors << "BMP base64 should start with Qk" unless bmp_data.start_with?('Qk')

    # Capture stderr to check for warning
    old_stderr = $stderr
    $stderr = StringIO.new

    begin
      TkPhotoImage.new(data: bmp_data)
    rescue TclTkLib::TclError
      # Expected - tkimg can't parse base64 data
    end

    warning = $stderr.string
    $stderr = old_stderr

    errors << "Should warn about base64 BMP" unless warning.include?('base64-encoded BMP')
    errors << "Warning should mention Base64.decode64" unless warning.include?('Base64.decode64')

    # PNG should NOT warn (native base64 support)
    # Reset so we're testing signature detection, not warn_once dedup
    Tk::Warnings.reset!
    png_path = File.expand_path('test/fixtures/sample.png')
    png_data = Base64.strict_encode64(File.binread(png_path))

    $stderr = StringIO.new
    begin
      img = TkPhotoImage.new(data: png_data)
      img.delete
    rescue => e
      errors << "PNG should load without error: #{e.message}"
    end
    png_warning = $stderr.string
    $stderr = old_stderr

    errors << "PNG should NOT warn about base64" if png_warning.include?('base64')

    raise errors.join("\n") unless errors.empty?
  end
end
