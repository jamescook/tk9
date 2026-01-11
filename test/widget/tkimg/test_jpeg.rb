# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../tk_test_helper"

# Tests for Tk::Img::JPEG - JPEG image format support
# Requires tkimg extension (libtk-img on Ubuntu, build from source on macOS)
class TestTkImgJpeg < Minitest::Test
  include TkTestHelper

  def test_jpeg_package
    assert_tk_app("TkImg JPEG package test", method(:jpeg_app))
  end

  def jpeg_app
    require "tk"
    require "tkextlib/tkimg/jpeg"

    errors = []

    # Test package info
    errors << "package_name mismatch" unless Tk::Img::JPEG.package_name == "img::jpeg"

    version = Tk::Img::JPEG.package_version
    errors << "package_version is empty" if version.nil? || version.empty?

    # Test loading a real JPEG file
    # Compute path inside method - worker subprocess doesn't have access to test constants
    fixture_path = File.expand_path("test/fixtures/sample.jpg")
    begin
      img = TkPhotoImage.new(file: fixture_path, format: "jpeg")
      errors << "image width should be > 0" unless img.width > 0
      errors << "image height should be > 0" unless img.height > 0
    rescue => e
      errors << "Failed to load JPEG image: #{e.message}"
    end

    raise "Failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
