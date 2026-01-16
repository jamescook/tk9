# frozen_string_literal: false
#
# tk/canvas.rb - Tk canvas classes
#                       by Yukihiro Matsumoto <matz@caelum.co.jp>
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/canvas.html
#
require 'tk' unless defined?(Tk)
require 'tk/canvastag'
require 'tk/scrollable'
require 'tk/option_dsl'
require 'tk/item_option_dsl'

module TkCanvasItemConfig
  include Tk::ItemOptionDSL::InstanceMethods
end

class Tk::Canvas<TkWindow
  include TkCanvasItemConfig
  include Tk::Scrollable
  include Tk::Generated::Canvas
  include Tk::Generated::CanvasItems
  # @generated:options:start
  # Available options (auto-generated from Tk introspection):
  #
  #   :background
  #   :bd
  #   :bg
  #   :borderwidth
  #   :closeenough
  #   :confine
  #   :cursor
  #   :height
  #   :highlightbackground
  #   :highlightcolor
  #   :highlightthickness
  #   :insertbackground
  #   :insertborderwidth
  #   :insertofftime
  #   :insertontime
  #   :insertwidth
  #   :offset
  #   :relief
  #   :scrollregion
  #   :selectbackground
  #   :selectborderwidth
  #   :selectforeground
  #   :state
  #   :takefocus
  #   :width
  #   :xscrollcommand
  #   :xscrollincrement
  #   :yscrollcommand
  #   :yscrollincrement
  # @generated:options:end



  TkCommandNames = ['canvas'.freeze].freeze
  WidgetClassName = 'Canvas'.freeze
  WidgetClassNames[WidgetClassName] ||= self

  def __destroy_hook__
    TkcItem::CItemID_TBL.delete(@path)
  end

  #def create_self(keys)
  #  if keys and keys != None
  #    tk_call_without_enc('canvas', @path, *hash_kv(keys, true))
  #  else
  #    tk_call_without_enc('canvas', @path)
  #  end
  #end
  #private :create_self

  # NOTE: __numval_optkeys override for 'closeenough' removed - now declared via OptionDSL
  # NOTE: __boolval_optkeys override for 'confine' removed - now declared via OptionDSL

  def tagid(tag)
    if tag.kind_of?(TkcItem) || tag.kind_of?(TkcTag)
      tag.id
    else
      tag  # maybe an Array of configure parameters
    end
  end
  private :tagid


  # create a canvas item without creating a TkcItem object
  def create(type, *args)
    if type.kind_of?(Class) && type < TkcItem
      # do nothing
    elsif TkcItem.type2class(type.to_s)
      type = TkcItem.type2class(type.to_s)
    else
      fail ArgumentError, "type must a subclass of TkcItem class, or a string in CItemTypeToClass"
    end
    type.create(self, *args)
  end

  def addtag(tag, mode, *args)
    mode = mode.to_s
    if args[0] && mode =~ /^(above|below|with(tag)?)$/
      args[0] = tagid(args[0])
    end
    tk_send_without_enc('addtag', tagid(tag), mode, *args)
    self
  end
  def addtag_above(tagOrId, target)
    addtag(tagOrId, 'above', tagid(target))
  end
  def addtag_all(tagOrId)
    addtag(tagOrId, 'all')
  end
  def addtag_below(tagOrId, target)
    addtag(tagOrId, 'below', tagid(target))
  end
  def addtag_closest(tagOrId, x, y, halo=None, start=None)
    addtag(tagOrId, 'closest', x, y, halo, start)
  end
  def addtag_enclosed(tagOrId, x1, y1, x2, y2)
    addtag(tagOrId, 'enclosed', x1, y1, x2, y2)
  end
  def addtag_overlapping(tagOrId, x1, y1, x2, y2)
    addtag(tagOrId, 'overlapping', x1, y1, x2, y2)
  end
  def addtag_withtag(tagOrId, tag)
    addtag(tagOrId, 'withtag', tagid(tag))
  end

  def bbox(tagOrId, *tags)
    list(tk_send_without_enc('bbox', tagid(tagOrId),
                             *tags.collect{|t| tagid(t)}))
  end

  def itembind(tag, context, *args, &block)
    # if args[0].kind_of?(Proc) || args[0].kind_of?(Method)
    if TkComm._callback_entry?(args[0]) || !block
      cmd = args.shift
    else
      cmd = block
    end
    _bind([path, "bind", tagid(tag)], context, cmd, *args)
    self
  end

  def itembind_append(tag, context, *args, &block)
    # if args[0].kind_of?(Proc) || args[0].kind_of?(Method)
    if TkComm._callback_entry?(args[0]) || !block
      cmd = args.shift
    else
      cmd = block
    end
    _bind_append([path, "bind", tagid(tag)], context, cmd, *args)
    self
  end

  def itembind_remove(tag, context)
    _bind_remove([path, "bind", tagid(tag)], context)
    self
  end

  def itembindinfo(tag, context=nil)
    _bindinfo([path, "bind", tagid(tag)], context)
  end

  def canvasx(screen_x, *args)
    #tk_tcl2ruby(tk_send_without_enc('canvasx', screen_x, *args))
    number(tk_send_without_enc('canvasx', screen_x, *args))
  end
  def canvasy(screen_y, *args)
    #tk_tcl2ruby(tk_send_without_enc('canvasy', screen_y, *args))
    number(tk_send_without_enc('canvasy', screen_y, *args))
  end
  alias canvas_x canvasx
  alias canvas_y canvasy

  def coords(tag, *args)
    if args.empty?
      tk_split_list(tk_send_without_enc('coords', tagid(tag)))
    else
      tk_send_without_enc('coords', tagid(tag), *(args.flatten))
      self
    end
  end

  def dchars(tag, first, last=None)
    tk_send_without_enc('dchars', tagid(tag),
                        _get_eval_enc_str(first), _get_eval_enc_str(last))
    self
  end

  def delete(*args)
    tbl = nil
    TkcItem::CItemID_TBL.mutex.synchronize{
      tbl = TkcItem::CItemID_TBL[self.path]
    }
    if tbl
      args.each{|tag|
        find('withtag', tag).each{|item|
          if item.kind_of?(TkcItem)
            TkcItem::CItemID_TBL.mutex.synchronize{
              tbl.delete(item.id)
            }
          end
        }
      }
    end
    tk_send_without_enc('delete', *args.collect{|t| tagid(t)})
    self
  end
  alias remove delete

  def dtag(tag, tag_to_del=None)
    tk_send_without_enc('dtag', tagid(tag), tagid(tag_to_del))
    self
  end
  alias deltag dtag

  def find(mode, *args)
    list(tk_send_without_enc('find', mode, *args)).collect!{|id|
      TkcItem.id2obj(self, id)
    }
  end
  def find_above(target)
    find('above', tagid(target))
  end
  def find_all
    find('all')
  end
  def find_below(target)
    find('below', tagid(target))
  end
  def find_closest(x, y, halo=None, start=None)
    find('closest', x, y, halo, start)
  end
  def find_enclosed(x1, y1, x2, y2)
    find('enclosed', x1, y1, x2, y2)
  end
  def find_overlapping(x1, y1, x2, y2)
    find('overlapping', x1, y1, x2, y2)
  end
  def find_withtag(tag)
    find('withtag', tag)
  end

  def itemfocus(tagOrId=nil)
    if tagOrId
      tk_send_without_enc('focus', tagid(tagOrId))
      self
    else
      ret = tk_send_without_enc('focus')
      if ret == ""
        nil
      else
        TkcItem.id2obj(self, ret)
      end
    end
  end

  def gettags(tagOrId)
    list(tk_send_without_enc('gettags', tagid(tagOrId))).collect{|tag|
      TkcTag.id2obj(self, tag)
    }
  end

  def icursor(tagOrId, index)
    tk_send_without_enc('icursor', tagid(tagOrId), index)
    self
  end

  def imove(tagOrId, idx, x, y)
    tk_send_without_enc('imove', tagid(tagOrId), idx, x, y)
    self
  end
  alias i_move imove

  def index(tagOrId, idx)
    number(tk_send_without_enc('index', tagid(tagOrId), idx))
  end

  def insert(tagOrId, index, string)
    tk_send_without_enc('insert', tagid(tagOrId), index,
                        _get_eval_enc_str(string))
    self
  end

  def lower(tag, below=nil)
    if below
      tk_send_without_enc('lower', tagid(tag), tagid(below))
    else
      tk_send_without_enc('lower', tagid(tag))
    end
    self
  end

  def move(tag, dx, dy)
    tk_send_without_enc('move', tagid(tag), dx, dy)
    self
  end

  def moveto(tag, x, y)
    # Tcl/Tk 8.6 or later
    tk_send_without_enc('moveto', tagid(tag), x, y)
    self
  end
  alias move_to moveto

  def postscript(keys)
    tk_send("postscript", *hash_kv(keys))
  end

  def raise(tag, above=nil)
    if above
      tk_send_without_enc('raise', tagid(tag), tagid(above))
    else
      tk_send_without_enc('raise', tagid(tag))
    end
    self
  end

  def rchars(tag, first, last, str_or_coords)
    # Tcl/Tk 8.6 or later
    str_or_coords = str_or_coords.flatten if str_or_coords.kind_of? Array
    tk_send_without_enc('rchars', tagid(tag), first, last, str_or_coords)
    self
  end
  alias replace_chars rchars
  alias replace_coords rchars

  def scale(tag, x, y, xs, ys)
    tk_send_without_enc('scale', tagid(tag), x, y, xs, ys)
    self
  end

  def scan_mark(x, y)
    tk_send_without_enc('scan', 'mark', x, y)
    self
  end
  def scan_dragto(x, y, gain=None)
    tk_send_without_enc('scan', 'dragto', x, y, gain)
    self
  end

  def select(mode, *args)
    r = tk_send_without_enc('select', mode, *args)
    (mode == 'item')? TkcItem.id2obj(self, r): self
  end
  def select_adjust(tagOrId, index)
    select('adjust', tagid(tagOrId), index)
  end
  def select_clear
    select('clear')
  end
  def select_from(tagOrId, index)
    select('from', tagid(tagOrId), index)
  end
  def select_item
    select('item')
  end
  def select_to(tagOrId, index)
    select('to', tagid(tagOrId), index)
  end

  def itemtype(tag)
    TkcItem.type2class(tk_send('type', tagid(tag)))
  end

  def create_itemobj_from_id(idnum)
    id = TkcItem.id2obj(self, idnum.to_i)
    return id if id.kind_of?(TkcItem)

    typename = tk_send('type', id)
    unless type = TkcItem.type2class(typename)
      (itemclass = typename.dup)[0,1] = typename[0,1].upcase
      type = TkcItem.const_set(itemclass, Class.new(TkcItem))
      type.const_set("CItemTypeName", typename.freeze)
      TkcItem::CItemTypeToClass[typename] = type
    end

    canvas = self
    (obj = type.allocate).instance_eval{
      @parent = @c = canvas
      @path = canvas.path
      @id = id
      TkcItem::CItemID_TBL.mutex.synchronize{
        TkcItem::CItemID_TBL[@path] = {} unless TkcItem::CItemID_TBL[@path]
        TkcItem::CItemID_TBL[@path][@id] = self
      }
    }
  end
