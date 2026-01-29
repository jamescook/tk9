# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../tk_test_helper"

# Tests for Tk::Img::WINDOW - Window capture format
# Captures Tk windows as images via: image create photo -format window -data $window_path
# See: https://www.mankier.com/n/img-window
class TestTkImgWindow < Minitest::Test
  include TkTestHelper

  def test_window_package
    assert_tk_app("TkImg WINDOW package test", method(:window_app))
  end

  def window_app
    require "tk"
    require "tkextlib/tkimg/window"

    errors = []

    errors << "package_name mismatch" unless Tk::Img::WINDOW.package_name == "img::window"

    version = Tk::Img::WINDOW.package_version
    errors << "package_version is empty" if version.nil? || version.empty?

    # Create a visible toplevel to capture (must be mapped and visible)
    begin
      root = Tk.root
      root.geometry("100x100+0+0")
      root.configure(bg: "red")
      root.deiconify
      root.raise
      Tk.update_idletasks
      Tk.update

      # Capture using: image create photo -format window -data $window_path
      img = TkPhotoImage.new(format: "window", data: root.path)
      errors << "captured image width should be > 0" unless img.width > 0
      errors << "captured image height should be > 0" unless img.height > 0
    rescue => e
      errors << "Failed to capture window: #{e.message}"
    end

    raise "Failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
