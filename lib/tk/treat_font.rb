# frozen_string_literal: false
#
# tk/treat_font.rb - Font configuration mixin for Tk widgets
#
# Provides font_configinfo, font_configure, latinfont_configure,
# kanjifont_configure, font_copy, etc.
#
# Included by TkConfigMethod.

module TkTreatFont
  def __font_optkeys
    ['font']
  end
  private :__font_optkeys

  def __pathname
    self.path
  end
  private :__pathname

  ################################

  def font_configinfo(key = nil)
    optkeys = __font_optkeys
    if key && !optkeys.find{|opt| opt.to_s == key.to_s}
      fail ArgumentError, "unknown font option name `#{key}'"
    end

    win, tag = __pathname.split(':')

    if key
      pathname = [win, tag, key].join(';')
      TkFont.used_on(pathname) ||
        TkFont.init_widget_font(pathname, *__confinfo_cmd)
    elsif optkeys.size == 1
      pathname = [win, tag, optkeys[0]].join(';')
      TkFont.used_on(pathname) ||
        TkFont.init_widget_font(pathname, *__confinfo_cmd)
    else
      fonts = {}
      optkeys.each{|k|
        k = k.to_s
        pathname = [win, tag, k].join(';')
        fonts[k] =
          TkFont.used_on(pathname) ||
          TkFont.init_widget_font(pathname, *__confinfo_cmd)
      }
      fonts
    end
  end
  alias fontobj font_configinfo

  def font_configure(slot)
    pathname = __pathname

    slot = _symbolkey2str(slot)

    __font_optkeys.each{|optkey|
      optkey = optkey.to_s
      l_optkey = 'latin' << optkey
      a_optkey = 'ascii' << optkey
      k_optkey = 'kanji' << optkey

      if slot.key?(optkey)
        fnt = slot.delete(optkey)
        if fnt.kind_of?(TkFont)
          slot.delete(l_optkey)
          slot.delete(a_optkey)
          slot.delete(k_optkey)

          fnt.call_font_configure([pathname, optkey], *(__config_cmd << {}))
          next
        else
          if fnt
            if (slot.key?(l_optkey) ||
                slot.key?(a_optkey) ||
                slot.key?(k_optkey))
              fnt = TkFont.new(fnt)

              lfnt = slot.delete(l_optkey)
              lfnt = slot.delete(a_optkey) if slot.key?(a_optkey)
              kfnt = slot.delete(k_optkey)

              fnt.latin_replace(lfnt) if lfnt
              fnt.kanji_replace(kfnt) if kfnt

              fnt.call_font_configure([pathname, optkey],
                                      *(__config_cmd << {}))
              next
            else
              fnt = hash_kv(fnt) if fnt.kind_of?(Hash)
              unless TkConfigMethod.__IGNORE_UNKNOWN_CONFIGURE_OPTION__
                tk_call(*(__config_cmd << "-#{optkey}" << fnt))
              else
                begin
                  tk_call(*(__config_cmd << "-#{optkey}" << fnt))
                rescue
                  # ignore
                end
              end
            end
          end
          next
        end
      end

      lfnt = slot.delete(l_optkey)
      lfnt = slot.delete(a_optkey) if slot.key?(a_optkey)
      kfnt = slot.delete(k_optkey)

      if lfnt && kfnt
        TkFont.new(lfnt, kfnt).call_font_configure([pathname, optkey],
                                                   *(__config_cmd << {}))
      elsif lfnt
        latinfont_configure([lfnt, optkey])
      elsif kfnt
        kanjifont_configure([kfnt, optkey])
      end
    }

    # configure other (without font) options
    tk_call(*(__config_cmd.concat(hash_kv(slot)))) if slot != {}
    self
  end

  def latinfont_configure(ltn, keys=nil)
    if ltn.kind_of?(Array)
      key = ltn[1]
      ltn = ltn[0]
    else
      key = nil
    end

    optkeys = __font_optkeys
    if key && !optkeys.find{|opt| opt.to_s == key.to_s}
      fail ArgumentError, "unknown font option name `#{key}'"
    end

    win, tag = __pathname.split(':')

    optkeys = [key] if key

    optkeys.each{|optkey|
      optkey = optkey.to_s

      pathname = [win, tag, optkey].join(';')

      if (fobj = TkFont.used_on(pathname))
        fobj = TkFont.new(fobj) # create a new TkFont object
      elsif Tk::JAPANIZED_TK
        fobj = fontobj          # create a new TkFont object
      else
        ltn = hash_kv(ltn) if ltn.kind_of?(Hash)
        unless TkConfigMethod.__IGNORE_UNKNOWN_CONFIGURE_OPTION__
          tk_call(*(__config_cmd << "-#{optkey}" << ltn))
        else
          begin
            tk_call(*(__config_cmd << "-#{optkey}" << ltn))
          rescue
            # ignore
          end
        end
        next
      end

      if fobj.kind_of?(TkFont)
        if ltn.kind_of?(TkFont)
          conf = {}
          ltn.latin_configinfo.each{|k,val| conf[k] = val}
          if keys
            fobj.latin_configure(conf.update(keys))
          else
            fobj.latin_configure(conf)
          end
        else
          fobj.latin_replace(ltn)
        end
      end

      fobj.call_font_configure([pathname, optkey], *(__config_cmd << {}))
    }
    self
  end
  alias asciifont_configure latinfont_configure

  def kanjifont_configure(knj, keys=nil)
    if knj.kind_of?(Array)
      key = knj[1]
      knj = knj[0]
    else
      key = nil
    end

    optkeys = __font_optkeys
    if key && !optkeys.find{|opt| opt.to_s == key.to_s}
      fail ArgumentError, "unknown font option name `#{key}'"
    end

    win, tag = __pathname.split(':')

    optkeys = [key] if key

    optkeys.each{|optkey|
      optkey = optkey.to_s

      pathname = [win, tag, optkey].join(';')

      if (fobj = TkFont.used_on(pathname))
        fobj = TkFont.new(fobj) # create a new TkFont object
      elsif Tk::JAPANIZED_TK
        fobj = fontobj          # create a new TkFont object
      else
        knj = hash_kv(knj) if knj.kind_of?(Hash)
        unless TkConfigMethod.__IGNORE_UNKNOWN_CONFIGURE_OPTION__
          tk_call(*(__config_cmd << "-#{optkey}" << knj))
        else
          begin
            tk_call(*(__config_cmd << "-#{optkey}" << knj))
          rescue
            # ignore
          end
        end
        next
      end

      if fobj.kind_of?(TkFont)
        if knj.kind_of?(TkFont)
          conf = {}
          knj.kanji_configinfo.each{|k,val| conf[k] = val}
          if keys
            fobj.kanji_configure(conf.update(keys))
          else
            fobj.kanji_configure(conf)
          end
        else
          fobj.kanji_replace(knj)
        end
      end

      fobj.call_font_configure([pathname, optkey], *(__config_cmd << {}))
    }
    self
  end

  def font_copy(win, wintag=nil, winkey=nil, targetkey=nil)
    if wintag
      if winkey
        fnt = win.tagfontobj(wintag, winkey).dup
      else
        fnt = win.tagfontobj(wintag).dup
      end
    else
      if winkey
        fnt = win.fontobj(winkey).dup
      else
        fnt = win.fontobj.dup
      end
    end

    if targetkey
      fnt.call_font_configure([__pathname, targetkey], *(__config_cmd << {}))
    else
      fnt.call_font_configure(__pathname, *(__config_cmd << {}))
    end
    self
  end

  def latinfont_copy(win, wintag=nil, winkey=nil, targetkey=nil)
    if targetkey
      fontobj(targetkey).dup.call_font_configure([__pathname, targetkey],
                                                 *(__config_cmd << {}))
    else
      fontobj.dup.call_font_configure(__pathname, *(__config_cmd << {}))
    end

    if wintag
      if winkey
        fontobj.latin_replace(win.tagfontobj(wintag, winkey).latin_font_id)
      else
        fontobj.latin_replace(win.tagfontobj(wintag).latin_font_id)
      end
    else
      if winkey
        fontobj.latin_replace(win.fontobj(winkey).latin_font_id)
      else
        fontobj.latin_replace(win.fontobj.latin_font_id)
      end
    end
    self
  end
  alias asciifont_copy latinfont_copy

  def kanjifont_copy(win, wintag=nil, winkey=nil, targetkey=nil)
    if targetkey
      fontobj(targetkey).dup.call_font_configure([__pathname, targetkey],
                                                 *(__config_cmd << {}))
    else
        fontobj.dup.call_font_configure(__pathname, *(__config_cmd << {}))
    end

    if wintag
      if winkey
        fontobj.kanji_replace(win.tagfontobj(wintag, winkey).kanji_font_id)
      else
        fontobj.kanji_replace(win.tagfontobj(wintag).kanji_font_id)
      end
    else
      if winkey
        fontobj.kanji_replace(win.fontobj(winkey).kanji_font_id)
      else
        fontobj.kanji_replace(win.fontobj.kanji_font_id)
      end
    end
    self
  end
end
