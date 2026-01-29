# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../tk_test_helper"

# Tests for Tk::Img::SGI - Silicon Graphics Image format support
# Generate with: magick sample.png sample.sgi
class TestTkImgSgi < Minitest::Test
  include TkTestHelper

  def test_sgi_package
    assert_tk_app("TkImg SGI package test", method(:sgi_app))
  end

  def sgi_app
    require "tk"
    require "tkextlib/tkimg/sgi"

    errors = []

    errors << "package_name mismatch" unless Tk::Img::SGI.package_name == "img::sgi"

    version = Tk::Img::SGI.package_version
    errors << "package_version is empty" if version.nil? || version.empty?

    fixture_path = File.expand_path("test/fixtures/sample.sgi")
    begin
      img = TkPhotoImage.new(file: fixture_path, format: "sgi")
      errors << "image width should be > 0" unless img.width > 0
      errors << "image height should be > 0" unless img.height > 0
    rescue => e
      errors << "Failed to load SGI image: #{e.message}"
    end

    raise "Failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
