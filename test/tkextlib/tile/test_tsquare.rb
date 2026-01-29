# frozen_string_literal: true

# Test for Tk::Tile::TSquare
#
# TSquare is an example widget from the Tile widget development tutorial,
# used to demonstrate how to create new themed widgets. It's not a standard
# widget in Tk distributions.
# See: https://tktable.sourceforge.net/tile/WidgetGuide.html

require_relative '../../test_helper'
require_relative '../../tk_test_helper'

class TestTileSquare < Minitest::Test
  include TkTestHelper

  def test_tsquare_class_structure
    assert_tk_app("Tile TSquare class structure", method(:tsquare_class_app))
  end

  def tsquare_class_app
    require 'tk'
    require 'tkextlib/tile/tsquare'

    errors = []

    # --- Class should exist ---
    errors << "TSquare class not defined" unless defined?(Tk::Tile::TSquare)

    # --- Alias should exist ---
    errors << "Square alias not defined" unless defined?(Tk::Tile::Square)
    errors << "Square should alias TSquare" unless Tk::Tile::Square == Tk::Tile::TSquare

    # --- Should include TileWidget ---
    unless Tk::Tile::TSquare.include?(Tk::Tile::TileWidget)
      errors << "TSquare should include TileWidget"
    end

    # --- TkCommandNames should be defined ---
    errors << "TkCommandNames not defined" unless defined?(Tk::Tile::TSquare::TkCommandNames)

    # Command name depends on USE_TTK_NAMESPACE
    cmd_names = Tk::Tile::TSquare::TkCommandNames
    valid_commands = ['::ttk::square', '::tsquare']
    unless valid_commands.any? { |c| cmd_names.include?(c) }
      errors << "TkCommandNames should contain ::ttk::square or ::tsquare, got #{cmd_names.inspect}"
    end

    # --- WidgetClassName ---
    errors << "WidgetClassName not defined" unless defined?(Tk::Tile::TSquare::WidgetClassName)
    errors << "WidgetClassName should be TSquare" unless Tk::Tile::TSquare::WidgetClassName == 'TSquare'

    # --- style class method ---
    unless Tk::Tile::TSquare.respond_to?(:style)
      errors << "TSquare should respond to style"
    end

    style = Tk::Tile::TSquare.style
    errors << "style() should return 'TSquare'" unless style == 'TSquare'

    style_with_args = Tk::Tile::TSquare.style('Custom')
    errors << "style('Custom') failed" unless style_with_args == 'TSquare.Custom'

    raise errors.join("\n") unless errors.empty?
  end
end
