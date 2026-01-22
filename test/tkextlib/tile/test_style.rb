# frozen_string_literal: true

# Tests for Tk::Tile::Style (ttk::style command)
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/ttk_style.html

require_relative '../../test_helper'
require_relative '../../tk_test_helper'

class TestTileStyle < Minitest::Test
  include TkTestHelper

  # ---------------------------------------------------------
  # Theme management
  # ---------------------------------------------------------

  def test_theme_names
    assert_tk_app("Style theme_names", method(:theme_names_app))
  end

  def theme_names_app
    require 'tk'
    require 'tkextlib/tile'

    errors = []

    themes = Tk::Tile::Style.theme_names
    errors << "theme_names should return array" unless themes.is_a?(Array)
    errors << "theme_names should not be empty" if themes.empty?

    # Standard themes that should exist in Tk 8.6+
    %w[default clam classic alt].each do |theme|
      errors << "missing standard theme: #{theme}" unless themes.include?(theme)
    end

    raise errors.join("\n") unless errors.empty?
  end

  def test_theme_use
    assert_tk_app("Style theme_use", method(:theme_use_app))
  end

  def theme_use_app
    require 'tk'
    require 'tkextlib/tile'

    errors = []

    themes = Tk::Tile::Style.theme_names

    # Switch to each available theme
    themes.each do |theme|
      begin
        Tk::Tile::Style.theme_use(theme)
      rescue => e
        errors << "theme_use(#{theme}) failed: #{e.message}"
      end
    end

    # Switch back to default
    Tk::Tile::Style.theme_use('default')

    raise errors.join("\n") unless errors.empty?
  end

  # ---------------------------------------------------------
  # Style configuration
  # ---------------------------------------------------------

  def test_configure
    assert_tk_app("Style configure", method(:configure_app))
  end

  def configure_app
    require 'tk'
    require 'tkextlib/tile'

    errors = []

    # Configure the default style
    Tk::Tile::Style.configure('.', background: 'white')

    # Configure a specific widget style
    Tk::Tile::Style.configure('TButton', padding: 5)

    # Create a button to verify style applies
    btn = Tk::Tile::TButton.new(root, text: "Test")
    btn.pack

    raise errors.join("\n") unless errors.empty?
  end

  def test_map
    assert_tk_app("Style map", method(:map_app))
  end

  def map_app
    require 'tk'
    require 'tkextlib/tile'

    errors = []

    # Set state-based style mappings
    Tk::Tile::Style.map('TButton',
      background: [:active, 'lightblue', :disabled, 'gray'])

    # Query the map
    result = Tk::Tile::Style.map('TButton', 'background')
    errors << "map query should return array" unless result.is_a?(Array)

    raise errors.join("\n") unless errors.empty?
  end

  def test_lookup
    assert_tk_app("Style lookup", method(:lookup_app))
  end

  def lookup_app
    require 'tk'
    require 'tkextlib/tile'

    errors = []

    # Lookup a style option value
    bg = Tk::Tile::Style.lookup('TButton', 'background')
    errors << "lookup should return a value" if bg.nil? || bg.to_s.empty?

    # Lookup with state
    bg_active = Tk::Tile::Style.lookup('TButton', 'background', 'active')
    # Result may be empty if not defined, that's ok

    raise errors.join("\n") unless errors.empty?
  end

  # ---------------------------------------------------------
  # Layout and elements
  # ---------------------------------------------------------

  def test_layout
    assert_tk_app("Style layout", method(:layout_app))
  end

  def layout_app
    require 'tk'
    require 'tkextlib/tile'

    errors = []

    # Query a widget layout
    layout = Tk::Tile::Style.layout('TButton')
    errors << "layout should return structure" if layout.nil?

    raise errors.join("\n") unless errors.empty?
  end

  def test_element_names
    assert_tk_app("Style element_names", method(:element_names_app))
  end

  def element_names_app
    require 'tk'
    require 'tkextlib/tile'

    errors = []

    elements = Tk::Tile::Style.element_names
    errors << "element_names should return array" unless elements.is_a?(Array)
    errors << "element_names should not be empty" if elements.empty?

    raise errors.join("\n") unless errors.empty?
  end

  def test_element_options
    assert_tk_app("Style element_options", method(:element_options_app))
  end

  def element_options_app
    require 'tk'
    require 'tkextlib/tile'

    errors = []

    elements = Tk::Tile::Style.element_names
    if elements.any?
      # Query options for first element
      opts = Tk::Tile::Style.element_options(elements.first)
      errors << "element_options should return array" unless opts.is_a?(Array)
    end

    raise errors.join("\n") unless errors.empty?
  end

  # ---------------------------------------------------------
  # Theme creation
  # ---------------------------------------------------------

  def test_theme_create
    assert_tk_app("Style theme_create", method(:theme_create_app))
  end

  def theme_create_app
    require 'tk'
    require 'tkextlib/tile'

    errors = []

    # Create a custom theme based on 'default'
    Tk::Tile::Style.theme_create('test_theme', parent: 'default')

    themes = Tk::Tile::Style.theme_names
    errors << "created theme should be in theme_names" unless themes.include?('test_theme')

    # Use the custom theme
    Tk::Tile::Style.theme_use('test_theme')

    # Switch back
    Tk::Tile::Style.theme_use('default')

    raise errors.join("\n") unless errors.empty?
  end
end
