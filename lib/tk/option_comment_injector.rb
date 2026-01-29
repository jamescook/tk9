# frozen_string_literal: true

require 'prism'

module Tk
  # Injects generated option documentation as comments into widget source files.
  # Uses Prism for proper AST parsing to find the right insertion point.
  class OptionCommentInjector
    MARKER_START = "# @generated:options:start"
    MARKER_END   = "# @generated:options:end"

    attr_reader :file_path

    def initialize(file_path)
      @file_path = file_path
    end

    # Inject option comments for a widget class
    # @param class_name [String] e.g., "Tk::Button"
    # @param options [Array<Tk::OptionGenerator::OptionEntry>] parsed options
    # @return [String] the modified source code
    def inject(class_name, options)
      source = File.read(file_path)

      # Remove existing generated block if present
      source = remove_existing_block(source)

      # Parse with Prism to find insertion point
      result = Prism.parse(source)
      class_node = find_class_node(result.value, class_name)

      unless class_node
        raise "Could not find class #{class_name} in #{file_path}"
      end

      # Find insertion point: after class line and any existing extend/include
      insert_line = find_insert_line(source, class_node)

      # Generate comment block
      comment_block = generate_comment_block(options)

      # Insert the block
      lines = source.lines
      lines.insert(insert_line, comment_block)
      lines.join
    end

    # Write the modified source back to file
    def inject!(class_name, options)
      modified = inject(class_name, options)
      File.write(file_path, modified)
      modified
    end

    private

    def remove_existing_block(source)
      if source.include?(MARKER_START) && source.include?(MARKER_END)
        # Remove everything between markers (inclusive)
        source.gsub(/^[ \t]*#{Regexp.escape(MARKER_START)}.*?#{Regexp.escape(MARKER_END)}\n?/m, '')
      else
        source
      end
    end

    def find_class_node(node, class_name)
      return nil unless node

      # Split class name for nested lookup (e.g., "Tk::Button")
      parts = class_name.split('::')

      case node
      when Prism::ClassNode
        if matches_class_name?(node, parts)
          return node
        end
        # Search in body
        find_class_node(node.body, class_name)
      when Prism::ModuleNode
        find_class_node(node.body, class_name)
      when Prism::StatementsNode
        node.body.each do |child|
          result = find_class_node(child, class_name)
          return result if result
        end
        nil
      when Prism::ProgramNode
        find_class_node(node.statements, class_name)
      else
        nil
      end
    end

    def matches_class_name?(class_node, parts)
      # Get the constant path from the class node
      const_path = extract_const_path(class_node.constant_path)
      const_path == parts
    end

    def extract_const_path(node)
      case node
      when Prism::ConstantReadNode
        [node.name.to_s]
      when Prism::ConstantPathNode
        extract_const_path(node.parent) + [node.name.to_s]
      else
        []
      end
    end

    def find_insert_line(source, class_node)
      lines = source.lines

      # Start from the class definition line
      class_line = class_node.location.start_line - 1  # 0-indexed

      # Scan forward past extend/include statements
      insert_at = class_line + 1
      (class_line + 1).upto(lines.length - 1) do |i|
        line = lines[i]
        if line =~ /^\s*(extend|include)\s+/
          insert_at = i + 1
        elsif line =~ /^\s*(TkCommandNames|WidgetClassName)\s*=/
          # Stop before constants
          break
        elsif line =~ /^\s*$/
          # Empty line - good place to stop
          break
        elsif line =~ /^\s*(def|option|#\s*@generated)/
          # Stop before methods, options, or generated blocks
          break
        else
          # Some other content - stop here
          break
        end
      end

      insert_at
    end

    def generate_comment_block(options)
      lines = []
      lines << "  #{MARKER_START}"
      lines << "  # Available options (auto-generated from Tk introspection):"
      lines << "  #"

      # Group by type
      regular = options.reject(&:alias?).sort_by(&:name)
      regular.each do |opt|
        type_str = opt.ruby_type && opt.ruby_type != :string ? " (#{opt.ruby_type})" : ""
        lines << "  #   :#{opt.name}#{type_str}"
      end

      lines << "  #{MARKER_END}"
      lines << ""

      lines.join("\n") + "\n"
    end
  end
end
