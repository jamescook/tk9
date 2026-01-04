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
    assert_tk_test("cget should return string for text option") do
      <<~RUBY
        require 'tk'
        require 'tk/button'

        root = TkRoot.new { withdraw }
        btn = TkButton.new(root, text: "Hello")

        result = btn.cget(:text)
        raise "Expected 'Hello', got \#{result.inspect}" unless result == "Hello"

        root.destroy
      RUBY
    end
  end

  def test_cget_numeric_option
    assert_tk_test("cget should return number for numeric options") do
      <<~RUBY
        require 'tk'
        require 'tk/button'

        root = TkRoot.new { withdraw }
        btn = TkButton.new(root, width: 20)

        result = btn.cget(:width)
        raise "Expected Integer, got \#{result.class}" unless result.is_a?(Integer)
        raise "Expected 20, got \#{result}" unless result == 20

        root.destroy
      RUBY
    end
  end

  def test_cget_boolean_option
    assert_tk_test("cget should return boolean for boolean options") do
      <<~RUBY
        require 'tk'
        require 'tk/checkbutton'

        root = TkRoot.new { withdraw }
        cb = TkCheckButton.new(root)

        # takefocus is a boolean-ish option
        result = cb.cget(:takefocus)
        # Should be truthy/falsy, not raise

        root.destroy
      RUBY
    end
  end

  def test_cget_tkstring_returns_raw
    assert_tk_test("cget_tkstring should return raw Tcl string") do
      <<~RUBY
        require 'tk'
        require 'tk/button'

        root = TkRoot.new { withdraw }
        btn = TkButton.new(root, width: 20)

        result = btn.cget_tkstring(:width)
        raise "Expected String, got \#{result.class}" unless result.is_a?(String)
        raise "Expected '20', got \#{result.inspect}" unless result == "20"

        root.destroy
      RUBY
    end
  end

  def test_cget_unknown_option_raises
    assert_tk_test("cget should raise for unknown option") do
      <<~RUBY
        require 'tk'
        require 'tk/button'

        root = TkRoot.new { withdraw }
        btn = TkButton.new(root)

        raised = false
        begin
          btn.cget(:nonexistent_option_xyz)
        rescue
          raised = true
        end

        raise "Expected error for unknown option" unless raised

        root.destroy
      RUBY
    end
  end

  # Test configure
  def test_configure_single_option
    assert_tk_test("configure should set single option") do
      <<~RUBY
        require 'tk'
        require 'tk/button'

        root = TkRoot.new { withdraw }
        btn = TkButton.new(root, text: "Before")

        btn.configure(:text, "After")
        result = btn.cget(:text)

        raise "Expected 'After', got \#{result.inspect}" unless result == "After"

        root.destroy
      RUBY
    end
  end

  def test_configure_hash
    assert_tk_test("configure should accept hash of options") do
      <<~RUBY
        require 'tk'
        require 'tk/button'

        root = TkRoot.new { withdraw }
        btn = TkButton.new(root)

        btn.configure(text: "New Text", width: 30)

        raise "text not set" unless btn.cget(:text) == "New Text"
        raise "width not set" unless btn.cget(:width) == 30

        root.destroy
      RUBY
    end
  end

  def test_configure_returns_self
    assert_tk_test("configure should return self for chaining") do
      <<~RUBY
        require 'tk'
        require 'tk/button'

        root = TkRoot.new { withdraw }
        btn = TkButton.new(root)

        result = btn.configure(text: "Test")
        raise "Expected self, got \#{result.class}" unless result == btn

        root.destroy
      RUBY
    end
  end

  def test_configure_optkey_alias
    assert_tk_test("configure should resolve __optkey_aliases") do
      <<~RUBY
        require 'tk'
        require 'tkextlib/tile/tentry'

        root = TkRoot.new { withdraw }
        entry = Tk::Tile::TEntry.new(root)

        # Configure using alias :vcmd instead of :validatecommand
        # This hits __optkey_aliases.each branch in __configure_core
        # Using a simple proc name as the validation command
        entry.configure(vcmd: "myvalidator")

        # Verify it was set via the real option name
        result = entry.cget(:validatecommand)
        raise "Expected 'myvalidator', got \#{result.inspect}" unless result == "myvalidator"

        root.destroy
      RUBY
    end
  end

  def test_configure_methodcall_optkeys
    assert_tk_test("configure should use __methodcall_optkeys for method-based options") do
      <<~RUBY
        require 'tk'

        root = TkRoot.new { withdraw }

        # Configure title via hash - this hits __methodcall_optkeys.each
        # since 'title' maps to the title() method, not a Tk option
        root.configure(title: "Test Title")

        result = root.title
        raise "Expected 'Test Title', got \#{result.inspect}" unless result == "Test Title"

        root.destroy
      RUBY
    end
  end

  def test_configure_ruby2val_optkeys
    assert_tk_test("configure should use __ruby2val_optkeys for value conversion") do
      <<~RUBY
        require 'tk'
        require 'tk/radiobutton'
        require 'tk/variable'

        root = TkRoot.new { withdraw }
        var = TkVariable.new

        # TkRadioButton has __ruby2val_optkeys for 'variable' option
        # The proc calls tk_trace_variable(v) to convert the Ruby object
        rb = TkRadioButton.new(root)
        rb.configure(variable: var)

        # Should not raise - the conversion happened
        root.destroy
      RUBY
    end
  end

  # Single-slot form tests: widget.configure(:slot, value)

  def test_configure_single_slot_ruby2val
    assert_tk_test("configure(:slot, value) should use __ruby2val_optkeys") do
      <<~RUBY
        require 'tk'
        require 'tk/radiobutton'
        require 'tk/variable'

        root = TkRoot.new { withdraw }
        var = TkVariable.new

        rb = TkRadioButton.new(root)
        # Single-slot form: configure(:variable, var) instead of configure(variable: var)
        rb.configure(:variable, var)

        root.destroy
      RUBY
    end
  end

  def test_configure_single_slot_methodcall
    assert_tk_test("configure(:slot, value) should use __methodcall_optkeys") do
      <<~RUBY
        require 'tk'

        root = TkRoot.new { withdraw }

        # Single-slot form: configure(:title, value) instead of configure(title: value)
        root.configure(:title, "Single Slot Title")

        result = root.title
        raise "Expected 'Single Slot Title', got \#{result.inspect}" unless result == "Single Slot Title"

        root.destroy
      RUBY
    end
  end

  def test_configure_single_slot_font
    assert_tk_test("configure(:font, value) should use font_configure") do
      <<~RUBY
        require 'tk'
        require 'tk/button'

        root = TkRoot.new { withdraw }
        btn = TkButton.new(root, text: "Test")

        # Single-slot form for font option
        btn.configure(:font, "Helvetica 12")

        # Verify font was set (returns a TkFont or string)
        result = btn.cget(:font)
        raise "Font not set" if result.nil? || result.to_s.empty?

        root.destroy
      RUBY
    end
  end

  def test_configure_single_slot_regular
    assert_tk_test("configure(:slot, value) should use tk_call for regular options") do
      <<~RUBY
        require 'tk'
        require 'tk/button'

        root = TkRoot.new { withdraw }
        btn = TkButton.new(root, text: "Original")

        # Single-slot form for regular option (hits the else branch)
        btn.configure(:text, "Updated")

        result = btn.cget(:text)
        raise "Expected 'Updated', got \#{result.inspect}" unless result == "Updated"

        root.destroy
      RUBY
    end
  end

  def test_configure_ignore_unknown_option_fallback
    assert_tk_test("__IGNORE_UNKNOWN_CONFIGURE_OPTION__ fallback filters invalid options") do
      <<~RUBY
        require 'tk'
        require 'tk/button'

        root = TkRoot.new { withdraw }
        btn = TkButton.new(root, text: "Original")

        # Save original and enable ignore mode
        original = TkConfigMethod.__IGNORE_UNKNOWN_CONFIGURE_OPTION__
        begin
          TkConfigMethod.__set_IGNORE_UNKNOWN_CONFIGURE_OPTION__!(true)

          # Pass a mix of valid and invalid options - should not raise
          # The fallback __check_available_configure_options filters out invalid ones
          btn.configure(text: "Updated", totally_bogus_option: "ignored")

          result = btn.cget(:text)
          raise "Expected 'Updated', got \#{result.inspect}" unless result == "Updated"
        ensure
          TkConfigMethod.__set_IGNORE_UNKNOWN_CONFIGURE_OPTION__!(original)
        end

        root.destroy
      RUBY
    end
  end

  # Test configinfo
  def test_configinfo_single_slot
    assert_tk_test("configinfo(slot) works in both array and hash modes") do
      <<~RUBY
        require 'tk'
        require 'tk/button'

        root = TkRoot.new { withdraw }
        btn = TkButton.new(root, text: "Hello")

        [true, false].each do |array_mode|
          original = TkComm::GET_CONFIGINFO_AS_ARRAY
          TkComm.send(:remove_const, :GET_CONFIGINFO_AS_ARRAY)
          TkComm::GET_CONFIGINFO_AS_ARRAY = array_mode

          info = btn.configinfo(:text)

          if array_mode
            raise "Expected Array, got \#{info.class}" unless info.is_a?(Array)
            raise "Expected first element to be 'text'" unless info[0] == "text"
            raise "Expected last element to be 'Hello'" unless info[-1] == "Hello"
          else
            raise "Expected Hash, got \#{info.class}" unless info.is_a?(Hash)
            raise "Missing 'text' key" unless info.has_key?("text")
          end

          TkComm.send(:remove_const, :GET_CONFIGINFO_AS_ARRAY)
          TkComm::GET_CONFIGINFO_AS_ARRAY = original
        end

        root.destroy
      RUBY
    end
  end

  def test_configinfo_all
    assert_tk_test("configinfo() works in both array and hash modes") do
      <<~RUBY
        require 'tk'
        require 'tk/button'

        root = TkRoot.new { withdraw }
        btn = TkButton.new(root)

        [true, false].each do |array_mode|
          original = TkComm::GET_CONFIGINFO_AS_ARRAY
          TkComm.send(:remove_const, :GET_CONFIGINFO_AS_ARRAY)
          TkComm::GET_CONFIGINFO_AS_ARRAY = array_mode

          info = btn.configinfo

          if array_mode
            raise "Expected Array, got \#{info.class}" unless info.is_a?(Array)
            raise "Expected non-empty array" if info.empty?
            raise "Expected array of arrays" unless info[0].is_a?(Array)
            option_names = info.map { |i| i[0] }
          else
            raise "Expected Hash, got \#{info.class}" unless info.is_a?(Hash)
            option_names = info.keys
          end

          raise "Missing 'text' option" unless option_names.include?("text")
          raise "Missing 'width' option" unless option_names.include?("width")

          TkComm.send(:remove_const, :GET_CONFIGINFO_AS_ARRAY)
          TkComm::GET_CONFIGINFO_AS_ARRAY = original
        end

        root.destroy
      RUBY
    end
  end

  # ==========================================================================
  # GET_CONFIGINFO_AS_ARRAY = false (Hash mode) tests
  #
  # This global flag changes configinfo's return format:
  #   true  => Array:  [["text", "text", "Text", "", "Hello"], ...]
  #   false => Hash:   {"text" => ["text", "Text", "", "Hello"], ...}
  #
  # The ENTIRE __configinfo_core method is duplicated for each mode (~380
  # lines each), so we need explicit tests for the false branch.
  # ==========================================================================

  def test_configinfo_hash_mode_single_slot
    assert_tk_test("configinfo(slot) in hash mode returns {opt => details}") do
      <<~RUBY
        require 'tk'
        require 'tk/button'

        # Must set BEFORE creating widgets (affects parsing)
        TkComm.send(:remove_const, :GET_CONFIGINFO_AS_ARRAY)
        TkComm::GET_CONFIGINFO_AS_ARRAY = false

        root = TkRoot.new { withdraw }
        btn = TkButton.new(root, text: "Hello")

        info = btn.configinfo(:text)

        raise "Expected Hash, got \#{info.class}" unless info.is_a?(Hash)
        raise "Missing 'text' key" unless info.has_key?("text")

        # Value should be array of config details (without the key)
        details = info["text"]
        raise "Expected Array value, got \#{details.class}" unless details.is_a?(Array)

        root.destroy
      RUBY
    end
  end

  def test_configinfo_hash_mode_all_options
    assert_tk_test("configinfo() in hash mode returns hash of all options") do
      <<~RUBY
        require 'tk'
        require 'tk/button'

        TkComm.send(:remove_const, :GET_CONFIGINFO_AS_ARRAY)
        TkComm::GET_CONFIGINFO_AS_ARRAY = false

        root = TkRoot.new { withdraw }
        btn = TkButton.new(root, text: "Hello", width: 20)

        info = btn.configinfo

        raise "Expected Hash, got \#{info.class}" unless info.is_a?(Hash)
        raise "Missing 'text' key" unless info.has_key?("text")
        raise "Missing 'width' key" unless info.has_key?("width")

        # Each value should be an array of config details
        raise "text value not Array" unless info["text"].is_a?(Array)
        raise "width value not Array" unless info["width"].is_a?(Array)

        root.destroy
      RUBY
    end
  end

  def test_configinfo_hash_mode_numeric_option
    assert_tk_test("configinfo in hash mode handles numeric options correctly") do
      <<~RUBY
        require 'tk'
        require 'tk/canvas'

        TkComm.send(:remove_const, :GET_CONFIGINFO_AS_ARRAY)
        TkComm::GET_CONFIGINFO_AS_ARRAY = false

        root = TkRoot.new { withdraw }
        canvas = TkCanvas.new(root, closeenough: 5.0)

        info = canvas.configinfo(:closeenough)

        raise "Expected Hash" unless info.is_a?(Hash)
        raise "Missing closeenough" unless info.has_key?("closeenough")

        # Current value (last element) should be numeric
        details = info["closeenough"]
        current_val = details.last
        raise "Expected numeric current value, got \#{current_val.class}" unless current_val.is_a?(Numeric)

        root.destroy
      RUBY
    end
  end

  def test_configinfo_hash_mode_boolean_option
    assert_tk_test("configinfo in hash mode handles boolean options correctly") do
      <<~RUBY
        require 'tk'
        require 'tk/canvas'

        TkComm.send(:remove_const, :GET_CONFIGINFO_AS_ARRAY)
        TkComm::GET_CONFIGINFO_AS_ARRAY = false

        root = TkRoot.new { withdraw }
        canvas = TkCanvas.new(root, confine: true)

        info = canvas.configinfo(:confine)

        raise "Expected Hash" unless info.is_a?(Hash)
        details = info["confine"]
        current_val = details.last
        raise "Expected boolean, got \#{current_val.inspect}" unless current_val == true

        root.destroy
      RUBY
    end
  end

  def test_current_configinfo_hash_mode
    assert_tk_test("current_configinfo works in hash mode") do
      <<~RUBY
        require 'tk'
        require 'tk/button'

        TkComm.send(:remove_const, :GET_CONFIGINFO_AS_ARRAY)
        TkComm::GET_CONFIGINFO_AS_ARRAY = false

        root = TkRoot.new { withdraw }
        btn = TkButton.new(root, text: "Hello", width: 15)

        info = btn.current_configinfo

        raise "Expected Hash" unless info.is_a?(Hash)
        raise "text wrong: \#{info['text'].inspect}" unless info["text"] == "Hello"
        raise "width wrong: \#{info['width'].inspect}" unless info["width"] == 15

        root.destroy
      RUBY
    end
  end

  # Test current_configinfo
  def test_current_configinfo_single_slot
    assert_tk_test("current_configinfo(slot) returns {option => value}") do
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
    assert_tk_test("current_configinfo() returns hash of all current values") do
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

  # Test IGNORE_UNKNOWN_CONFIGURE_OPTION mode
  def test_ignore_unknown_option_mode
    assert_tk_test("IGNORE_UNKNOWN mode should return nil for unknown options") do
      <<~RUBY
        require 'tk'
        require 'tk/button'

        root = TkRoot.new { withdraw }
        btn = TkButton.new(root)

        # Enable ignore mode
        TkConfigMethod.__set_IGNORE_UNKNOWN_CONFIGURE_OPTION__!(true)

        result = btn.cget(:totally_fake_option)
        raise "Expected nil, got \#{result.inspect}" unless result.nil?

        # Disable it
        TkConfigMethod.__set_IGNORE_UNKNOWN_CONFIGURE_OPTION__!(false)

        root.destroy
      RUBY
    end
  end

  def test_cget_strict_ignores_ignore_mode
    assert_tk_test("cget_strict should raise even in IGNORE mode") do
      <<~RUBY
        require 'tk'
        require 'tk/button'

        root = TkRoot.new { withdraw }
        btn = TkButton.new(root)

        TkConfigMethod.__set_IGNORE_UNKNOWN_CONFIGURE_OPTION__!(true)

        raised = false
        begin
          btn.cget_strict(:totally_fake_option)
        rescue
          raised = true
        end

        TkConfigMethod.__set_IGNORE_UNKNOWN_CONFIGURE_OPTION__!(false)

        raise "cget_strict should have raised" unless raised

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
    assert_tk_test("configinfo font tests font handling in both modes") do
      <<~RUBY
        require 'tk'
        require 'tk/button'

        root = TkRoot.new { withdraw }
        btn = TkButton.new(root, text: "Hello")

        [true, false].each do |array_mode|
          original = TkComm::GET_CONFIGINFO_AS_ARRAY
          TkComm.send(:remove_const, :GET_CONFIGINFO_AS_ARRAY)
          TkComm::GET_CONFIGINFO_AS_ARRAY = array_mode

          info = btn.configinfo(:font)
          if array_mode
            raise "Expected Array" unless info.is_a?(Array)
            raise "First element should be 'font'" unless info[0] == "font"
            current = info[-1]
          else
            raise "Expected Hash" unless info.is_a?(Hash)
            current = info["font"][-1]
          end
          raise "Font value is nil" if current.nil?

          TkComm.send(:remove_const, :GET_CONFIGINFO_AS_ARRAY)
          TkComm::GET_CONFIGINFO_AS_ARRAY = original
        end

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
    assert_tk_test("configinfo option aliases work in both modes") do
      <<~RUBY
        require 'tk'
        require 'tkextlib/tile/tentry'

        root = TkRoot.new { withdraw }
        entry = Tk::Tile::TEntry.new(root)

        [true, false].each do |array_mode|
          original = TkComm::GET_CONFIGINFO_AS_ARRAY
          TkComm.send(:remove_const, :GET_CONFIGINFO_AS_ARRAY)
          TkComm::GET_CONFIGINFO_AS_ARRAY = array_mode

          # Query using the alias - should resolve to real option
          info = entry.configinfo(:vcmd)
          if array_mode
            raise "Expected Array" unless info.is_a?(Array)
          else
            raise "Expected Hash" unless info.is_a?(Hash)
          end

          TkComm.send(:remove_const, :GET_CONFIGINFO_AS_ARRAY)
          TkComm::GET_CONFIGINFO_AS_ARRAY = original
        end

        root.destroy
      RUBY
    end
  end

  def test_cget_option_alias
    assert_tk_test("cget should resolve option aliases") do
      <<~RUBY
        require 'tk'
        require 'tkextlib/tile/tentry'

        root = TkRoot.new { withdraw }
        entry = Tk::Tile::TEntry.new(root)

        # Set via real name, get via alias
        entry.configure(:validatecommand, "")

        # cget using alias should work
        result = entry.cget(:vcmd)
        # Should not raise - alias resolved to validatecommand

        root.destroy
      RUBY
    end
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
    assert_tk_test("configinfo full list includes Tk aliases in both modes") do
      <<~RUBY
        require 'tk'
        require 'tk/button'

        root = TkRoot.new { withdraw }
        btn = TkButton.new(root)

        [true, false].each do |array_mode|
          original = TkComm::GET_CONFIGINFO_AS_ARRAY
          TkComm.send(:remove_const, :GET_CONFIGINFO_AS_ARRAY)
          TkComm::GET_CONFIGINFO_AS_ARRAY = array_mode

          all_info = btn.configinfo

          if array_mode
            # Find the 'bd' alias entry in the full list
            bd_entry = all_info.find { |entry| entry[0] == "bd" }
            raise "No 'bd' entry found" if bd_entry.nil?
            # Alias entries have 2 elements: [name, target]
            raise "Expected 2-element alias entry" unless bd_entry.size == 2
            raise "Expected 'borderwidth' as target" unless bd_entry[1] == "borderwidth"
          else
            raise "Expected Hash" unless all_info.is_a?(Hash)
            raise "Missing 'bd' key" unless all_info.has_key?("bd")
            # In hash mode, alias value is just the target name
            raise "Expected 'borderwidth'" unless all_info["bd"] == "borderwidth"
          end

          TkComm.send(:remove_const, :GET_CONFIGINFO_AS_ARRAY)
          TkComm::GET_CONFIGINFO_AS_ARRAY = original
        end

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
    assert_tk_test("cget should use __val2ruby_optkeys to convert labelwidget to Ruby object") do
      <<~RUBY
        require 'tk'
        require 'tk/labelframe'
        require 'tk/label'

        root = TkRoot.new { withdraw }

        # Create a label to use as the labelwidget
        lbl = TkLabel.new(root, text: "Header")

        # Create labelframe with the label as its labelwidget
        lf = TkLabelFrame.new(root, labelwidget: lbl)

        # cget(:labelwidget) should return the Ruby TkLabel object,
        # not the raw Tk path string like ".label1"
        result = lf.cget(:labelwidget)

        raise "Expected TkLabel, got \#{result.class}" unless result.is_a?(TkLabel)
        raise "Expected same object" unless result == lbl

        root.destroy
      RUBY
    end
  end

  def test_configinfo_val2ruby_labelwidget
    assert_tk_test("configinfo labelwidget tests __val2ruby_optkeys in both modes") do
      <<~RUBY
        require 'tk'
        require 'tk/labelframe'
        require 'tk/label'

        root = TkRoot.new { withdraw }
        lbl = TkLabel.new(root, text: "Header")
        lf = TkLabelFrame.new(root, labelwidget: lbl)

        [true, false].each do |array_mode|
          original = TkComm::GET_CONFIGINFO_AS_ARRAY
          TkComm.send(:remove_const, :GET_CONFIGINFO_AS_ARRAY)
          TkComm::GET_CONFIGINFO_AS_ARRAY = array_mode

          # Test single slot
          info = lf.configinfo(:labelwidget)
          if array_mode
            raise "Expected Array" unless info.is_a?(Array)
            raise "First element should be 'labelwidget'" unless info[0] == "labelwidget"
            current = info[-1]
          else
            raise "Expected Hash" unless info.is_a?(Hash)
            current = info["labelwidget"][-1]
          end
          raise "Expected TkLabel, got \#{current.class}" unless current.is_a?(TkLabel)

          # Test full list (else branch)
          all_info = lf.configinfo
          if array_mode
            lw_entry = all_info.find { |e| e[0] == "labelwidget" }
            current = lw_entry[-1]
          else
            current = all_info["labelwidget"][-1]
          end
          raise "Expected TkLabel in full list" unless current.is_a?(TkLabel)

          TkComm.send(:remove_const, :GET_CONFIGINFO_AS_ARRAY)
          TkComm::GET_CONFIGINFO_AS_ARRAY = original
        end

        root.destroy
      RUBY
    end
  end

  # ==========================================================================
  # __methodcall_optkeys tests
  #
  # Some "options" aren't real Tk widget options - they're virtual options
  # that call Ruby methods instead of querying Tcl. Example: TkRoot's
  # 'title' and 'geometry' are actually wm commands, not widget options.
  # When you call cget(:title), it calls self.title() instead of
  # querying "-title" from Tcl.
  # ==========================================================================

  def test_cget_methodcall_title
    assert_tk_test("cget(:title) should call title() method, not query Tcl option") do
      <<~RUBY
        require 'tk'

        root = TkRoot.new { withdraw }
        root.title("My Window Title")

        # cget(:title) calls self.title() which is a wm command wrapper
        result = root.cget(:title)

        raise "Expected 'My Window Title', got \#{result.inspect}" unless result == "My Window Title"

        root.destroy
      RUBY
    end
  end

  def test_cget_methodcall_geometry
    assert_tk_test("cget(:geometry) should call geometry() method") do
      <<~RUBY
        require 'tk'

        root = TkRoot.new { withdraw }
        root.geometry("400x300+100+50")

        result = root.cget(:geometry)

        # Result should be a geometry string like "400x300+100+50"
        raise "Expected geometry string, got \#{result.inspect}" unless result =~ /\\d+x\\d+/

        root.destroy
      RUBY
    end
  end

  def test_configinfo_methodcall_title
    assert_tk_test("configinfo title tests __methodcall_optkeys in both modes") do
      <<~RUBY
        require 'tk'

        root = TkRoot.new { withdraw }
        root.title("Test Window")

        [true, false].each do |array_mode|
          original = TkComm::GET_CONFIGINFO_AS_ARRAY
          TkComm.send(:remove_const, :GET_CONFIGINFO_AS_ARRAY)
          TkComm::GET_CONFIGINFO_AS_ARRAY = array_mode

          # Test single slot
          info = root.configinfo(:title)
          if array_mode
            raise "Expected Array" unless info.is_a?(Array)
            raise "First element should be 'title'" unless info[0] == "title"
            current = info[-1]
          else
            raise "Expected Hash" unless info.is_a?(Hash)
            current = info["title"][-1]
          end
          raise "Expected 'Test Window'" unless current == "Test Window"

          TkComm.send(:remove_const, :GET_CONFIGINFO_AS_ARRAY)
          TkComm::GET_CONFIGINFO_AS_ARRAY = original
        end

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
    assert_tk_test("cget should convert __numval_optkeys to numbers (canvas closeenough)") do
      <<~RUBY
        require 'tk'
        require 'tk/canvas'

        root = TkRoot.new { withdraw }
        canvas = TkCanvas.new(root, closeenough: 2.5)

        result = canvas.cget(:closeenough)

        raise "Expected Numeric, got \#{result.class}" unless result.is_a?(Numeric)
        raise "Expected 2.5, got \#{result}" unless result == 2.5

        root.destroy
      RUBY
    end
  end

  def test_configinfo_numval_closeenough
    assert_tk_test("configinfo closeenough tests __numval_optkeys in both modes") do
      <<~RUBY
        require 'tk'
        require 'tk/canvas'

        root = TkRoot.new { withdraw }
        canvas = TkCanvas.new(root, closeenough: 3.5)

        [true, false].each do |array_mode|
          original = TkComm::GET_CONFIGINFO_AS_ARRAY
          TkComm.send(:remove_const, :GET_CONFIGINFO_AS_ARRAY)
          TkComm::GET_CONFIGINFO_AS_ARRAY = array_mode

          # Test single slot
          info = canvas.configinfo(:closeenough)
          if array_mode
            raise "Expected Array" unless info.is_a?(Array)
            raise "First element should be 'closeenough'" unless info[0] == "closeenough"
            current = info[-1]
          else
            raise "Expected Hash" unless info.is_a?(Hash)
            current = info["closeenough"][-1]
          end
          raise "Expected Numeric, got \#{current.class}" unless current.is_a?(Numeric)
          raise "Expected 3.5" unless current == 3.5

          # Test full list (else branch)
          all_info = canvas.configinfo
          if array_mode
            ce_entry = all_info.find { |entry| entry[0] == "closeenough" }
            current = ce_entry[-1]
          else
            current = all_info["closeenough"][-1]
          end
          raise "Expected Numeric in full list" unless current.is_a?(Numeric)

          TkComm.send(:remove_const, :GET_CONFIGINFO_AS_ARRAY)
          TkComm::GET_CONFIGINFO_AS_ARRAY = original
        end

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
    assert_tk_test("cget should convert __boolval_optkeys to boolean (canvas confine)") do
      <<~RUBY
        require 'tk'
        require 'tk/canvas'

        root = TkRoot.new { withdraw }
        canvas = TkCanvas.new(root, confine: true)

        result = canvas.cget(:confine)

        # Should be boolean true, not string "1" or integer 1
        raise "Expected true, got \#{result.inspect}" unless result == true

        canvas.configure(confine: false)
        result = canvas.cget(:confine)
        raise "Expected false, got \#{result.inspect}" unless result == false

        root.destroy
      RUBY
    end
  end

  def test_configinfo_boolval_confine
    assert_tk_test("configinfo confine tests __boolval_optkeys in both modes") do
      <<~RUBY
        require 'tk'
        require 'tk/canvas'

        root = TkRoot.new { withdraw }
        canvas = TkCanvas.new(root, confine: true)

        [true, false].each do |array_mode|
          original = TkComm::GET_CONFIGINFO_AS_ARRAY
          TkComm.send(:remove_const, :GET_CONFIGINFO_AS_ARRAY)
          TkComm::GET_CONFIGINFO_AS_ARRAY = array_mode

          # Test single slot
          info = canvas.configinfo(:confine)
          if array_mode
            raise "Expected Array" unless info.is_a?(Array)
            raise "First element should be 'confine'" unless info[0] == "confine"
            current = info[-1]
          else
            raise "Expected Hash" unless info.is_a?(Hash)
            current = info["confine"][-1]
          end
          raise "Expected true, got \#{current.inspect}" unless current == true

          # Test full list (else branch)
          all_info = canvas.configinfo
          if array_mode
            cf_entry = all_info.find { |entry| entry[0] == "confine" }
            current = cf_entry[-1]
          else
            current = all_info["confine"][-1]
          end
          raise "Expected boolean in full list" unless current == true

          TkComm.send(:remove_const, :GET_CONFIGINFO_AS_ARRAY)
          TkComm::GET_CONFIGINFO_AS_ARRAY = original
        end

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
    assert_tk_test("cget should wrap __tkvariable_optkeys in TkVarAccess") do
      <<~RUBY
        require 'tk'
        require 'tk/entry'
        require 'tk/variable'

        root = TkRoot.new { withdraw }

        # Create a TkVariable and bind it to an entry
        var = TkVariable.new("initial value")
        entry = TkEntry.new(root, textvariable: var)

        # cget(:textvariable) should return a TkVarAccess (or similar)
        result = entry.cget(:textvariable)

        raise "Expected truthy result, got nil" if result.nil?
        # The result should let us access the variable's value
        raise "Variable access failed" unless result.value == "initial value"

        root.destroy
      RUBY
    end
  end

  def test_configinfo_tkvariable_textvariable
    assert_tk_test("configinfo textvariable tests __tkvariable_optkeys in both modes") do
      <<~RUBY
        require 'tk'
        require 'tk/entry'
        require 'tk/variable'

        root = TkRoot.new { withdraw }
        var = TkVariable.new("test value")
        entry = TkEntry.new(root, textvariable: var)

        [true, false].each do |array_mode|
          original = TkComm::GET_CONFIGINFO_AS_ARRAY
          TkComm.send(:remove_const, :GET_CONFIGINFO_AS_ARRAY)
          TkComm::GET_CONFIGINFO_AS_ARRAY = array_mode

          # Test single slot
          info = entry.configinfo(:textvariable)
          if array_mode
            raise "Expected Array" unless info.is_a?(Array)
            raise "First element should be 'textvariable'" unless info[0] == "textvariable"
            current = info[-1]
          else
            raise "Expected Hash" unless info.is_a?(Hash)
            current = info["textvariable"][-1]
          end
          raise "Expected TkVariable, got nil" if current.nil?
          raise "Variable access failed" unless current.value == "test value"

          # Test full list (else branch)
          all_info = entry.configinfo
          if array_mode
            tv_entry = all_info.find { |e| e[0] == "textvariable" }
            current = tv_entry[-1]
          else
            current = all_info["textvariable"][-1]
          end
          raise "Expected TkVariable in full list" if current.nil?

          TkComm.send(:remove_const, :GET_CONFIGINFO_AS_ARRAY)
          TkComm::GET_CONFIGINFO_AS_ARRAY = original
        end

        root.destroy
      RUBY
    end
  end

  # ==========================================================================
  # __strval_optkeys tests
  #
  # Options in __strval_optkeys are ensured to return as strings.
  # Base class has: 'text', 'label', 'show', 'data', 'file', various colors...
  # ==========================================================================

  def test_configinfo_strval_text
    assert_tk_test("configinfo text tests __strval_optkeys in both modes") do
      <<~RUBY
        require 'tk'
        require 'tk/button'

        root = TkRoot.new { withdraw }
        btn = TkButton.new(root, text: "Hello World")

        [true, false].each do |array_mode|
          original = TkComm::GET_CONFIGINFO_AS_ARRAY
          TkComm.send(:remove_const, :GET_CONFIGINFO_AS_ARRAY)
          TkComm::GET_CONFIGINFO_AS_ARRAY = array_mode

          # Test single slot
          info = btn.configinfo(:text)
          if array_mode
            raise "Expected Array" unless info.is_a?(Array)
            raise "First element should be 'text'" unless info[0] == "text"
            current = info[-1]
          else
            raise "Expected Hash" unless info.is_a?(Hash)
            current = info["text"][-1]
          end
          raise "Expected String" unless current.is_a?(String)
          raise "Expected 'Hello World'" unless current == "Hello World"

          # Test full list (else branch)
          all_info = btn.configinfo
          if array_mode
            text_entry = all_info.find { |e| e[0] == "text" }
            current = text_entry[-1]
          else
            current = all_info["text"][-1]
          end
          raise "Expected String in full list" unless current.is_a?(String)

          TkComm.send(:remove_const, :GET_CONFIGINFO_AS_ARRAY)
          TkComm::GET_CONFIGINFO_AS_ARRAY = original
        end

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
    assert_tk_test("cget(:values) should convert to Ruby array (spinbox values)") do
      <<~RUBY
        require 'tk'
        require 'tk/spinbox'

        root = TkRoot.new { withdraw }
        spinbox = TkSpinbox.new(root, values: ["one", "two", "three"])

        result = spinbox.cget(:values)

        raise "Expected Array, got \#{result.class}" unless result.is_a?(Array)
        raise "Expected 3 values, got \#{result.size}" unless result.size == 3
        raise "Expected ['one', 'two', 'three']" unless result == ["one", "two", "three"]

        root.destroy
      RUBY
    end
  end

  def test_configinfo_listval_values
    assert_tk_test("configinfo values tests __listval_optkeys in both modes") do
      <<~RUBY
        require 'tk'
        require 'tk/spinbox'

        root = TkRoot.new { withdraw }
        spinbox = TkSpinbox.new(root, values: ["a", "b", "c"])

        [true, false].each do |array_mode|
          original = TkComm::GET_CONFIGINFO_AS_ARRAY
          TkComm.send(:remove_const, :GET_CONFIGINFO_AS_ARRAY)
          TkComm::GET_CONFIGINFO_AS_ARRAY = array_mode

          # Test single slot
          info = spinbox.configinfo(:values)
          if array_mode
            raise "Expected Array" unless info.is_a?(Array)
            raise "First element should be 'values'" unless info[0] == "values"
            current = info[-1]
          else
            raise "Expected Hash" unless info.is_a?(Hash)
            current = info["values"][-1]
          end
          raise "Expected Array value" unless current.is_a?(Array)
          raise "Expected ['a', 'b', 'c']" unless current == ["a", "b", "c"]

          # Test full list (else branch)
          all_info = spinbox.configinfo
          if array_mode
            vals_entry = all_info.find { |e| e[0] == "values" }
            current = vals_entry[-1]
          else
            current = all_info["values"][-1]
          end
          raise "Expected Array in full list" unless current.is_a?(Array)

          TkComm.send(:remove_const, :GET_CONFIGINFO_AS_ARRAY)
          TkComm::GET_CONFIGINFO_AS_ARRAY = original
        end

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
    assert_tk_test("cget should handle state option") do
      <<~RUBY
        require 'tk'
        require 'tk/button'

        root = TkRoot.new { withdraw }
        btn = TkButton.new(root)

        # Default state should be normal
        state = btn.cget(:state)
        raise "Expected 'normal', got \#{state.inspect}" unless state == "normal"

        btn.configure(state: "disabled")
        state = btn.cget(:state)
        raise "Expected 'disabled', got \#{state.inspect}" unless state == "disabled"

        root.destroy
      RUBY
    end
  end
end
