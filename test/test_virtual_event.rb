# frozen_string_literal: true

# Tests for TkVirtualEvent - custom event bindings

require_relative 'test_helper'
require_relative 'tk_test_helper'

class TestVirtualEvent < Minitest::Test
  include TkTestHelper

  def test_create_virtual_event
    assert_tk_app("create virtual event", method(:app_create_virtual_event))
  end

  def app_create_virtual_event
    require 'tk'
    require 'tk/virtevent'

    # Create a virtual event bound to Control-x
    vevent = TkVirtualEvent.new('Control-x')

    raise "virtual event should have a path" unless vevent.path
    raise "path should be wrapped in angle brackets" unless vevent.path.to_s.start_with?('<')

    # Clean up
    vevent.delete
  end

  def test_virtual_event_info
    assert_tk_app("virtual event info", method(:app_virtual_event_info))
  end

  def app_virtual_event_info
    require 'tk'
    require 'tk/virtevent'

    # Create a virtual event with multiple sequences
    vevent = TkVirtualEvent.new('Control-a', 'Control-b')

    info = vevent.info
    raise "info should return array" unless info.is_a?(Array)
    raise "info should have 2 sequences" unless info.size == 2

    vevent.delete
  end

  def test_virtual_event_add_delete_sequence
    assert_tk_app("add/delete sequences", method(:app_add_delete_sequence))
  end

  def app_add_delete_sequence
    require 'tk'
    require 'tk/virtevent'

    vevent = TkVirtualEvent.new('Control-z')

    # Add another sequence
    vevent.add('Control-y')
    info = vevent.info
    raise "should have 2 sequences after add" unless info.size == 2

    # Delete one sequence
    vevent.delete('Control-y')
    info = vevent.info
    raise "should have 1 sequence after delete" unless info.size == 1

    # Delete entire event
    vevent.delete
  end

  def test_bind_to_virtual_event
    assert_tk_app("bind widget to virtual event", method(:app_bind_virtual_event))
  end

  def app_bind_virtual_event
    require 'tk'
    require 'tk/virtevent'

    vevent = TkVirtualEvent.new('Control-t')

    btn = TkButton.new(root)
    btn.bind(vevent.path) { }  # callback may not trigger in test environment

    # Generate the virtual event (may not trigger without real display)
    btn.event_generate(vevent.path)
    Tk.update

    vevent.delete
    # Just verify no errors occurred
  end

  def test_predef_virtual_event
    assert_tk_app("predefined virtual event", method(:app_predef_virtual_event))
  end

  def app_predef_virtual_event
    require 'tk'
    require 'tk/virtevent'

    # Get list of all defined virtual events
    events = TkVirtualEvent.info
    raise "info should return array" unless events.is_a?(Array)

    # There should be some predefined events like <<Copy>>, <<Paste>>, etc.
    # (depends on platform)
  end
end
