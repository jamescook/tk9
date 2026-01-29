# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../tk_test_helper"

# Tests for Tk::Img::TIFF - TIFF image format support
class TestTkImgTiff < Minitest::Test
  include TkTestHelper

  def test_tiff_package
    assert_tk_app("TkImg TIFF package test", method(:tiff_app))
  end

  def tiff_app
    require "tk"
    require "tkextlib/tkimg/tiff"

    errors = []

    errors << "package_name mismatch" unless Tk::Img::TIFF.package_name == "img::tiff"

    version = Tk::Img::TIFF.package_version
    errors << "package_version is empty" if version.nil? || version.empty?

    fixture_path = File.expand_path("test/fixtures/sample.tiff")
    begin
      img = TkPhotoImage.new(file: fixture_path, format: "tiff")
      errors << "image width should be > 0" unless img.width > 0
      errors << "image height should be > 0" unless img.height > 0
    rescue => e
      errors << "Failed to load TIFF image: #{e.message}"
    end

    raise "Failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
