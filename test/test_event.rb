# frozen_string_literal: true

# Tests for TkEvent module (lib/tk/event.rb)

require_relative 'test_helper'
require_relative 'tk_test_helper'

class TestEvent < Minitest::Test
  include TkTestHelper

  # --- TkEvent::Event class methods ---

  def test_event_type_id
    assert_tk_app("Event.type_id", method(:app_event_type_id))
  end

  def app_event_type_id
    require 'tk'

    errors = []

    # Known event type names to IDs
    errors << "KeyPress should be 2" unless TkEvent::Event.type_id('KeyPress') == 2
    errors << "Key should be 2" unless TkEvent::Event.type_id('Key') == 2
    errors << "ButtonPress should be 4" unless TkEvent::Event.type_id('ButtonPress') == 4
    errors << "Button should be 4" unless TkEvent::Event.type_id('Button') == 4
    errors << "Motion should be 6" unless TkEvent::Event.type_id('Motion') == 6
    errors << "Enter should be 7" unless TkEvent::Event.type_id('Enter') == 7
    errors << "Leave should be 8" unless TkEvent::Event.type_id('Leave') == 8
    errors << "Destroy should be 17" unless TkEvent::Event.type_id('Destroy') == 17
    errors << "Configure should be 22" unless TkEvent::Event.type_id('Configure') == 22
    errors << "MouseWheel should be 38" unless TkEvent::Event.type_id('MouseWheel') == 38

    # Unknown returns nil
    errors << "Unknown type should return nil" unless TkEvent::Event.type_id('NotARealEvent').nil?

    raise errors.join("\n") unless errors.empty?
  end

  def test_event_type_name
    assert_tk_app("Event.type_name", method(:app_event_type_name))
  end

  def app_event_type_name
    require 'tk'

    errors = []

    # ID to primary name
    errors << "2 should be KeyPress" unless TkEvent::Event.type_name(2) == 'KeyPress'
    errors << "4 should be ButtonPress" unless TkEvent::Event.type_name(4) == 'ButtonPress'
    errors << "6 should be Motion" unless TkEvent::Event.type_name(6) == 'Motion'
    errors << "17 should be Destroy" unless TkEvent::Event.type_name(17) == 'Destroy'

    # Unknown ID returns nil
    errors << "999 should return nil" unless TkEvent::Event.type_name(999).nil?

    raise errors.join("\n") unless errors.empty?
  end

  def test_event_group_flag
    assert_tk_app("Event.group_flag", method(:app_event_group_flag))
  end

  def app_event_group_flag
    require 'tk'

    errors = []
    grp = TkEvent::Event::Grp

    # Check group flags for various event types
    errors << "KeyPress should have KEY flag" unless TkEvent::Event.group_flag(2) == grp::KEY
    errors << "ButtonPress should have BUTTON flag" unless TkEvent::Event.group_flag(4) == grp::BUTTON
    errors << "Motion should have MOTION flag" unless TkEvent::Event.group_flag(6) == grp::MOTION
    errors << "Enter should have CROSSING flag" unless TkEvent::Event.group_flag(7) == grp::CROSSING
    errors << "FocusIn should have FOCUS flag" unless TkEvent::Event.group_flag(9) == grp::FOCUS
    errors << "Expose should have EXPOSE flag" unless TkEvent::Event.group_flag(12) == grp::EXPOSE
    errors << "Destroy should have DESTROY flag" unless TkEvent::Event.group_flag(17) == grp::DESTROY
    errors << "Configure should have CONFIG flag" unless TkEvent::Event.group_flag(22) == grp::CONFIG
    errors << "MouseWheel should have MWHEEL flag" unless TkEvent::Event.group_flag(38) == grp::MWHEEL

    # Unknown ID returns 0
    errors << "Unknown ID should return 0" unless TkEvent::Event.group_flag(999) == 0

    raise errors.join("\n") unless errors.empty?
  end

  # --- TkEvent::Event::Grp constants ---

  def test_event_grp_constants
    assert_tk_app("Event::Grp constants", method(:app_event_grp_constants))
  end

  def app_event_grp_constants
    require 'tk'

    errors = []
    grp = TkEvent::Event::Grp

    # Verify bit flags are powers of 2 (single bit set)
    errors << "KEY should be 0x1" unless grp::KEY == 0x1
    errors << "BUTTON should be 0x2" unless grp::BUTTON == 0x2
    errors << "MOTION should be 0x4" unless grp::MOTION == 0x4
    errors << "CROSSING should be 0x8" unless grp::CROSSING == 0x8
    errors << "FOCUS should be 0x10" unless grp::FOCUS == 0x10
    errors << "EXPOSE should be 0x20" unless grp::EXPOSE == 0x20
    errors << "VISIBILITY should be 0x40" unless grp::VISIBILITY == 0x40
    errors << "DESTROY should be 0x100" unless grp::DESTROY == 0x100
    errors << "CONFIG should be 0x1000" unless grp::CONFIG == 0x1000
    errors << "VIRTUAL should be 0x20000" unless grp::VIRTUAL == 0x20000

    # Compound flags
    errors << "MWHEEL should equal KEY" unless grp::MWHEEL == grp::KEY
    errors << "ALL should be 0xFFFFFFFF" unless grp::ALL == 0xFFFFFFFF

    # KEY_BUTTON_MOTION_VIRTUAL should combine the flags
    expected = grp::KEY | grp::MWHEEL | grp::BUTTON | grp::MOTION | grp::VIRTUAL
    errors << "KEY_BUTTON_MOTION_VIRTUAL wrong" unless grp::KEY_BUTTON_MOTION_VIRTUAL == expected

    raise errors.join("\n") unless errors.empty?
  end

  # --- TkEvent::Event::TypeNum constants ---

  def test_event_typenum_constants
    assert_tk_app("Event::TypeNum constants", method(:app_event_typenum))
  end

  def app_event_typenum
    require 'tk'

    errors = []
    tn = TkEvent::Event::TypeNum

    errors << "KeyPress should be 2" unless tn::KeyPress == 2
    errors << "KeyRelease should be 3" unless tn::KeyRelease == 3
    errors << "ButtonPress should be 4" unless tn::ButtonPress == 4
    errors << "ButtonRelease should be 5" unless tn::ButtonRelease == 5
    errors << "MotionNotify should be 6" unless tn::MotionNotify == 6
    errors << "EnterNotify should be 7" unless tn::EnterNotify == 7
    errors << "LeaveNotify should be 8" unless tn::LeaveNotify == 8
    errors << "FocusIn should be 9" unless tn::FocusIn == 9
    errors << "FocusOut should be 10" unless tn::FocusOut == 10
    errors << "DestroyNotify should be 17" unless tn::DestroyNotify == 17
    errors << "ConfigureNotify should be 22" unless tn::ConfigureNotify == 22
    errors << "MouseWheelEvent should be 38" unless tn::MouseWheelEvent == 38
    errors << "TK_LASTEVENT should be 39" unless tn::TK_LASTEVENT == 39

    raise errors.join("\n") unless errors.empty?
  end

  # --- TkEvent::Event::StateMask constants ---

  def test_event_statemask_constants
    assert_tk_app("Event::StateMask constants", method(:app_event_statemask))
  end

  def app_event_statemask
    require 'tk'

    errors = []
    sm = TkEvent::Event::StateMask

    # Verify modifier masks are correct bit positions
    errors << "ShiftMask should be 1" unless sm::ShiftMask == 1
    errors << "LockMask should be 2" unless sm::LockMask == 2
    errors << "ControlMask should be 4" unless sm::ControlMask == 4
    errors << "Mod1Mask should be 8" unless sm::Mod1Mask == 8
    errors << "Mod2Mask should be 16" unless sm::Mod2Mask == 16
    errors << "Mod3Mask should be 32" unless sm::Mod3Mask == 32
    errors << "Mod4Mask should be 64" unless sm::Mod4Mask == 64
    errors << "Mod5Mask should be 128" unless sm::Mod5Mask == 128
    errors << "Button1Mask should be 256" unless sm::Button1Mask == 256
    errors << "Button2Mask should be 512" unless sm::Button2Mask == 512
    errors << "Button3Mask should be 1024" unless sm::Button3Mask == 1024
    errors << "AnyModifier should be 32768" unless sm::AnyModifier == 32768

    # Mac-specific aliases
    errors << "CommandMask should equal Mod1Mask" unless sm::CommandMask == sm::Mod1Mask
    errors << "OptionMask should equal Mod2Mask" unless sm::OptionMask == sm::Mod2Mask

    raise errors.join("\n") unless errors.empty?
  end

  # --- TYPE_NAME_TBL and TYPE_ID_TBL ---

  def test_event_type_tables
    assert_tk_app("Event type tables", method(:app_event_type_tables))
  end

  def app_event_type_tables
    require 'tk'

    errors = []

    # TYPE_NAME_TBL maps names to IDs
    tbl = TkEvent::Event::TYPE_NAME_TBL
    errors << "TYPE_NAME_TBL should be frozen" unless tbl.frozen?
    errors << "TYPE_NAME_TBL should have KeyPress" unless tbl['KeyPress'] == 2
    errors << "TYPE_NAME_TBL should have Key alias" unless tbl['Key'] == 2
    errors << "TYPE_NAME_TBL should have Button alias" unless tbl['Button'] == 4

    # TYPE_ID_TBL maps IDs to name arrays
    id_tbl = TkEvent::Event::TYPE_ID_TBL
    errors << "TYPE_ID_TBL should be frozen" unless id_tbl.frozen?
    errors << "TYPE_ID_TBL[2] should include KeyPress" unless id_tbl[2].include?('KeyPress')
    errors << "TYPE_ID_TBL[2] should include Key" unless id_tbl[2].include?('Key')
    errors << "TYPE_ID_TBL[4] should include ButtonPress" unless id_tbl[4].include?('ButtonPress')

    raise errors.join("\n") unless errors.empty?
  end

  # --- FIELD_FLAG ---

  def test_event_field_flag
    assert_tk_app("Event FIELD_FLAG", method(:app_event_field_flag))
  end

  def app_event_field_flag
    require 'tk'

    errors = []
    grp = TkEvent::Event::Grp
    ff = TkEvent::Event::FIELD_FLAG

    # Check some field flags
    errors << "button field should have BUTTON flag" unless ff['button'] == grp::BUTTON
    errors << "keycode field should have KEY flag" unless ff['keycode'] == grp::KEY
    errors << "keysym field should have KEY flag" unless ff['keysym'] == grp::KEY
    errors << "count field should have EXPOSE flag" unless ff['count'] == grp::EXPOSE
    errors << "delta field should have MWHEEL flag" unless ff['delta'] == grp::MWHEEL
    errors << "serial field should have ALL flag" unless ff['serial'] == grp::ALL

    # height has multiple flags
    expected_height = grp::EXPOSE | grp::CONFIG
    errors << "height field should have EXPOSE|CONFIG" unless ff['height'] == expected_height

    raise errors.join("\n") unless errors.empty?
  end

  # --- Event binding with callback ---

  def test_event_binding
    assert_tk_app("Event binding", method(:app_event_binding))
  end

  def app_event_binding
    require 'tk'

    errors = []
    root.deiconify

    btn = TkButton.new(root, text: "Click me")
    btn.pack

    clicked = false
    btn.bind('ButtonPress-1') { clicked = true }

    # Generate a button click event
    Tk.update
    Tk.event_generate(btn, 'ButtonPress-1')
    Tk.update

    errors << "Callback should have been triggered" unless clicked

    raise errors.join("\n") unless errors.empty?
  end

  def test_event_binding_with_event_object
    assert_tk_app("Event binding with event object", method(:app_event_with_object))
  end

  def app_event_with_object
    require 'tk'

    errors = []
    root.deiconify

    btn = TkButton.new(root, text: "Click")
    btn.pack

    event_type = nil
    event_widget = nil
    btn.bind('ButtonPress-1') do |e|
      event_type = e.type
      event_widget = e.widget
    end

    Tk.update
    Tk.event_generate(btn, 'ButtonPress-1')
    Tk.update

    errors << "Event type should be 4 (ButtonPress)" unless event_type == 4
    errors << "Event widget should be the button" unless event_widget == btn

    raise errors.join("\n") unless errors.empty?
  end

  def test_event_binding_key_event
    assert_tk_app("Event key binding", method(:app_event_key))
  end

  def app_event_key
    require 'tk'

    errors = []
    root.deiconify
    Tk.update

    entry = TkEntry.new(root)
    entry.pack
    Tk.update

    key_pressed = false
    entry.bind('KeyPress-a') do
      key_pressed = true
    end

    # Key events require focus - use :force since window may not have real focus
    entry.focus(:force)
    Tk.update

    # Generate with -when now to process immediately
    Tk.tk_call('event', 'generate', entry.path, '<KeyPress-a>', '-when', 'now')
    Tk.update

    errors << "Key callback should have been triggered" unless key_pressed

    raise errors.join("\n") unless errors.empty?
  end

  # --- ALIAS_TBL ---

  def test_event_alias_tbl
    assert_tk_app("Event ALIAS_TBL", method(:app_event_alias_tbl))
  end

  def app_event_alias_tbl
    require 'tk'

    errors = []
    tbl = TkEvent::Event::ALIAS_TBL

    errors << "button should alias num" unless tbl[:button] == :num
    errors << "delta should alias wheel_delta" unless tbl[:delta] == :wheel_delta
    errors << "root should alias rootwin_id" unless tbl[:root] == :rootwin_id
    errors << "rootx should alias x_root" unless tbl[:rootx] == :x_root
    errors << "rooty should alias y_root" unless tbl[:rooty] == :y_root
    errors << "sendevent should alias send_event" unless tbl[:sendevent] == :send_event
    errors << "window should alias widget" unless tbl[:window] == :widget

    raise errors.join("\n") unless errors.empty?
  end

  # --- KEY_TBL and PROC_TBL ---

  def test_event_key_tbl
    assert_tk_app("Event KEY_TBL", method(:app_event_key_tbl))
  end

  def app_event_key_tbl
    require 'tk'

    errors = []
    key_tbl = TkEvent::Event::KEY_TBL

    # KEY_TBL contains substitution definitions
    # Each entry is [subst_char, proc_type_char, attr_name]
    serial_entry = key_tbl.find { |e| e.is_a?(Array) && e[2] == :serial }
    errors << "KEY_TBL should have serial entry" unless serial_entry
    errors << "serial subst char should be #" unless serial_entry && serial_entry[0] == ?#

    widget_entry = key_tbl.find { |e| e.is_a?(Array) && e[2] == :widget }
    errors << "KEY_TBL should have widget entry" unless widget_entry
    errors << "widget subst char should be W" unless widget_entry && widget_entry[0] == ?W

    keysym_entry = key_tbl.find { |e| e.is_a?(Array) && e[2] == :keysym }
    errors << "KEY_TBL should have keysym entry" unless keysym_entry
    errors << "keysym subst char should be K" unless keysym_entry && keysym_entry[0] == ?K

    raise errors.join("\n") unless errors.empty?
  end

  def test_event_proc_tbl
    assert_tk_app("Event PROC_TBL", method(:app_event_proc_tbl))
  end

  def app_event_proc_tbl
    require 'tk'

    errors = []
    proc_tbl = TkEvent::Event::PROC_TBL

    # PROC_TBL maps proc_type_char to conversion procs/methods
    num_entry = proc_tbl.find { |e| e.is_a?(Array) && e[0] == ?n }
    errors << "PROC_TBL should have numeric converter" unless num_entry
    errors << "numeric converter should be callable" unless num_entry && num_entry[1].respond_to?(:call)

    str_entry = proc_tbl.find { |e| e.is_a?(Array) && e[0] == ?s }
    errors << "PROC_TBL should have string converter" unless str_entry

    bool_entry = proc_tbl.find { |e| e.is_a?(Array) && e[0] == ?b }
    errors << "PROC_TBL should have boolean converter" unless bool_entry

    win_entry = proc_tbl.find { |e| e.is_a?(Array) && e[0] == ?w }
    errors << "PROC_TBL should have window converter" unless win_entry

    raise errors.join("\n") unless errors.empty?
  end

  # --- Event fields in callback ---

  def test_event_fields_in_callback
    assert_tk_app("Event fields in callback", method(:app_event_fields))
  end

  def app_event_fields
    require 'tk'

    errors = []
    root.deiconify
    Tk.update

    btn = TkButton.new(root, text: "Test")
    btn.pack
    Tk.update

    event_serial = nil
    event_x = nil
    event_y = nil
    event_time = nil

    btn.bind('ButtonPress-1') do |e|
      event_serial = e.serial
      event_x = e.x
      event_y = e.y
      event_time = e.time
    end

    # Generate event with specific coordinates
    Tk.event_generate(btn, 'ButtonPress-1', x: 10, y: 20)
    Tk.update

    errors << "serial should be a number" unless event_serial.is_a?(Integer)
    errors << "x should be 10, got #{event_x}" unless event_x == 10
    errors << "y should be 20, got #{event_y}" unless event_y == 20
    errors << "time should be a number" unless event_time.is_a?(Integer)

    raise errors.join("\n") unless errors.empty?
  end

  # --- Virtual events ---

  def test_virtual_event_binding
    assert_tk_app("Virtual event binding", method(:app_virtual_event))
  end

  def app_virtual_event
    require 'tk'

    errors = []
    root.deiconify

    btn = TkButton.new(root, text: "Test")
    btn.pack
    Tk.update

    triggered = false
    # Virtual events use simple binding (no event object)
    Tk.tk_call('bind', btn.path, '<<MyCustomEvent>>', proc { triggered = true })

    # Generate virtual event using tk_call
    Tk.tk_call('event', 'generate', btn.path, '<<MyCustomEvent>>')
    Tk.update

    errors << "Virtual event should have triggered" unless triggered

    raise errors.join("\n") unless errors.empty?
  end

  # --- Mouse wheel event ---

  def test_mousewheel_event
    assert_tk_app("MouseWheel event", method(:app_mousewheel_event))
  end

  def app_mousewheel_event
    require 'tk'

    errors = []
    root.deiconify
    Tk.update

    canvas = TkCanvas.new(root, width: 200, height: 200)
    canvas.pack
    Tk.update

    delta_received = nil
    canvas.bind('MouseWheel') do |e|
      delta_received = e.wheel_delta
    end

    # Generate mousewheel event with delta
    Tk.event_generate(canvas, 'MouseWheel', delta: 120)
    Tk.update

    errors << "wheel_delta should be 120, got #{delta_received}" unless delta_received == 120

    raise errors.join("\n") unless errors.empty?
  end

  # --- Motion event ---

  def test_motion_event
    assert_tk_app("Motion event", method(:app_motion_event))
  end

  def app_motion_event
    require 'tk'

    errors = []
    root.deiconify
    Tk.update

    canvas = TkCanvas.new(root, width: 200, height: 200)
    canvas.pack
    Tk.update

    motion_x = nil
    motion_y = nil
    canvas.bind('Motion') do |e|
      motion_x = e.x
      motion_y = e.y
    end

    Tk.event_generate(canvas, 'Motion', x: 50, y: 75)
    Tk.update

    errors << "motion x should be 50, got #{motion_x}" unless motion_x == 50
    errors << "motion y should be 75, got #{motion_y}" unless motion_y == 75

    raise errors.join("\n") unless errors.empty?
  end

  # --- Focus events ---

  def test_focus_events
    assert_tk_app("Focus events", method(:app_focus_events))
  end

  def app_focus_events
    require 'tk'

    errors = []
    root.deiconify
    Tk.update

    entry = TkEntry.new(root)
    entry.pack
    Tk.update

    focus_in = false
    focus_out = false

    entry.bind('FocusIn') { focus_in = true }
    entry.bind('FocusOut') { focus_out = true }

    entry.focus(:force)
    Tk.update
    errors << "FocusIn should have triggered" unless focus_in

    # Create another widget and focus it
    entry2 = TkEntry.new(root)
    entry2.pack
    entry2.focus(:force)
    Tk.update
    errors << "FocusOut should have triggered" unless focus_out

    raise errors.join("\n") unless errors.empty?
  end

  # --- Configure event ---

  def test_configure_event
    assert_tk_app("Configure event", method(:app_configure_event))
  end

  def app_configure_event
    require 'tk'

    errors = []
    root.deiconify
    Tk.update

    frame = TkFrame.new(root, width: 100, height: 100)
    frame.pack
    Tk.update

    config_width = nil
    config_height = nil
    frame.bind('Configure') do |e|
      config_width = e.width
      config_height = e.height
    end

    # Resize the frame
    frame.configure(width: 200, height: 150)
    Tk.update

    # Configure event should have been triggered
    errors << "Configure width should be set" unless config_width.is_a?(Integer)
    errors << "Configure height should be set" unless config_height.is_a?(Integer)

    raise errors.join("\n") unless errors.empty?
  end

  # --- LONGKEY_TBL ---

  def test_event_longkey_tbl
    assert_tk_app("Event LONGKEY_TBL", method(:app_event_longkey_tbl))
  end

  def app_event_longkey_tbl
    require 'tk'

    errors = []

    # LONGKEY_TBL is for long substitution keys (like tkdnd)
    # It's typically empty but should be an array
    tbl = TkEvent::Event::LONGKEY_TBL
    errors << "LONGKEY_TBL should be an Array" unless tbl.is_a?(Array)

    raise errors.join("\n") unless errors.empty?
  end

  # --- Event with explicit arguments ---

  def test_event_binding_with_args
    assert_tk_app("Event binding with explicit args", method(:app_event_with_args))
  end

  def app_event_with_args
    require 'tk'

    errors = []
    root.deiconify
    Tk.update

    btn = TkButton.new(root, text: "Test")
    btn.pack
    Tk.update

    received_x = nil
    received_y = nil

    # Bind with explicit arguments (only x and y)
    btn.bind('ButtonPress-1', proc { |x, y|
      received_x = x
      received_y = y
    }, :x, :y)

    Tk.event_generate(btn, 'ButtonPress-1', x: 30, y: 40)
    Tk.update

    errors << "x should be 30, got #{received_x}" unless received_x == 30
    errors << "y should be 40, got #{received_y}" unless received_y == 40

    raise errors.join("\n") unless errors.empty?
  end
end
