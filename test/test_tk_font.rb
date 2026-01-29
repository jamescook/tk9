# frozen_string_literal: true

# Tests for TkFont

require_relative 'test_helper'
require_relative 'tk_test_helper'

class TestTkFont < Minitest::Test
  include TkTestHelper

  def test_font_new_with_string
    assert_tk_app("TkFont.new with string", method(:app_font_new_string))
  end

  def app_font_new_string
    require 'tk'

    font = TkFont.new('Helvetica 12 bold')

    # TkFont now creates named Tcl fonts, so to_s returns the font name
    raise "to_s should return font name" unless font.to_s.start_with?('rbfont')
    raise "to_str should return font name" unless font.to_str.start_with?('rbfont')

    # Verify the font has a family (Tk may substitute if Helvetica unavailable)
    raise "family should not be empty" if font.family.to_s.empty?
  end

  def test_font_new_with_hash
    assert_tk_app("TkFont.new with hash options", method(:app_font_new_hash))
  end

  def app_font_new_hash
    require 'tk'

    font = TkFont.new(family: 'Helvetica', size: 14, weight: 'bold')

    # TkFont creates named Tcl fonts
    raise "font should be named" unless font.to_s.start_with?('rbfont')
    raise "family incorrect" unless font.family == 'Helvetica'
    raise "size incorrect" unless font.actual_size == 14
  end

  def test_font_families
    assert_tk_app("TkFont.families", method(:app_font_families))
  end

  def app_font_families
    require 'tk'

    families = TkFont.families

    raise "families should return array" unless families.is_a?(Array)
    raise "families should not be empty" if families.empty?
  end

  def test_font_measure
    assert_tk_app("TkFont.measure", method(:app_font_measure))
  end

  def app_font_measure
    require 'tk'

    width = TkFont.measure('Helvetica 12', 'Hello World')

    raise "measure should return integer" unless width.is_a?(Integer)
    raise "measure should be positive" unless width > 0
  end

  def test_font_used_in_widget
    assert_tk_app("TkFont used in widget configure", method(:app_font_in_widget))
  end

  def app_font_in_widget
    require 'tk'

    font = TkFont.new('Courier 10')
    label = TkLabel.new(root, text: 'Test', font: font)

    # Should work - TkFont has to_str so it converts to string
    configured_font = label.cget(:font)
    raise "font not configured" if configured_font.nil? || configured_font.to_s.empty?
  end

  def test_font_defaults_to_tkdefaultfont
    assert_tk_app("TkFont defaults to TkDefaultFont", method(:app_font_default_family))
  end

  def app_font_default_family
    require 'tk'

    # When only size is specified, should default to TkDefaultFont
    font = TkFont.new(size: -24)

    # Verify it actually works in a widget (doesn't raise Tcl error)
    label = TkLabel.new(root, text: 'Test', font: font)
    configured_font = label.cget(:font)
    raise "font not configured" if configured_font.nil? || configured_font.to_s.empty?
  end

  def test_font_setters
    assert_tk_app("TkFont attribute setters", method(:app_font_setters))
  end

  def app_font_setters
    require 'tk'

    font = TkFont.new(family: 'Helvetica', size: 12)
    TkLabel.new(root, text: 'Test', font: font)

    # Change family - should update the widget automatically
    font.family = 'Courier'
    raise "family setter failed" unless font.family == 'Courier'

    # Change size
    font.size = 18
    raise "size setter failed" unless font.actual_size == 18

    # Change weight
    font.weight = 'bold'

    # Change slant
    font.slant = 'italic'
  end

  def test_font_creates_tcl_font
    assert_tk_app("TkFont creates named Tcl font", method(:app_font_tcl_font))
  end

  def app_font_tcl_font
    require 'tk'

    font = TkFont.new(family: 'Helvetica', size: 14)

    # The font name should be usable in Tcl
    font_name = font.to_s
    raise "font name should start with rbfont" unless font_name.start_with?('rbfont')

    # Should be able to query the font
    families = Tk.tk_call('font', 'names')
    raise "font should exist in Tcl" unless families.include?(font_name)
  end

  def test_font_registry_returns_same_object
    assert_tk_app("TkFont registry returns same object", method(:app_font_registry))
  end

  def app_font_registry
    require 'tk'

    font = TkFont.new(family: 'Courier', size: 12)
    font_name = font.to_s

    # id2obj should return the same object
    looked_up = TkFont.id2obj(font_name)
    raise "id2obj should return same object" unless looked_up.equal?(font)

    # Unknown font should return nil
    raise "id2obj for unknown should be nil" unless TkFont.id2obj('nonexistent').nil?
  end

  def test_font_cget_returns_same_object
    assert_tk_app("widget.cget(:font) returns same TkFont", method(:app_font_cget_same))
  end

  def app_font_cget_same
    require 'tk'

    font = TkFont.new(family: 'Helvetica', size: 16)
    label = TkLabel.new(root, text: 'Test', font: font)

    # cget should return the same TkFont object
    retrieved = label.cget(:font)
    raise "cget(:font) should return TkFont" unless retrieved.is_a?(TkFont)
    raise "cget(:font) should return same object" unless retrieved.equal?(font)
  end

  def test_font_setter_updates_widget
    assert_tk_app("font setter updates widget automatically", method(:app_font_setter_updates))
  end

  def app_font_setter_updates
    require 'tk'

    font = TkFont.new(family: 'Helvetica', size: 12)
    label = TkLabel.new(root, text: 'Test', font: font)

    # Change the font family via setter
    font.family = 'Courier'

    # The label should now have Courier (Tcl named fonts auto-update)
    retrieved = label.cget(:font)
    raise "font should still be same object" unless retrieved.equal?(font)
    raise "family should be Courier" unless retrieved.family == 'Courier'
  end

  # Test the widget.font.family = value pattern (used by toolbar demo)
  def test_widget_font_accessor_mutation
    assert_tk_app("widget.font.family = value pattern", method(:app_widget_font_accessor))
  end

  def app_widget_font_accessor
    require 'tk'

    # Create a text widget (like toolbar demo uses)
    text = Tk::Text.new(root, width: 40, height: 10)

    # Get font via widget.font accessor (method_missing -> cget)
    font = text.font
    raise "text.font should return TkFont" unless font.is_a?(TkFont)

    # Mutate font via accessor - this is the toolbar demo pattern
    text.font.family = 'Courier'

    # Verify the change took effect
    raise "family should be Courier" unless text.font.family == 'Courier'

    # Change size too
    text.font.size = 18
    raise "size should be 18" unless text.font.actual_size == 18
  end

  # Test that multiple widgets sharing a font all update when font changes
  def test_shared_font_updates_all_widgets
    assert_tk_app("shared font updates all widgets", method(:app_shared_font))
  end

  def app_shared_font
    require 'tk'

    font = TkFont.new(family: 'Helvetica', size: 12)
    label1 = TkLabel.new(root, text: 'Label 1', font: font)
    label2 = TkLabel.new(root, text: 'Label 2', font: font)

    # Change font - both widgets should see the change
    font.family = 'Courier'

    # Both widgets should report the new family
    raise "label1 font family should be Courier" unless label1.cget(:font).family == 'Courier'
    raise "label2 font family should be Courier" unless label2.cget(:font).family == 'Courier'

    # And they should all reference the same TkFont object
    raise "label1 and label2 should share same font" unless label1.cget(:font).equal?(label2.cget(:font))
  end

  # Test deriving a font with modified attributes (viewIcons.rb pattern)
  def test_font_derive_with_options
    assert_tk_app("TkFont.new(base_font, :weight=>:bold)", method(:app_font_derive))
  end

  def app_font_derive
    require 'tk'

    # Create base font
    base = TkFont.new(family: 'Courier', size: 12, weight: 'normal')
    base_size = base.actual_size

    # Derive bold version (pattern from viewIcons.rb)
    bold = TkFont.new(base, :weight => :bold)

    # Bold font should inherit size from base
    raise "derived font should inherit size" unless bold.actual_size == base_size
    # And should have a non-empty family (whatever Tk resolved it to)
    raise "derived font should have family" unless bold.family && !bold.family.empty?

    # Also test deriving from widget.font
    label = TkLabel.new(root, text: 'Test', font: base)
    widget_font = label.font
    derived = TkFont.new(widget_font, :size => 18)

    raise "derived from widget.font should work" unless derived.actual_size == 18
  end
end
