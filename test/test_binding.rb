# frozen_string_literal: true

# Tests for Tk event bindings and bindtags
#
# Key features exercised:
#   - bindtags (viewing/manipulating binding tag order)
#   - bind with event substitution (%x, %y, %K, etc.)
#   - bind_append (adding to existing bindings)
#   - TkBindTag (custom binding tags)
#   - TkCallbackBreak (stopping event propagation)

require_relative 'test_helper'
require_relative 'tk_test_helper'

class TestBinding < Minitest::Test
  include TkTestHelper

  SAMPLE_PATH = File.expand_path('../sample/binding_demo.rb', __dir__)

  # Smoke test - UI loads without crashing
  def test_binding_demo_loads
    assert_sample_loads(SAMPLE_PATH, message: "binding_demo.rb should load")
  end

  # Test bindtags returns correct structure
  def test_bindtags_returns_array
    assert_tk_test("bindtags should return array with widget, class, toplevel, all") do
      <<~RUBY
        require 'tk'
        root = TkRoot.new { withdraw }
        btn = TkButton.new(root)

        tags = btn.bindtags
        raise "bindtags should be Array, got \#{tags.class}" unless tags.is_a?(Array)
        raise "expected 4 tags, got \#{tags.size}" unless tags.size == 4

        # First should be the widget itself
        raise "first tag should be the button widget" unless tags[0] == btn

        # Second should be the class
        raise "second tag should be Tk::Button, got \#{tags[1]}" unless tags[1] == Tk::Button

        # Third should be toplevel
        raise "third tag should be root" unless tags[2] == root

        # Fourth should be TkBindTag::ALL
        raise "fourth tag should be TkBindTag::ALL" unless tags[3] == TkBindTag::ALL

        root.destroy
      RUBY
    end
  end

  # Test bindtags= can set custom order
  def test_bindtags_assignment
    assert_tk_test("bindtags= should change binding order") do
      <<~RUBY
        require 'tk'
        root = TkRoot.new { withdraw }
        btn = TkButton.new(root)

        original = btn.bindtags.dup
        reversed = original.reverse
        btn.bindtags = reversed

        new_tags = btn.bindtags
        raise "tags should be reversed" unless new_tags == reversed

        root.destroy
      RUBY
    end
  end

  # Test TkBindTag creates custom binding tags
  def test_custom_bindtag
    assert_tk_test("TkBindTag should create custom binding tags") do
      <<~RUBY
        require 'tk'
        require 'tk/bindtag'
        root = TkRoot.new { withdraw }

        # Create custom tag
        my_tag = TkBindTag.new
        raise "TkBindTag should have an id" if my_tag.to_eval.nil?

        # Bind to it
        called = false
        my_tag.bind('Enter') { called = true }

        # Add to widget
        btn = TkButton.new(root)
        btn.bindtags = [my_tag] + btn.bindtags

        # Verify it's in the list
        raise "custom tag should be first" unless btn.bindtags[0] == my_tag

        root.destroy
      RUBY
    end
  end

  # Test bind receives event object with correct fields
  def test_bind_event_fields
    assert_tk_test("bind should receive event with x, y, widget fields") do
      <<~RUBY
        require 'tk'
        # Note: can't use withdraw - events require mapped windows
        root = TkRoot.new
        btn = TkButton.new(root) { pack }
        Tk.update  # ensure widget is mapped

        event_data = nil
        btn.bind('Button-1') { |e| event_data = e }

        # Generate a click event
        btn.event_generate('Button-1', x: 10, y: 20)
        Tk.update

        raise "event should be received" if event_data.nil?
        raise "event.x should be 10, got \#{event_data.x}" unless event_data.x == 10
        raise "event.y should be 20, got \#{event_data.y}" unless event_data.y == 20
        raise "event.widget should be set" if event_data.widget.nil?

        root.destroy
      RUBY
    end
  end

  # Test bind_append adds to existing bindings
  def test_bind_append
    assert_tk_test("bind_append should add without replacing") do
      <<~RUBY
        require 'tk'
        # Note: can't use withdraw - events require mapped windows
        root = TkRoot.new
        btn = TkButton.new(root) { pack }
        Tk.update  # ensure widget is mapped

        results = []
        btn.bind('Button-1') { results << 'first' }
        btn.bind_append('Button-1') { results << 'second' }

        btn.event_generate('Button-1', x: 5, y: 5)
        Tk.update

        raise "expected 2 results, got \#{results.size}" unless results.size == 2
        raise "first binding should fire first" unless results[0] == 'first'
        raise "appended binding should fire second" unless results[1] == 'second'

        root.destroy
      RUBY
    end
  end

  # Test TkCallbackBreak stops propagation
  def test_callback_break
    assert_tk_test("TkCallbackBreak should stop further bindings") do
      <<~RUBY
        require 'tk'
        # Note: can't use withdraw - events require mapped windows
        root = TkRoot.new
        btn = TkButton.new(root) { pack }
        Tk.update  # ensure widget is mapped

        results = []
        btn.bind('Button-1') do
          results << 'first'
          raise TkCallbackBreak
        end
        btn.bind_append('Button-1') { results << 'second' }

        btn.event_generate('Button-1', x: 5, y: 5)
        Tk.update

        raise "expected 1 result (break should stop), got \#{results.size}: \#{results}" unless results.size == 1
        raise "only first should fire" unless results[0] == 'first'

        root.destroy
      RUBY
    end
  end

  # Test bindinfo returns binding information
  def test_bindinfo
    assert_tk_test("bindinfo should return bound events") do
      <<~RUBY
        require 'tk'
        root = TkRoot.new { withdraw }
        btn = TkButton.new(root)

        btn.bind('Button-1') { }
        btn.bind('Enter') { }

        info = btn.bindinfo
        raise "bindinfo should be Array" unless info.is_a?(Array)
        raise "should have Button-1" unless info.any? { |e| e.include?('Button-1') || e.include?('1') }
        raise "should have Enter" unless info.any? { |e| e.include?('Enter') }

        root.destroy
      RUBY
    end
  end

  # Test bind_remove removes a binding
  def test_bind_remove
    assert_tk_test("bind_remove should remove a binding") do
      <<~RUBY
        require 'tk'
        root = TkRoot.new { withdraw }
        btn = TkButton.new(root)

        btn.bind('Button-1') { }
        raise "should have binding" unless btn.bindinfo.any? { |e| e.include?('Button-1') || e.include?('1') }

        btn.bind_remove('Button-1')
        remaining = btn.bindinfo.select { |e| e.include?('Button-1') || e.include?('1') }
        raise "binding should be removed, still have: \#{remaining}" unless remaining.empty?

        root.destroy
      RUBY
    end
  end
end
