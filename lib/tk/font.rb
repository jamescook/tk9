# frozen_string_literal: true
#
# tk/font.rb - TkFont class for creating and manipulating fonts
#
# TkFont creates named Tcl fonts that can be modified after creation.
# Changes to a TkFont automatically propagate to all widgets using it.
#
# Usage:
#   font = TkFont.new('Helvetica 12 bold')
#   font = TkFont.new(family: 'Courier', size: 14)
#   label = TkLabel.new(root, font: font)
#
#   # Modify font - widget updates automatically
#   font.family = 'Times'
#   font.size = 18
#
#   # Or via widget.font accessor:
#   label.font.family = 'Arial'
#
require 'tk'

class TkFont
  @font_id = 0
  @font_id_mutex = Mutex.new
  @registry = {}
  @registry_mutex = Mutex.new

  def self.next_font_id
    @font_id_mutex.synchronize { @font_id += 1 }
  end

  # Registry for looking up TkFont objects by their Tcl font name
  def self.register(name, font)
    @registry_mutex.synchronize { @registry[name] = font }
  end

  def self.id2obj(name)
    @registry_mutex.synchronize { @registry[name] }
  end

  # TkFont.new('Helvetica 12') or TkFont.new(family: 'Helvetica', size: 12)
  # widget: optional source widget for auto-reconfigure on setter calls
  def initialize(font_spec = nil, fallback = nil, widget: nil, **opts)
    if font_spec.is_a?(Hash)
      opts = font_spec
      font_spec = nil
    end

    # Track source widget so setters can reconfigure it
    @source_widget = widget

    # Create a named Tcl font so we can modify it later
    @tcl_font_name = "rbfont#{TkFont.next_font_id}"

    # Determine base font to derive from
    base_font = if font_spec && !font_spec.to_s.empty?
                  font_spec.to_s
                else
                  'TkDefaultFont'
                end

    if opts.any?
      # Get actual attributes of base font, then override with opts
      actual = Tk.tk_call('font', 'actual', base_font)
      attrs = Hash[*TkCore::INTERP._split_tklist(actual)]

      # Override with provided options
      attrs['-family'] = opts[:family].to_s if opts[:family]
      attrs['-size'] = opts[:size].to_s if opts[:size]
      attrs['-weight'] = opts[:weight].to_s if opts[:weight]
      attrs['-slant'] = opts[:slant].to_s if opts[:slant]
      attrs['-underline'] = (opts[:underline] ? '1' : '0') if opts.key?(:underline)
      attrs['-overstrike'] = (opts[:overstrike] ? '1' : '0') if opts.key?(:overstrike)

      create_opts = attrs.to_a.flatten
      Tk.tk_call('font', 'create', @tcl_font_name, *create_opts)
    else
      # Create named font from base font spec
      actual = Tk.tk_call('font', 'actual', base_font)
      Tk.tk_call('font', 'create', @tcl_font_name, *TkCore::INTERP._split_tklist(actual))
    end

    @font = @tcl_font_name

    # Register in lookup table so cget(:font) can return this same object
    TkFont.register(@tcl_font_name, self)

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

  # Attribute setters - modify the underlying Tcl font and reconfigure source widget
  def family=(value)
    Tk.tk_call('font', 'configure', @tcl_font_name, '-family', value)
    _reconfigure_source_widget
  end

  def size=(value)
    Tk.tk_call('font', 'configure', @tcl_font_name, '-size', value)
    _reconfigure_source_widget
  end

  def weight=(value)
    Tk.tk_call('font', 'configure', @tcl_font_name, '-weight', value)
    _reconfigure_source_widget
  end

  def slant=(value)
    Tk.tk_call('font', 'configure', @tcl_font_name, '-slant', value)
    _reconfigure_source_widget
  end

  def underline=(value)
    Tk.tk_call('font', 'configure', @tcl_font_name, '-underline', value ? '1' : '0')
    _reconfigure_source_widget
  end

  def overstrike=(value)
    Tk.tk_call('font', 'configure', @tcl_font_name, '-overstrike', value ? '1' : '0')
    _reconfigure_source_widget
  end

  # Attribute getters
  def family
    Tk.tk_call('font', 'configure', @tcl_font_name, '-family')
  end

  def actual_size
    Tk.tk_call('font', 'configure', @tcl_font_name, '-size').to_i
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

  # Reconfigure the source widget to use this font (needed when wrapping existing fonts)
  def _reconfigure_source_widget
    return unless @source_widget
    @source_widget.apply_font(@tcl_font_name)
  end

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
    TkCore::INTERP._split_tklist(Tk.tk_call('font', 'families'))
  end

  # TkFont.measure(font, text) - measure text width in pixels
  def self.measure(font, text)
    font_str = font.respond_to?(:to_str) ? font.to_str : font.to_s
    Tk.tk_call('font', 'measure', font_str, text).to_i
  end

  # TkFont.metrics(font, option) - get font metrics
  def self.metrics(font, option = nil)
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
