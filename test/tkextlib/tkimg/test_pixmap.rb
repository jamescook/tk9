# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../tk_test_helper"

# Tests for Tk::Img::PIXMAP - Pixmap image format support
# Uses XPM format data. TkPixmapImage is a specialized image class.
class TestTkImgPixmap < Minitest::Test
  include TkTestHelper

  def test_pixmap_package
    assert_tk_app("TkImg PIXMAP package test", method(:pixmap_app))
  end

  def pixmap_app
    require "tk"
    require "tkextlib/tkimg/pixmap"

    errors = []

    errors << "package_name mismatch" unless Tk::Img::PIXMAP.package_name == "img::pixmap"

    version = Tk::Img::PIXMAP.package_version
    errors << "package_version is empty" if version.nil? || version.empty?

    # TkPixmapImage uses XPM format - test with existing XPM fixture
    fixture_path = File.expand_path("test/fixtures/sample.xpm")
    begin
      img = TkPixmapImage.new(file: fixture_path)
      errors << "TkPixmapImage width should be > 0" unless img.width > 0
      errors << "TkPixmapImage height should be > 0" unless img.height > 0
    rescue => e
      errors << "Failed to create TkPixmapImage: #{e.message}"
    end

    raise "Failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
