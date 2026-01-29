# frozen_string_literal: true

# Tests for methods in lib/tk.rb (the Tk module).

require_relative 'test_helper'
require_relative 'tk_test_helper'

class TestTkModule < Minitest::Test
  include TkTestHelper

  # --- Tcl library loading ---

  def test_load_tcllibrary_with_invalid_file
    require 'tk'
    # Test that load_tcllibrary properly delegates to Tcl's load command
    # by verifying it raises an error for a non-existent file
    assert_raises(TclTkLib::TclError) do
      Tk.load_tcllibrary('/nonexistent/file.so')
    end
  end

  def test_unload_tcllibrary_with_invalid_args
    require 'tk'
    # Test that unload_tcllibrary properly delegates to Tcl's unload command
    assert_raises(TclTkLib::TclError) do
      Tk.unload_tcllibrary('/nonexistent/file.so')
    end
  end

  # --- Tcl variable accessors ---

  def test_tcl_library_method
    require 'tk'
    result = Tk.tcl_library
    assert_kind_of String, result
    refute_empty result
    assert result.frozen?
  end

  def test_tk_library_method
    require 'tk'
    result = Tk.tk_library
    assert_kind_of String, result
    refute_empty result
    assert result.frozen?
  end

  def test_library_method
    require 'tk'
    result = Tk.library
    assert_kind_of String, result
    refute_empty result
    assert result.frozen?
  end

  def test_platform_method
    require 'tk'
    result = Tk.platform
    assert_kind_of Hash, result
    assert_includes %w[unix windows macintosh], result['platform']
  end

  def test_tcl_env_method
    require 'tk'
    result = Tk.tcl_env
    assert_kind_of Hash, result
    refute_empty result
  end

  def test_auto_index_method
    require 'tk'
    result = Tk.auto_index
    assert_kind_of Hash, result
  end

  def test_priv_method
    require 'tk'
    result = Tk.priv
    assert_kind_of Hash, result
  end

  # --- Deprecated const_missing API ---

  def test_unknown_constant_raises_name_error
    require 'tk'
    assert_raises(NameError) { Tk::NONEXISTENT_CONSTANT_12345 }
  end

  # --- Tk.errorInfo and Tk.errorCode ---

  def test_error_info_after_tcl_error
    assert_tk_app("Tk.errorInfo", method(:error_info_app))
  end

  def error_info_app
    require 'tk'

    errors = []

    # Trigger a Tcl error to populate errorInfo
    begin
      Tk.ip_eval('error "test error message"')
    rescue RuntimeError
      # Expected
    end

    # errorInfo should contain the error message and stack trace
    info = Tk.errorInfo
    errors << "errorInfo should be a string" unless info.is_a?(String)
    errors << "errorInfo should contain the error message" unless info.include?("test error message")

    raise "errorInfo failures:\n  " + errors.join("\n  ") unless errors.empty?
  end

  def test_error_code_basic
    assert_tk_app("Tk.errorCode", method(:error_code_app))
  end

  def error_code_app
    require 'tk'

    errors = []

    # errorCode should return an array
    code = Tk.errorCode
    errors << "errorCode should be an array, got #{code.class}" unless code.is_a?(Array)

    # Trigger a specific error with errorcode
    begin
      Tk.ip_eval('error "test" {} {POSIX ENOENT "no such file"}')
    rescue RuntimeError
      # Expected
    end

    code = Tk.errorCode
    errors << "errorCode should be POSIX, got #{code.inspect}" unless code[0] == "POSIX"

    raise "errorCode failures:\n  " + errors.join("\n  ") unless errors.empty?
  end

  # --- Tk.bell and Tk.bell_on_display ---

  def test_bell
    assert_tk_app("Tk.bell test", method(:bell_app))
  end

  def bell_app
    require 'tk'

    errors = []

    # Basic bell (can't verify audio, just verify no error and returns nil)
    result = Tk.bell
    errors << "Tk.bell should return nil" unless result.nil?

    # Nice mode
    result = Tk.bell(true)
    errors << "Tk.bell(true) should return nil" unless result.nil?

    # bell_on_display with root window
    result = Tk.bell_on_display(root)
    errors << "Tk.bell_on_display should return nil" unless result.nil?

    # bell_on_display with nice mode
    result = Tk.bell_on_display(root, true)
    errors << "Tk.bell_on_display(root, true) should return nil" unless result.nil?

    raise "Bell test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end

  # --- Tk.focus and Tk.current_grabs ---

  def test_focus_methods
    assert_tk_app("Tk.focus methods", method(:focus_app))
  end

  def focus_app
    require 'tk'

    errors = []

    # Need visible window for focus to work
    root.deiconify
    Tk.update

    # Create widgets that can receive focus
    entry1 = TkEntry.new(root)
    entry1.pack
    entry2 = TkEntry.new(root)
    entry2.pack

    Tk.update

    # Tk.focus_to - set focus to a widget (use force for headless environments)
    Tk.focus_to(entry1, true)
    Tk.update

    # Tk.focus - get current focus
    focused = Tk.focus
    errors << "focus_to failed: expected entry1" unless focused && focused.path == entry1.path

    # Tk.focus_to another widget
    Tk.focus_to(entry2, true)
    Tk.update

    focused = Tk.focus
    errors << "focus_to failed: expected entry2" unless focused && focused.path == entry2.path

    # Tk.focus_lastfor - get last focused widget in window
    last = Tk.focus_lastfor(root)
    errors << "focus_lastfor should return a window" unless last

    # Tk.focus_next / focus_prev - traverse focus order
    Tk.focus_to(entry1, true)
    Tk.update

    next_widget = Tk.focus_next(entry1)
    errors << "focus_next should return a widget" unless next_widget

    prev_widget = Tk.focus_prev(entry2)
    errors << "focus_prev should return a widget" unless prev_widget

    raise "Focus test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end

  def test_grab_methods
    assert_tk_app("Tk.current_grabs methods", method(:grab_app))
  end

  def grab_app
    require 'tk'

    errors = []

    # Initially no grabs
    grabs = Tk.current_grabs
    errors << "initial grabs should be empty array" unless grabs.is_a?(Array)

    # Create a toplevel to grab
    win = TkToplevel.new(root)
    Tk.update

    # Set a grab on the window
    win.grab_set

    # Check current_grabs with window arg
    grabbed = Tk.current_grabs(win)
    errors << "current_grabs(win) should return the grabbed window" unless grabbed

    # Check current_grabs without arg (returns list)
    grabs = Tk.current_grabs
    errors << "current_grabs should include grabbed window" unless grabs.any? { |w| w.path == win.path }

    # Release grab
    win.grab_release
    Tk.update

    grabs = Tk.current_grabs
    has_win = grabs.any? { |w| w.path == win.path rescue false }
    errors << "grab_release failed: window should not be in grabs" if has_win

    raise "Grab test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end

  # --- Tk.raise_window and Tk.lower_window ---

  def test_raise_and_lower_window
    assert_tk_app("Tk.raise_window and Tk.lower_window", method(:stacking_app))
  end

  def stacking_app
    require 'tk'

    errors = []

    # Create two toplevel windows
    win1 = TkToplevel.new(root, title: "Window 1")
    win2 = TkToplevel.new(root, title: "Window 2")

    # Need to update to ensure windows are mapped
    Tk.update

    # Get stack order via wm stackorder (returns list lowest-to-highest)
    def stack_order
      Tk.ip_invoke('wm', 'stackorder', '.').split
    end

    # win2 was created last, should be on top initially
    order = stack_order
    win1_path = win1.path
    win2_path = win2.path

    # Lower win2 below win1
    Tk.lower_window(win2, win1)
    Tk.update

    order = stack_order
    idx1 = order.index(win1_path)
    idx2 = order.index(win2_path)
    errors << "lower_window failed: win2 should be below win1" if idx2 && idx1 && idx2 > idx1

    # Raise win2 above win1
    Tk.raise_window(win2, win1)
    Tk.update

    order = stack_order
    idx1 = order.index(win1_path)
    idx2 = order.index(win2_path)
    errors << "raise_window failed: win2 should be above win1" if idx2 && idx1 && idx2 < idx1

    # Raise win1 to top (no second arg)
    Tk.raise_window(win1)
    Tk.update

    order = stack_order
    errors << "raise_window(win1) failed: win1 should be at top" if order.last != win1_path

    # Lower win1 to bottom (no second arg)
    Tk.lower_window(win1)
    Tk.update

    order = stack_order
    # win1 should be lower than win2 now
    idx1 = order.index(win1_path)
    idx2 = order.index(win2_path)
    errors << "lower_window(win1) failed: win1 should be below win2" if idx1 && idx2 && idx1 > idx2

    raise "Stacking test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end

  # --- Tk.grid, Tk.grid_forget, Tk.ungrid ---

  def test_grid_methods
    assert_tk_app("Tk.grid methods", method(:grid_app))
  end

  def grid_app
    require 'tk'

    errors = []

    # Create widgets
    lbl = TkLabel.new(root, text: "Test")
    btn = TkButton.new(root, text: "Button")

    # Tk.grid - arrange in grid
    Tk.grid(lbl, row: 0, column: 0)
    Tk.grid(btn, row: 1, column: 0)

    # Verify they're gridded
    errors << "label not gridded" unless lbl.winfo_manager == "grid"
    errors << "button not gridded" unless btn.winfo_manager == "grid"

    # Tk.grid_forget - remove from grid
    Tk.grid_forget(lbl)
    errors << "label should be ungridded" unless lbl.winfo_manager == ""

    # Tk.ungrid - alias for grid_forget
    Tk.ungrid(btn)
    errors << "button should be ungridded" unless btn.winfo_manager == ""

    raise "Grid test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end

  # --- Tk.place, Tk.place_forget, Tk.unplace ---

  def test_place_methods
    assert_tk_app("Tk.place methods", method(:place_app))
  end

  def place_app
    require 'tk'

    errors = []

    # Create widgets
    lbl = TkLabel.new(root, text: "Test")
    btn = TkButton.new(root, text: "Button")

    # Tk.place - absolute positioning
    Tk.place(lbl, x: 10, y: 10)
    Tk.place(btn, x: 10, y: 50)

    # Verify they're placed
    errors << "label not placed" unless lbl.winfo_manager == "place"
    errors << "button not placed" unless btn.winfo_manager == "place"

    # Tk.place_forget - remove from place
    Tk.place_forget(lbl)
    errors << "label should be unplaced" unless lbl.winfo_manager == ""

    # Tk.unplace - alias for place_forget
    Tk.unplace(btn)
    errors << "button should be unplaced" unless btn.winfo_manager == ""

    raise "Place test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end

  # --- Tk.sleep and Tk.wakeup ---
  # Note: test_threading.rb has more comprehensive threading integration tests

  def test_sleep_basic
    assert_tk_app("Tk.sleep basic", method(:sleep_basic_app))
  end

  def sleep_basic_app
    require 'tk'

    errors = []

    # Tk.sleep with short duration
    start = Time.now
    Tk.sleep(50)  # 50ms
    elapsed = Time.now - start

    errors << "Tk.sleep(50) should sleep ~50ms, got #{(elapsed * 1000).round}ms" if elapsed < 0.03 || elapsed > 0.3

    raise errors.join("\n") unless errors.empty?
  end

  def test_wakeup
    assert_tk_app("Tk.wakeup", method(:wakeup_app))
  end

  def wakeup_app
    require 'tk'

    errors = []

    # Create a variable for sleep/wakeup coordination
    var = TkVariable.new

    # Schedule wakeup after 50ms
    TkAfter.new(50, 1) { Tk.wakeup(var) }.start

    # Sleep for a long time - should be interrupted by wakeup
    start = Time.now
    Tk.sleep(5000, var)  # 5 seconds, but will be interrupted
    elapsed = Time.now - start

    # Should have been woken up early (< 1 second)
    errors << "Tk.wakeup should interrupt sleep early, took #{elapsed}s" if elapsed > 1.0

    raise errors.join("\n") unless errors.empty?
  end

  # --- Tk.root instance method ---

  def test_root_method
    assert_tk_app("Tk.root instance method", method(:root_method_app))
  end

  def root_method_app
    require 'tk'

    errors = []

    # Tk module extends itself, so instance methods are available on Tk
    tk_root = Tk.root
    errors << "Tk.root should return a Tk::Root, got #{tk_root.class}" unless tk_root.is_a?(Tk::Root)

    # Multiple calls should return new instances (not cached)
    tk_root2 = Tk.root
    errors << "Tk.root should return Tk::Root instances" unless tk_root2.is_a?(Tk::Root)

    raise errors.join("\n") unless errors.empty?
  end

  # --- Tk.has_mainwindow? ---

  def test_has_mainwindow
    assert_tk_app("Tk.has_mainwindow?", method(:has_mainwindow_app))
  end

  def has_mainwindow_app
    require 'tk'

    errors = []

    # When Tk is initialized, main window should exist
    result = Tk.has_mainwindow?
    errors << "Tk.has_mainwindow? should return true when Tk is running" unless result == true

    raise errors.join("\n") unless errors.empty?
  end

  # --- Tk.destroy ---

  def test_destroy
    assert_tk_app("Tk.destroy", method(:destroy_app))
  end

  def destroy_app
    require 'tk'

    errors = []

    # Create widgets to destroy
    btn1 = TkButton.new(root, text: "Button 1")
    btn1.pack
    btn2 = TkButton.new(root, text: "Button 2")
    btn2.pack

    # Verify widgets exist
    errors << "btn1 should exist" unless btn1.winfo_exist?
    errors << "btn2 should exist" unless btn2.winfo_exist?

    # Destroy multiple widgets at once
    Tk.destroy(btn1, btn2)

    errors << "btn1 should be destroyed" if btn1.winfo_exist?
    errors << "btn2 should be destroyed" if btn2.winfo_exist?

    raise errors.join("\n") unless errors.empty?
  end

  # --- Tk.pack, Tk.pack_forget, Tk.unpack ---

  def test_pack_methods
    assert_tk_app("Tk.pack methods", method(:pack_methods_app))
  end

  def pack_methods_app
    require 'tk'

    errors = []

    lbl = TkLabel.new(root, text: "Test")
    btn = TkButton.new(root, text: "Button")

    # Tk.pack - pack widgets
    Tk.pack(lbl, side: :top)
    Tk.pack(btn, side: :bottom)

    errors << "label not packed" unless lbl.winfo_manager == "pack"
    errors << "button not packed" unless btn.winfo_manager == "pack"

    # Tk.pack_forget - remove from pack
    Tk.pack_forget(lbl)
    errors << "label should be unpacked" unless lbl.winfo_manager == ""

    # Tk.unpack - alias for pack_forget
    Tk.unpack(btn)
    errors << "button should be unpacked" unless btn.winfo_manager == ""

    raise errors.join("\n") unless errors.empty?
  end

  # --- Tk.update_idletasks ---

  def test_update_idletasks
    assert_tk_app("Tk.update_idletasks", method(:update_idletasks_app))
  end

  def update_idletasks_app
    require 'tk'

    errors = []

    # update_idletasks processes pending idle callbacks
    # Returns empty string from Tcl's 'update idletasks' command
    result = Tk.update_idletasks
    errors << "Tk.update_idletasks should return empty string, got #{result.inspect}" unless result == ""

    # Tk.update(true) is equivalent
    result = Tk.update(true)
    errors << "Tk.update(true) should return empty string, got #{result.inspect}" unless result == ""

    # Regular update
    result = Tk.update
    errors << "Tk.update should return empty string, got #{result.inspect}" unless result == ""

    raise errors.join("\n") unless errors.empty?
  end

  # --- Tk.strictMotif ---

  def test_strict_motif
    assert_tk_app("Tk.strictMotif", method(:strict_motif_app))
  end

  def strict_motif_app
    require 'tk'

    errors = []

    # Get current value
    result = Tk.strictMotif
    errors << "Tk.strictMotif should return boolean, got #{result.class}" unless [true, false].include?(result)

    # Set to true
    Tk.strictMotif(true)
    result = Tk.strictMotif
    errors << "Tk.strictMotif(true) should set to true" unless result == true

    # Set to false
    Tk.strictMotif(false)
    result = Tk.strictMotif
    errors << "Tk.strictMotif(false) should set to false" unless result == false

    raise errors.join("\n") unless errors.empty?
  end

  # --- Tk encoding methods ---

  def test_encoding_methods
    assert_tk_app("Tk encoding methods", method(:encoding_methods_app))
  end

  def encoding_methods_app
    require 'tk'

    errors = []

    # Tk.encoding
    result = Tk.encoding
    errors << "Tk.encoding should return 'utf-8', got #{result.inspect}" unless result == 'utf-8'

    # Tk.encoding_name
    result = Tk.encoding_name
    errors << "Tk.encoding_name should return 'utf-8', got #{result.inspect}" unless result == 'utf-8'

    # Tk.encoding_system
    result = Tk.encoding_system
    errors << "Tk.encoding_system should return 'utf-8', got #{result.inspect}" unless result == 'utf-8'

    # Tk.encoding_obj
    result = Tk.encoding_obj
    errors << "Tk.encoding_obj should return Encoding::UTF_8" unless result == Encoding::UTF_8

    # Tk.encoding_system_obj
    result = Tk.encoding_system_obj
    errors << "Tk.encoding_system_obj should return Encoding::UTF_8" unless result == Encoding::UTF_8

    # Tk.tk_encoding_names - returns list of Tcl encoding names
    result = Tk.tk_encoding_names
    errors << "Tk.tk_encoding_names should return an array" unless result.is_a?(Array)
    errors << "Tk.tk_encoding_names should include utf-8" unless result.include?('utf-8')

    # Tk.encoding_names - alias
    result = Tk.encoding_names
    errors << "Tk.encoding_names should return an array" unless result.is_a?(Array)

    raise errors.join("\n") unless errors.empty?
  end

  # --- TclTkLib encoding stub methods ---

  def test_tcltk_lib_encoding_stubs
    # These are no-op stubs for compatibility - just verify they don't error
    require 'tk'

    # Setters (no-ops)
    TclTkLib.force_default_encoding = true
    TclTkLib.default_encoding = 'utf-8'
    TclTkLib.encoding = 'utf-8'

    # Getters
    assert_equal true, TclTkLib.force_default_encoding?
    assert_equal 'utf-8', TclTkLib.encoding_name
    assert_equal 'utf-8', TclTkLib.encoding
    assert_equal 'utf-8', TclTkLib.default_encoding
    assert_equal Encoding::UTF_8, TclTkLib.encoding_obj
  end

  # --- Deprecated methods (should still work with warnings) ---

  def test_deprecated_to_utf8
    assert_tk_app("Tk.toUTF8 deprecated", method(:deprecated_to_utf8_app))
  end

  def deprecated_to_utf8_app
    require 'tk'

    errors = []

    # toUTF8 just returns the string (no-op since Ruby is UTF-8)
    result = Tk.toUTF8("hello")
    errors << "Tk.toUTF8 should return 'hello', got #{result.inspect}" unless result == "hello"

    # With encoding arg (ignored)
    result = Tk.toUTF8("hello", "iso-8859-1")
    errors << "Tk.toUTF8 with encoding should return 'hello'" unless result == "hello"

    raise errors.join("\n") unless errors.empty?
  end

  def test_deprecated_from_utf8
    assert_tk_app("Tk.fromUTF8 deprecated", method(:deprecated_from_utf8_app))
  end

  def deprecated_from_utf8_app
    require 'tk'

    errors = []

    # fromUTF8 just returns the string (no-op)
    result = Tk.fromUTF8("hello")
    errors << "Tk.fromUTF8 should return 'hello', got #{result.inspect}" unless result == "hello"

    raise errors.join("\n") unless errors.empty?
  end

  def test_deprecated_thread_update
    assert_tk_app("Tk.thread_update deprecated", method(:deprecated_thread_update_app))
  end

  def deprecated_thread_update_app
    require 'tk'

    errors = []

    # thread_update now just calls update (deprecated)
    # Should not raise
    Tk.thread_update
    Tk.thread_update(true)
    Tk.thread_update_idletasks

    raise errors.join("\n") unless errors.empty?
  end

  def test_deprecated_instance_update
    assert_tk_app("Instance #update deprecated", method(:deprecated_instance_update_app))
  end

  def deprecated_instance_update_app
    require 'tk'

    errors = []

    # Create a widget
    lbl = TkLabel.new(root, text: "Test")
    lbl.pack

    # Instance update method is deprecated but should work
    result = lbl.update
    errors << "lbl.update should return self" unless result == lbl

    result = lbl.update(true)
    errors << "lbl.update(true) should return self" unless result == lbl

    raise errors.join("\n") unless errors.empty?
  end

  # --- Tk.load_tclscript ---

  def test_load_tclscript
    assert_tk_app("Tk.load_tclscript", method(:load_tclscript_app))
  end

  def load_tclscript_app
    require 'tk'
    require 'tempfile'

    errors = []

    # Create a temporary Tcl script
    script = Tempfile.new(['test', '.tcl'])
    script.write('set __test_var_from_script 42')
    script.close

    begin
      # Load the script
      Tk.load_tclscript(script.path)

      # Verify it ran by checking the variable
      result = Tk.ip_invoke('set', '__test_var_from_script')
      errors << "Script should set __test_var_from_script to 42, got #{result}" unless result == '42'
    ensure
      script.unlink
    end

    raise errors.join("\n") unless errors.empty?
  end

  def test_load_tclscript_with_encoding
    assert_tk_app("Tk.load_tclscript with encoding", method(:load_tclscript_encoding_app))
  end

  def load_tclscript_encoding_app
    require 'tk'
    require 'tempfile'

    errors = []

    # Create a temporary Tcl script with UTF-8 content
    script = Tempfile.new(['test', '.tcl'])
    script.write('set __test_utf8_var "日本語"')
    script.close

    begin
      # Load with explicit encoding
      Tk.load_tclscript(script.path, 'utf-8')

      result = Tk.ip_invoke('set', '__test_utf8_var')
      errors << "Script should set __test_utf8_var to '日本語', got #{result}" unless result == '日本語'
    ensure
      script.unlink
    end

    raise errors.join("\n") unless errors.empty?
  end

  def test_load_tclscript_file_not_found
    assert_tk_app("Tk.load_tclscript file not found", method(:load_tclscript_not_found_app))
  end

  def load_tclscript_not_found_app
    require 'tk'

    errors = []

    # Should raise an error for non-existent file
    begin
      Tk.load_tclscript('/nonexistent/path/to/script.tcl')
      errors << "Should raise error for non-existent file"
    rescue => e
      errors << "Expected TclError, got #{e.class}" unless e.is_a?(RuntimeError) || e.is_a?(TclTkLib::TclError)
    end

    raise errors.join("\n") unless errors.empty?
  end

  # --- Tk.pkgconfig methods ---
  # These may not be available on all systems, so we test gracefully

  def test_tcl_pkgconfig_list
    assert_tk_app("Tk.tcl_pkgconfig_list", method(:tcl_pkgconfig_list_app))
  end

  def tcl_pkgconfig_list_app
    require 'tk'

    errors = []

    begin
      result = Tk.tcl_pkgconfig_list
      errors << "Tk.tcl_pkgconfig_list should return an array" unless result.is_a?(Array)
    rescue => e
      # pkgconfig may not be available - that's OK, just verify the method exists
      errors << "Tk.tcl_pkgconfig_list raised unexpected error: #{e.class}" unless e.message.include?('pkgconfig') || e.message.include?('invalid command')
    end

    raise errors.join("\n") unless errors.empty?
  end

  def test_tk_pkgconfig_list
    assert_tk_app("Tk.tk_pkgconfig_list", method(:tk_pkgconfig_list_app))
  end

  def tk_pkgconfig_list_app
    require 'tk'

    errors = []

    begin
      result = Tk.tk_pkgconfig_list
      errors << "Tk.tk_pkgconfig_list should return an array" unless result.is_a?(Array)
    rescue => e
      # pkgconfig may not be available
      errors << "Tk.tk_pkgconfig_list raised unexpected error: #{e.class}" unless e.message.include?('pkgconfig') || e.message.include?('invalid command')
    end

    raise errors.join("\n") unless errors.empty?
  end

  # --- Tk version constants ---

  def test_version_constants
    require 'tk'

    # TCL_VERSION
    assert_kind_of String, Tk::TCL_VERSION
    assert_match(/^\d+\.\d+$/, Tk::TCL_VERSION)
    assert Tk::TCL_VERSION.frozen?

    # TCL_PATCHLEVEL
    assert_kind_of String, Tk::TCL_PATCHLEVEL
    assert Tk::TCL_PATCHLEVEL.frozen?

    # TCL_MAJOR_VERSION, TCL_MINOR_VERSION
    assert_kind_of Integer, Tk::TCL_MAJOR_VERSION
    assert_kind_of Integer, Tk::TCL_MINOR_VERSION
    assert Tk::TCL_MAJOR_VERSION >= 8

    # TK_VERSION
    assert_kind_of String, Tk::TK_VERSION
    assert_match(/^\d+\.\d+$/, Tk::TK_VERSION)
    assert Tk::TK_VERSION.frozen?

    # TK_PATCHLEVEL
    assert_kind_of String, Tk::TK_PATCHLEVEL
    assert Tk::TK_PATCHLEVEL.frozen?

    # TK_MAJOR_VERSION, TK_MINOR_VERSION
    assert_kind_of Integer, Tk::TK_MAJOR_VERSION
    assert_kind_of Integer, Tk::TK_MINOR_VERSION
    assert Tk::TK_MAJOR_VERSION >= 8

    # RELEASE_DATE
    assert_kind_of String, Tk::RELEASE_DATE
    assert Tk::RELEASE_DATE.frozen?
  end
end
