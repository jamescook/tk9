# frozen_string_literal: true

class TkObject<TkKernel
  extend  TkCore
  include Tk
  include TkUtil
  include TkBindCore

  # Global flag to ignore unknown configure options (for compatibility)
  @ignore_unknown_option = false
  class << self
    attr_accessor :ignore_unknown_option
  end

  # Returns the Tk widget path (e.g., ".frame1.button2")
  def path
    @path
  end

  def epath
    @path
  end

  def to_eval
    @path
  end

  def tk_send(cmd, *rest)
    tk_call(path, cmd, *rest)
  end
  def tk_send_without_enc(cmd, *rest)
    tk_call_without_enc(path, cmd, *rest)
  end
  def tk_send_with_enc(cmd, *rest)
    tk_call_with_enc(path, cmd, *rest)
  end

  def tk_send_to_list(cmd, *rest)
    tk_call_to_list(path, cmd, *rest)
  end
  def tk_send_to_list_without_enc(cmd, *rest)
    tk_call_to_list_without_enc(path, cmd, *rest)
  end
  def tk_send_to_list_with_enc(cmd, *rest)
    tk_call_to_list_with_enc(path, cmd, *rest)
  end
  def tk_send_to_simplelist(cmd, *rest)
    tk_call_to_simplelist(path, cmd, *rest)
  end
  def tk_send_to_simplelist_without_enc(cmd, *rest)
    tk_call_to_simplelist_without_enc(path, cmd, *rest)
  end
  def tk_send_to_simplelist_with_enc(cmd, *rest)
    tk_call_to_simplelist_with_enc(path, cmd, *rest)
  end

  def method_missing(id, *args)
    name = id.id2name
    case args.length
    when 1
      if name[-1] == ?=
        configure name[0..-2], args[0]
        args[0]
      else
        configure name, args[0]
        self
      end
    when 0
      begin
        cget(name)
      rescue => e
        if self.kind_of?(TkWindow) && name != "to_ary" && name != "to_str"
          fail NameError,
               "unknown option '#{id}' for #{self.inspect} (deleted widget?) - original error: #{e.class}: #{e.message}"
        else
          super(id, *args)
        end
      end
    else
      super(id, *args)
    end
  end

  def event_generate(context, keys=nil)
    if context.kind_of?(TkEvent::Event)
      context.generate(self, ((keys)? keys: {}))
    elsif keys
      tk_call_without_enc('event', 'generate', path,
                          "<#{tk_event_sequence(context)}>",
                          *hash_kv(keys, true))
    else
      tk_call_without_enc('event', 'generate', path,
                          "<#{tk_event_sequence(context)}>")
    end
  end

  def destroy
  end

  #----------------------------------------------------------
  # Configuration methods (formerly TkConfigMethod)
  #----------------------------------------------------------

  def [](id)
    cget(id)
  end

  def []=(id, val)
    configure(id, val)
    val
  end

  def cget_tkstring(option)
    opt = option.to_s
    fail ArgumentError, "Invalid option `#{option.inspect}'" if opt.length == 0
    tk_call_without_enc(path, 'cget', "-#{opt}")
  end

  def cget(slot)
    slot = slot.to_s
    fail ArgumentError, "Invalid option `#{slot.inspect}'" if slot.empty?

    # Resolve via Option registry (handles aliases)
    opt = self.class.respond_to?(:resolve_option) && self.class.resolve_option(slot)
    slot = opt.tcl_name if opt

    # Get raw value from Tcl
    raw_value = tk_call_without_enc(path, 'cget', "-#{slot}")

    # Use Option registry for type conversion
    if opt
      opt.from_tcl(raw_value, widget: self)
    else
      Tk::Warnings.warn_once(:"cget_undeclared_#{self.class}_#{slot}",
        "#{self.class}#cget(:#{slot}) - option not declared, returning raw string")
      raw_value
    end
  end

  def cget_strict(slot)
    cget(slot)
  end

  def configure(slot, value=None)
    if slot.kind_of? Hash
      slot = _symbolkey2str(slot)

      # Filter version-restricted options
      slot.delete_if { |k, _| _skip_version_restricted?(k) }

      # Resolve aliases
      if self.class.respond_to?(:declared_optkey_aliases)
        self.class.declared_optkey_aliases.each do |alias_name, real_name|
          if slot.key?(alias_name.to_s)
            slot[real_name.to_s] = slot.delete(alias_name.to_s)
          end
        end
      end

      tk_call(path, 'configure', *hash_kv(slot)) if slot.size > 0
    else
      orig_slot = slot
      slot = slot.to_s
      fail ArgumentError, "Invalid option `#{orig_slot.inspect}'" if slot.empty?

      # Resolve alias
      if self.class.respond_to?(:declared_optkey_aliases)
        _, real_name = self.class.declared_optkey_aliases.find { |k, _| k.to_s == slot }
        slot = real_name.to_s if real_name
      end

      return self if _skip_version_restricted?(slot)

      tk_call(path, 'configure', "-#{slot}", value)
    end
    self
  end

  # Backwards compatibility stub - font_configure used to handle compound
  # latin/kanji fonts for JAPANIZED_TK. Now just passes through to configure.
  def font_configure(slot)
    if slot.kind_of?(Hash)
      tk_call(path, 'configure', *hash_kv(slot))
    else
      tk_call(path, 'configure', "-#{slot}")
    end
    self
  end

  def configure_cmd(slot, value)
    configure(slot, install_cmd(value))
  end

  # Apply a font to this widget. Called by TkFont when font attributes change.
  # Widgets with special font handling can override this method.
  def apply_font(font_name)
    configure('font', font_name)
  end

  # Get Tcl configure info for option(s)
  # Returns [option, dbname, dbclass, default, current] for single option
  # Returns array of above for all options (when slot is nil)
  # Alias entries return just [option, target]
  def configinfo(slot = nil)
    if slot
      slot = slot.to_s
      opt = self.class.resolve_option(slot)
      slot = opt.tcl_name if opt
      _process_conf(tk_split_simplelist(tk_call_without_enc(path, 'configure', "-#{slot}"), false, true))
    else
      tk_split_simplelist(tk_call_without_enc(path, 'configure'), false, false).map do |conflist|
        _process_conf(tk_split_simplelist(conflist, false, true))
      end
    end
  end

  # Get current values for option(s)
  # Returns {option => value} hash
  # Uses cget() which handles type conversion via Option registry
  def current_configinfo(slot = nil)
    if slot
      {slot.to_s => cget(slot)}
    else
      result = {}
      configinfo.each do |conf|
        result[conf[TkComm::CONF_KEY]] = cget(conf[TkComm::CONF_KEY]) if conf.size > 2
      end
      result
    end
  end

  private

  # Process a raw Tcl configure array: strip dashes, convert current value
  def _process_conf(conf)
    conf[TkComm::CONF_KEY] = conf[TkComm::CONF_KEY][1..-1]  # strip leading dash
    if conf.size == 2
      # Alias entry: strip dash from target
      conf[TkComm::CONF_DBNAME] = conf[TkComm::CONF_DBNAME][1..-1] if conf[TkComm::CONF_DBNAME]&.start_with?('-')
    else
      conf[TkComm::CONF_CURRENT] = _convert_value(conf[TkComm::CONF_KEY], conf[TkComm::CONF_CURRENT])
    end
    conf
  end

  # Convert a raw Tcl value to Ruby using the Option registry
  def _convert_value(option_name, raw_value)
    opt = self.class.resolve_option(option_name)
    opt ? opt.from_tcl(raw_value, widget: self) : raw_value
  end

  def _skip_version_restricted?(option_name)
    # Only applies to classes using OptionDSL
    return false unless self.class.respond_to?(:option_version_required)

    # Check regular options with min_version
    required = self.class.option_version_required(option_name)
    if required
      _handle_version_mismatch(option_name, "#{required}.0")
      return true
    end

    # Check future_options (options from newer Tk versions)
    info = self.class.future_option_info(option_name.to_sym)
    if info
      _handle_version_mismatch(option_name, info[:min_version])
      return true
    end

    false
  end

  def _handle_version_mismatch(option_name, min_version)
    case Tk.version_mismatch
    when :raise
      raise ArgumentError, "Option '#{option_name}' requires Tk #{min_version}+ (running #{Tk::TK_VERSION})"
    when :warn
      Tk::Warnings.warn_once(:"version_mismatch_#{self.class}_#{option_name}",
        "#{self.class}: option '#{option_name}' requires Tk #{min_version}+ (running #{Tk::TK_VERSION}), ignoring")
    end
  end
end
