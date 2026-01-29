# frozen_string_literal: true

# Test for Tk::Tile::TLabel (ttk::label) widget
# This tests tkextlib coverage

require_relative '../test_helper'
require_relative '../tk_test_helper'

class TestTileLabelWidget < Minitest::Test
  include TkTestHelper

  def test_tile_label_basic
    assert_tk_app("Tile Label basic test", method(:tile_label_app))
  end

  def tile_label_app
    require 'tk'
    require 'tkextlib/tile/tlabel'

    errors = []

    # Basic creation
    lbl = Tk::Tile::TLabel.new(root, text: "Tile Label")
    errors << "text not set" unless lbl.cget(:text) == "Tile Label"

    # Style option (tile-specific)
    lbl_styled = Tk::Tile::TLabel.new(root, text: "Styled")
    # Just verify it doesn't error - style may be empty string by default
    lbl_styled.cget(:style)

    # Dynamic configure
    lbl.configure(text: "Updated")
    errors << "configure failed" unless lbl.cget(:text) == "Updated"

    unless errors.empty?
      raise "Tile Label test failures:\n  " + errors.join("\n  ")
    end
  end

  def test_tile_label_padding
    assert_tk_app("Tile Label padding test", method(:tile_label_padding_app))
  end

  def tile_label_padding_app
    require 'tk'
    require 'tkextlib/tile/tlabel'

    errors = []

    # Single value padding (uniform all sides)
    lbl = Tk::Tile::TLabel.new(root, text: "Padded", padding: 10)
    lbl.pack

    # Padding should be set
    padding = lbl.cget(:padding)
    errors << "padding not set, got: #{padding.inspect}" if padding.nil? || padding.to_s.empty?

    # Two-value padding (horizontal, vertical)
    lbl2 = Tk::Tile::TLabel.new(root, text: "Padded 2", padding: "5 10")
    lbl2.pack

    # Four-value padding (left, top, right, bottom)
    lbl3 = Tk::Tile::TLabel.new(root, text: "Padded 4", padding: "2 4 6 8")
    lbl3.pack

    # Configure padding dynamically
    lbl.configure(padding: 20)
    new_padding = lbl.cget(:padding)
    errors << "dynamic padding failed" if new_padding.nil? || new_padding.to_s.empty?

    unless errors.empty?
      raise "Tile Label padding test failures:\n  " + errors.join("\n  ")
    end
  end

  def test_tile_label_font_and_colors
    assert_tk_app("Tile Label font/colors test", method(:tile_label_font_colors_app))
  end

  def tile_label_font_colors_app
    require 'tk'
    require 'tkextlib/tile/tlabel'

    errors = []

    lbl = Tk::Tile::TLabel.new(root,
      text: "Styled Label",
      font: "Helvetica 14 bold",
      foreground: "blue",
      background: "yellow"
    )
    lbl.pack

    font = lbl.cget(:font)
    errors << "font should be TkFont" unless font.is_a?(TkFont)
    # Font family may be substituted if Helvetica unavailable, just verify it's set
    errors << "font family should not be empty" if font.family.to_s.empty?
    errors << "foreground not set" unless lbl.cget(:foreground) == "blue"
    errors << "background not set" unless lbl.cget(:background) == "yellow"

    unless errors.empty?
      raise "Tile Label font/colors test failures:\n  " + errors.join("\n  ")
    end
  end
end
