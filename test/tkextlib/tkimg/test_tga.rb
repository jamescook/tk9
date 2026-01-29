# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../tk_test_helper"

# Tests for Tk::Img::TGA - Targa image format support
# Fixture requirements: 24-bit RGB TrueColor (not 8-bit indexed)
# Generate with: magick sample.png -type TrueColor TGA:sample.tga
class TestTkImgTga < Minitest::Test
  include TkTestHelper

  def test_tga_package
    assert_tk_app("TkImg TGA package test", method(:tga_app))
  end

  def tga_app
    require "tk"
    require "tkextlib/tkimg/tga"

    errors = []

    errors << "package_name mismatch" unless Tk::Img::TGA.package_name == "img::tga"

    version = Tk::Img::TGA.package_version
    errors << "package_version is empty" if version.nil? || version.empty?

    fixture_path = File.expand_path("test/fixtures/sample.tga")
    begin
      img = TkPhotoImage.new(file: fixture_path, format: "tga")
      errors << "image width should be > 0" unless img.width > 0
      errors << "image height should be > 0" unless img.height > 0
    rescue => e
      errors << "Failed to load TGA image: #{e.message}"
    end

    raise "Failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
