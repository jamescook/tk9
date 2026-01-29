# frozen_string_literal: true

require_relative 'option'

module Tk
  # DSL for declaring item options and providing item configuration methods.
  #
  # This module provides both the class-level DSL for declaring item options
  # and command patterns, AND the instance methods for itemcget/itemconfigure.
  # When you `extend Tk::ItemOptionDSL`, it automatically includes the
  # InstanceMethods module to provide the implementation.
  #
  # Example:
  #   class TkCanvas
  #     extend Tk::OptionDSL
  #     extend Tk::ItemOptionDSL
  #
  #     # Declare how item commands are built
  #     item_commands cget: 'itemcget', configure: 'itemconfigure'
  #
  #     # Item options (for rectangles, ovals, lines, text, etc.)
  #     item_option :fill, type: :color
  #     item_option :outline, type: :color
  #     item_option :width, type: :integer
  #     item_option :smooth, type: :boolean
  #   end
  #
  #   # Now instances have itemcget, itemconfigure, itemconfiginfo methods
  #   canvas.itemcget(item_id, :fill)
  #   canvas.itemconfigure(item_id, fill: 'red')
  #
  module ItemOptionDSL
    # Called when module is extended into a class/module - adds instance methods
    def self.extended(base)
      base.instance_variable_set(:@_item_options, {})
      if base.is_a?(Class)
        # Class: include so instances get the methods
        base.include(InstanceMethods)
      else
        # Module singleton (like Tk::Busy): extend so module itself gets the methods
        base.extend(InstanceMethods)
      end
    end

    # Inherit item options and command config from parent class
    def inherited(subclass)
      super
      if instance_variable_defined?(:@_item_options)
        subclass.instance_variable_set(:@_item_options, _item_options.dup)
      end
      # Inherit item command configuration
      %i[@_item_command_cget @_item_command_configure
         @_item_cget_proc @_item_configure_proc].each do |ivar|
        if instance_variable_defined?(ivar)
          subclass.instance_variable_set(ivar, instance_variable_get(ivar))
        end
      end
    end

    # Declare an item option for this widget class.
    #
    # @param name [Symbol] Ruby-facing option name
    # @param type [Symbol] Type converter (:string, :integer, :boolean, etc.)
    # @param tcl_name [String, nil] Tcl option name if different from Ruby name
    # @param alias [Symbol, nil] Single alias for this option
    # @param aliases [Array<Symbol>] Alternative names for this option
    #
    def item_option(name, type: :string, tcl_name: nil, alias: nil, aliases: [])
      # Support both alias: :foo (single) and aliases: [:foo, :bar] (multiple)
      all_aliases = Array(binding.local_variable_get(:alias)) + Array(aliases)
      all_aliases.compact!

      opt = Option.new(name: name, tcl_name: tcl_name, type: type, aliases: all_aliases)
      _item_options[opt.name] = opt
      all_aliases.each { |a| _item_options[a.to_sym] = opt }
    end

    # All declared item options (including aliases pointing to same Option)
    def item_options
      _item_options.dup
    end

    # Look up an item option by name or alias
    #
    # @param name [Symbol, String] Option name or alias
    # @return [Tk::Option, nil]
    #
    def resolve_item_option(name)
      _item_options[name.to_sym]
    end

    # List of canonical item option names (excludes aliases)
    def item_option_names
      _item_options.values.uniq.map(&:name)
    end

    def declared_item_optkey_aliases
      _item_options.values.uniq.each_with_object({}) do |opt, hash|
        opt.aliases.each { |a| hash[a] = opt.name }
      end
    end

    # ========================================================================
    # Item Command DSL
    # ========================================================================
    #
    # Declarative way to specify how item cget/configure commands are built.
    #
    # Simple usage (most widgets):
    #   item_commands cget: 'entrycget', configure: 'entryconfigure'
    #
    # Full control via procs:
    #   item_cget_cmd { |(type, tag_or_id)| [path, type, 'cget', tag_or_id] }
    #   item_configure_cmd { |(type, tag_or_id)| [path, type, 'configure', tag_or_id] }
    #
    # ========================================================================

    # Shorthand for widgets that just need different command words.
    # Builds: [path, cget_cmd, id] and [path, configure_cmd, id]
    #
    # @param cget [String] The cget subcommand (e.g., 'itemcget', 'entrycget')
    # @param configure [String] The configure subcommand (e.g., 'itemconfigure', 'entryconfigure')
    #
    def item_commands(cget:, configure:)
      @_item_command_cget = cget
      @_item_command_configure = configure
    end

    # Full control over cget command building via a block.
    # Block receives (id) and should return command array.
    # Block is instance_exec'd on the widget, so `path` etc. are available.
    #
    # @example Text widget with structured id
    #   item_cget_cmd { |(type, tag_or_id)| [path, type, 'cget', tag_or_id] }
    #
    # @example Treeview where id is splatted
    #   item_cget_cmd { |id| [path, *id] }
    #
    # @example Busy with window path extraction
    #   item_cget_cmd { |win| ['tk', 'busy', 'cget', win.path] }
    #
    def item_cget_cmd(&block)
      @_item_cget_proc = block
    end

    # Full control over configure command building via a block.
    #
    def item_configure_cmd(&block)
      @_item_configure_proc = block
    end

    # Returns the item command configuration, or nil if not configured.
    #
    # @return [Hash, nil] Configuration hash with :cget, :configure, :cget_proc, :configure_proc
    #
    def item_command_config
      cget_cmd = instance_variable_get(:@_item_command_cget)
      cget_proc = instance_variable_get(:@_item_cget_proc)

      return nil unless cget_cmd || cget_proc

      {
        cget: cget_cmd,
        configure: instance_variable_get(:@_item_command_configure),
        cget_proc: cget_proc,
        configure_proc: instance_variable_get(:@_item_configure_proc),
      }
    end

    private

    def _item_options
      @_item_options ||= {}
    end

    # ========================================================================
    # Instance Methods - included automatically when extending ItemOptionDSL
    # ========================================================================
    #
    # These provide the actual itemcget, itemconfigure, itemconfiginfo methods.
    # They use the DSL configuration to build commands and convert values.
    #
    module InstanceMethods
      include TkUtil

      def itemcget_tkstring(tagOrId, option)
        opt = option.to_s
        raise ArgumentError, "Invalid option `#{option.inspect}'" if opt.empty?
        tk_call_without_enc(*(_item_cget_cmd(tagid(tagOrId)) << "-#{opt}"))
      end

      def itemcget(tagOrId, option)
        option = option.to_s
        raise ArgumentError, "Invalid option `#{option.inspect}'" if option.empty?

        # Resolve alias if declared
        if self.class.respond_to?(:resolve_item_option)
          opt = self.class.resolve_item_option(option)
          option = opt.tcl_name if opt
        end

        raw = tk_call_without_enc(*(_item_cget_cmd(tagid(tagOrId)) << "-#{option}"))
        _convert_item_value(option, raw)
      end
      alias itemcget_strict itemcget

      def itemconfigure(tagOrId, slot, value = None)
        if slot.kind_of?(Hash)
          slot = _symbolkey2str(slot)

          # Resolve aliases
          if self.class.respond_to?(:declared_item_optkey_aliases)
            self.class.declared_item_optkey_aliases.each do |alias_name, real_name|
              if slot.key?(alias_name.to_s)
                slot[real_name.to_s] = slot.delete(alias_name.to_s)
              end
            end
          end

          tk_call(*(_item_config_cmd(tagid(tagOrId)).concat(hash_kv(slot)))) unless slot.empty?
        else
          slot = slot.to_s
          raise ArgumentError, "Invalid option `#{slot.inspect}'" if slot.empty?

          # Resolve alias if declared
          if self.class.respond_to?(:resolve_item_option)
            opt = self.class.resolve_item_option(slot)
            slot = opt.tcl_name if opt
          end

          tk_call(*(_item_config_cmd(tagid(tagOrId)) << "-#{slot}" << value))
        end
        self
      end

      def itemconfiginfo(tagOrId, slot = nil)
        if slot
          slot = slot.to_s

          # Resolve alias if declared
          if self.class.respond_to?(:resolve_item_option)
            opt = self.class.resolve_item_option(slot)
            slot = opt.tcl_name if opt
          end

          _process_item_conf(tk_split_simplelist(tk_call_without_enc(*(_item_confinfo_cmd(tagid(tagOrId)) << "-#{slot}")), false, true))
        else
          tk_split_simplelist(tk_call_without_enc(*(_item_confinfo_cmd(tagid(tagOrId)))), false, false).map do |conflist|
            _process_item_conf(tk_split_simplelist(conflist, false, true))
          end
        end
      end

      def current_itemconfiginfo(tagOrId, slot = nil)
        if slot
          conf = itemconfiginfo(tagOrId, slot)
          # Follow alias chain
          while conf.size == 2
            conf = itemconfiginfo(tagOrId, conf[1])
          end
          { conf[0] => conf[-1] }
        else
          ret = {}
          itemconfiginfo(tagOrId).each do |conf|
            ret[conf[0]] = conf[-1] if conf.size > 2  # skip aliases
          end
          ret
        end
      end

      # Override in subclass if needed
      def tagid(tagOrId)
        tagOrId
      end

      private

      # Build the cget command array using DSL configuration
      def _item_cget_cmd(id)
        _build_item_cmd(:cget, id) || [self.path, 'itemcget', id]
      end

      # Build the configure command array using DSL configuration
      def _item_config_cmd(id)
        _build_item_cmd(:configure, id) || [self.path, 'itemconfigure', id]
      end

      # Build the confinfo command array (usually same as configure)
      def _item_confinfo_cmd(id)
        _item_config_cmd(id)
      end

      # Build item command from DSL configuration.
      def _build_item_cmd(cmd_type, id)
        # For class instances, check self.class; for module singletons (like Tk::Busy), check self
        config_source = self.is_a?(Module) ? self : self.class
        config = config_source.respond_to?(:item_command_config) ? config_source.item_command_config : nil
        return nil unless config

        # Check for proc-based configuration (full control)
        proc_key = :"#{cmd_type}_proc"
        if config[proc_key]
          return instance_exec(id, &config[proc_key])
        end

        # Check for simple command-word configuration
        cmd_word = config[cmd_type]
        return nil unless cmd_word

        [self.path, cmd_word, id]
      end

      # Convert a raw Tcl value to Ruby using the ItemOption registry
      def _convert_item_value(option_name, raw_value)
        return raw_value unless self.class.respond_to?(:resolve_item_option)
        opt = self.class.resolve_item_option(option_name)
        opt ? opt.from_tcl(raw_value, widget: self) : raw_value
      end

      # Process a raw Tcl configure array: strip dashes, convert current value
      def _process_item_conf(conf)
        conf[TkComm::CONF_KEY] = conf[TkComm::CONF_KEY][1..-1]  # strip leading dash
        if conf.size == 2
          # Alias entry: strip dash from target
          conf[TkComm::CONF_DBNAME] = conf[TkComm::CONF_DBNAME][1..-1] if conf[TkComm::CONF_DBNAME]&.start_with?('-')
        else
          conf[TkComm::CONF_CURRENT] = _convert_item_value(conf[TkComm::CONF_KEY], conf[TkComm::CONF_CURRENT])
        end
        conf
      end
    end
  end
end
