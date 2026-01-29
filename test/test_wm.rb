# frozen_string_literal: true

# Tests for Tk::Wm window manager methods
# https://www.tcl.tk/man/tcl8.6/TkCmd/wm.htm

require_relative 'test_helper'
require_relative 'tk_test_helper'

class TestWm < Minitest::Test
  include TkTestHelper

  def test_title
    assert_tk_app("wm title", method(:title_app))
  end

  def title_app
    require 'tk'
    errors = []

    root.title("Test Window")
    errors << "title not set" unless root.title == "Test Window"

    root.wm_title("Another Title")
    errors << "wm_title alias failed" unless root.title == "Another Title"

    raise errors.join("\n") unless errors.empty?
  end

  def test_geometry
    assert_tk_app("wm geometry", method(:geometry_app))
  end

  def geometry_app
    require 'tk'
    errors = []

    # Reset any size constraints from previous tests
    root.minsize(1, 1)
    root.maxsize(10000, 10000)

    root.geometry("200x150+100+50")
    Tk.update
    geom = root.geometry
    errors << "geometry should contain 200x150: #{geom}" unless geom.include?("200x150")

    raise errors.join("\n") unless errors.empty?
  end

  def test_minsize_maxsize
    assert_tk_app("wm minsize/maxsize", method(:minsize_maxsize_app))
  end

  def minsize_maxsize_app
    require 'tk'
    errors = []

    root.minsize(100, 80)
    errors << "minsize wrong: #{root.minsize.inspect}" unless root.minsize == [100, 80]

    root.maxsize(800, 600)
    errors << "maxsize wrong: #{root.maxsize.inspect}" unless root.maxsize == [800, 600]

    raise errors.join("\n") unless errors.empty?
  end

  def test_resizable
    assert_tk_app("wm resizable", method(:resizable_app))
  end

  def resizable_app
    require 'tk'
    errors = []

    root.resizable(false, false)
    errors << "resizable(false,false) failed: #{root.resizable.inspect}" unless root.resizable == [false, false]

    root.resizable(true, true)
    errors << "resizable(true,true) failed: #{root.resizable.inspect}" unless root.resizable == [true, true]

    raise errors.join("\n") unless errors.empty?
  end

  def test_state_withdraw_deiconify
    assert_tk_app("wm state/withdraw/deiconify", method(:state_app))
  end

  def state_app
    require 'tk'
    errors = []

    # TkWorker root starts withdrawn - deiconify first
    root.deiconify
    Tk.update
    errors << "deiconify should set state to normal" unless root.state == "normal"

    root.withdraw
    Tk.update
    errors << "withdraw should set state to withdrawn" unless root.state == "withdrawn"

    root.deiconify
    Tk.update
    errors << "deiconify after withdraw should be normal" unless root.state == "normal"

    # withdraw(false) should deiconify
    root.withdraw
    Tk.update
    root.withdraw(false)
    Tk.update
    errors << "withdraw(false) should deiconify" unless root.state == "normal"

    raise errors.join("\n") unless errors.empty?
  end

  def test_attributes
    assert_tk_app("wm attributes", method(:attributes_app))
  end

  def attributes_app
    require 'tk'
    errors = []

    attrs = root.attributes

    # Platform-specific attribute checks
    # X11/Linux: zoomed, fullscreen, topmost, type
    # macOS: alpha, fullscreen, modified, notify, titlepath, topmost, transparent
    # Windows: alpha, disabled, fullscreen, toolwindow, topmost, transparentcolor
    case Tk.platform["platform"]
    when "unix"
      if Tk.platform["os"] == "Darwin"
        errors << "macOS should have 'alpha' attribute" unless attrs.key?("alpha")
      else
        # Linux/X11
        errors << "X11 should have 'zoomed' attribute" unless attrs.key?("zoomed")
      end
    when "windows"
      errors << "Windows should have 'alpha' attribute" unless attrs.key?("alpha")
    end

    # Test fullscreen attribute (exists on all platforms)
    root.attributes("fullscreen", false)
    val = root.attributes("fullscreen")
    errors << "fullscreen should be false/0, got: #{val.inspect}" unless val == "0" || val == 0 || val == false

    raise errors.join("\n") unless errors.empty?
  end

  def test_protocol
    assert_tk_app("wm protocol", method(:protocol_app))
  end

  def protocol_app
    require 'tk'
    errors = []

    root.protocol("WM_DELETE_WINDOW") { }
    protocols = root.protocol
    errors << "protocol list should include WM_DELETE_WINDOW" unless protocols.include?("WM_DELETE_WINDOW")

    handler = root.protocol("WM_DELETE_WINDOW")
    errors << "protocol handler should be retrievable" if handler.nil?

    raise errors.join("\n") unless errors.empty?
  end

  def test_protocols_hash
    assert_tk_app("wm protocols hash", method(:protocols_hash_app))
  end

  def protocols_hash_app
    require 'tk'
    errors = []

    root.protocols({
      "WM_DELETE_WINDOW" => proc { },
      "WM_SAVE_YOURSELF" => proc { }
    })
    all = root.protocols
    errors << "protocols should have WM_DELETE_WINDOW key" unless all.key?("WM_DELETE_WINDOW")
    errors << "protocols should have WM_SAVE_YOURSELF key" unless all.key?("WM_SAVE_YOURSELF")

    raise errors.join("\n") unless errors.empty?
  end

  def test_overrideredirect
    assert_tk_app("wm overrideredirect", method(:overrideredirect_app))
  end

  def overrideredirect_app
    require 'tk'
    errors = []

    errors << "overrideredirect default should be false" unless root.overrideredirect == false

    root.overrideredirect(true)
    errors << "overrideredirect(true) failed" unless root.overrideredirect == true

    root.overrideredirect(false)
    errors << "overrideredirect(false) failed" unless root.overrideredirect == false

    raise errors.join("\n") unless errors.empty?
  end

  def test_focusmodel
    assert_tk_app("wm focusmodel", method(:focusmodel_app))
  end

  def focusmodel_app
    require 'tk'
    errors = []

    root.focusmodel("passive")
    errors << "focusmodel(passive) failed" unless root.focusmodel == "passive"

    root.focusmodel("active")
    errors << "focusmodel(active) failed" unless root.focusmodel == "active"

    raise errors.join("\n") unless errors.empty?
  end

  def test_iconname
    assert_tk_app("wm iconname", method(:iconname_app))
  end

  def iconname_app
    require 'tk'
    errors = []

    root.iconname("TestIcon")
    errors << "iconname not set" unless root.iconname == "TestIcon"

    raise errors.join("\n") unless errors.empty?
  end

  def test_client
    assert_tk_app("wm client", method(:client_app))
  end

  def client_app
    require 'tk'
    errors = []

    root.client("testclient")
    errors << "client not set" unless root.client == "testclient"

    root.client(nil)
    errors << "client(nil) should clear" unless root.client == ""

    raise errors.join("\n") unless errors.empty?
  end

  def test_positionfrom_sizefrom
    assert_tk_app("wm positionfrom/sizefrom", method(:positionfrom_sizefrom_app))
  end

  def positionfrom_sizefrom_app
    require 'tk'
    errors = []

    root.positionfrom("user")
    errors << "positionfrom(user) failed" unless root.positionfrom == "user"

    root.sizefrom("program")
    errors << "sizefrom(program) failed" unless root.sizefrom == "program"

    raise errors.join("\n") unless errors.empty?
  end

  def test_aspect
    assert_tk_app("wm aspect", method(:aspect_app))
  end

  def aspect_app
    require 'tk'
    errors = []

    root.aspect(1, 1, 2, 1)
    errors << "aspect not set" unless root.aspect == [1, 1, 2, 1]

    root.aspect("", "", "", "")
    errors << "aspect clear failed" unless root.aspect == []

    raise errors.join("\n") unless errors.empty?
  end

  def test_stackorder
    assert_tk_app("wm stackorder", method(:stackorder_app))
  end

  def stackorder_app
    require 'tk'
    errors = []

    child = TkToplevel.new(root)
    child_path = child.path
    Tk.update

    order = root.stackorder
    # stackorder returns window objects - should include our child
    found_child = order.any? { |w| w.respond_to?(:path) && w.path == child_path }
    errors << "stackorder should include child #{child_path}: #{order.map { |w| w.respond_to?(:path) ? w.path : w }.inspect}" unless found_child

    child.destroy

    raise errors.join("\n") unless errors.empty?
  end

  def test_transient
    assert_tk_app("wm transient", method(:transient_app))
  end

  def transient_app
    require 'tk'
    errors = []

    child = TkToplevel.new(root)
    child.transient(root)
    Tk.update
    master = child.transient
    errors << "transient should return master window" if master.nil?
    child.destroy

    raise errors.join("\n") unless errors.empty?
  end

  def test_frame
    assert_tk_app("wm frame", method(:frame_app))
  end

  def frame_app
    require 'tk'
    errors = []

    frame_id = root.frame
    # frame returns hex window ID or empty string
    errors << "frame should return hex ID or empty: #{frame_id}" unless frame_id == "" || frame_id =~ /^0x[0-9a-f]+$/i

    raise errors.join("\n") unless errors.empty?
  end

  # Note: iconify test skipped - hangs in headless xvfb environment

  def test_wm_command
    assert_tk_app("wm command", method(:wm_command_app))
  end

  def wm_command_app
    require 'tk'
    errors = []

    root.wm_command("myapp --option value")
    errors << "wm_command not set" unless root.wm_command == "myapp --option value"

    raise errors.join("\n") unless errors.empty?
  end

  def test_iconposition
    assert_tk_app("wm iconposition", method(:iconposition_app))
  end

  def iconposition_app
    require 'tk'
    errors = []

    root.iconposition(100, 200)
    pos = root.iconposition
    errors << "iconposition should be [100, 200], got #{pos.inspect}" unless pos == [100, 200]

    raise errors.join("\n") unless errors.empty?
  end

  def test_group
    assert_tk_app("wm group", method(:group_app))
  end

  def group_app
    require 'tk'
    errors = []

    child = TkToplevel.new(root)
    child.group(root)
    Tk.update

    leader = child.group
    errors << "group should return leader window" if leader.nil?
    child.destroy

    raise errors.join("\n") unless errors.empty?
  end

  def test_wm_grid
    assert_tk_app("wm grid", method(:wm_grid_app))
  end

  def wm_grid_app
    require 'tk'
    errors = []

    # Set grid: baseWidth, baseHeight, widthInc, heightInc
    root.wm_grid(10, 10, 5, 5)
    grid = root.wm_grid
    errors << "wm_grid should be [10, 10, 5, 5], got #{grid.inspect}" unless grid == [10, 10, 5, 5]

    # Clear grid
    root.wm_grid("", "", "", "")
    grid = root.wm_grid
    errors << "wm_grid clear failed, got #{grid.inspect}" unless grid == []

    raise errors.join("\n") unless errors.empty?
  end

  def test_colormapwindows
    assert_tk_app("wm colormapwindows", method(:colormapwindows_app))
  end

  def colormapwindows_app
    require 'tk'
    errors = []

    # Get current colormap windows (may be empty or contain root)
    windows = root.colormapwindows
    # Should return an array (possibly empty)
    errors << "colormapwindows should return array, got #{windows.class}" unless windows.is_a?(Array)

    raise errors.join("\n") unless errors.empty?
  end

  def test_manage_forget
    assert_tk_app("wm manage/forget", method(:manage_forget_app))
  end

  def manage_forget_app
    require 'tk'
    errors = []

    # Create a frame inside root
    frame = TkFrame.new(root)
    frame.pack
    Tk.update

    # wm manage makes a frame into a toplevel
    Tk::Wm.manage(frame)
    Tk.update

    # Frame should now have wm properties - set and get title
    Tk::Wm.title(frame, "Managed Frame")
    errors << "managed frame title failed" unless Tk::Wm.title(frame) == "Managed Frame"

    # wm forget returns it to normal frame
    Tk::Wm.forget(frame)
    Tk.update

    frame.destroy

    raise errors.join("\n") unless errors.empty?
  end
end
