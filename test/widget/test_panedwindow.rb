# frozen_string_literal: true

# Comprehensive test for Tk::PanedWindow widget options.
# Runs in a single subprocess to minimize overhead.
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/panedwindow.html

require_relative '../test_helper'
require_relative '../tk_test_helper'

class TestPanedWindowWidget < Minitest::Test
  include TkTestHelper

  def test_panedwindow_comprehensive
    assert_tk_app("PanedWindow widget comprehensive test", method(:panedwindow_app))
  end

  def panedwindow_app
    require 'tk'
    require 'tk/panedwindow'
    require 'tk/frame'
    require 'tk/label'
    require 'tk/button'

    errors = []

    # --- Horizontal paned window ---
    h_paned = TkPanedWindow.new(root, orient: "horizontal")
    h_paned.pack(fill: "both", expand: true, padx: 10, pady: 10)

    errors << "orient failed" unless h_paned.cget(:orient) == "horizontal"

    # Add left pane
    left_frame = TkFrame.new(h_paned, width: 150, height: 200, bg: "lightblue")
    TkLabel.new(left_frame, text: "Left Pane", bg: "lightblue").pack(pady: 10)

    # Add right pane
    right_frame = TkFrame.new(h_paned, width: 200, height: 200, bg: "lightgreen")
    TkLabel.new(right_frame, text: "Right Pane", bg: "lightgreen").pack(pady: 10)

    h_paned.add(left_frame, right_frame)

    # --- Sash appearance ---
    h_paned.configure(sashwidth: 8)
    errors << "sashwidth failed" unless h_paned.cget(:sashwidth).to_i == 8

    h_paned.configure(sashpad: 2)
    errors << "sashpad failed" unless h_paned.cget(:sashpad).to_i == 2

    h_paned.configure(sashrelief: "raised")
    errors << "sashrelief failed" unless h_paned.cget(:sashrelief) == "raised"

    # --- Handle appearance ---
    h_paned.configure(showhandle: true)
    errors << "showhandle true failed" unless h_paned.cget(:showhandle)

    h_paned.configure(handlesize: 10)
    errors << "handlesize failed" unless h_paned.cget(:handlesize).to_i == 10

    h_paned.configure(handlepad: 8)
    errors << "handlepad failed" unless h_paned.cget(:handlepad).to_i == 8

    # --- Opaque resize ---
    h_paned.configure(opaqueresize: false)
    errors << "opaqueresize false failed" if h_paned.cget(:opaqueresize)

    h_paned.configure(opaqueresize: true)
    errors << "opaqueresize true failed" unless h_paned.cget(:opaqueresize)

    # --- Border ---
    h_paned.configure(borderwidth: 2)
    errors << "borderwidth failed" unless h_paned.cget(:borderwidth).to_i == 2

    # --- Vertical paned window ---
    v_paned = TkPanedWindow.new(root, orient: "vertical")
    errors << "vertical orient failed" unless v_paned.cget(:orient) == "vertical"

    # Add top and bottom panes
    top_frame = TkFrame.new(v_paned, width: 200, height: 100, bg: "lightyellow")
    bottom_frame = TkFrame.new(v_paned, width: 200, height: 100, bg: "lightpink")
    v_paned.add(top_frame, bottom_frame)

    # --- Pane operations ---
    panes = h_paned.panes
    errors << "panes count failed" unless panes.size == 2

    # --- Pane configuration ---
    h_paned.paneconfigure(left_frame, minsize: 100)
    # Note: panecget returns different types depending on option

    # --- Sash operations ---
    coords = h_paned.sash_coord(0)
    errors << "sash_coord failed" unless coords.is_a?(Array) && coords.size == 2

    # Check errors before tk_end
    unless errors.empty?
      raise "PanedWindow test failures:\n  " + errors.join("\n  ")
    end

  end

  # --- Additional coverage tests ---

  def test_panedwindow_forget
    assert_tk_app("PanedWindow forget", method(:panedwindow_forget_app))
  end

  def panedwindow_forget_app
    require 'tk'
    require 'tk/panedwindow'

    errors = []

    paned = TkPanedWindow.new(root, orient: "horizontal")
    paned.pack(fill: "both", expand: true)

    frame1 = TkFrame.new(paned, width: 100, height: 100, bg: "red")
    frame2 = TkFrame.new(paned, width: 100, height: 100, bg: "blue")
    frame3 = TkFrame.new(paned, width: 100, height: 100, bg: "green")

    paned.add(frame1, frame2, frame3)
    errors << "should have 3 panes" unless paned.panes.size == 3

    # forget removes a pane
    paned.forget(frame2)
    errors << "forget failed: should have 2 panes, got #{paned.panes.size}" unless paned.panes.size == 2

    # forget multiple panes
    paned.forget(frame1, frame3)
    errors << "forget multiple failed: should have 0 panes" unless paned.panes.size == 0

    raise errors.join("\n") unless errors.empty?
  end

  def test_panedwindow_identify
    assert_tk_app("PanedWindow identify", method(:panedwindow_identify_app))
  end

  def panedwindow_identify_app
    require 'tk'
    require 'tk/panedwindow'

    errors = []

    paned = TkPanedWindow.new(root, orient: "horizontal", sashwidth: 10)
    paned.pack(fill: "both", expand: true)

    frame1 = TkFrame.new(paned, width: 100, height: 100)
    frame2 = TkFrame.new(paned, width: 100, height: 100)
    paned.add(frame1, frame2)

    Tk.update

    # identify returns what's at given coordinates
    # At 0,0 it's probably empty or a pane
    result = paned.identify(0, 0)
    errors << "identify should return a list" unless result.is_a?(Array)

    raise errors.join("\n") unless errors.empty?
  end

  def test_panedwindow_panecget
    assert_tk_app("PanedWindow panecget", method(:panedwindow_panecget_app))
  end

  def panedwindow_panecget_app
    require 'tk'
    require 'tk/panedwindow'

    errors = []

    paned = TkPanedWindow.new(root, orient: "horizontal")
    paned.pack(fill: "both", expand: true)

    frame = TkFrame.new(paned, width: 100, height: 100)
    paned.add(frame, minsize: 50, sticky: "nsew")

    # panecget retrieves pane-specific options
    minsize = paned.panecget(frame, :minsize)
    errors << "panecget minsize failed: expected 50, got #{minsize}" unless minsize.to_i == 50

    # panecget_strict should work the same
    minsize2 = paned.panecget_strict(frame, :minsize)
    errors << "panecget_strict failed" unless minsize2.to_i == 50

    raise errors.join("\n") unless errors.empty?
  end

  def test_panedwindow_proxy
    assert_tk_app("PanedWindow proxy", method(:panedwindow_proxy_app))
  end

  def panedwindow_proxy_app
    require 'tk'
    require 'tk/panedwindow'

    errors = []

    paned = TkPanedWindow.new(root, orient: "horizontal", opaqueresize: false)
    paned.pack(fill: "both", expand: true)

    frame1 = TkFrame.new(paned, width: 100, height: 100)
    frame2 = TkFrame.new(paned, width: 100, height: 100)
    paned.add(frame1, frame2)

    Tk.update

    # proxy_place places the proxy sash at coordinates
    result = paned.proxy_place(50, 50)
    errors << "proxy_place should return self" unless result == paned

    # proxy_coord returns proxy coordinates
    coords = paned.proxy_coord
    errors << "proxy_coord should return array" unless coords.is_a?(Array)

    # proxy_forget removes the proxy
    result = paned.proxy_forget
    errors << "proxy_forget should return self" unless result == paned

    raise errors.join("\n") unless errors.empty?
  end

  def test_panedwindow_sash_manipulation
    assert_tk_app("PanedWindow sash manipulation", method(:panedwindow_sash_app))
  end

  def panedwindow_sash_app
    require 'tk'
    require 'tk/panedwindow'

    errors = []

    paned = TkPanedWindow.new(root, orient: "horizontal")
    paned.pack(fill: "both", expand: true)

    frame1 = TkFrame.new(paned, width: 100, height: 100)
    frame2 = TkFrame.new(paned, width: 100, height: 100)
    paned.add(frame1, frame2)

    Tk.update

    # sash_mark sets the mark for dragging
    result = paned.sash_mark(0, 50, 50)
    errors << "sash_mark should return self" unless result == paned

    # sash_dragto moves sash relative to mark
    result = paned.sash_dragto(0, 60, 50)
    errors << "sash_dragto should return self" unless result == paned

    # sash_place places sash at absolute position
    result = paned.sash_place(0, 80, 0)
    errors << "sash_place should return self" unless result == paned

    # Verify sash moved
    coords = paned.sash_coord(0)
    errors << "sash_coord should return coordinates" unless coords.is_a?(Array) && coords.size == 2

    raise errors.join("\n") unless errors.empty?
  end

  def test_panedwindow_paneconfiginfo
    assert_tk_app("PanedWindow paneconfiginfo", method(:panedwindow_paneconfiginfo_app))
  end

  def panedwindow_paneconfiginfo_app
    require 'tk'
    require 'tk/panedwindow'

    errors = []

    paned = TkPanedWindow.new(root, orient: "horizontal")
    paned.pack(fill: "both", expand: true)

    frame = TkFrame.new(paned, width: 100, height: 100)
    paned.add(frame, minsize: 30, sticky: "ns")

    # paneconfiginfo with key returns info for that option
    info = paned.paneconfiginfo(frame, :minsize)
    errors << "paneconfiginfo(key) should return array" unless info.is_a?(Array)
    errors << "paneconfiginfo[0] should be 'minsize'" unless info[0] == 'minsize'

    # paneconfiginfo without key returns all pane options
    all_info = paned.paneconfiginfo(frame)
    errors << "paneconfiginfo() should return array" unless all_info.is_a?(Array)
    errors << "paneconfiginfo() should have entries" if all_info.empty?

    # current_paneconfiginfo returns hash of current values
    current = paned.current_paneconfiginfo(frame)
    errors << "current_paneconfiginfo should return hash" unless current.is_a?(Hash)

    # current_paneconfiginfo with key
    current_key = paned.current_paneconfiginfo(frame, :minsize)
    errors << "current_paneconfiginfo(key) should return hash" unless current_key.is_a?(Hash)

    raise errors.join("\n") unless errors.empty?
  end

  def test_panedwindow_add_with_options
    assert_tk_app("PanedWindow add with options", method(:panedwindow_add_options_app))
  end

  def panedwindow_add_options_app
    require 'tk'
    require 'tk/panedwindow'

    errors = []

    paned = TkPanedWindow.new(root, orient: "horizontal")
    paned.pack(fill: "both", expand: true)

    frame = TkFrame.new(paned, width: 100, height: 100)

    # add with options hash
    paned.add(frame, minsize: 75, sticky: "nsew", padx: 5, pady: 5)

    # Verify options were set
    minsize = paned.panecget(frame, :minsize)
    errors << "add with minsize failed: expected 75, got #{minsize}" unless minsize.to_i == 75

    raise errors.join("\n") unless errors.empty?
  end

  def test_panedwindow_aliases
    assert_tk_app("PanedWindow method aliases", method(:panedwindow_aliases_app))
  end

  def panedwindow_aliases_app
    require 'tk'
    require 'tk/panedwindow'

    errors = []

    paned = TkPanedWindow.new(root, orient: "horizontal")
    paned.pack(fill: "both", expand: true)

    frame1 = TkFrame.new(paned, width: 100, height: 100)
    frame2 = TkFrame.new(paned, width: 100, height: 100)
    paned.add(frame1, frame2)

    # del is alias for forget
    paned.del(frame1)
    errors << "del alias failed" unless paned.panes.size == 1

    # delete is alias for forget
    paned.delete(frame2)
    errors << "delete alias failed" unless paned.panes.size == 0

    # Add back for remove test
    paned.add(frame1)
    paned.remove(frame1)
    errors << "remove alias failed" unless paned.panes.size == 0

    # pane_config is alias for paneconfigure
    paned.add(frame1)
    paned.pane_config(frame1, minsize: 40)
    minsize = paned.panecget(frame1, :minsize)
    errors << "pane_config alias failed" unless minsize.to_i == 40

    # pane_configinfo is alias for paneconfiginfo
    info = paned.pane_configinfo(frame1, :minsize)
    errors << "pane_configinfo alias failed" unless info.is_a?(Array)

    # current_pane_configinfo is alias
    current = paned.current_pane_configinfo(frame1)
    errors << "current_pane_configinfo alias failed" unless current.is_a?(Hash)

    raise errors.join("\n") unless errors.empty?
  end
end
