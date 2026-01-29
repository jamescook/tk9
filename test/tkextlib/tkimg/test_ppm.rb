# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../tk_test_helper"

# Tests for Tk::Img::PPM - PPM image format support
class TestTkImgPpm < Minitest::Test
  include TkTestHelper

  def test_ppm_package
    assert_tk_app("TkImg PPM package test", method(:ppm_app))
  end

  def ppm_app
    require "tk"
    require "tkextlib/tkimg/ppm"

    errors = []

    errors << "package_name mismatch" unless Tk::Img::PPM.package_name == "img::ppm"

    version = Tk::Img::PPM.package_version
    errors << "package_version is empty" if version.nil? || version.empty?

    fixture_path = File.expand_path("test/fixtures/sample.ppm")
    begin
      img = TkPhotoImage.new(file: fixture_path, format: "ppm")
      errors << "image width should be > 0" unless img.width > 0
      errors << "image height should be > 0" unless img.height > 0
    rescue => e
      errors << "Failed to load PPM image: #{e.message}"
    end

    raise "Failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
