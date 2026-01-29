# frozen_string_literal: true

# Tests for TkWinfo - window information query methods
#
# TkWinfo wraps Tk's 'winfo' command which provides introspection
# for widget dimensions, positions, hierarchy, and display info.
#
# See: https://www.tcl.tk/man/tcl8.6/TkCmd/winfo.htm

require_relative 'test_helper'
require_relative 'tk_test_helper'
require 'tk'

class TestTkWinfo < Minitest::Test
  include TkTestHelper

  # --- Dimension queries ---

  def test_winfo_width_and_height
    assert_tk_app("winfo width/height return integers", method(:app_width_height))
  end

  def app_width_height
    require 'tk'
    btn = TkButton.new(root, text: "Test", width: 10)
    btn.pack
    root.update

    errors = []
    w = btn.winfo_width
    h = btn.winfo_height

    errors << "width should be Integer, got #{w.class}" unless w.is_a?(Integer)
    errors << "height should be Integer, got #{h.class}" unless h.is_a?(Integer)
    errors << "width should be > 0, got #{w}" unless w > 0
    errors << "height should be > 0, got #{h}" unless h > 0

    raise errors.join("\n") unless errors.empty?
  end

  def test_winfo_reqwidth_and_reqheight
    assert_tk_app("winfo reqwidth/reqheight return requested size", method(:app_reqwidth_reqheight))
  end

  def app_reqwidth_reqheight
    require 'tk'
    btn = TkButton.new(root, text: "Test")
    btn.pack

    errors = []
    rw = btn.winfo_reqwidth
    rh = btn.winfo_reqheight

    errors << "reqwidth should be Integer, got #{rw.class}" unless rw.is_a?(Integer)
    errors << "reqheight should be Integer, got #{rh.class}" unless rh.is_a?(Integer)
    errors << "reqwidth should be > 0, got #{rw}" unless rw > 0
    errors << "reqheight should be > 0, got #{rh}" unless rh > 0

    raise errors.join("\n") unless errors.empty?
  end

  def test_winfo_geometry
    assert_tk_app("winfo geometry returns WxH+X+Y string", method(:app_geometry))
  end

  def app_geometry
    require 'tk'
    btn = TkButton.new(root, text: "Test")
    btn.pack
    root.update

    geom = btn.winfo_geometry
    raise "geometry should be String, got #{geom.class}" unless geom.is_a?(String)
    raise "geometry should match WxH+X+Y pattern, got '#{geom}'" unless geom =~ /^\d+x\d+\+\d+\+\d+$/
  end

  # --- Position queries ---

  def test_winfo_x_and_y
    assert_tk_app("winfo x/y return position integers", method(:app_x_y))
  end

  def app_x_y
    require 'tk'
    btn = TkButton.new(root, text: "Test")
    btn.pack
    root.update

    errors = []
    x = btn.winfo_x
    y = btn.winfo_y

    errors << "x should be Integer, got #{x.class}" unless x.is_a?(Integer)
    errors << "y should be Integer, got #{y.class}" unless y.is_a?(Integer)

    raise errors.join("\n") unless errors.empty?
  end

  def test_winfo_rootx_and_rooty
    assert_tk_app("winfo rootx/rooty return screen position", method(:app_rootx_rooty))
  end

  def app_rootx_rooty
    require 'tk'
    btn = TkButton.new(root, text: "Test")
    btn.pack
    root.update

    errors = []
    rx = btn.winfo_rootx
    ry = btn.winfo_rooty

    errors << "rootx should be Integer, got #{rx.class}" unless rx.is_a?(Integer)
    errors << "rooty should be Integer, got #{ry.class}" unless ry.is_a?(Integer)

    raise errors.join("\n") unless errors.empty?
  end

  # --- Hierarchy queries ---

  def test_winfo_parent
    assert_tk_app("winfo parent returns parent widget", method(:app_parent))
  end

  def app_parent
    require 'tk'
    frame = TkFrame.new(root)
    btn = TkButton.new(frame, text: "Child")

    parent = btn.winfo_parent
    raise "parent should be the frame, got #{parent.inspect}" unless parent.path == frame.path
  end

  def test_winfo_children
    assert_tk_app("winfo children returns child widgets", method(:app_children))
  end

  def app_children
    require 'tk'
    frame = TkFrame.new(root)
    btn1 = TkButton.new(frame, text: "One")
    btn2 = TkButton.new(frame, text: "Two")

    children = frame.winfo_children
    raise "children should be Array, got #{children.class}" unless children.is_a?(Array)
    raise "expected 2 children, got #{children.size}" unless children.size == 2

    paths = children.map(&:path)
    raise "children should include btn1" unless paths.include?(btn1.path)
    raise "children should include btn2" unless paths.include?(btn2.path)
  end

  def test_winfo_toplevel
    assert_tk_app("winfo toplevel returns containing toplevel", method(:app_toplevel))
  end

  def app_toplevel
    require 'tk'
    frame = TkFrame.new(root)
    btn = TkButton.new(frame, text: "Deep")

    tl = btn.winfo_toplevel
    raise "toplevel should be root, got #{tl.path}" unless tl.path == root.path
  end

  # --- Widget info queries ---

  def test_winfo_classname
    assert_tk_app("winfo class returns widget class", method(:app_classname))
  end

  def app_classname
    require 'tk'
    btn = TkButton.new(root, text: "Test")
    label = TkLabel.new(root, text: "Label")

    btn_class = btn.winfo_classname
    label_class = label.winfo_classname

    raise "button class should be 'Button', got '#{btn_class}'" unless btn_class == "Button"
    raise "label class should be 'Label', got '#{label_class}'" unless label_class == "Label"
  end

  def test_winfo_exist
    assert_tk_app("winfo exist? returns boolean", method(:app_exist))
  end

  def app_exist
    require 'tk'
    btn = TkButton.new(root, text: "Test")

    raise "widget should exist" unless btn.winfo_exist?

    btn.destroy
    raise "destroyed widget should not exist" if btn.winfo_exist?
  end

  def test_winfo_manager
    assert_tk_app("winfo manager returns geometry manager", method(:app_manager))
  end

  def app_manager
    require 'tk'
    btn = TkButton.new(root, text: "Test")
    btn.pack

    mgr = btn.winfo_manager
    raise "manager should be 'pack', got '#{mgr}'" unless mgr == "pack"
  end

  def test_winfo_mapped
    assert_tk_app("winfo mapped? returns visibility state", method(:app_mapped))
  end

  def app_mapped
    require 'tk'
    btn = TkButton.new(root, text: "Test")

    raise "unpacked widget should not be mapped" if btn.winfo_mapped?

    root.deiconify
    btn.pack
    root.update

    raise "packed widget should be mapped" unless btn.winfo_mapped?
  end

  def test_winfo_viewable
    assert_tk_app("winfo viewable returns viewability", method(:app_viewable))
  end

  def app_viewable
    require 'tk'
    btn = TkButton.new(root, text: "Test")
    btn.pack
    root.update

    # root is withdrawn so button should not be viewable
    raise "widget in withdrawn window should not be viewable" if btn.winfo_viewable

    # deiconify and check again
    root.deiconify
    root.update

    raise "widget in visible window should be viewable" unless btn.winfo_viewable
  end

  # --- Screen/display queries ---

  def test_winfo_screen_dimensions
    assert_tk_app("winfo screen dimensions return integers", method(:app_screen_dimensions))
  end

  def app_screen_dimensions
    require 'tk'
    errors = []

    sw = root.winfo_screenwidth
    sh = root.winfo_screenheight

    errors << "screenwidth should be Integer, got #{sw.class}" unless sw.is_a?(Integer)
    errors << "screenheight should be Integer, got #{sh.class}" unless sh.is_a?(Integer)
    errors << "screenwidth should be > 0, got #{sw}" unless sw > 0
    errors << "screenheight should be > 0, got #{sh}" unless sh > 0

    raise errors.join("\n") unless errors.empty?
  end

  def test_winfo_screendepth
    assert_tk_app("winfo screendepth returns color depth", method(:app_screendepth))
  end

  def app_screendepth
    require 'tk'
    depth = root.winfo_screendepth

    raise "screendepth should be Integer, got #{depth.class}" unless depth.is_a?(Integer)
    raise "screendepth should be > 0, got #{depth}" unless depth > 0
  end

  def test_winfo_depth
    assert_tk_app("winfo depth returns window color depth", method(:app_depth))
  end

  def app_depth
    require 'tk'
    depth = root.winfo_depth

    raise "depth should be Integer, got #{depth.class}" unless depth.is_a?(Integer)
    raise "depth should be > 0, got #{depth}" unless depth > 0
  end

  def test_winfo_cells
    assert_tk_app("winfo cells returns colormap size", method(:app_cells))
  end

  def app_cells
    require 'tk'
    cells = root.winfo_cells

    raise "cells should be Integer, got #{cells.class}" unless cells.is_a?(Integer)
    raise "cells should be > 0, got #{cells}" unless cells > 0
  end

  def test_winfo_visual
    assert_tk_app("winfo visual returns visual class", method(:app_visual))
  end

  def app_visual
    require 'tk'
    visual = root.winfo_visual

    raise "visual should be String, got #{visual.class}" unless visual.is_a?(String)
    raise "visual should not be empty" if visual.empty?
  end

  def test_winfo_screen
    assert_tk_app("winfo screen returns display name", method(:app_screen))
  end

  def app_screen
    require 'tk'
    screen = root.winfo_screen

    raise "screen should be String, got #{screen.class}" unless screen.is_a?(String)
    raise "screen should not be empty" if screen.empty?
  end

  # --- ID and atom queries ---

  def test_winfo_id
    assert_tk_app("winfo id returns window id", method(:app_id))
  end

  def app_id
    require 'tk'
    id = root.winfo_id

    raise "id should be String, got #{id.class}" unless id.is_a?(String)
    raise "id should not be empty" if id.empty?
  end

  def test_winfo_atom_and_atomname
    assert_tk_app("winfo atom/atomname roundtrip", method(:app_atom_atomname))
  end

  def app_atom_atomname
    require 'tk'
    # Get atom ID for a name
    atom_id = root.winfo_atom("WM_NAME")
    raise "atom should be Integer, got #{atom_id.class}" unless atom_id.is_a?(Integer)

    # Convert back to name
    name = root.winfo_atomname(atom_id)
    raise "atomname should be 'WM_NAME', got '#{name}'" unless name == "WM_NAME"
  end

  # --- Pixel conversion ---

  def test_winfo_pixels
    assert_tk_app("winfo pixels converts distances", method(:app_pixels))
  end

  def app_pixels
    require 'tk'
    px = root.winfo_pixels("1i")  # 1 inch
    raise "pixels('1i') should be Integer, got #{px.class}" unless px.is_a?(Integer)
    raise "1 inch should be > 50 pixels, got #{px}" unless px > 50

    px_cm = root.winfo_pixels("1c")  # 1 centimeter
    raise "pixels('1c') should be Integer, got #{px_cm.class}" unless px_cm.is_a?(Integer)
    raise "1cm should be > 20 pixels, got #{px_cm}" unless px_cm > 20
  end

  def test_winfo_fpixels
    assert_tk_app("winfo fpixels returns float", method(:app_fpixels))
  end

  def app_fpixels
    require 'tk'
    fpx = root.winfo_fpixels("1i")

    raise "fpixels should be Numeric, got #{fpx.class}" unless fpx.is_a?(Numeric)
    raise "1 inch should be > 50 pixels, got #{fpx}" unless fpx > 50
  end

  # --- RGB query ---

  def test_winfo_rgb
    assert_tk_app("winfo rgb returns color components", method(:app_rgb))
  end

  def app_rgb
    require 'tk'
    rgb = root.winfo_rgb("red")

    raise "rgb should be Array, got #{rgb.class}" unless rgb.is_a?(Array)
    raise "rgb should have 3 components, got #{rgb.size}" unless rgb.size == 3

    r, g, b = rgb.map { |v| v.to_i }
    raise "red component should be high (>60000), got #{r}" unless r > 60000
    raise "green component should be low (<1000), got #{g}" unless g < 1000
    raise "blue component should be low (<1000), got #{b}" unless b < 1000
  end

  # --- Virtual root queries ---

  def test_winfo_vroot
    assert_tk_app("winfo vroot queries work", method(:app_vroot))
  end

  def app_vroot
    require 'tk'
    errors = []

    vw = root.winfo_vrootwidth
    vh = root.winfo_vrootheight
    vx = root.winfo_vrootx
    vy = root.winfo_vrooty

    errors << "vrootwidth should be Integer, got #{vw.class}" unless vw.is_a?(Integer)
    errors << "vrootheight should be Integer, got #{vh.class}" unless vh.is_a?(Integer)
    errors << "vrootx should be Integer, got #{vx.class}" unless vx.is_a?(Integer)
    errors << "vrooty should be Integer, got #{vy.class}" unless vy.is_a?(Integer)

    raise errors.join("\n") unless errors.empty?
  end

  # --- Module method variants ---

  def test_tkwinfo_module_methods
    assert_tk_app("TkWinfo module methods work", method(:app_module_methods))
  end

  def app_module_methods
    require 'tk'
    btn = TkButton.new(root, text: "Test")
    btn.pack
    root.update

    errors = []

    # Test a sampling of module methods
    w = TkWinfo.width(btn)
    errors << "TkWinfo.width should return Integer, got #{w.class}" unless w.is_a?(Integer)

    h = TkWinfo.height(btn)
    errors << "TkWinfo.height should return Integer, got #{h.class}" unless h.is_a?(Integer)

    exists = TkWinfo.exist?(btn)
    errors << "TkWinfo.exist? should return true" unless exists == true

    cls = TkWinfo.classname(btn)
    errors << "TkWinfo.classname should return 'Button', got '#{cls}'" unless cls == "Button"

    parent = TkWinfo.parent(btn)
    errors << "TkWinfo.parent should return root" unless parent.path == root.path

    raise errors.join("\n") unless errors.empty?
  end

  # --- Interps query ---

  def test_winfo_interps
    assert_tk_app("winfo interps returns interpreter list", method(:app_interps))
  end

  def app_interps
    require 'tk'
    interps = root.winfo_interps

    raise "interps should be Array, got #{interps.class}" unless interps.is_a?(Array)
    # Should have at least our own interpreter
    raise "interps should not be empty" if interps.empty?
  end

  # --- Containing query ---

  def test_winfo_containing
    # Use subprocess for complete isolation - this test depends on
    # absolute screen coordinates which can be affected by prior test state
    assert_tk_subprocess("winfo containing finds widget at coords") do
      <<~RUBY
        require 'tk'
        root = TkRoot.new
        root.geometry("200x100+0+0")  # Explicit position
        root.deiconify

        btn = TkButton.new(root, text: "Test")
        btn.pack

        # Wait for geometry to settle
        20.times do
          Tk.update
          break if btn.winfo_width > 0 && btn.winfo_height > 0
          sleep 0.05
        end

        rx = btn.winfo_rootx
        ry = btn.winfo_rooty
        w = btn.winfo_width
        h = btn.winfo_height
        center_x = rx + w / 2
        center_y = ry + h / 2

        widget = TkWinfo.containing(center_x, center_y)
        unless widget
          raise "containing returned nil at \#{center_x},\#{center_y}. btn: \#{rx},\#{ry} \#{w}x\#{h}"
        end

        root.destroy
      RUBY
    end
  end

  # --- Screen mm dimensions ---

  def test_winfo_screenmm
    assert_tk_app("winfo screenmm dimensions work", method(:app_screenmm))
  end

  def app_screenmm
    require 'tk'
    errors = []

    mmw = root.winfo_screenmmwidth
    mmh = root.winfo_screenmmheight

    errors << "screenmmwidth should be Integer, got #{mmw.class}" unless mmw.is_a?(Integer)
    errors << "screenmmheight should be Integer, got #{mmh.class}" unless mmh.is_a?(Integer)
    errors << "screenmmwidth should be > 0, got #{mmw}" unless mmw > 0
    errors << "screenmmheight should be > 0, got #{mmh}" unless mmh > 0

    raise errors.join("\n") unless errors.empty?
  end

  # --- Pointer queries ---

  def test_winfo_pointer
    assert_tk_app("winfo pointer queries work", method(:app_pointer))
  end

  def app_pointer
    require 'tk'
    errors = []

    px = root.winfo_pointerx
    py = root.winfo_pointery
    pxy = root.winfo_pointerxy

    errors << "pointerx should be Integer, got #{px.class}" unless px.is_a?(Integer)
    errors << "pointery should be Integer, got #{py.class}" unless py.is_a?(Integer)
    errors << "pointerxy should be Array, got #{pxy.class}" unless pxy.is_a?(Array)
    errors << "pointerxy should have 2 elements, got #{pxy.size}" unless pxy.size == 2

    raise errors.join("\n") unless errors.empty?
  end

  # --- Server info ---

  def test_winfo_server
    assert_tk_app("winfo server returns server info", method(:app_server))
  end

  def app_server
    require 'tk'
    server = root.winfo_server

    raise "server should be String, got #{server.class}" unless server.is_a?(String)
    raise "server should not be empty" if server.empty?
  end

  # --- Colormapfull ---

  def test_winfo_colormapfull
    assert_tk_app("winfo colormapfull returns boolean", method(:app_colormapfull))
  end

  def app_colormapfull
    require 'tk'
    full = root.winfo_colormapfull

    raise "colormapfull should be boolean, got #{full.class}" unless [true, false].include?(full)
  end

  # --- Appname ---

  def test_winfo_appname
    assert_tk_app("winfo appname returns widget name", method(:app_appname))
  end

  def app_appname
    require 'tk'
    btn = TkButton.new(root, text: "Test")

    name = btn.winfo_appname
    raise "appname should be String, got #{name.class}" unless name.is_a?(String)
  end

  # --- Visualsavailable ---

  def test_winfo_visualsavailable
    assert_tk_app("winfo visualsavailable returns list", method(:app_visualsavailable))
  end

  def app_visualsavailable
    require 'tk'
    visuals = root.winfo_visualsavailable

    raise "visualsavailable should be Array, got #{visuals.class}" unless visuals.is_a?(Array)
    raise "visualsavailable should not be empty" if visuals.empty?
  end

  # --- Visualid ---

  def test_winfo_visualid
    assert_tk_app("winfo visualid returns id", method(:app_visualid))
  end

  def app_visualid
    require 'tk'
    vid = root.winfo_visualid

    raise "visualid should be String, got #{vid.class}" unless vid.is_a?(String)
  end

  # --- Screencells ---

  def test_winfo_screencells
    assert_tk_app("winfo screencells returns count", method(:app_screencells))
  end

  def app_screencells
    require 'tk'
    cells = root.winfo_screencells

    raise "screencells should be Integer, got #{cells.class}" unless cells.is_a?(Integer)
    raise "screencells should be > 0, got #{cells}" unless cells > 0
  end

  # --- Screenvisual ---

  def test_winfo_screenvisual
    assert_tk_app("winfo screenvisual returns visual type", method(:app_screenvisual))
  end

  def app_screenvisual
    require 'tk'
    visual = root.winfo_screenvisual

    raise "screenvisual should be String, got #{visual.class}" unless visual.is_a?(String)
    raise "screenvisual should not be empty" if visual.empty?
  end

  # --- Widget (pathname) ---

  def test_winfo_widget
    assert_tk_app("winfo widget finds widget by id", method(:app_widget))
  end

  def app_widget
    require 'tk'
    btn = TkButton.new(root, text: "Test")

    # Get the window id
    id = btn.winfo_id

    # Find widget by id
    found = TkWinfo.widget(id)
    raise "widget should find button, got #{found.inspect}" unless found.path == btn.path
  end
end