end

#TkCanvas = Tk::Canvas unless Object.const_defined? :TkCanvas
#Tk.__set_toplevel_aliases__(:Tk, Tk::Canvas, :TkCanvas)
Tk.__set_loaded_toplevel_aliases__('tk/canvas.rb', :Tk, Tk::Canvas, :TkCanvas)


class TkcItem<TkObject
  extend Tk
  include TkcTagAccess
  include Tk::Generated::CanvasItems

  CItemTypeName = nil
  CItemTypeToClass = {}

  CItemID_TBL = TkCore::INTERP.create_table

  TkCore::INTERP.init_ip_env{
    CItemID_TBL.mutex.synchronize{ CItemID_TBL.clear }
  }

  def TkcItem.type2class(type)
    CItemTypeToClass[type]
  end

  def TkcItem.id2obj(canvas, id)
    cpath = canvas.path
    CItemID_TBL.mutex.synchronize{
      if CItemID_TBL[cpath]
        CItemID_TBL[cpath][id]? CItemID_TBL[cpath][id]: id
      else
        id
      end
    }
  end

  ########################################
  def self._parse_create_args(args)
    if args[-1].kind_of? Hash
      keys = _symbolkey2str(args.pop)
      if args.size == 0
        args = keys.delete('coords')
        unless args.kind_of?(Array)
          fail "coords parameter must be given by an Array"
        end
      end

      # Resolve aliases (e.g., :tag -> :tags)
      declared_item_optkey_aliases.each do |alias_name, real_name|
        alias_name = alias_name.to_s
        keys[real_name.to_s] = keys.delete(alias_name) if keys.key?(alias_name)
      end

      args = args.flatten.concat(hash_kv(keys))
    else
      args = args.flatten
    end

    args
  end
  private_class_method :_parse_create_args

  def self.create(canvas, *args)
    unless self::CItemTypeName
      fail RuntimeError, "#{self} is an abstract class"
    end
    args = _parse_create_args(args)
    idnum = tk_call_without_enc(canvas.path, 'create',
                                self::CItemTypeName, *args)
    idnum.to_i  # 'canvas item id' is an integer number
  end
  ########################################

  def initialize(parent, *args)
    #unless parent.kind_of?(Tk::Canvas)
    #  fail ArgumentError, "expect Tk::Canvas for 1st argument"
    #end
    @parent = @c = parent
    @path = parent.path

    @id = create_self(*args) # an integer number as 'canvas item id'
    CItemID_TBL.mutex.synchronize{
      CItemID_TBL[@path] = {} unless CItemID_TBL[@path]
      CItemID_TBL[@path][@id] = self
    }
  end
  def create_self(*args)
    self.class.create(@c, *args) # return an integer number as 'canvas item id'
  end
  private :create_self

  def id
    @id
  end

  def exist?
    if @c.find_withtag(@id)
      true
    else
      false
    end
  end

  def delete
    @c.delete @id
    CItemID_TBL.mutex.synchronize{
      CItemID_TBL[@path].delete(@id) if CItemID_TBL[@path]
    }
    self
  end
  alias remove  delete
  alias destroy delete
