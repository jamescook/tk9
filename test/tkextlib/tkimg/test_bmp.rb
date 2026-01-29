# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../tk_test_helper"

# Tests for Tk::Img::BMP - BMP image format support
# Fixture requirements: BMP3 format with 24-bit TrueColor (not 8-bit indexed)
# Generate with: magick sample.png -type TrueColor BMP3:sample.bmp
class TestTkImgBmp < Minitest::Test
  include TkTestHelper

  def test_bmp_package
    assert_tk_app("TkImg BMP package test", method(:bmp_app))
  end

  def bmp_app
    require "tk"
    require "tkextlib/tkimg/bmp"

    errors = []

    errors << "package_name mismatch" unless Tk::Img::BMP.package_name == "img::bmp"

    version = Tk::Img::BMP.package_version
    errors << "package_version is empty" if version.nil? || version.empty?

    fixture_path = File.expand_path("test/fixtures/sample.bmp")
    begin
      img = TkPhotoImage.new(file: fixture_path, format: "bmp")
      errors << "image width should be > 0" unless img.width > 0
      errors << "image height should be > 0" unless img.height > 0
    rescue => e
      errors << "Failed to load BMP image: #{e.message}"
    end

    raise "Failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
