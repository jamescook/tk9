# frozen_string_literal: true

# Tests for Tk::Mac - macOS-specific Tk functionality
#
# Tk::Mac wraps ::tk::mac::* procedures for macOS integration.
# These tests only run on macOS (darwin).
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/tk_mac.html

require_relative 'test_helper'
require_relative 'tk_test_helper'

class TestTkMac < Minitest::Test
  include TkTestHelper

  def setup
    skip "macOS-only tests" unless RUBY_PLATFORM =~ /darwin/
  end

  # ===========================================
  # Event handler definitions - verify procs are created
  # ===========================================

  def test_def_quit_creates_proc
    assert_tk_app("Tk::Mac def_Quit creates proc", method(:def_quit_proc_created_app))
  end

  def def_quit_proc_created_app
    require 'tk'
    require 'tk/tk_mac'

    errors = []

    Tk::Mac.def_Quit { "quit handler" }

    # Verify the Tcl proc was created
    result = Tk.tk_call('info', 'commands', '::tk::mac::Quit')
    errors << "Quit proc should be created" if result.empty?

    raise errors.join("\n") unless errors.empty?
  end

  def test_def_show_preferences_creates_proc
    assert_tk_app("Tk::Mac def_ShowPreferences creates proc", method(:def_prefs_proc_app))
  end

  def def_prefs_proc_app
    require 'tk'
    require 'tk/tk_mac'

    errors = []

    Tk::Mac.def_ShowPreferences { "prefs handler" }

    result = Tk.tk_call('info', 'commands', '::tk::mac::ShowPreferences')
    errors << "ShowPreferences proc should be created" if result.empty?

    raise errors.join("\n") unless errors.empty?
  end

  def test_def_open_document_creates_proc
    assert_tk_app("Tk::Mac def_OpenDocument creates proc", method(:def_open_doc_app))
  end

  def def_open_doc_app
    require 'tk'
    require 'tk/tk_mac'

    errors = []

    Tk::Mac.def_OpenDocument { |*files| "open #{files}" }

    result = Tk.tk_call('info', 'commands', '::tk::mac::OpenDocument')
    errors << "OpenDocument proc should be created" if result.empty?

    raise errors.join("\n") unless errors.empty?
  end

  def test_def_on_hide_creates_proc
    assert_tk_app("Tk::Mac def_OnHide creates proc", method(:def_on_hide_app))
  end

  def def_on_hide_app
    require 'tk'
    require 'tk/tk_mac'

    errors = []

    Tk::Mac.def_OnHide { "hide handler" }

    result = Tk.tk_call('info', 'commands', '::tk::mac::OnHide')
    errors << "OnHide proc should be created" if result.empty?

    raise errors.join("\n") unless errors.empty?
  end

  def test_def_on_show_creates_proc
    assert_tk_app("Tk::Mac def_OnShow creates proc", method(:def_on_show_app))
  end

  def def_on_show_app
    require 'tk'
    require 'tk/tk_mac'

    errors = []

    Tk::Mac.def_OnShow { "show handler" }

    result = Tk.tk_call('info', 'commands', '::tk::mac::OnShow')
    errors << "OnShow proc should be created" if result.empty?

    raise errors.join("\n") unless errors.empty?
  end

  # ===========================================
  # Handler with proc vs block
  # ===========================================

  def test_def_quit_accepts_proc
    assert_tk_app("Tk::Mac def_Quit accepts proc", method(:def_quit_accepts_proc_app))
  end

  def def_quit_accepts_proc_app
    require 'tk'
    require 'tk/tk_mac'

    errors = []

    handler = proc { "proc handler" }
    Tk::Mac.def_Quit(handler)

    result = Tk.tk_call('info', 'commands', '::tk::mac::Quit')
    errors << "Quit proc should be created with proc arg" if result.empty?

    raise errors.join("\n") unless errors.empty?
  end

  # ===========================================
  # Standard dialogs
  # ===========================================

  def test_standard_about_panel_callable
    assert_tk_app("Tk::Mac standardAboutPanel callable", method(:about_panel_app))
  end

  def about_panel_app
    require 'tk'
    require 'tk/tk_mac'

    errors = []

    # Verify the command exists (don't actually call it - shows modal dialog)
    result = Tk.tk_call('info', 'commands', '::tk::mac::standardAboutPanel')
    errors << "standardAboutPanel should exist" if result.empty?

    raise errors.join("\n") unless errors.empty?
  end

  # ===========================================
  # IconBitmap
  # ===========================================

  def test_icon_bitmap_creates_image
    assert_tk_app("Tk::Mac::IconBitmap creates image", method(:icon_bitmap_app))
  end

  def icon_bitmap_app
    require 'tk'
    require 'tk/tk_mac'

    errors = []

    # Create an icon bitmap from a system icon
    # -source 1 means NSImageNameComputer system icon
    begin
      icon = Tk::Mac::IconBitmap.new(32, 32, ostype: 'APPL')
      errors << "should be a TkImage" unless icon.is_a?(TkImage)
      errors << "should have a path" if icon.path.nil? || icon.path.empty?
    rescue TclTkLib::TclError => e
      # Some icon types may not be available - that's ok for this test
      # Just verify the class exists and is callable
      errors << "IconBitmap should be callable" unless e.message.include?("ostype")
    end

    raise errors.join("\n") unless errors.empty?
  end


  # ===========================================
  # Additional available commands
  # ===========================================

  def test_macos_version_available
    assert_tk_app("Tk::Mac macOSVersion available", method(:macos_version_app))
  end

  def macos_version_app
    require 'tk'
    require 'tk/tk_mac'

    errors = []

    # ::tk::mac::macOSVersion is available in modern Tk
    result = Tk.tk_call('info', 'commands', '::tk::mac::macOSVersion')
    if result.empty?
      # Command might not exist in all versions
    else
      version = Tk.tk_call('::tk::mac::macOSVersion')
      errors << "macOSVersion should return a number" unless version.to_i > 0
    end

    raise errors.join("\n") unless errors.empty?
  end
end
