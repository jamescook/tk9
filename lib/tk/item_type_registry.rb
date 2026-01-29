# frozen_string_literal: true

module Tk
  # Maps item option names to Ruby types for value conversion.
  # Unlike widget options, item options (canvas items, menu entries, etc.)
  # don't expose db_class in their configure output, so we map by name.
  #
  # Only types that need actual conversion are listed here.
  # Everything else falls back to :string (no conversion needed).
  #
  module ItemTypeRegistry
    MAPPINGS = {
      # Boolean options
      "smooth" => :boolean,
      "columnbreak" => :boolean,
      "hidemargin" => :boolean,
      "indicatoron" => :boolean,

      # Integer options
      "underline" => :integer,
      "splinesteps" => :integer,

      # Float options
      "extent" => :float,
      "start" => :float,
      "angle" => :float,
      "width" => :float,
      "activewidth" => :float,
      "disabledwidth" => :float,

      # Callback options
      "command" => :callback,

      # TkVariable options
      "variable" => :tkvariable,

      # Widget reference options
      "menu" => :widget,
      "window" => :widget,
    }.freeze

    # Known item options that should exist but may not be returned by
    # introspection on some Tcl versions (e.g., 8.6 menu entryconfigure
    # only returns 2 options in headless/xvfb environments).
    #
    # Format: { widget_type => [option_names] }
    # These get merged with introspected options during generation.
    KNOWN_OPTIONS = {
      menu: %w[
        accelerator activebackground activeforeground background bitmap
        columnbreak command compound font foreground hidemargin image
        indicatoron label menu offvalue onvalue selectcolor selectimage
        state underline value variable
      ].freeze,
    }.freeze

    # Ruby-side convenience aliases (not in Tk itself).
    # These provide friendlier names that Ruby/Tk users expect.
    # Format: { "canonical_option" => ["alias1", "alias2", ...] }
    RUBY_ALIASES = {
      "tags" => ["tag"],  # Canvas items use -tags (plural)
    }.freeze

    # Widget-specific type overrides.
    # Some options need different types depending on the widget context.
    # Format: { widget_type => { "option_name" => :type } }
    WIDGET_TYPE_OVERRIDES = {
      canvas: {
        "tags" => :canvas_tags,  # Returns TkcTag objects
      },
    }.freeze

    def self.type_for(option_name, widget_type: nil)
      # Check widget-specific override first
      if widget_type && WIDGET_TYPE_OVERRIDES[widget_type]
        override = WIDGET_TYPE_OVERRIDES[widget_type][option_name.to_s]
        return override if override
      end
      MAPPINGS[option_name.to_s] || :string
    end

    def self.needs_conversion?(option_name)
      MAPPINGS.key?(option_name.to_s)
    end

    def self.known_options_for(widget_type)
      KNOWN_OPTIONS[widget_type] || []
    end

    def self.ruby_aliases_for(option_name)
      RUBY_ALIASES[option_name.to_s] || []
    end
  end
end
