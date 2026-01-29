# frozen_string_literal: true

module Tk
  # Maps Tk dbClass names to Ruby types for value conversion.
  # Only types that need actual conversion are listed here.
  # Everything else falls back to :string (no conversion needed).
  #
  # All dbClass values found via introspection (106 total):
  # ---------------------------------------------------------
  # ActiveStyle, Anchor, Aspect, Background, BackgroundImage, Bitmap,
  # BorderWidth, Class, Colormap, Compound, Cursor, Default, Direction,
  # DisabledBackground, DisabledForeground, Font, Foreground, Format,
  # HandlePad, HandleSize, HighlightBackground, HighlightColor,
  # HighlightThickness, Image, Increment, InsertUnfocussed, InsertWidth,
  # InvalidCommand, Justify, Label, LabelAnchor, LabelWidget, Length,
  # MaxUndo, Menu, OffRelief, Offset, OpaqueResize, Orient, OverRelief,
  # Pad, PlaceHolder, PlaceholderForeground, ProxyBackground,
  # ProxyBorderWidth, ReadonlyBackground, Relief, SashPad, Screen,
  # ScrollCommand, ScrollIncrement, ScrollRegion, SelectImage, SelectMode,
  # Show, ShowHandle, SliderLength, SliderRelief, Spacing, State, TabStyle,
  # Tabs, TakeFocus, TearOff, TearOffCommand, Text, Tile, Title,
  # TristateImage, TristateValue, Type, Use, Validate, ValidateCommand,
  # Value, Values, Visual, Wrap, WrapLength
  #
  # Already mapped: AutoSeparators, BigIncrement, BlockCursor, Boolean,
  # CloseEnough, Command, Confine, Container, Digits, ExportSelection,
  # From, Height, IndicatorOn, Jump, OffTime, OnTime, RepeatDelay,
  # RepeatInterval, Resolution, SetGrid, ShowValue, TickInterval, To,
  # Underline, Undo, Variable, Width
  #
  module TypeRegistry
    MAPPINGS = {
      # TkVariable options - need to wrap in TkVariable object
      "Variable" => :tkvariable,

      # Widget reference options - convert path to widget object
      "LabelWidget" => :widget,
      "Menu" => :widget,

      # Callback options - need to register proc and return callback id
      "Command" => :callback,

      # Font options - wrap in TkFont for backwards compatibility
      "Font" => :font,

      # Boolean options - true/false <-> "1"/"0"
      "Boolean" => :boolean,
      "IndicatorOn" => :boolean,
      "ExportSelection" => :boolean,
      "SetGrid" => :boolean,
      "AutoSeparators" => :boolean,
      "BlockCursor" => :boolean,
      "Undo" => :boolean,
      "Jump" => :boolean,
      "ShowValue" => :boolean,
      "Confine" => :boolean,
      "Container" => :boolean,
      "OpaqueResize" => :boolean,
      "ShowHandle" => :boolean,
      "TearOff" => :boolean,
      # "Wrap" => :boolean,  # Ambiguous: boolean for Spinbox, enum (none/char/word) for Text

      # Numeric options
      "Int" => :integer,
      "Double" => :float,
      "RepeatDelay" => :integer,
      "RepeatInterval" => :integer,
      "Digits" => :integer,
      "From" => :float,
      "To" => :float,
      "BigIncrement" => :float,
      "Resolution" => :float,
      "TickInterval" => :float,
      "Width" => :integer,
      "Height" => :integer,
      "Underline" => :integer,
      "OffTime" => :integer,
      "OnTime" => :integer,
      "CloseEnough" => :float,
      # Sizes and spacing (pixels/units)
      "MaxUndo" => :integer,
      "HandlePad" => :integer,
      "HandleSize" => :integer,
      "SashPad" => :integer,
      "Spacing" => :integer,
      "Increment" => :float,
      "Offset" => :integer,
      "Aspect" => :integer,
      "BorderWidth" => :integer,
      "HighlightThickness" => :integer,
      "InsertWidth" => :integer,
      "Length" => :integer,
      "Pad" => :integer,
      "ProxyBorderWidth" => :integer,
      "SliderLength" => :integer,
      "WrapLength" => :integer,

      # List options - array <-> space-separated string
      "List" => :list,
      "Values" => :list,
    }.freeze

    def self.type_for(db_class)
      MAPPINGS[db_class] || :string
    end

    def self.needs_conversion?(db_class)
      MAPPINGS.key?(db_class)
    end
  end
end
