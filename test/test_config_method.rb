# frozen_string_literal: true

# Unit tests for TkConfigMethod - widget configuration API
#
# Tests the public config methods:
#   - cget(slot) - get option value with type coercion
#   - cget_strict(slot) - same, ignores IGNORE_UNKNOWN flag
#   - cget_tkstring(option) - get raw Tcl string value
#   - configure(slot, value) / configure(hash) - set options
#   - configinfo(slot) / configinfo() - get full config info
#   - current_configinfo(slot) / current_configinfo() - get current values

require_relative 'test_helper'
require_relative 'tk_test_helper'

class TestConfigMethod < Minitest::Test
  include TkTestHelper

  # Test cget with various option types using a real button widget
  def test_cget_string_option
    assert_tk_app("cget should return string for text option", method(:app_cget_string_option))
  end

  def app_cget_string_option
    require 'tk'
    require 'tk/button'

    btn = TkButton.new(root, text: "Hello")
    result = btn.cget(:text)
    raise "Expected 'Hello', got #{result.inspect}" unless result == "Hello"
  end

  def test_cget_numeric_option
    assert_tk_app("cget should return number for numeric options", method(:app_cget_numeric_option))
  end

  def app_cget_numeric_option
    require 'tk'
    require 'tk/button'

    btn = TkButton.new(root, width: 20)
    result = btn.cget(:width)
    raise "Expected Integer, got #{result.class}" unless result.is_a?(Integer)
    raise "Expected 20, got #{result}" unless result == 20
  end

  def test_cget_boolean_option
    assert_tk_app("cget should return boolean for boolean options", method(:app_cget_boolean_option))
  end

  def app_cget_boolean_option
    require 'tk'
    require 'tk/checkbutton'

    cb = TkCheckButton.new(root)
    # takefocus is a boolean-ish option - just verify it doesn't raise
    cb.cget(:takefocus)
  end

  def test_cget_tkstring_returns_raw
    assert_tk_app("cget_tkstring should return raw Tcl string", method(:app_cget_tkstring_returns_raw))
  end

  def app_cget_tkstring_returns_raw
    require 'tk'
    require 'tk/button'

    btn = TkButton.new(root, width: 20)
    result = btn.cget_tkstring(:width)
    raise "Expected String, got #{result.class}" unless result.is_a?(String)
    raise "Expected '20', got #{result.inspect}" unless result == "20"
  end

  def test_cget_unknown_option_raises
    assert_tk_app("cget should raise for unknown option", method(:app_cget_unknown_option_raises))
  end

  def app_cget_unknown_option_raises
    require 'tk'
    require 'tk/button'

    btn = TkButton.new(root)
    raised = false
    begin
      btn.cget(:nonexistent_option_xyz)
    rescue
      raised = true
    end
    raise "Expected error for unknown option" unless raised
  end

  # Test dimension strings (e.g., "10c" for centimeters) round-trip correctly
  def test_canvas_dimension_string_roundtrip
    assert_tk_app("canvas width with dimension string should round-trip", method(:app_canvas_dimension_roundtrip))
  end

  def app_canvas_dimension_roundtrip
    require 'tk'
    require 'tk/canvas'

    # Configure with dimension string (centimeters)
    canvas = TkCanvas.new(root, width: "5c", height: "3c")

    # cget should return integer (pixels) - Tk converts dimensions to pixels internally
    width = canvas.cget(:width)
    height = canvas.cget(:height)

    raise "width should be Integer, got #{width.class}" unless width.is_a?(Integer)
    raise "height should be Integer, got #{height.class}" unless height.is_a?(Integer)
    raise "width should be > 0, got #{width}" unless width > 0
    raise "height should be > 0, got #{height}" unless height > 0

    # Configure with plain integer
    canvas.configure(width: 200, height: 150)
    raise "width should be 200, got #{canvas.cget(:width)}" unless canvas.cget(:width) == 200
    raise "height should be 150, got #{canvas.cget(:height)}" unless canvas.cget(:height) == 150
  end

  # Test configure
  def test_configure_single_option
    assert_tk_app("configure should set single option", method(:app_configure_single_option))
  end

  def app_configure_single_option
    require 'tk'
    require 'tk/button'

    btn = TkButton.new(root, text: "Before")

    btn.configure(:text, "After")
    result = btn.cget(:text)

    raise "Expected 'After', got #{result.inspect}" unless result == "After"
  end

  def test_configure_hash
    assert_tk_app("configure should accept hash of options", method(:app_configure_hash))
  end

  def app_configure_hash
    require 'tk'
    require 'tk/button'

    btn = TkButton.new(root)

    btn.configure(text: "New Text", width: 30)

    raise "text not set" unless btn.cget(:text) == "New Text"
    raise "width not set" unless btn.cget(:width) == 30
  end

  def test_configure_returns_self
    assert_tk_app("configure should return self for chaining", method(:app_configure_returns_self))
  end

  def app_configure_returns_self
    require 'tk'
    require 'tk/button'

    btn = TkButton.new(root)

    result = btn.configure(text: "Test")
    raise "Expected self, got #{result.class}" unless result == btn
  end

  def test_configure_optkey_alias
    assert_tk_app("configure should resolve __optkey_aliases", method(:app_configure_optkey_alias))
  end

  def app_configure_optkey_alias
    require 'tk'
    require 'tkextlib/tile/tentry'

    entry = Tk::Tile::TEntry.new(root)

    # Configure using alias :vcmd instead of :validatecommand
    # This hits __optkey_aliases.each branch in __configure_core
    # Using a simple proc name as the validation command
    entry.configure(vcmd: "myvalidator")

    # Verify it was set via the real option name
    result = entry.cget(:validatecommand)
    raise "Expected 'myvalidator', got #{result.inspect}" unless result == "myvalidator"
  end

  def test_configure_wm_shim
    assert_tk_app("configure should use wm shim for wm properties", method(:app_configure_wm_shim))
  end

  def app_configure_wm_shim
    require 'tk'

    # Configure title via hash - this hits the wm shim in Root
    # since 'title' is a wm property, not a Tk widget option
    root.configure(title: "Test Title")

    result = root.title
    raise "Expected 'Test Title', got #{result.inspect}" unless result == "Test Title"
  end

  def test_configure_ruby2val_optkeys
    assert_tk_app("configure should use __ruby2val_optkeys for value conversion", method(:app_configure_ruby2val_optkeys))
  end

  def app_configure_ruby2val_optkeys
    require 'tk'
    require 'tk/radiobutton'
    require 'tk/variable'

    var = TkVariable.new

    # TkRadioButton has __ruby2val_optkeys for 'variable' option
    # The proc calls tk_trace_variable(v) to convert the Ruby object
    rb = TkRadioButton.new(root)
    rb.configure(variable: var)

    # Should not raise - the conversion happened
  end

  # Single-slot form tests: widget.configure(:slot, value)

  def test_configure_single_slot_ruby2val
    assert_tk_app("configure(:slot, value) should use __ruby2val_optkeys", method(:app_configure_single_slot_ruby2val))
  end

  def app_configure_single_slot_ruby2val
    require 'tk'
    require 'tk/radiobutton'
    require 'tk/variable'

    var = TkVariable.new

    rb = TkRadioButton.new(root)
    # Single-slot form: configure(:variable, var) instead of configure(variable: var)
    rb.configure(:variable, var)
  end

  def test_configure_single_slot_wm_shim
    assert_tk_app("configure(:slot, value) should use wm shim for wm properties", method(:app_configure_single_slot_wm_shim))
  end

  def app_configure_single_slot_wm_shim
    require 'tk'

    # Single-slot form: configure(:title, value) instead of configure(title: value)
    root.configure(:title, "Single Slot Title")

    result = root.title
    raise "Expected 'Single Slot Title', got #{result.inspect}" unless result == "Single Slot Title"
  end

  def test_configure_single_slot_font
    assert_tk_app("configure(:font, value) should use font_configure", method(:app_configure_single_slot_font))
  end

  def app_configure_single_slot_font
    require 'tk'
    require 'tk/button'

    btn = TkButton.new(root, text: "Test")

    # Single-slot form for font option
    btn.configure(:font, "Helvetica 12")

    # Verify font was set (returns a TkFont or string)
    result = btn.cget(:font)
    raise "Font not set" if result.nil? || result.to_s.empty?
  end

  def test_configure_single_slot_regular
    assert_tk_app("configure(:slot, value) should use tk_call for regular options", method(:app_configure_single_slot_regular))
  end

  def app_configure_single_slot_regular
    require 'tk'
    require 'tk/button'

    btn = TkButton.new(root, text: "Original")

    # Single-slot form for regular option (hits the else branch)
    btn.configure(:text, "Updated")

    result = btn.cget(:text)
    raise "Expected 'Updated', got #{result.inspect}" unless result == "Updated"
  end

  # Test configinfo
  def test_configinfo_single_slot
    assert_tk_subprocess("configinfo(slot) returns array") do
      <<~RUBY
        require 'tk'
        require 'tk/button'

        root = TkRoot.new { withdraw }
        btn = TkButton.new(root, text: "Hello")

        info = btn.configinfo(:text)

        raise "Expected Array, got \#{info.class}" unless info.is_a?(Array)
        raise "Expected first element to be 'text'" unless info[0] == "text"
        raise "Expected last element to be 'Hello'" unless info[-1] == "Hello"

        root.destroy
      RUBY
    end
  end

  def test_configinfo_all
    assert_tk_subprocess("configinfo() returns array of arrays") do
      <<~RUBY
        require 'tk'
        require 'tk/button'

        root = TkRoot.new { withdraw }
        btn = TkButton.new(root)

        info = btn.configinfo

        raise "Expected Array, got \#{info.class}" unless info.is_a?(Array)
        raise "Expected non-empty array" if info.empty?
        raise "Expected array of arrays" unless info[0].is_a?(Array)
        option_names = info.map { |i| i[0] }

        raise "Missing 'text' option" unless option_names.include?("text")
        raise "Missing 'width' option" unless option_names.include?("width")

        root.destroy
      RUBY
    end
  end

  # ==========================================================================
  # Test current_configinfo
  def test_current_configinfo_single_slot
    assert_tk_subprocess("current_configinfo(slot) returns {option => value}") do
      <<~RUBY
        require 'tk'
        require 'tk/button'

        root = TkRoot.new { withdraw }
        btn = TkButton.new(root, text: "Hello")

        info = btn.current_configinfo(:text)

        raise "Expected Hash, got \#{info.class}" unless info.is_a?(Hash)
        raise "Expected {'text' => 'Hello'}, got \#{info.inspect}" unless info["text"] == "Hello"

        root.destroy
      RUBY
    end
  end

  def test_current_configinfo_all
    assert_tk_subprocess("current_configinfo() returns hash of all current values") do
      <<~RUBY
        require 'tk'
        require 'tk/button'

        root = TkRoot.new { withdraw }
        btn = TkButton.new(root, text: "Hello", width: 25)

        info = btn.current_configinfo

        raise "Expected Hash, got \#{info.class}" unless info.is_a?(Hash)
        raise "text value wrong" unless info["text"] == "Hello"
        raise "width value wrong" unless info["width"] == 25

        root.destroy
      RUBY
    end
  end

  # ==========================================================================
  # Font option tests (lines 817-837 in __configinfo_core)
  #
  # Font options get special handling. When you query configinfo(:font),
  # the code wraps the result in TkFont objects and handles system fonts.
  # The regex matches: font, latinfont, asciifont, kanjifont
  # ==========================================================================

  def test_configinfo_font_option
    assert_tk_subprocess("configinfo font tests font handling") do
      <<~RUBY
        require 'tk'
        require 'tk/button'

        root = TkRoot.new { withdraw }
        btn = TkButton.new(root, text: "Hello")

        info = btn.configinfo(:font)
        raise "Expected Array" unless info.is_a?(Array)
        raise "First element should be 'font'" unless info[0] == "font"
        current = info[-1]
        raise "Font value is nil" if current.nil?

        root.destroy
      RUBY
    end
  end

  # ==========================================================================
  # Option alias tests (lines 842-844 in __configinfo_core)
  #
  # Widgets can define shortcut names for options via __optkey_aliases.
  # Example: Ttk::TEntry defines {:vcmd => :validatecommand}
  # When you call configinfo(:vcmd), it resolves to :validatecommand.
  # ==========================================================================

  def test_configinfo_option_alias
    assert_tk_subprocess("configinfo option aliases work") do
      <<~RUBY
        require 'tk'
        require 'tkextlib/tile/tentry'

        root = TkRoot.new { withdraw }
        entry = Tk::Tile::TEntry.new(root)

        # Query using the alias - should resolve to real option
        info = entry.configinfo(:vcmd)
        raise "Expected option name 'validatecommand', got \#{info.inspect}" unless info[0] == "validatecommand"

        root.destroy
      RUBY
    end
  end

  def test_cget_option_alias
    assert_tk_app("cget should resolve option aliases", method(:app_cget_option_alias))
  end

  def app_cget_option_alias
    require 'tk'
    require 'tkextlib/tile/tentry'

    entry = Tk::Tile::TEntry.new(root)

    # Set via real name, get via alias
    entry.configure(:validatecommand, "")

    # cget using alias should work
    entry.cget(:vcmd)
    # Should not raise - alias resolved to validatecommand
  end

  # ==========================================================================
  # Tk-level option alias tests (lines 831-835 in __configinfo_core)
  #
  # Tk itself has built-in option aliases like -bd => -borderwidth.
  # When you query configinfo(:bd), Tcl returns a 2-element list:
  #   {-bd -borderwidth}
  # meaning "bd is an alias for borderwidth". The code strips the leading
  # dash from the alias target name.
  # ==========================================================================

  def test_configinfo_tk_builtin_alias_in_full_list
    assert_tk_subprocess("configinfo full list includes Tk aliases") do
      <<~RUBY
        require 'tk'
        require 'tk/button'

        root = TkRoot.new { withdraw }
        btn = TkButton.new(root)

        all_info = btn.configinfo

        # Find the 'bd' alias entry in the full list
        bd_entry = all_info.find { |entry| entry[0] == "bd" }
        raise "No 'bd' entry found" if bd_entry.nil?
        # Alias entries have 2 elements: [name, target]
        raise "Expected 2-element alias entry" unless bd_entry.size == 2
        raise "Expected 'borderwidth' as target" unless bd_entry[1] == "borderwidth"

        root.destroy
      RUBY
    end
  end

  # ==========================================================================
  # __val2ruby_optkeys tests
  #
  # Some widgets define custom value converters: { option_name => proc }
  # When cget is called, the proc transforms the raw Tcl string into a
  # Ruby object. Example: TkLabelFrame's 'labelwidget' option returns
  # the actual Ruby widget object, not just the Tk path string.
  # ==========================================================================

  def test_cget_val2ruby_labelwidget
    assert_tk_app("cget should use __val2ruby_optkeys to convert labelwidget to Ruby object", method(:app_cget_val2ruby_labelwidget))
  end

  def app_cget_val2ruby_labelwidget
    require 'tk'
    require 'tk/labelframe'
    require 'tk/label'

    # Create a label to use as the labelwidget
    lbl = TkLabel.new(root, text: "Header")

    # Create labelframe with the label as its labelwidget
    lf = TkLabelFrame.new(root, labelwidget: lbl)

    # cget(:labelwidget) should return the Ruby TkLabel object,
    # not the raw Tk path string like ".label1"
    result = lf.cget(:labelwidget)

    raise "Expected TkLabel, got #{result.class}" unless result.is_a?(TkLabel)
    raise "Expected same object" unless result == lbl
  end

  def test_configinfo_val2ruby_labelwidget
    assert_tk_subprocess("configinfo labelwidget tests __val2ruby_optkeys") do
      <<~RUBY
        require 'tk'
        require 'tk/labelframe'
        require 'tk/label'

        root = TkRoot.new { withdraw }
        lbl = TkLabel.new(root, text: "Header")
        lf = TkLabelFrame.new(root, labelwidget: lbl)

        # Test single slot
        info = lf.configinfo(:labelwidget)
        raise "Expected Array" unless info.is_a?(Array)
        raise "First element should be 'labelwidget'" unless info[0] == "labelwidget"
        current = info[-1]
        raise "Expected TkLabel, got \#{current.class}" unless current.is_a?(TkLabel)

        # Test full list
        all_info = lf.configinfo
        lw_entry = all_info.find { |e| e[0] == "labelwidget" }
        current = lw_entry[-1]
        raise "Expected TkLabel in full list" unless current.is_a?(TkLabel)

        root.destroy
      RUBY
    end
  end

  # ==========================================================================
  # WM Shim tests
  #
  # Some "options" aren't real Tk widget options - they're wm commands
  # that the wm shim in Root/Toplevel intercepts. Example: TkRoot's
  # 'title' and 'geometry' are actually wm commands, not widget options.
  # When you call cget(:title), the wm shim intercepts it and calls
  # tk_call('wm', 'title', path) directly.
  # ==========================================================================

  def test_cget_wm_shim_title
    assert_tk_app("cget(:title) should use wm shim, not query Tcl option", method(:app_cget_wm_shim_title))
  end

  def app_cget_wm_shim_title
    require 'tk'

    root.title("My Window Title")

    # cget(:title) calls self.title() which is a wm command wrapper
    result = root.cget(:title)

    raise "Expected 'My Window Title', got #{result.inspect}" unless result == "My Window Title"
  end

  def test_cget_wm_shim_geometry
    assert_tk_app("cget(:geometry) should use wm shim", method(:app_cget_wm_shim_geometry))
  end

  def app_cget_wm_shim_geometry
    require 'tk'

    root.deiconify
    root.geometry("400x300+100+50")

    # Wait for geometry to settle (CI may need time)
    wait_for_display.call("true", timeout: 2.0) {
      Tk.update
      root.winfo_width > 0 && root.winfo_height > 0
    }

    result = root.cget(:geometry)

    # Result should be a geometry string like "400x300+100+50"
    raise "Expected geometry string with positive dimensions, got #{result.inspect}" unless result =~ /\d+x\d+/
  end

  def test_configinfo_wm_shim_title
    assert_tk_subprocess("configinfo title tests wm shim") do
      <<~RUBY
        require 'tk'

        root = TkRoot.new { withdraw }
        root.title("Test Window")

        # Test single slot
        info = root.configinfo(:title)
        raise "Expected Array" unless info.is_a?(Array)
        raise "First element should be 'title'" unless info[0] == "title"
        current = info[-1]
        raise "Expected 'Test Window'" unless current == "Test Window"

        root.destroy
      RUBY
    end
  end

  # ==========================================================================
  # __numval_optkeys tests
  #
  # Widgets can declare options that should always be converted to numbers.
  # The base TkConfigMethod returns [] but widgets override this.
  # Example: TkCanvas adds 'closeenough' - a floating point threshold for
  # how close a click must be to a canvas item to select it.
  # ==========================================================================

  def test_cget_numval_closeenough
    assert_tk_app("cget should convert __numval_optkeys to numbers (canvas closeenough)", method(:app_cget_numval_closeenough))
  end

  def app_cget_numval_closeenough
    require 'tk'
    require 'tk/canvas'

    canvas = TkCanvas.new(root, closeenough: 2.5)

    result = canvas.cget(:closeenough)

    raise "Expected Numeric, got #{result.class}" unless result.is_a?(Numeric)
    raise "Expected 2.5, got #{result}" unless result == 2.5
  end

  def test_configinfo_numval_closeenough
    assert_tk_subprocess("configinfo closeenough tests __numval_optkeys") do
      <<~RUBY
        require 'tk'
        require 'tk/canvas'

        root = TkRoot.new { withdraw }
        canvas = TkCanvas.new(root, closeenough: 3.5)

        # Test single slot
        info = canvas.configinfo(:closeenough)
        raise "Expected Array" unless info.is_a?(Array)
        raise "First element should be 'closeenough'" unless info[0] == "closeenough"
        current = info[-1]
        raise "Expected Numeric, got \#{current.class}" unless current.is_a?(Numeric)
        raise "Expected 3.5" unless current == 3.5

        # Test full list
        all_info = canvas.configinfo
        ce_entry = all_info.find { |entry| entry[0] == "closeenough" }
        current = ce_entry[-1]
        raise "Expected Numeric in full list" unless current.is_a?(Numeric)

        root.destroy
      RUBY
    end
  end

  # ==========================================================================
  # __boolval_optkeys tests
  #
  # Options listed in __boolval_optkeys are converted to true/false.
  # Base class includes: 'exportselection', 'jump', 'setgrid', 'takefocus'
  # Widgets can add more (e.g., TkCanvas adds 'confine').
  # ==========================================================================

  def test_cget_boolval_confine
    assert_tk_app("cget should convert __boolval_optkeys to boolean (canvas confine)", method(:app_cget_boolval_confine))
  end

  def app_cget_boolval_confine
    require 'tk'
    require 'tk/canvas'

    canvas = TkCanvas.new(root, confine: true)

    result = canvas.cget(:confine)

    # Should be boolean true, not string "1" or integer 1
    raise "Expected true, got #{result.inspect}" unless result == true

    canvas.configure(confine: false)
    result = canvas.cget(:confine)
    raise "Expected false, got #{result.inspect}" unless result == false
  end

  def test_configinfo_boolval_confine
    assert_tk_subprocess("configinfo confine tests __boolval_optkeys") do
      <<~RUBY
        require 'tk'
        require 'tk/canvas'

        root = TkRoot.new { withdraw }
        canvas = TkCanvas.new(root, confine: true)

        # Test single slot
        info = canvas.configinfo(:confine)
        raise "Expected Array" unless info.is_a?(Array)
        raise "First element should be 'confine'" unless info[0] == "confine"
        current = info[-1]
        raise "Expected true, got \#{current.inspect}" unless current == true

        # Test full list
        all_info = canvas.configinfo
        cf_entry = all_info.find { |entry| entry[0] == "confine" }
        current = cf_entry[-1]
        raise "Expected boolean in full list" unless current == true

        root.destroy
      RUBY
    end
  end

  # ==========================================================================
  # __tkvariable_optkeys tests
  #
  # Options like 'variable' and 'textvariable' store Tcl variable names.
  # When retrieved via cget, they're wrapped in TkVarAccess objects so
  # you can read/write the variable from Ruby.
  # ==========================================================================

  def test_cget_tkvariable_textvariable
    assert_tk_app("cget should wrap __tkvariable_optkeys in TkVarAccess", method(:app_cget_tkvariable_textvariable))
  end

  def app_cget_tkvariable_textvariable
    require 'tk'
    require 'tk/entry'
    require 'tk/variable'

    # Create a TkVariable and bind it to an entry
    var = TkVariable.new("initial value")
    entry = TkEntry.new(root, textvariable: var)

    # cget(:textvariable) should return a TkVarAccess (or similar)
    result = entry.cget(:textvariable)

    raise "Expected truthy result, got nil" if result.nil?
    # The result should let us access the variable's value
    raise "Variable access failed" unless result.value == "initial value"
  end

  def test_configinfo_tkvariable_textvariable
    assert_tk_subprocess("configinfo textvariable tests __tkvariable_optkeys") do
      <<~RUBY
        require 'tk'
        require 'tk/entry'
        require 'tk/variable'

        root = TkRoot.new { withdraw }
        var = TkVariable.new("test value")
        entry = TkEntry.new(root, textvariable: var)

        # Test single slot
        info = entry.configinfo(:textvariable)
        raise "Expected Array" unless info.is_a?(Array)
        raise "First element should be 'textvariable'" unless info[0] == "textvariable"
        current = info[-1]
        raise "Expected TkVariable, got nil" if current.nil?
        raise "Variable access failed" unless current.value == "test value"

        # Test full list
        all_info = entry.configinfo
        tv_entry = all_info.find { |e| e[0] == "textvariable" }
        current = tv_entry[-1]
        raise "Expected TkVariable in full list" if current.nil?

        root.destroy
      RUBY
    end
  end

  def test_tkvariable_accepts_string_or_tkvariable
    assert_tk_app("tkvariable options accept both string and TkVariable", method(:app_tkvariable_accepts_string_or_tkvariable))
  end

  def app_tkvariable_accepts_string_or_tkvariable
    require 'tk'
    require 'tk/entry'
    require 'tk/variable'

    # Test 1: Pass a TkVariable instance
    var = TkVariable.new("from_tkvariable")
    entry1 = TkEntry.new(root, textvariable: var)
    result1 = entry1.cget(:textvariable)
    raise "Expected TkVariable result" unless result1.respond_to?(:value)
    raise "Expected 'from_tkvariable', got '#{result1.value}'" unless result1.value == "from_tkvariable"

    # Test 2: Pass a raw string (Tcl variable name)
    # First set up a Tcl variable with a value
    Tk.ip_eval('set my_tcl_var "from_string"')
    entry2 = TkEntry.new(root, textvariable: "my_tcl_var")
    result2 = entry2.cget(:textvariable)
    raise "Expected TkVarAccess result" unless result2.respond_to?(:value)
    raise "Expected 'from_string', got '#{result2.value}'" unless result2.value == "from_string"

    # Test 3: Verify the returned object works for both cases
    result1.value = "updated1"
    raise "TkVariable update failed" unless entry1.get == "updated1"

    result2.value = "updated2"
    raise "String var update failed" unless entry2.get == "updated2"
  end

  # ==========================================================================
  # __strval_optkeys tests
  #
  # Options in __strval_optkeys are ensured to return as strings.
  # Base class has: 'text', 'label', 'show', 'data', 'file', various colors...
  # ==========================================================================

  def test_configinfo_strval_text
    assert_tk_subprocess("configinfo text tests __strval_optkeys") do
      <<~RUBY
        require 'tk'
        require 'tk/button'

        root = TkRoot.new { withdraw }
        btn = TkButton.new(root, text: "Hello World")

        # Test single slot
        info = btn.configinfo(:text)
        raise "Expected Array" unless info.is_a?(Array)
        raise "First element should be 'text'" unless info[0] == "text"
        current = info[-1]
        raise "Expected String" unless current.is_a?(String)
        raise "Expected 'Hello World'" unless current == "Hello World"

        # Test full list
        all_info = btn.configinfo
        text_entry = all_info.find { |e| e[0] == "text" }
        current = text_entry[-1]
        raise "Expected String in full list" unless current.is_a?(String)

        root.destroy
      RUBY
    end
  end

  # ==========================================================================
  # __listval_optkeys tests
  #
  # Options that return Tcl lists are converted to Ruby arrays.
  # TkSpinbox has 'values' which is a list option.
  # ==========================================================================

  def test_cget_listval_values
    assert_tk_app("cget(:values) should convert to Ruby array (spinbox values)", method(:app_cget_listval_values))
  end

  def app_cget_listval_values
    require 'tk'
    require 'tk/spinbox'

    spinbox = TkSpinbox.new(root, values: ["one", "two", "three"])

    result = spinbox.cget(:values)

    raise "Expected Array, got #{result.class}" unless result.is_a?(Array)
    raise "Expected 3 values, got #{result.size}" unless result.size == 3
    raise "Expected ['one', 'two', 'three']" unless result == ["one", "two", "three"]
  end

  def test_configinfo_listval_values
    assert_tk_subprocess("configinfo values tests __listval_optkeys") do
      <<~RUBY
        require 'tk'
        require 'tk/spinbox'

        root = TkRoot.new { withdraw }
        spinbox = TkSpinbox.new(root, values: ["a", "b", "c"])

        # Test single slot
        info = spinbox.configinfo(:values)
        raise "Expected Array" unless info.is_a?(Array)
        raise "First element should be 'values'" unless info[0] == "values"
        current = info[-1]
        raise "Expected Array value" unless current.is_a?(Array)
        raise "Expected ['a', 'b', 'c']" unless current == ["a", "b", "c"]

        # Test full list
        all_info = spinbox.configinfo
        vals_entry = all_info.find { |e| e[0] == "values" }
        current = vals_entry[-1]
        raise "Expected Array in full list" unless current.is_a?(Array)

        root.destroy
      RUBY
    end
  end

  # ==========================================================================
  # __numlistval_optkeys tests
  #
  # Options that return lists of numbers. Base class returns [].
  # Only extensions like tcllib/iwidgets override this - extension-only.
  # ==========================================================================

  # (Extension-only - no core Tk widgets use __numlistval_optkeys)

  # ==========================================================================
  # Original edge case tests
  # ==========================================================================

  # Test type coercion edge cases
  def test_cget_state_option
    assert_tk_app("cget should handle state option", method(:app_cget_state_option))
  end

  def app_cget_state_option
    require 'tk'
    require 'tk/button'

    btn = TkButton.new(root)

    # Default state should be normal
    state = btn.cget(:state)
    raise "Expected 'normal', got #{state.inspect}" unless state == "normal"

    btn.configure(state: "disabled")
    state = btn.cget(:state)
    raise "Expected 'disabled', got #{state.inspect}" unless state == "disabled"
  end

  # ==========================================================================
  # Canvas item coords tests
  #
  # Canvas items have a coords method/setter that is NOT a config option.
  # It uses the canvas 'coords' command, not 'itemconfigure'.
  # ==========================================================================

  def test_canvas_item_coords_setter
    assert_tk_app("canvas item coords= setter", method(:app_canvas_item_coords_setter))
  end

  def app_canvas_item_coords_setter
    require 'tk'
    require 'tk/canvas'

    canvas = TkCanvas.new(root)

    # Create a polygon with initial coords
    poly = TkcPolygon.new(canvas, [0, 0], [10, 0], [10, 10], [0, 10])

    # Get initial coords
    initial = poly.coords
    raise "coords should return Array, got #{initial.class}" unless initial.is_a?(Array)
    raise "Expected 8 values (4 points), got #{initial.size}" unless initial.size == 8

    # Set new coords using coords= setter
    new_coords = [[100, 100], [200, 100], [200, 200], [100, 200]]
    poly.coords = new_coords

    # Verify coords changed
    updated = poly.coords
    raise "First x should be 100, got #{updated[0]}" unless updated[0] == 100
    raise "First y should be 100, got #{updated[1]}" unless updated[1] == 100
    raise "Third x should be 200, got #{updated[4]}" unless updated[4] == 200
  end
end
