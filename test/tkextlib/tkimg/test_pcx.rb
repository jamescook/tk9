# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../tk_test_helper"

# Tests for Tk::Img::PCX - PCX image format support
class TestTkImgPcx < Minitest::Test
  include TkTestHelper

  def test_pcx_package
    assert_tk_app("TkImg PCX package test", method(:pcx_app))
  end

  def pcx_app
    require "tk"
    require "tkextlib/tkimg/pcx"

    errors = []

    errors << "package_name mismatch" unless Tk::Img::PCX.package_name == "img::pcx"

    version = Tk::Img::PCX.package_version
    errors << "package_version is empty" if version.nil? || version.empty?

    fixture_path = File.expand_path("test/fixtures/sample.pcx")
    begin
      img = TkPhotoImage.new(file: fixture_path, format: "pcx")
      errors << "image width should be > 0" unless img.width > 0
      errors << "image height should be > 0" unless img.height > 0
    rescue => e
      errors << "Failed to load PCX image: #{e.message}"
    end

    raise "Failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
