# frozen_string_literal: true

# Tests for TkComm module (lib/tkcomm.rb)
# See test_tk_tcl2ruby.rb and test_tk_list.rb for tk_tcl2ruby and list tests.

require_relative 'test_helper'
require_relative 'tk_test_helper'

class TestTkComm < Minitest::Test
  include TkTestHelper

  # --- _at helper ---

  def test_at_with_one_arg
    assert_tk_app("TkComm._at with one arg", method(:app_at_one))
  end

  def app_at_one
    require 'tk'

    errors = []

    result = TkComm._at(10)
    errors << "expected '@10', got #{result.inspect}" unless result == "@10"

    result = TkComm._at(0)
    errors << "expected '@0', got #{result.inspect}" unless result == "@0"

    raise errors.join("\n") unless errors.empty?
  end

  def test_at_with_two_args
    assert_tk_app("TkComm._at with two args", method(:app_at_two))
  end

  def app_at_two
    require 'tk'

    errors = []

    result = TkComm._at(10, 20)
    errors << "expected '@10,20', got #{result.inspect}" unless result == "@10,20"

    result = TkComm._at(0, 0)
    errors << "expected '@0,0', got #{result.inspect}" unless result == "@0,0"

    raise errors.join("\n") unless errors.empty?
  end

  # --- window helper ---

  def test_window_lookup
    assert_tk_app("TkComm.window lookup", method(:app_window_lookup))
  end

  def app_window_lookup
    require 'tk'

    errors = []

    # Root window
    result = TkComm.window(".")
    errors << "root should be TkRoot" unless result.is_a?(TkRoot)

    # Create a widget and look it up
    btn = TkButton.new(root, text: "Test")
    result = TkComm.window(btn.path)
    errors << "should return the button widget" unless result == btn

    # Non-widget path returns nil
    result = TkComm.window("not_a_path")
    errors << "non-path should return nil" unless result.nil?

    raise errors.join("\n") unless errors.empty?
  end

  # --- image_obj helper ---

  def test_image_obj_lookup
    assert_tk_app("TkComm.image_obj lookup", method(:app_image_obj))
  end

  def app_image_obj
    require 'tk'

    errors = []

    # Non-image pattern returns as-is
    result = TkComm.image_obj("not_an_image")
    errors << "non-image should return as-is" unless result == "not_an_image"

    # Image pattern not in table returns as-is
    result = TkComm.image_obj("i99999")
    errors << "unregistered image should return as-is" unless result == "i99999"

    raise errors.join("\n") unless errors.empty?
  end

  # --- procedure helper ---

  def test_procedure_lookup
    assert_tk_app("TkComm.procedure lookup", method(:app_procedure))
  end

  def app_procedure
    require 'tk'

    errors = []

    # Non-callback pattern returns as-is
    result = TkComm.procedure("not_a_callback")
    errors << "non-callback should return as-is" unless result == "not_a_callback"

    # Callback pattern - register one and look it up
    test_proc = proc { "test" }
    cmd_str = TkComm.install_cmd(test_proc)
    result = TkComm.procedure(cmd_str)
    errors << "should return the proc" unless result == test_proc

    TkComm.uninstall_cmd(cmd_str)
    raise errors.join("\n") unless errors.empty?
  end

  # --- _callback_entry? type checks ---

  def test_callback_entry_check
    assert_tk_app("TkComm._callback_entry?", method(:app_callback_entry))
  end

  def app_callback_entry
    require 'tk'

    errors = []

    errors << "Proc should be callback entry" unless TkComm._callback_entry?(proc {})
    errors << "lambda should be callback entry" unless TkComm._callback_entry?(-> {})

    def self.test_method; end
    errors << "Method should be callback entry" unless TkComm._callback_entry?(method(:test_method))

    errors << "String should not be callback entry" if TkComm._callback_entry?("string")
    errors << "Integer should not be callback entry" if TkComm._callback_entry?(42)

    raise errors.join("\n") unless errors.empty?
  end

  # --- install_cmd / uninstall_cmd ---

  def test_install_uninstall_cmd
    assert_tk_app("TkComm install/uninstall cmd", method(:app_install_cmd))
  end

  def app_install_cmd
    require 'tk'

    errors = []

    # Install a command
    test_proc = proc { "installed" }
    cmd_str = TkComm.install_cmd(test_proc)

    errors << "cmd_str should start with 'rb_out'" unless cmd_str.start_with?("rb_out")
    errors << "cmd_str should contain command ID" unless cmd_str =~ /c(_\d+_)?\d+/

    # Extract the full ID (format: c or c_N_XXXXX)
    id = cmd_str.match(/c(_\d+_)?\d+/)[0]

    # Verify it's in the table (use has_key? since [] raises for missing keys)
    errors << "cmd should be in table" unless TkCore::INTERP.tk_cmd_tbl.has_key?(id)

    # Uninstall
    TkComm.uninstall_cmd(cmd_str)
    errors << "cmd should be removed from table" if TkCore::INTERP.tk_cmd_tbl.has_key?(id)

    # Empty string returns empty
    result = TkComm.install_cmd('')
    errors << "empty cmd should return empty string" unless result == ''

    raise errors.join("\n") unless errors.empty?
  end

  # --- slice_ary ---

  def test_slice_ary
    assert_tk_app("TkComm.slice_ary", method(:app_slice_ary))
  end

  def app_slice_ary
    require 'tk'

    errors = []

    # Without block
    result = TkComm.slice_ary([1, 2, 3, 4, 5, 6], 2)
    errors << "should slice into pairs" unless result == [[1, 2], [3, 4], [5, 6]]

    result = TkComm.slice_ary([1, 2, 3, 4, 5], 3)
    errors << "should handle uneven slices" unless result == [[1, 2, 3], [4, 5]]

    # With block
    collected = []
    TkComm.slice_ary([1, 2, 3, 4], 2) { |chunk| collected << chunk }
    errors << "block should receive chunks" unless collected == [[1, 2], [3, 4]]

    raise errors.join("\n") unless errors.empty?
  end

  # --- subst (via Tk which includes TkComm) ---

  def test_subst
    assert_tk_app("subst via Tk", method(:app_subst))
  end

  def app_subst
    require 'tk'

    errors = []

    # subst is mixed into Tk via TkComm
    # Create a Tcl variable directly
    Tk.tk_call('set', 'test_subst_var', 'hello')
    result = Tk.subst('$test_subst_var')
    errors << "should substitute variable, got #{result.inspect}" unless result == "hello"

    # With nocommands option
    result = Tk.subst('[expr 1+1]', :nocommands)
    errors << "nocommands should prevent cmd substitution" unless result == "[expr 1+1]"

    raise errors.join("\n") unless errors.empty?
  end

  # --- _toUTF8 / _fromUTF8 (no-ops) ---

  def test_encoding_no_ops
    assert_tk_app("TkComm encoding no-ops", method(:app_encoding_no_ops))
  end

  def app_encoding_no_ops
    require 'tk'

    errors = []

    # _toUTF8 returns string as-is
    result = TkComm._toUTF8("hello")
    errors << "_toUTF8 should return string" unless result == "hello"

    # _fromUTF8 returns string as-is
    result = TkComm._fromUTF8("world")
    errors << "_fromUTF8 should return string" unless result == "world"

    # Works with symbols too (to_s)
    result = TkComm._toUTF8(:symbol)
    errors << "_toUTF8 should handle symbol" unless result == "symbol"

    raise errors.join("\n") unless errors.empty?
  end

  # --- tk_event_sequence ---

  def test_tk_event_sequence
    assert_tk_app("TkComm tk_event_sequence", method(:app_event_sequence))
  end

  def app_event_sequence
    require 'tk'

    errors = []

    # Include TkComm to access private method via send
    obj = Object.new
    obj.extend(TkComm)

    # Simple string
    result = obj.send(:tk_event_sequence, "Button-1")
    errors << "simple should pass through" unless result == "Button-1"

    # Comma-separated becomes angle-bracket separated
    result = obj.send(:tk_event_sequence, "Control, a")
    errors << "comma should become >< separator" unless result == "Control><a"

    # Array of events
    result = obj.send(:tk_event_sequence, ["Button-1", "Button-3"])
    errors << "array should be joined" unless result == "Button-1><Button-3"

    raise errors.join("\n") unless errors.empty?
  end

  # --- bind / bindinfo (via Tk which includes TkComm) ---

  def test_bind_and_bindinfo
    assert_tk_app("bind/bindinfo via Tk", method(:app_bind_bindinfo))
  end

  def app_bind_bindinfo
    require 'tk'

    errors = []

    btn = TkButton.new(root, text: "Bind test")

    # Bind a callback - use Tk.bind which includes TkComm
    Tk.bind(btn.path, "Button-1") { }

    # Check bindinfo
    info = Tk.bindinfo(btn.path, "Button-1")
    errors << "bindinfo should return binding" unless info && info.size > 0

    # bindinfo without context lists all sequences
    seqs = Tk.bindinfo(btn.path)
    errors << "bindinfo should list sequences" unless seqs.include?("Button-1")

    raise errors.join("\n") unless errors.empty?
  end

  def test_bind_append
    assert_tk_app("bind_append via Tk", method(:app_bind_append))
  end

  def app_bind_append
    require 'tk'

    errors = []

    btn = TkButton.new(root, text: "Append test")

    count = 0
    Tk.bind(btn.path, "Button-1") { count += 1 }
    Tk.bind_append(btn.path, "Button-1") { count += 10 }

    # Both bindings should exist
    info = Tk.bindinfo(btn.path, "Button-1")
    errors << "should have 2 bindings" unless info.size == 2

    raise errors.join("\n") unless errors.empty?
  end

  def test_bind_remove
    assert_tk_app("bind_remove via Tk", method(:app_bind_remove))
  end

  def app_bind_remove
    require 'tk'

    errors = []

    btn = TkButton.new(root, text: "Remove test")

    Tk.bind(btn.path, "Button-1") { }
    Tk.bind_remove(btn.path, "Button-1")

    # Binding should be removed
    info = Tk.bindinfo(btn.path, "Button-1")
    # After remove, bindinfo returns empty or just ""
    errors << "binding should be removed" unless info.empty? || info == [""]

    raise errors.join("\n") unless errors.empty?
  end

  # --- bind_all / bindinfo_all ---

  def test_bind_all
    assert_tk_app("bind_all via Tk", method(:app_bind_all))
  end

  def app_bind_all
    require 'tk'

    errors = []

    # bind_all returns TkBindTag::ALL
    result = Tk.bind_all("Control-Shift-F12") { }
    errors << "should return TkBindTag::ALL" unless result == TkBindTag::ALL

    # bindinfo_all should show the binding (format may vary)
    seqs = Tk.bindinfo_all
    # Check if any sequence contains our key combination
    found = seqs.any? { |s| s.to_s.include?("Control") && s.to_s.include?("F12") }
    errors << "should list bound sequence, got #{seqs.inspect}" unless found

    # Clean up
    Tk.bind_remove_all("Control-Shift-F12")

    raise errors.join("\n") unless errors.empty?
  end

  # --- WidgetClassNames ---

  def test_widget_class_names
    assert_tk_app("TkComm WidgetClassNames", method(:app_widget_class_names))
  end

  def app_widget_class_names
    require 'tk'

    errors = []

    # Create widgets to ensure they're loaded and registered
    TkButton.new(root)
    TkLabel.new(root)
    TkFrame.new(root)
    TkEntry.new(root)

    # Now they should be registered
    errors << "Button should be registered" unless TkComm::WidgetClassNames['Button']
    errors << "Label should be registered" unless TkComm::WidgetClassNames['Label']
    errors << "Frame should be registered" unless TkComm::WidgetClassNames['Frame']
    errors << "Entry should be registered" unless TkComm::WidgetClassNames['Entry']

    # Toplevel needs explicit require
    require 'tk/toplevel'
    TkToplevel.new(root) { withdraw }
    errors << "Toplevel should be registered" unless TkComm::WidgetClassNames['Toplevel']

    raise errors.join("\n") unless errors.empty?
  end
end
