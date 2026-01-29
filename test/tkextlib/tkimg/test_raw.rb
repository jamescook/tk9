# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../tk_test_helper"

# Tests for Tk::Img::Raw - Raw image data format
# Raw format requires specifying dimensions and pixel format
# Fixture: 10x10 RGB raw pixels (300 bytes)
# Generate with: magick -size 10x10 xc:red -depth 8 RGB:sample.raw
class TestTkImgRaw < Minitest::Test
  include TkTestHelper

  def test_raw_package
    assert_tk_app("TkImg Raw package test", method(:raw_app))
  end

  def raw_app
    require "tk"
    require "tkextlib/tkimg/raw"

    errors = []

    errors << "package_name mismatch" unless Tk::Img::Raw.package_name == "img::raw"

    version = Tk::Img::Raw.package_version
    errors << "package_version is empty" if version.nil? || version.empty?

    fixture_path = File.expand_path("test/fixtures/sample.raw")
    begin
      # Raw format needs dimensions and pixel format specified
      img = TkPhotoImage.new(
        file: fixture_path,
        format: "RAW -useheader 0 -width 10 -height 10 -nchan 3 -pixeltype byte"
      )
      errors << "image width should be 10" unless img.width == 10
      errors << "image height should be 10" unless img.height == 10
    rescue => e
      errors << "Failed to load RAW image: #{e.message}"
    end

    raise "Failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
