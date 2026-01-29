# frozen_string_literal: true

# Test for Tk::Tile::TButton (ttk::button) widget

require_relative '../test_helper'
require_relative '../tk_test_helper'

class TestTileButtonWidget < Minitest::Test
  include TkTestHelper

  def test_tile_button_basic
    assert_tk_app("Tile Button basic test", method(:tile_button_basic_app))
  end

  def tile_button_basic_app
    require 'tk'
    require 'tkextlib/tile/tbutton'

    errors = []

    # Basic creation
    btn = Tk::Tile::TButton.new(root, text: "Click Me")
    btn.pack

    errors << "text not set" unless btn.cget(:text) == "Click Me"

    # Configure dynamically
    btn.configure(text: "Updated")
    errors << "configure failed" unless btn.cget(:text) == "Updated"

    unless errors.empty?
      raise "Tile Button test failures:\n  " + errors.join("\n  ")
    end
  end

  def test_tile_button_padding
    assert_tk_app("Tile Button padding test", method(:tile_button_padding_app))
  end

  def tile_button_padding_app
    require 'tk'
    require 'tkextlib/tile/tbutton'

    errors = []

    # Padding option
    btn = Tk::Tile::TButton.new(root, text: "Padded", padding: 15)
    btn.pack

    padding = btn.cget(:padding)
    errors << "padding not set, got: #{padding.inspect}" if padding.nil? || padding.to_s.empty?

    # Multi-value padding
    btn2 = Tk::Tile::TButton.new(root, text: "Padded 2", padding: "10 5")
    btn2.pack

    unless errors.empty?
      raise "Tile Button padding test failures:\n  " + errors.join("\n  ")
    end
  end

  def test_tile_button_command
    assert_tk_app("Tile Button command test", method(:tile_button_command_app))
  end

  def tile_button_command_app
    require 'tk'
    require 'tkextlib/tile/tbutton'

    errors = []
    clicked = false

    btn = Tk::Tile::TButton.new(root, text: "Click") do
      clicked = true
    end
    btn.pack

    # Invoke the button programmatically
    btn.invoke

    errors << "command not executed" unless clicked

    unless errors.empty?
      raise "Tile Button command test failures:\n  " + errors.join("\n  ")
    end
  end

  def test_tile_button_width
    assert_tk_app("Tile Button width test", method(:tile_button_width_app))
  end

  def tile_button_width_app
    require 'tk'
    require 'tkextlib/tile/tbutton'

    errors = []

    # Width in characters
    btn = Tk::Tile::TButton.new(root, text: "Wide", width: 20)
    btn.pack

    width = btn.cget(:width)
    errors << "width not set, got: #{width.inspect}" unless width.to_i == 20

    unless errors.empty?
      raise "Tile Button width test failures:\n  " + errors.join("\n  ")
    end
  end
end
