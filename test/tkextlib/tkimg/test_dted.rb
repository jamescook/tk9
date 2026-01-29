# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../tk_test_helper"

# Tests for Tk::Img::DTED - Digital Terrain Elevation Data format
# DTED is a military/geographic elevation data format
# Fixture: Generated Level 0 file (30 arc-second, 121x121 posts)
# Generate with: ruby test/fixtures/generate_dted.rb
class TestTkImgDted < Minitest::Test
  include TkTestHelper

  def test_dted_package
    assert_tk_app("TkImg DTED package test", method(:dted_app))
  end

  def dted_app
    require "tk"
    require "tkextlib/tkimg/dted"

    errors = []

    errors << "package_name mismatch" unless Tk::Img::DTED.package_name == "img::dted"

    version = Tk::Img::DTED.package_version
    errors << "package_version is empty" if version.nil? || version.empty?

    fixture_path = File.expand_path("test/fixtures/sample.dt0")
    begin
      img = TkPhotoImage.new(file: fixture_path, format: "dted")
      errors << "image width should be > 0" unless img.width > 0
      errors << "image height should be > 0" unless img.height > 0
    rescue => e
      errors << "Failed to load DTED image: #{e.message}"
    end

    raise "Failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