end

class TkcArc<TkcItem
  CItemTypeName = 'arc'.freeze
  CItemTypeToClass[CItemTypeName] = self
end

class TkcBitmap<TkcItem
  CItemTypeName = 'bitmap'.freeze
  CItemTypeToClass[CItemTypeName] = self
end

class TkcImage<TkcItem
  CItemTypeName = 'image'.freeze
  CItemTypeToClass[CItemTypeName] = self
end

class TkcLine<TkcItem
  CItemTypeName = 'line'.freeze
  CItemTypeToClass[CItemTypeName] = self
end

class TkcOval<TkcItem
  CItemTypeName = 'oval'.freeze
  CItemTypeToClass[CItemTypeName] = self
end

class TkcPolygon<TkcItem
  CItemTypeName = 'polygon'.freeze
  CItemTypeToClass[CItemTypeName] = self
end

class TkcRectangle<TkcItem
  CItemTypeName = 'rectangle'.freeze
  CItemTypeToClass[CItemTypeName] = self
end

class TkcText<TkcItem
  CItemTypeName = 'text'.freeze
  CItemTypeToClass[CItemTypeName] = self
  def self.create(canvas, *args)
    if args[-1].kind_of?(Hash)
      keys = _symbolkey2str(args.pop)
      txt = keys['text']
      keys['text'] = _get_eval_enc_str(txt) if txt
      args.push(keys)
    end
    super(canvas, *args)
  end
end

class TkcWindow<TkcItem
  CItemTypeName = 'window'.freeze
  CItemTypeToClass[CItemTypeName] = self

  # Override window option to return widget objects, not path strings
  extend Tk::ItemOptionDSL
  item_option :window, type: :widget

  def self.create(canvas, *args)
    if args[-1].kind_of?(Hash)
      keys = _symbolkey2str(args.pop)
      win = keys['window']
      # keys['window'] = win.epath if win.kind_of?(TkWindow)
      keys['window'] = _epath(win) if win
      args.push(keys)
    end
    super(canvas, *args)
  end
end
