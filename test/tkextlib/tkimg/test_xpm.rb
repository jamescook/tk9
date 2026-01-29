# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../tk_test_helper"

# Tests for Tk::Img::XPM - X PixMap format support
class TestTkImgXpm < Minitest::Test
  include TkTestHelper

  def test_xpm_package
    assert_tk_app("TkImg XPM package test", method(:xpm_app))
  end

  def xpm_app
    require "tk"
    require "tkextlib/tkimg/xpm"

    errors = []

    errors << "package_name mismatch" unless Tk::Img::XPM.package_name == "img::xpm"

    version = Tk::Img::XPM.package_version
    errors << "package_version is empty" if version.nil? || version.empty?

    fixture_path = File.expand_path("test/fixtures/sample.xpm")
    begin
      img = TkPhotoImage.new(file: fixture_path, format: "xpm")
      errors << "image width should be > 0" unless img.width > 0
      errors << "image height should be > 0" unless img.height > 0
    rescue => e
      errors << "Failed to load XPM image: #{e.message}"
    end

    raise "Failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
