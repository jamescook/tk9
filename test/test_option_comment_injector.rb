# frozen_string_literal: true

require_relative 'test_helper'
require 'tk/option_comment_injector'
require 'tk/option_generator'
require 'tempfile'

class TestOptionCommentInjector < Minitest::Test
  def setup
    @sample_source = <<~RUBY
      # frozen_string_literal: false
      require 'tk'

      class Tk::Button < Tk::Label
        extend Tk::OptionDSL
        include Tk::Generated::Button

        TkCommandNames = ['button'.freeze].freeze
        WidgetClassName = 'Button'.freeze

        def invoke
          tk_send('invoke')
        end
      end
    RUBY

    @sample_options = [
      mock_option('text'),
      mock_option('command', type: :callback),
      mock_option('width'),
      mock_option('bg', alias_target: 'background'),
    ]
  end

  def mock_option(name, type: :string, alias_target: nil)
    Tk::OptionGenerator::OptionEntry.new(
      name: name,
      db_name: name,
      db_class: type == :callback ? 'Command' : 'String',
      default: nil,
      alias_target: alias_target
    )
  end

  def test_inject_adds_comment_block
    tempfile = Tempfile.new(['widget', '.rb'])
    tempfile.write(@sample_source)
    tempfile.close

    injector = Tk::OptionCommentInjector.new(tempfile.path)
    result = injector.inject('Tk::Button', @sample_options)

    assert_includes result, '# @generated:options:start'
    assert_includes result, '# @generated:options:end'
    assert_includes result, ':command (callback)'
    assert_includes result, ':text'
    assert_includes result, ':width'
    # Aliases should not appear in the list
    refute_includes result, ':bg'
  ensure
    tempfile.unlink
  end

  def test_inject_preserves_class_structure
    tempfile = Tempfile.new(['widget', '.rb'])
    tempfile.write(@sample_source)
    tempfile.close

    injector = Tk::OptionCommentInjector.new(tempfile.path)
    result = injector.inject('Tk::Button', @sample_options)

    # Should still have the class definition
    assert_includes result, 'class Tk::Button < Tk::Label'
    assert_includes result, 'extend Tk::OptionDSL'
    assert_includes result, 'include Tk::Generated::Button'
    assert_includes result, 'def invoke'
    assert_includes result, 'TkCommandNames'
  ensure
    tempfile.unlink
  end

  def test_inject_replaces_existing_block
    source_with_block = <<~RUBY
      class Tk::Button < Tk::Label
        extend Tk::OptionDSL
        # @generated:options:start
        # OLD OPTIONS HERE
        # @generated:options:end

        def invoke
        end
      end
    RUBY

    tempfile = Tempfile.new(['widget', '.rb'])
    tempfile.write(source_with_block)
    tempfile.close

    injector = Tk::OptionCommentInjector.new(tempfile.path)
    result = injector.inject('Tk::Button', @sample_options)

    # Should have exactly one block
    assert_equal 1, result.scan('# @generated:options:start').count
    assert_equal 1, result.scan('# @generated:options:end').count
    # Old content should be gone
    refute_includes result, 'OLD OPTIONS HERE'
    # New content should be there
    assert_includes result, ':command (callback)'
  ensure
    tempfile.unlink
  end

  def test_inject_bang_writes_to_file
    tempfile = Tempfile.new(['widget', '.rb'])
    tempfile.write(@sample_source)
    tempfile.close

    injector = Tk::OptionCommentInjector.new(tempfile.path)
    injector.inject!('Tk::Button', @sample_options)

    content = File.read(tempfile.path)
    assert_includes content, '# @generated:options:start'
  ensure
    tempfile.unlink
  end

  def test_raises_if_class_not_found
    tempfile = Tempfile.new(['widget', '.rb'])
    tempfile.write("class Foo; end")
    tempfile.close

    injector = Tk::OptionCommentInjector.new(tempfile.path)

    assert_raises(RuntimeError) do
      injector.inject('Tk::Button', @sample_options)
    end
  ensure
    tempfile.unlink
  end
end
