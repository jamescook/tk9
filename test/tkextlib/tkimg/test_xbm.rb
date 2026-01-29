# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../tk_test_helper"

# Tests for Tk::Img::XBM - X BitMap format support
class TestTkImgXbm < Minitest::Test
  include TkTestHelper

  def test_xbm_package
    assert_tk_app("TkImg XBM package test", method(:xbm_app))
  end

  def xbm_app
    require "tk"
    require "tkextlib/tkimg/xbm"

    errors = []

    errors << "package_name mismatch" unless Tk::Img::XBM.package_name == "img::xbm"

    version = Tk::Img::XBM.package_version
    errors << "package_version is empty" if version.nil? || version.empty?

    fixture_path = File.expand_path("test/fixtures/sample.xbm")
    begin
      img = TkPhotoImage.new(file: fixture_path, format: "xbm")
      errors << "image width should be > 0" unless img.width > 0
      errors << "image height should be > 0" unless img.height > 0
    rescue => e
      errors << "Failed to load XBM image: #{e.message}"
    end

    raise "Failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
