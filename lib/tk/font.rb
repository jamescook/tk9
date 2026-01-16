# frozen_string_literal: true
#
# tk/font.rb - TkFont compatibility shim
#
# TkFont was removed in earlier refactoring. This shim provides backward
# compatibility for code that uses TkFont.new('fontspec') by simply
# storing and returning the font string.
#
# In modern Tk, you can just pass font strings directly to widgets:
#   TkLabel.new(root, font: 'Helvetica 12 bold')
#
require 'tk' unless defined?(Tk)

class TkFont
  @deprecation_warned = false

  def self.warn_deprecation
    return if @deprecation_warned
    warn "TkFont is deprecated. Use font strings directly, e.g., 'Helvetica 12 bold'", uplevel: 3
    @deprecation_warned = true
  end

  # TkFont.new('Helvetica 12') or TkFont.new(family: 'Helvetica', size: 12)
  def initialize(font_spec = nil, fallback = nil, **opts)
    TkFont.warn_deprecation

    if font_spec.is_a?(Hash)
      opts = font_spec
      font_spec = nil
    end

    if opts.any?
      # Convert hash options to font string: {family: 'Helvetica', size: 12} -> 'Helvetica 12'
      parts = []
      parts << opts[:family] if opts[:family]
      parts << opts[:size].to_s if opts[:size]
      parts << opts[:weight].to_s if opts[:weight]
      parts << opts[:slant].to_s if opts[:slant]
      @font = parts.join(' ')
    else
      @font = font_spec.to_s
    end

    # Store fallback for Japanese font support (ignored in modern Tk)
    @fallback = fallback
  end

  def to_s
    @font
  end

  def to_str
    @font
  end

  # Allow TkFont to be used directly where strings are expected
  def to_eval
    @font
  end

  # Font modifier methods - return new TkFont with modified attributes
  # Uses Tcl's font system to properly derive fonts from named fonts like TkDefaultFont
  def weight(w)
    TkFont.new(_derive_font('-weight', w))
  end

  def slant(s)
    TkFont.new(_derive_font('-slant', s))
  end

  def size(s)
    TkFont.new(_derive_font('-size', s))
  end

  private

  # Derive a new font spec by getting actual font attributes and modifying one
  def _derive_font(option, value)
    actual = Tk.tk_call('font', 'actual', @font)
    attrs = Hash[*TkCore::INTERP._split_tklist(actual)]
    attrs[option] = value.to_s
    "{#{attrs['-family']} #{attrs['-size']} #{attrs['-weight']} #{attrs['-slant']}}"
  end

  public

  # TkFont.families - list available font families
  def self.families
    warn_deprecation
    Tk.tk_call('font', 'families').split
  end

  # TkFont.measure(font, text) - measure text width in pixels
  def self.measure(font, text)
    warn_deprecation
    font_str = font.respond_to?(:to_str) ? font.to_str : font.to_s
    Tk.tk_call('font', 'measure', font_str, text).to_i
  end

  # TkFont.metrics(font, option) - get font metrics
  def self.metrics(font, option = nil)
    warn_deprecation
    font_str = font.respond_to?(:to_str) ? font.to_str : font.to_s
    if option
      Tk.tk_call('font', 'metrics', font_str, "-#{option}").to_i
    else
      result = {}
      Tk.tk_call('font', 'metrics', font_str).split.each_slice(2) do |k, v|
        result[k.sub(/^-/, '').to_sym] = v.to_i
      end
      result
    end
  end
end
