# frozen_string_literal: true

class TkObject<TkKernel
  extend  TkCore
  include Tk
  include TkUtil
  include TkTreatFont
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
      rescue
        if self.kind_of?(TkWindow) && name != "to_ary" && name != "to_str"
          fail NameError,
               "unknown option '#{id}' for #{self.inspect} (deleted widget?)"
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

    # Font options (complex, keep special handling)
    if _font_optkey?(slot)
      fnt = tk_tcl2ruby(tk_call_without_enc(path, 'cget', "-#{slot}"), true)
      return fnt.kind_of?(TkFont) ? fnt : fontobj(slot)
    end

    # Get raw value from Tcl
    raw_value = tk_call_without_enc(path, 'cget', "-#{slot}")

    # Use Option registry for type conversion
    if opt
      opt.from_tcl(raw_value, widget: self)
    else
      warn "#{self.class}#cget(:#{slot}) - option not declared, returning raw string"
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

      # Font options
      font_keys = slot.select { |k, _| k =~ /^(|latin|ascii|kanji)(#{_font_optkeys.join('|')})$/ }
      if font_keys.any?
        font_configure(slot)
      elsif slot.size > 0
        tk_call(path, 'configure', *hash_kv(slot))
      end
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

      if slot =~ /^(|latin|ascii|kanji)(#{_font_optkeys.join('|')})$/
        value == None ? fontobj($2) : font_configure({slot => value})
      else
        tk_call(path, 'configure', "-#{slot}", value)
      end
    end
    self
  end

  def configure_cmd(slot, value)
    configure(slot, install_cmd(value))
  end

  def configinfo(slot = nil)
    if TkComm::GET_CONFIGINFO_AS_ARRAY
      _configinfo_array(slot)
    else
      _configinfo_hash(slot)
    end
  end

  def current_configinfo(slot = nil)
    if TkComm::GET_CONFIGINFO_AS_ARRAY
      if slot
        conf = configinfo(slot)
        { conf[0] => conf[-1] }
      else
        ret = {}
        configinfo.each { |cnf| ret[cnf[0]] = cnf[-1] if cnf.size > 2 }
        ret
      end
    else
      ret = {}
      configinfo(slot).each { |key, cnf| ret[key] = cnf[-1] if cnf.kind_of?(Array) }
      ret
    end
  end

  private

  # Config command array for Tcl calls - used by TkTreatFont
  def __config_cmd
    [self.path, 'configure']
  end

  def __confinfo_cmd
    __config_cmd
  end

  # Font option keys - override in subclasses if needed
  def _font_optkeys
    ['font']
  end

  def _font_optkey?(slot)
    slot =~ /^(|latin|ascii|kanji)(#{_font_optkeys.join('|')})$/
  end

  def _skip_version_restricted?(option_name)
    return false unless self.class.respond_to?(:option_version_required)
    required = self.class.option_version_required(option_name)
    return false unless required
    warn "#{self.class}: option '#{option_name}' requires Tcl/Tk #{required}.0+ (current: #{Tk::TK_VERSION}). Option ignored."
    true
  end

  def _configinfo_array(slot)
    if slot
      slot = slot.to_s
      # Resolve alias
      if self.class.respond_to?(:declared_optkey_aliases)
        _, real_name = self.class.declared_optkey_aliases.find { |k, _| k.to_s == slot }
        slot = real_name.to_s if real_name
      end

      # Font options
      if _font_optkey?(slot)
        fontkey = slot.sub(/^(latin|ascii|kanji)/, '')
        conf = tk_split_simplelist(tk_call_without_enc(path, 'configure', "-#{fontkey}"), false, true)
        conf[0] = conf[0][1..-1]
        conf[-1] = fontobj(fontkey)
        return conf
      end

      # Regular option
      conf = tk_split_simplelist(tk_call_without_enc(path, 'configure', "-#{slot}"), false, true)
      conf[0] = conf[0][1..-1]

      # Apply type conversion via Option registry
      opt = self.class.respond_to?(:resolve_option) && self.class.resolve_option(slot)
      if opt
        conf[3] = opt.from_tcl(conf[3], widget: self) rescue conf[3] if conf[3]
        conf[4] = opt.from_tcl(conf[4], widget: self) rescue conf[4] if conf[4]
      end
      conf
    else
      # All options
      ret = tk_split_simplelist(tk_call_without_enc(path, 'configure'), false, false).map do |conflist|
        conf = tk_split_simplelist(conflist, false, true)
        conf[0] = conf[0][1..-1]  # strip leading dash from option name

        # Alias entries are 2-element arrays: ["-bd", "-borderwidth"]
        # Strip the dash from the target too
        if conf.size == 2 && conf[1].is_a?(String) && conf[1].start_with?('-')
          conf[1] = conf[1][1..-1]
        end

        optkey = conf[0]

        opt = self.class.respond_to?(:resolve_option) && self.class.resolve_option(optkey)
        if opt
          conf[3] = opt.from_tcl(conf[3], widget: self) rescue conf[3] if conf[3]
          conf[4] = opt.from_tcl(conf[4], widget: self) rescue conf[4] if conf[4]
        end
        conf
      end

      ret
    end
  end

  def _configinfo_hash(slot)
    if slot
      slot = slot.to_s
      if self.class.respond_to?(:declared_optkey_aliases)
        _, real_name = self.class.declared_optkey_aliases.find { |k, _| k.to_s == slot }
        slot = real_name.to_s if real_name
      end

      conf = tk_split_simplelist(tk_call_without_enc(path, 'configure', "-#{slot}"), false, true)
      conf[0] = conf[0][1..-1]

      opt = self.class.respond_to?(:resolve_option) && self.class.resolve_option(slot)
      if opt
        conf[3] = opt.from_tcl(conf[3], widget: self) rescue conf[3] if conf[3]
        conf[4] = opt.from_tcl(conf[4], widget: self) rescue conf[4] if conf[4]
      end
      { conf.shift => conf }
    else
      ret = {}
      tk_split_simplelist(tk_call_without_enc(path, 'configure'), false, false).each do |conflist|
        conf = tk_split_simplelist(conflist, false, true)
        conf[0] = conf[0][1..-1]  # strip leading dash from option name
        optkey = conf[0]

        # Alias entries are 2-element arrays: ["-bd", "-borderwidth"]
        # In hash mode: { "bd" => "borderwidth" }
        if conf.size == 2
          target = conf[1]
          target = target[1..-1] if target.is_a?(String) && target.start_with?('-')
          ret[optkey] = target
          next
        end

        opt = self.class.respond_to?(:resolve_option) && self.class.resolve_option(optkey)
        if opt
          conf[3] = opt.from_tcl(conf[3], widget: self) rescue conf[3] if conf[3]
          conf[4] = opt.from_tcl(conf[4], widget: self) rescue conf[4] if conf[4]
        end
        ret[conf.shift] = conf
      end

      ret
    end
  end
end
