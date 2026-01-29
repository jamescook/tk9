# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../tk_test_helper"

# Tests for Tk::Img::GIF - GIF image format support
class TestTkImgGif < Minitest::Test
  include TkTestHelper

  def test_gif_package
    assert_tk_app("TkImg GIF package test", method(:gif_app))
  end

  def gif_app
    require "tk"
    require "tkextlib/tkimg/gif"

    errors = []

    errors << "package_name mismatch" unless Tk::Img::GIF.package_name == "img::gif"

    version = Tk::Img::GIF.package_version
    errors << "package_version is empty" if version.nil? || version.empty?

    fixture_path = File.expand_path("test/fixtures/sample.gif")
    begin
      img = TkPhotoImage.new(file: fixture_path, format: "gif")
      errors << "image width should be > 0" unless img.width > 0
      errors << "image height should be > 0" unless img.height > 0
    rescue => e
      errors << "Failed to load GIF image: #{e.message}"
    end

    raise "Failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
