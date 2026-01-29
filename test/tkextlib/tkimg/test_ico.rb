# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../tk_test_helper"

# Tests for Tk::Img::ICO - Windows Icon format support
# Fixture requirements: Single-size icon (32x32), not multi-size
# Generate with: magick sample.png -resize 32x32! -define icon:auto-resize=32 sample.ico
class TestTkImgIco < Minitest::Test
  include TkTestHelper

  def test_ico_package
    assert_tk_app("TkImg ICO package test", method(:ico_app))
  end

  def ico_app
    require "tk"
    require "tkextlib/tkimg/ico"

    errors = []

    errors << "package_name mismatch" unless Tk::Img::ICO.package_name == "img::ico"

    version = Tk::Img::ICO.package_version
    errors << "package_version is empty" if version.nil? || version.empty?

    fixture_path = File.expand_path("test/fixtures/sample.ico")
    begin
      img = TkPhotoImage.new(file: fixture_path, format: "ico")
      errors << "image width should be > 0" unless img.width > 0
      errors << "image height should be > 0" unless img.height > 0
    rescue => e
      errors << "Failed to load ICO image: #{e.message}"
    end

    raise "Failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
