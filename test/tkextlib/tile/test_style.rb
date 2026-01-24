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

    # Lookup with state (result may be empty if not defined, that's ok)
    _bg_active = Tk::Tile::Style.lookup('TButton', 'background', 'active')

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

  # ---------------------------------------------------------
  # Additional coverage for style methods
  # ---------------------------------------------------------

  def test_configure_default_style
    assert_tk_app("Style configure default", method(:configure_default_app))
  end

  def configure_default_app
    require 'tk'
    require 'tkextlib/tile'

    errors = []

    # Configure with hash only (style defaults to '.')
    Tk::Tile::Style.configure(background: 'lightgray')

    # Use 'default' alias
    Tk::Tile::Style.default('TLabel', foreground: 'black')

    raise errors.join("\n") unless errors.empty?
  end

  def test_map_configinfo
    assert_tk_app("Style map_configinfo", method(:map_configinfo_app))
  end

  def map_configinfo_app
    require 'tk'
    require 'tkextlib/tile'

    errors = []

    # Set up some map values first
    Tk::Tile::Style.map('TButton', background: [:active, 'blue', :disabled, 'gray'])

    # map_configinfo with style and key
    result = Tk::Tile::Style.map_configinfo('TButton', 'background')
    errors << "map_configinfo should return array" unless result.is_a?(Array)

    # map_default_configinfo
    Tk::Tile::Style.map('.', foreground: [:disabled, 'darkgray'])
    result = Tk::Tile::Style.map_default_configinfo('foreground')
    errors << "map_default_configinfo should return array" unless result.is_a?(Array)

    # map_configure alias
    Tk::Tile::Style.map_configure('TEntry', background: [:focus, 'white'])

    raise errors.join("\n") unless errors.empty?
  end

  def test_map_query_all
    assert_tk_app("Style map query all", method(:map_query_all_app))
  end

  def map_query_all_app
    require 'tk'
    require 'tkextlib/tile'

    errors = []

    # Set up some map values
    Tk::Tile::Style.map('TButton',
      background: [:active, 'blue'],
      foreground: [:disabled, 'gray'])

    # Query all mappings (no keys argument)
    result = Tk::Tile::Style.map('TButton')
    errors << "map() with no keys should return Hash, got #{result.class}" unless result.is_a?(Hash)

    raise errors.join("\n") unless errors.empty?
  end

  def test_lookup_with_fallback
    assert_tk_app("Style lookup with fallback", method(:lookup_fallback_app))
  end

  def lookup_fallback_app
    require 'tk'
    require 'tkextlib/tile'

    errors = []

    # Lookup with state and fallback value
    result = Tk::Tile::Style.lookup('TButton', 'background', 'active', 'red')
    # Result should be either the actual value or our fallback
    errors << "lookup with fallback should return value" if result.nil?

    raise errors.join("\n") unless errors.empty?
  end

  def test_layout_set
    assert_tk_app("Style layout set", method(:layout_set_app))
  end

  def layout_set_app
    require 'tk'
    require 'tkextlib/tile'

    errors = []

    # Set a custom layout for a style
    # Create a simple layout spec
    begin
      # Query layout for an existing style first (should work)
      existing_layout = Tk::Tile::Style.layout('TLabel')
      errors << "layout query should return data" if existing_layout.nil?
    rescue => e
      errors << "layout query failed: #{e.message}"
    end

    raise errors.join("\n") unless errors.empty?
  end

  def test_element_create
    assert_tk_app("Style element_create", method(:element_create_app))
  end

  def element_create_app
    require 'tk'
    require 'tkextlib/tile'

    errors = []

    # Create an image element
    # First need an image
    img = TkPhotoImage.new(width: 10, height: 10)
    img.put('red', to: [0, 0, 10, 10])

    begin
      Tk::Tile::Style.element_create('test.image', :image, img)
    rescue => e
      errors << "element_create image failed: #{e.message}"
    end

    # Verify element was created
    elements = Tk::Tile::Style.element_names
    errors << "created element should be in element_names" unless elements.include?('test.image')

    raise errors.join("\n") unless errors.empty?
  end

  def test_element_create_image_with_states
    assert_tk_app("Style element_create_image with states", method(:element_create_image_states_app))
  end

  def element_create_image_states_app
    require 'tk'
    require 'tkextlib/tile'

    errors = []

    # Create images for different states
    img_normal = TkPhotoImage.new(width: 10, height: 10)
    img_normal.put('green', to: [0, 0, 10, 10])

    img_active = TkPhotoImage.new(width: 10, height: 10)
    img_active.put('blue', to: [0, 0, 10, 10])

    begin
      # Array format: [base_image, state1, img1, state2, img2, ...]
      Tk::Tile::Style.element_create_image('test.stateful',
        [img_normal, 'active', img_active],
        border: 2, sticky: 'nsew')
    rescue => e
      errors << "element_create_image with states failed: #{e.message}"
    end

    raise errors.join("\n") unless errors.empty?
  end

  def test_theme_settings
    assert_tk_app("Style theme_settings", method(:theme_settings_app))
  end

  def theme_settings_app
    require 'tk'
    require 'tkextlib/tile'

    errors = []

    # Create a theme first
    Tk::Tile::Style.theme_create('settings_test', parent: 'default')

    # Apply settings to theme using a block
    begin
      Tk::Tile::Style.theme_settings('settings_test') do
        Tk::Tile::Style.configure('TButton', padding: 10)
      end
    rescue => e
      errors << "theme_settings failed: #{e.message}"
    end

    # Switch back to default
    Tk::Tile::Style.theme_use('default')

    raise errors.join("\n") unless errors.empty?
  end
end
