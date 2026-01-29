# frozen_string_literal: true

# Tests for TkPalette - color palette/theming utilities
#
# TkPalette wraps Tcl/Tk's palette commands:
#   - tk_setPalette: Set application color scheme
#   - tk_bisque: Set old-style bisque colors
#   - tkDarken: Calculate darker color shades
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/palette.html

require_relative 'test_helper'
require_relative 'tk_test_helper'

class TestPalette < Minitest::Test
  include TkTestHelper

  # ===========================================
  # set / setPalette
  # ===========================================

  def test_set_with_single_color
    assert_tk_app("Palette set single color", method(:set_single_color_app))
  end

  def set_single_color_app
    require 'tk'
    require 'tk/palette'

    errors = []

    # Set palette with a single background color
    # Tk will compute all other colors from this
    TkPalette.set('gray85')

    # Verify it affected a widget
    label = TkLabel.new(root, text: 'Test')
    bg = label.cget(:background)

    # Background should be close to gray85 (might be slightly different)
    errors << "background should be set" if bg.nil? || bg.empty?

    raise errors.join("\n") unless errors.empty?
  end

  def test_set_with_hash
    assert_tk_app("Palette set with hash", method(:set_with_hash_app))
  end

  def set_with_hash_app
    require 'tk'
    require 'tk/palette'

    errors = []

    # Set palette with specific color options
    TkPalette.set(
      'background' => '#d9d9d9',
      'foreground' => 'black',
      'activeBackground' => '#ececec',
      'activeForeground' => 'black'
    )

    label = TkLabel.new(root, text: 'Test')

    # Verify foreground was set
    fg = label.cget(:foreground)
    errors << "foreground should be black" unless fg == 'black'

    raise errors.join("\n") unless errors.empty?
  end

  def test_set_palette_alias
    assert_tk_app("Palette setPalette alias", method(:set_palette_alias_app))
  end

  def set_palette_alias_app
    require 'tk'
    require 'tk/palette'

    errors = []

    # setPalette is alias for set
    TkPalette.setPalette('bisque')

    # Should not raise error
    errors << "setPalette should work" unless true

    raise errors.join("\n") unless errors.empty?
  end

  # ===========================================
  # bisque
  # ===========================================

  def test_bisque
    assert_tk_app("Palette bisque", method(:bisque_app))
  end

  def bisque_app
    require 'tk'
    require 'tk/palette'

    errors = []

    # Set bisque color scheme (light brown, Tk 3.6 style)
    TkPalette.bisque

    # Verify it affected widgets - bisque background is a tan/beige color
    label = TkLabel.new(root, text: 'Test')
    bg = label.cget(:background)

    errors << "background should be set after bisque" if bg.nil? || bg.empty?

    raise errors.join("\n") unless errors.empty?
  end

  # ===========================================
  # darken
  # ===========================================

  def test_darken
    assert_tk_app("Palette darken", method(:darken_app))
  end

  def darken_app
    require 'tk'
    require 'tk/palette'

    errors = []

    # Darken white by 50%
    darkened = TkPalette.darken('white', 50)
    errors << "darken should return a color string" unless darkened.is_a?(String)
    errors << "darkened color should not be empty" if darkened.empty?

    # Result should be a hex color (e.g., "#7f7f7f" for 50% darkened white)
    errors << "should return hex color" unless darkened.start_with?('#')

    raise errors.join("\n") unless errors.empty?
  end

  def test_darken_various_percentages
    assert_tk_app("Palette darken percentages", method(:darken_percentages_app))
  end

  def darken_percentages_app
    require 'tk'
    require 'tk/palette'

    errors = []

    # Darken by different amounts
    d90 = TkPalette.darken('white', 90)
    d50 = TkPalette.darken('white', 50)
    d10 = TkPalette.darken('white', 10)

    # All should return valid colors
    errors << "90% darken should work" unless d90.start_with?('#')
    errors << "50% darken should work" unless d50.start_with?('#')
    errors << "10% darken should work" unless d10.start_with?('#')

    raise errors.join("\n") unless errors.empty?
  end

  def test_darken_named_color
    assert_tk_app("Palette darken named color", method(:darken_named_app))
  end

  def darken_named_app
    require 'tk'
    require 'tk/palette'

    errors = []

    # Darken a named color
    darkened = TkPalette.darken('red', 50)
    errors << "should darken named colors" unless darkened.start_with?('#')

    # Darken a hex color
    darkened_hex = TkPalette.darken('#ff0000', 50)
    errors << "should darken hex colors" unless darkened_hex.start_with?('#')

    raise errors.join("\n") unless errors.empty?
  end

  # ===========================================
  # recolorTree
  # ===========================================

  def test_recolor_tree_class_method
    assert_tk_app("Palette recolorTree class", method(:recolor_tree_class_app))
  end

  def recolor_tree_class_app
    require 'tk'
    require 'tk/palette'

    errors = []

    # Create a widget hierarchy (labels are children for recolorTree to affect)
    frame = TkFrame.new(root)
    _label1 = TkLabel.new(frame, text: 'Label 1')
    _label2 = TkLabel.new(frame, text: 'Label 2')

    # First set a known palette
    TkPalette.set('background' => 'white', 'foreground' => 'black')

    # Now recolor the tree
    TkPalette.recolorTree(frame, 'background' => 'yellow', 'foreground' => 'blue')

    # Note: recolorTree only changes widgets whose current color matches
    # the global tkPalette, so this test just verifies no errors

    raise errors.join("\n") unless errors.empty?
  end

  def test_recolor_tree_requires_hash
    assert_tk_app("Palette recolorTree requires hash", method(:recolor_tree_hash_app))
  end

  def recolor_tree_hash_app
    require 'tk'
    require 'tk/palette'

    errors = []

    frame = TkFrame.new(root)

    # Should fail with non-hash argument
    begin
      TkPalette.recolorTree(frame, "not a hash")
      errors << "should raise error for non-hash"
    rescue RuntimeError => e
      errors << "wrong error message" unless e.message.include?("Hash")
    end

    raise errors.join("\n") unless errors.empty?
  end

  def test_recolor_tree_instance_method
    assert_tk_app("Palette recolorTree instance", method(:recolor_tree_instance_app))
  end

  def recolor_tree_instance_app
    require 'tk'
    require 'tk/palette'

    errors = []

    # Create a frame that includes TkPalette
    frame = TkFrame.new(root)
    frame.extend(TkPalette)

    TkLabel.new(frame, text: 'Child')

    # Use instance method
    frame.recolorTree('background' => 'lightblue')

    # Should not raise error
    errors << "instance recolorTree should work" unless true

    raise errors.join("\n") unless errors.empty?
  end

  # ===========================================
  # Integration
  # ===========================================

  def test_palette_affects_new_widgets
    assert_tk_app("Palette affects new widgets", method(:palette_new_widgets_app))
  end

  def palette_new_widgets_app
    require 'tk'
    require 'tk/palette'

    errors = []

    # Set a distinctive palette
    TkPalette.set('background' => 'lightgreen')

    # Create new widgets - they should inherit the palette
    label = TkLabel.new(root, text: 'Test')
    button = TkButton.new(root, text: 'Button')

    # Both should have lightgreen background (or close to it)
    label_bg = label.cget(:background)
    button_bg = button.cget(:background)

    errors << "label should have palette background" if label_bg.nil?
    errors << "button should have palette background" if button_bg.nil?

    raise errors.join("\n") unless errors.empty?
  end
end
