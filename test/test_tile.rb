# frozen_string_literal: true

require_relative 'test_helper'
require_relative 'tk_test_helper'

class TestTile < Minitest::Test
  include TkTestHelper

  def test_define_load_images_proc
    assert_tk_app("__define_LoadImages_proc_for_compatibility__!", method(:app_load_images_proc))
  end

  def app_load_images_proc
    require 'tk'
    require 'tkextlib/tile'

    # Call the compatibility method
    Tk::Tile.__define_LoadImages_proc_for_compatibility__!

    # Verify the proc was defined in at least one namespace
    tile_cmd = Tk.info(:commands, '::tile::LoadImages')
    ttk_cmd = Tk.info(:commands, '::ttk::LoadImages')

    raise "LoadImages not defined in either namespace" if tile_cmd.empty? && ttk_cmd.empty?
  end

  def test_tile_themes
    assert_tk_app("Tk::Tile.themes", method(:app_tile_themes))
  end

  def app_tile_themes
    require 'tk'
    require 'tkextlib/tile'

    themes = Tk::Tile.themes
    raise "themes should return array" unless themes.is_a?(Array)
    raise "themes should not be empty" if themes.empty?
  end

  def test_tile_set_theme
    assert_tk_app("Tk::Tile.set_theme", method(:app_set_theme))
  end

  def app_set_theme
    require 'tk'
    require 'tkextlib/tile'

    # Get available themes and set one
    themes = Tk::Tile.themes
    raise "no themes available" if themes.empty?

    # Try setting the first available theme
    Tk::Tile.set_theme(themes.first)
  end
end
