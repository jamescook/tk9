# frozen_string_literal: true

# Comprehensive test for Tk::Tile::TEntry widget options.
# Runs in a single subprocess to minimize overhead.
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/ttk_entry.html

require_relative '../../test_helper'
require_relative '../../tk_test_helper'

class TestTEntryWidget < Minitest::Test
  include TkTestHelper

  def test_tentry_comprehensive
    assert_tk_app("TEntry widget comprehensive test", method(:tentry_app))
  end

  def tentry_app
    require 'tk'
    require 'tkextlib/tile'

    errors = []

    frame = Tk::Tile::TFrame.new(root, padding: 20)
    frame.pack(fill: "both", expand: true)

    # --- Basic entry ---
    entry = Tk::Tile::TEntry.new(frame, width: 30)
    entry.pack(pady: 10)

    errors << "width failed" unless entry.cget(:width).to_i == 30

    # --- Insert and get text ---
    entry.insert(0, "Hello World")
    errors << "insert/get failed" unless entry.get == "Hello World"

    # --- Delete text ---
    entry.delete(0, 5)
    errors << "delete failed" unless entry.get == " World"

    entry.delete(0, "end")
    errors << "delete all failed" unless entry.get == ""

    # --- Show (password masking) ---
    password_entry = Tk::Tile::TEntry.new(frame, show: "*", width: 20)
    password_entry.pack(pady: 5)

    errors << "show failed" unless password_entry.cget(:show) == "*"

    password_entry.insert(0, "secret")
    errors << "password insert failed" unless password_entry.get == "secret"

    # --- Justify ---
    entry.configure(justify: "center")
    errors << "justify failed" unless entry.cget(:justify) == "center"

    # --- State ---
    entry.configure(state: "disabled")
    errors << "disabled state failed" unless entry.cget(:state) == "disabled"

    entry.configure(state: "readonly")
    errors << "readonly state failed" unless entry.cget(:state) == "readonly"

    entry.configure(state: "normal")
    errors << "normal state failed" unless entry.cget(:state) == "normal"

    # --- Validate command aliases (vcmd/invcmd) ---
    # Just verify they're configurable (actual validation requires callback setup)
    entry.configure(validate: "key")
    errors << "validate failed" unless entry.cget(:validate) == "key"

    # --- Style (ttk-specific) ---
    original_style = entry.cget(:style)
    errors << "style cget failed" if original_style.nil?

    # --- Placeholder (Tk 9.0+ only) ---
    if Tk::TK_MAJOR_VERSION >= 9
      entry.configure(placeholder: "Enter text here...")
      errors << "placeholder failed on Tk 9+" unless entry.cget(:placeholder) == "Enter text here..."
    end

    # --- Multiple entries ---
    Tk::Tile::TLabel.new(frame, text: "Username:").pack(anchor: "w")
    username = Tk::Tile::TEntry.new(frame, width: 25)
    username.pack(fill: "x", pady: 2)

    Tk::Tile::TLabel.new(frame, text: "Password:").pack(anchor: "w")
    password = Tk::Tile::TEntry.new(frame, width: 25, show: "*")
    password.pack(fill: "x", pady: 2)

    errors << "username width failed" unless username.cget(:width).to_i == 25
    errors << "password show failed" unless password.cget(:show) == "*"

    raise "TEntry test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
