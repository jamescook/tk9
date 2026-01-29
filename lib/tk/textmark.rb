# frozen_string_literal: false
#
# tk/textmark.rb - methods for treating text marks
#
require 'tk/text'

class TkTextMark<TkObject
  include Tk::Text::IndexModMethods

  (Tk_TextMark_ID = ['mark'.freeze, '00000']).instance_eval{
    @mutex = Mutex.new
    def mutex; @mutex; end
    freeze
  }

  # Look up a mark by ID. Delegates to the text widget's tagid2obj.
  def TkTextMark.id2obj(text, id)
    text.tagid2obj(id)
  end

  def initialize(parent, index)
    #unless parent.kind_of?(Tk::Text)
    #  fail ArgumentError, "expect Tk::Text for 1st argument"
    #end
    @parent = @t = parent
    @tpath = parent.path
    Tk_TextMark_ID.mutex.synchronize{
      # @path = @id = Tk_TextMark_ID.join('')
      @path = @id = Tk_TextMark_ID.join(TkCore::INTERP._ip_id_).freeze
      Tk_TextMark_ID[1].succ!
    }
    tk_call_without_enc(@t.path, 'mark', 'set', @id,
                        _get_eval_enc_str(index))
    @t._addtag id, self
  end

  def id
    Tk::Text::IndexString.new(@id)
  end

  def exist?
    #if ( tk_split_simplelist(_fromUTF8(tk_call_without_enc(@t.path, 'mark', 'names'))).find{|id| id == @id } )
    if ( tk_split_simplelist(tk_call_without_enc(@t.path, 'mark', 'names'), false, true).find{|id| id == @id } )
      true
    else
      false
    end
  end

=begin
  # move to Tk::Text::IndexModMethods module
  def +(mod)
    return chars(mod) if mod.kind_of?(Numeric)

    mod = mod.to_s
    if mod =~ /^\s*[+-]?\d/
      Tk::Text::IndexString.new(@id + ' + ' + mod)
    else
      Tk::Text::IndexString.new(@id + ' ' + mod)
    end
  end

  def -(mod)
    return chars(-mod) if mod.kind_of?(Numeric)

    mod = mod.to_s
    if mod =~ /^\s*[+-]?\d/
      Tk::Text::IndexString.new(@id + ' - ' + mod)
    elsif mod =~ /^\s*[-]\s+(\d.*)$/
      Tk::Text::IndexString.new(@id + ' - -' + $1)
    else
      Tk::Text::IndexString.new(@id + ' ' + mod)
    end
  end
=end

  def pos
    @t.index(@id)
  end

  def pos=(where)
    set(where)
  end

  def set(where)
    tk_call_without_enc(@t.path, 'mark', 'set', @id,
                        _get_eval_enc_str(where))
    self
  end

  def unset
    tk_call_without_enc(@t.path, 'mark', 'unset', @id)
    self
  end
  alias destroy unset

  def gravity
    tk_call_without_enc(@t.path, 'mark', 'gravity', @id)
  end

  def gravity=(direction)
    tk_call_without_enc(@t.path, 'mark', 'gravity', @id, direction)
    #self
    direction
  end

  def next(index = nil)
    if index
      @t.tagid2obj(tk_call_without_enc(@t.path, 'mark', 'next', _get_eval_enc_str(index)))
    else
      @t.tagid2obj(tk_call_without_enc(@t.path, 'mark', 'next', @id))
    end
  end

  def previous(index = nil)
    if index
      @t.tagid2obj(tk_call_without_enc(@t.path, 'mark', 'previous', _get_eval_enc_str(index)))
    else
      @t.tagid2obj(tk_call_without_enc(@t.path, 'mark', 'previous', @id))
    end
  end
end
TktMark = TkTextMark

# Named marks are cached per (parent, name) pair via the text widget's @tags hash.
# self.new returns existing mark if found, otherwise creates new via initialize.
class TkTextNamedMark<TkTextMark
  def self.new(parent, name, index=nil)
    # Return existing mark if already registered with this text widget
    existing = parent.tagid2obj(name)
    return existing if existing.kind_of?(TkTextMark)

    # Create new mark via normal instantiation
    super
  end

  def initialize(parent, name, index=nil)
    @parent = @t = parent
    @tpath = parent.path
    @path = @id = name
    tk_call_without_enc(@t.path, 'mark', 'set', @id,
                        _get_eval_enc_str(index)) if index
    @t._addtag @id, self
  end
end
TktNamedMark = TkTextNamedMark

class TkTextMarkInsert<TkTextNamedMark
  def self.new(parent,*args)
    super(parent, 'insert', *args)
  end
end
TktMarkInsert = TkTextMarkInsert

class TkTextMarkCurrent<TkTextNamedMark
  def self.new(parent,*args)
    super(parent, 'current', *args)
  end
end
TktMarkCurrent = TkTextMarkCurrent

class TkTextMarkAnchor<TkTextNamedMark
  def self.new(parent,*args)
    super(parent, 'anchor', *args)
  end
end
TktMarkAnchor = TkTextMarkAnchor

# Add deprecation warning for removed TMarkID_TBL constant
TkTextMark.extend(TkTextMarkCompat)
