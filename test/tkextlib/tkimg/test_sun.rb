# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../tk_test_helper"

# Tests for Tk::Img::SUN - Sun Raster image format support
# Generate with: magick sample.png sample.sun
class TestTkImgSun < Minitest::Test
  include TkTestHelper

  def test_sun_package
    assert_tk_app("TkImg SUN package test", method(:sun_app))
  end

  def sun_app
    require "tk"
    require "tkextlib/tkimg/sun"

    errors = []

    errors << "package_name mismatch" unless Tk::Img::SUN.package_name == "img::sun"

    version = Tk::Img::SUN.package_version
    errors << "package_version is empty" if version.nil? || version.empty?

    fixture_path = File.expand_path("test/fixtures/sample.sun")
    begin
      img = TkPhotoImage.new(file: fixture_path, format: "sun")
      errors << "image width should be > 0" unless img.width > 0
      errors << "image height should be > 0" unless img.height > 0
    rescue => e
      errors << "Failed to load SUN image: #{e.message}"
    end

    raise "Failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
