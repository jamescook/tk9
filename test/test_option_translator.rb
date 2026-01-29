# frozen_string_literal: true

# Tests for Tk::Tile::OptionTranslator
# Translates Tk options to Ttk equivalents (e.g., padx/pady -> padding)

require_relative 'test_helper'
require_relative 'tk_test_helper'

class TestOptionTranslator < Minitest::Test
  include TkTestHelper

  def setup
    # Load tile to get OptionTranslator
    require 'tk'
    require 'tkextlib/tile'
  end

  # Unit tests for translate_options (no Tk display needed)

  def test_translate_padx_only
    result = Tk::Tile::OptionTranslator.translate_options({ 'padx' => 5 })
    assert_equal [5, 0], result['padding']
    refute result.key?('padx')
  end

  def test_translate_pady_only
    result = Tk::Tile::OptionTranslator.translate_options({ 'pady' => 10 })
    assert_equal [0, 10], result['padding']
    refute result.key?('pady')
  end

  def test_translate_padx_and_pady
    result = Tk::Tile::OptionTranslator.translate_options({ 'padx' => 5, 'pady' => 10 })
    assert_equal [5, 10], result['padding']
    refute result.key?('padx')
    refute result.key?('pady')
  end

  def test_translate_symbol_keys
    result = Tk::Tile::OptionTranslator.translate_options({ padx: 5, pady: 10 })
    assert_equal [5, 10], result['padding']
    refute result.key?(:padx)
    refute result.key?(:pady)
  end

  def test_no_translation_when_padding_present
    result = Tk::Tile::OptionTranslator.translate_options({
      'padx' => 5,
      'pady' => 10,
      'padding' => [1, 2, 3, 4]
    })
    # padding should be preserved, padx/pady removed but not merged
    assert_equal [1, 2, 3, 4], result['padding']
  end

  def test_no_translation_when_no_pad_options
    input = { 'text' => 'hello', 'foreground' => 'blue' }
    result = Tk::Tile::OptionTranslator.translate_options(input)
    assert_equal 'hello', result['text']
    assert_equal 'blue', result['foreground']
    refute result.key?('padding')
  end

  def test_does_not_mutate_original_hash
    original = { 'padx' => 5, 'pady' => 10 }
    original_dup = original.dup
    Tk::Tile::OptionTranslator.translate_options(original)
    assert_equal original_dup, original
  end

  # Integration test with actual Ttk widget

  def test_padx_pady_translation_on_ttk_label
    assert_tk_app("OptionTranslator integration", method(:option_translator_integration_app))
  end

  def option_translator_integration_app
    require 'tk'
    require 'tkextlib/tile/tlabel'

    errors = []

    # Suppress padding translation warning for this test since we're intentionally using padx/pady
    Tk::Warnings.suppress(:"tile_padding_Tk::Tile::TLabel") do
      # Create label and configure with padx/pady (should be translated to padding)
      lbl = Tk::Tile::TLabel.new(root, text: "Test")
      lbl.configure('padx' => 5, 'pady' => 10)

      # Verify padding was set (translation worked)
      padding = lbl.cget(:padding)
      if padding.nil? || padding.to_s.empty?
        errors << "padding not set after padx/pady translation"
      end
    end

    unless errors.empty?
      raise "OptionTranslator integration test failures:\n  " + errors.join("\n  ")
    end
  end
end
