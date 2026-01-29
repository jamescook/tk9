# frozen_string_literal: false
#
#  treeview widget
#                               by Hidetoshi NAGAI (nagai@ai.kyutech.ac.jp)
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/ttk_treeview.html
#
require 'tk'
require 'tk/option_dsl'
require 'tk/item_option_dsl'
require 'tkextlib/tile.rb'

module Tk
  module Tile
    class Treeview < TkWindow
    end
  end
end

module Tk::Tile::TreeviewConfig
  include Tk::ItemOptionDSL::InstanceMethods

  ###################

  # Item command configuration set on Tk::Tile::Treeview class via DSL:
  #   item_cget_cmd { |id| [path, *id] }
  #   item_configure_cmd { |id| [path, *id] }

  alias __itemcget_tkstring itemcget_tkstring
  alias __itemcget itemcget
  alias __itemcget_strict itemcget_strict
  alias __itemconfigure itemconfigure
  alias __itemconfiginfo itemconfiginfo
  alias __current_itemconfiginfo current_itemconfiginfo

  private :__itemcget_tkstring, :__itemcget, :__itemcget_strict
  private :__itemconfigure, :__itemconfiginfo, :__current_itemconfiginfo

  # Treeview Item
  def itemcget_tkstring(tagOrId, option)
    __itemcget_tkstring([:item, tagOrId], option)
  end
  def itemcget(tagOrId, option)
    __itemcget([:item, tagOrId], option)
  end
  def itemcget_strict(tagOrId, option)
    __itemcget_strict([:item, tagOrId], option)
  end
  def itemconfigure(tagOrId, slot, value=None)
    __itemconfigure([:item, tagOrId], slot, value)
  end
  def itemconfiginfo(tagOrId, slot=nil)
    __itemconfiginfo([:item, tagOrId], slot)
  end
  def current_itemconfiginfo(tagOrId, slot=nil)
    __current_itemconfiginfo([:item, tagOrId], slot)
  end

  # Treeview Column
  def columncget_tkstring(tagOrId, option)
    __itemcget_tkstring([:column, tagOrId], option)
  end
  def columncget(tagOrId, option)
    __itemcget([:column, tagOrId], option)
  end
  def columncget_strict(tagOrId, option)
    __itemcget_strict([:column, tagOrId], option)
  end
  def columnconfigure(tagOrId, slot, value=None)
    __itemconfigure([:column, tagOrId], slot, value)
  end
  def columnconfiginfo(tagOrId, slot=nil)
    __itemconfiginfo([:column, tagOrId], slot)
  end
  def current_columnconfiginfo(tagOrId, slot=nil)
    __current_itemconfiginfo([:column, tagOrId], slot)
  end
  alias column_cget_tkstring columncget_tkstring
  alias column_cget columncget
  alias column_cget_strict columncget_strict
  alias column_configure columnconfigure
  alias column_configinfo columnconfiginfo
  alias current_column_configinfo current_columnconfiginfo

  # Treeview Heading (simplified - tile-0.7.x workaround removed, we require Tk 8.6+)
  def headingcget_tkstring(tagOrId, option)
    __itemcget_tkstring([:heading, tagOrId], option)
  end
  def headingcget_strict(tagOrId, option)
    __itemcget_strict([:heading, tagOrId], option)
  end
  def headingcget(tagOrId, option)
    __itemcget([:heading, tagOrId], option)
  end
  def headingconfigure(tagOrId, slot, value=None)
    __itemconfigure([:heading, tagOrId], slot, value)
  end
  def headingconfiginfo(tagOrId, slot=nil)
    __itemconfiginfo([:heading, tagOrId], slot)
  end
  def current_headingconfiginfo(tagOrId, slot=nil)
    __current_itemconfiginfo([:heading, tagOrId], slot)
  end
  alias heading_cget_tkstring headingcget_tkstring
  alias heading_cget headingcget
  alias heading_cget_strict headingcget_strict
  alias heading_configure headingconfigure
  alias heading_configinfo headingconfiginfo
  alias current_heading_configinfo current_headingconfiginfo

  # Treeview Tag
  def tagcget_tkstring(tagOrId, option)
    __itemcget_tkstring([:tag, :configure, tagOrId], option)
  end
  def tagcget(tagOrId, option)
    __itemcget([:tag, :configure, tagOrId], option)
  end
  def tagcget_strict(tagOrId, option)
    __itemcget_strict([:tag, :configure, tagOrId], option)
  end
  def tagconfigure(tagOrId, slot, value=None)
    __itemconfigure([:tag, :configure, tagOrId], slot, value)
  end
  def tagconfiginfo(tagOrId, slot=nil)
    __itemconfiginfo([:tag, :configure, tagOrId], slot)
  end
  def current_tagconfiginfo(tagOrId, slot=nil)
    __current_itemconfiginfo([:tag, :configure, tagOrId], slot)
  end
  alias tag_cget_tkstring tagcget_tkstring
  alias tag_cget tagcget
  alias tag_cget_strict tagcget_strict
  alias tag_configure tagconfigure
  alias tag_configinfo tagconfiginfo
  alias current_tag_configinfo current_tagconfiginfo
end

########################

class Tk::Tile::Treeview::Item < TkObject
  ItemID_TBL = TkCore::INTERP.create_table

  TkCore::INTERP.init_ip_env{
    Tk::Tile::Treeview::Item::ItemID_TBL.mutex.synchronize{
      Tk::Tile::Treeview::Item::ItemID_TBL.clear
    }
  }

  def self.id2obj(tree, id)
    tpath = tree.path
    Tk::Tile::Treeview::Item::ItemID_TBL.mutex.synchronize{
      if Tk::Tile::Treeview::Item::ItemID_TBL[tpath]
        (Tk::Tile::Treeview::Item::ItemID_TBL[tpath][id])? \
             Tk::Tile::Treeview::Item::ItemID_TBL[tpath][id]: id
      else
        id
      end
    }
  end

  def self.assign(tree, id)
    tpath = tree.path
    obj = nil
    Tk::Tile::Treeview::Item::ItemID_TBL.mutex.synchronize{
      if Tk::Tile::Treeview::Item::ItemID_TBL[tpath] &&
          Tk::Tile::Treeview::Item::ItemID_TBL[tpath][id]
        return Tk::Tile::Treeview::Item::ItemID_TBL[tpath][id]
      end

      obj = self.allocate
      obj.instance_eval{
        @parent = @t = tree
        @tpath = tpath
        @path = @id = id
      }
      Tk::Tile::Treeview::Item::ItemID_TBL[tpath] ||= {}
      Tk::Tile::Treeview::Item::ItemID_TBL[tpath][id] = obj
    }
    obj
  end

  def _insert_item(tree, parent_item, idx, keys={})
    keys = _symbolkey2str(keys)
    id = keys.delete('id')
    if id
      num_or_str(tk_call(tree, 'insert',
                         parent_item, idx, '-id', id, *hash_kv(keys)))
    else
      num_or_str(tk_call(tree, 'insert', parent_item, idx, *hash_kv(keys)))
    end
  end
  private :_insert_item

  def initialize(tree, parent_item = '', idx = 'end', keys = {})
    if parent_item.kind_of?(Hash)
      keys = parent_item
      idx = 'end'
      parent_item = ''
    elsif idx.kind_of?(Hash)
      keys = idx
      idx = 'end'
    end

    @parent = @t = tree
    @tpath = tree.path
    @path = @id = _insert_item(@t, parent_item, idx, keys)
    Tk::Tile::Treeview::Item::ItemID_TBL.mutex.synchronize{
      ItemID_TBL[@tpath] = {} unless ItemID_TBL[@tpath]
      ItemID_TBL[@tpath][@id] = self
    }
  end
  def id
    @id
  end

  def cget_tkstring(option)
    @t.itemcget_tkstring(@id, option)
  end
  def cget(option)
    @t.itemcget(@id, option)
  end
  def cget_strict(option)
    @t.itemcget_strict(@id, option)
  end

  def configure(key, value=None)
    @t.itemconfigure(@id, key, value)
    self
  end

  def configinfo(key=nil)
    @t.itemconfiginfo(@id, key)
  end

  def current_configinfo(key=nil)
    @t.current_itemconfiginfo(@id, key)
  end

  def open?
    cget('open')
  end
  def open
    configure('open', true)
    self
  end
  def close
    configure('open', false)
    self
  end

  def tag_has?(tag)
    @t.tag_has?(tag, @id)
  end
  alias has_tag? tag_has?

  def bbox(column=None)
    @t.bbox(@id, column)
  end

  def children
    @t.children(@id)
  end
  def set_children(*items)
    @t.set_children(@id, *items)
    self
  end

  def delete
    @t.delete(@id)
    self
  end

  def detach
    @t.detach(@id)
    self
  end

  def exist?
    @t.exist?(@id)
  end

  def focus
    @t.focus_item(@id)
  end

  def index
    @t.index(@id)
  end

  def insert(idx='end', keys={})
    @t.insert(@id, idx, keys)
  end

  def move(parent, idx)
    @t.move(@id, parent, idx)
    self
  end

  def next_item
    @t.next_item(@id)
  end

  def parent_item
    @t.parent_item(@id)
  end

  def prev_item
    @t.prev_item(@id)
  end

  def see
    @t.see(@id)
    self
  end

  def selection_add
    @t.selection_add(@id)
    self
  end

  def selection_remove
    @t.selection_remove(@id)
    self
  end

  def selection_set
    @t.selection_set(@id)
    self
  end

  def selection_toggle
    @t.selection_toggle(@id)
    self
  end

  def get_directory
    @t.get_directory(@id)
  end
  alias get_dictionary get_directory

  def get(col)
    @t.get(@id, col)
  end

  def set(col, value)
    @t.set(@id, col, value)
  end
end

########################

# Root represents the treeview's root node (id='').
# Cached via Treeview#root memoization - no need for complex self.new override.
# Note: Root is NOT registered in ItemID_TBL because all id2obj calls guard
# against empty id (returning nil instead). The root is accessed via tree.root.
class Tk::Tile::Treeview::Root < Tk::Tile::Treeview::Item
  def initialize(tree, keys = {})
    @parent = @t = tree
    @tpath = tree.path
    @path = @id = ''
    configure(keys) if keys && !keys.empty?
  end
end

########################

class Tk::Tile::Treeview::Tag < TkObject
  include TkTreatTagFont

  TagID_TBL = TkCore::INTERP.create_table

  (Tag_ID = ['tile_treeview_tag'.freeze, '00000']).instance_eval{
    @mutex = Mutex.new
    def mutex; @mutex; end
    freeze
  }

  TkCore::INTERP.init_ip_env{
    Tk::Tile::Treeview::Tag::TagID_TBL.mutex.synchronize{
      Tk::Tile::Treeview::Tag::TagID_TBL.clear
    }
  }

  def self.id2obj(tree, id)
    tpath = tree.path
    Tk::Tile::Treeview::Tag::TagID_TBL.mutex.synchronize{
      if Tk::Tile::Treeview::Tag::TagID_TBL[tpath]
        (Tk::Tile::Treeview::Tag::TagID_TBL[tpath][id])? \
               Tk::Tile::Treeview::Tag::TagID_TBL[tpath][id]: id
      else
        id
      end
    }
  end

  def initialize(tree, keys=nil)
    @parent = @t = tree
    @tpath = tree.path
    Tag_ID.mutex.synchronize{
      @path = @id = Tag_ID.join(TkCore::INTERP._ip_id_)
      Tag_ID[1].succ!
    }
    TagID_TBL.mutex.synchronize{
      TagID_TBL[@tpath] = {} unless TagID_TBL[@tpath]
      TagID_TBL[@tpath][@id] = self
    }
    if keys && keys != None
      tk_call_without_enc(@tpath, 'tag', 'configure', @id, *hash_kv(keys,true))
    end
  end
  def id
    @id
  end

  def tag_has?(item)
    @t.tag_has?(@id, item)
  end
  alias added? tag_has?

  def tag_has
    @t.tag_has(@id)
  end

  def add(*items)
    @t.tag_add(@id, *items)
  end

  def remove(*items)
    @t.tag_remove(@id, *items)
  end

  def bind(seq, *args, &block)
    if TkComm._callback_entry?(args[0]) || !block
      cmd = args.shift
    else
      cmd = block
    end
    @t.tag_bind(@id, seq, cmd, *args)
    self
  end

  def bind_append(seq, *args, &block)
    if TkComm._callback_entry?(args[0]) || !block
      cmd = args.shift
    else
      cmd = block
    end
    @t.tag_bind_append(@id, seq, cmd, *args)
    self
  end

  def bind_remove(seq)
    @t.tag_bind_remove(@id, seq)
    self
  end

  def bindinfo(seq=nil)
    @t.tag_bindinfo(@id, seq)
  end

  def cget_tkstring(option)
    @t.tagcget_tkstring(@id, option)
  end
  def cget(option)
    @t.tagcget(@id, option)
  end
  def cget_strict(option)
    @t.tagcget_strict(@id, option)
  end

  def configure(key, value=None)
    @t.tagconfigure(@id, key, value)
    self
  end

  def configinfo(key=nil)
    @t.tagconfiginfo(@id, key)
  end

  def current_configinfo(key=nil)
    @t.current_tagconfiginfo(@id, key)
  end
end

########################

class Tk::Tile::Treeview < TkWindow
  extend Tk::OptionDSL
  extend Tk::ItemOptionDSL
  include Tk::Tile::TileWidget
  include Scrollable
  include Tk::Generated::TtkTreeview

  include Tk::Tile::TreeviewConfig

  # Declare item command structure (treeview uses id as command suffix array)
  # e.g., id = [:item, 'I001'] produces [path, 'item', 'I001']
  item_cget_cmd { |id| [path, *id] }
  item_configure_cmd { |id| [path, *id] }

  if Tk::Tile::USE_TTK_NAMESPACE
    TkCommandNames = ['::ttk::treeview'.freeze].freeze
  else
    TkCommandNames = ['::treeview'.freeze].freeze
  end
  WidgetClassName = 'Treeview'.freeze
  WidgetClassNames[WidgetClassName] ||= self

  # Override generated options with correct types (generator defaults to :string)
  option :columns,        type: :list     # list of column identifiers
  option :displaycolumns, type: :list     # columns to display (or "#all")
  option :show,           type: :list     # elements to show: tree, headings

  # Tk 9.0+ options (TIP 552) - not auto-generated
  # TODO: min_version is stored but not enforced at runtime - configure will fail on Tk 8.6
  option :striped,        type: :boolean, min_version: 9  # zebra striping
  option :selecttype,     type: :string,  min_version: 9  # item, cell
  option :titlecolumns,   type: :integer, min_version: 9  # non-scrolling columns
  option :titleitems,     type: :integer, min_version: 9  # non-scrolling items

  # ================================================================
  # Item options (flattened for items, columns, headings, and tags)
  # ================================================================

  # Item options
  item_option :open,          type: :boolean   # item expanded state
  item_option :values,        type: :list      # item column values
  item_option :tags,          type: :list      # item tags

  # Column options
  item_option :width,         type: :integer   # column width
  item_option :minwidth,      type: :integer   # column minimum width
  item_option :stretch,       type: :boolean   # column resizable
  item_option :anchor,        type: :string    # content alignment

  # Heading options
  item_option :text,          type: :string    # heading text

  # Tag options (for styling)
  item_option :foreground,    type: :string    # text color
  item_option :background,    type: :string    # background color
  item_option :image,         type: :string    # icon image

  def __destroy_hook__
    Tk::Tile::Treeview::Item::ItemID_TBL.mutex.synchronize{
      Tk::Tile::Treeview::Item::ItemID_TBL.delete(@path)
    }
    Tk::Tile::Treeview::Tag::ItemID_TBL.mutex.synchronize{
      Tk::Tile::Treeview::Tag::ItemID_TBL.delete(@path)
    }
  end

  def self.style(*args)
    [self::WidgetClassName, *(args.map!{|a| _get_eval_string(a)})].join('.')
  end

  def tagid(id)
    if id.kind_of?(Tk::Tile::Treeview::Item) ||
        id.kind_of?(Tk::Tile::Treeview::Tag)
      id.id
    elsif id.kind_of?(Array)
      # size is 2 or 3
      id[0..-2] << _get_eval_string(id[-1])
    else
      _get_eval_string(id)
    end
  end

  def root
    @root ||= Tk::Tile::Treeview::Root.new(self)
  end

  def bbox(item, column=None)
    list(tk_send('item', 'bbox', item, column))
  end

  def children(item)
    simplelist(tk_send_without_enc('children', item)).collect{|id|
      Tk::Tile::Treeview::Item.id2obj(self, id)
    }
  end
  def set_children(item, *items)
    tk_send_without_enc('children', item,
                        array2tk_list(items.flatten, true))
    self
  end

  def delete(*items)
    tk_send_without_enc('delete', array2tk_list(items.flatten, true))
    self
  end

  def detach(*items)
    tk_send_without_enc('detach', array2tk_list(items.flatten, true))
    self
  end

  def exist?(item)
    bool(tk_send_without_enc('exists', _get_eval_enc_str(item)))
  end

  def focus_item(item = nil)
    if item
      tk_send('focus', item)
      item
    else
      id = tk_send('focus')
      (id.empty?)? nil: Tk::Tile::Treeview::Item.id2obj(self, id)
    end
  end

  def identify(x, y)
    # tile-0.7.2 or previous
    ret = simplelist(tk_send('identify', x, y))
    case ret[0]
    when 'heading', 'separator'
      ret[-1] = num_or_str(ret[-1])
    when 'cell'
      ret[1] = Tk::Tile::Treeview::Item.id2obj(self, ret[1])
      ret[-1] = num_or_str(ret[-1])
    when 'item', 'row'
      ret[1] = Tk::Tile::Treeview::Item.id2obj(self, ret[1])
    end
  end

  def identify_region(x, y)
    tk_send('identify', 'region', x, y)
  end

  def identify_item(x, y)
    id = tk_send('identify', 'item', x, y)
    (id.empty?)? nil: Tk::Tile::Treeview::Item.id2obj(self, id)
  end

  def identify_element(x, y)
    tk_send('identify', 'element', x, y)
  end

  def row_identify(x, y)
    id = tk_send('identify', 'row', x, y)
    (id.empty?)? nil: Tk::Tile::Treeview::Item.id2obj(self, id)
  end
  alias identify_row row_identify

  def column_identify(x, y)
    tk_send('identify', 'column', x, y)
  end
  alias identify_column column_identify

  def index(item)
    number(tk_send('index', item))
  end

  # def insert(parent, idx='end', keys={})
  #   keys = _symbolkey2str(keys)
  #   id = keys.delete('id')
  #   if id
  #     num_or_str(tk_send('insert', parent, idx, '-id', id, *hash_kv(keys)))
  #   else
  #     num_or_str(tk_send('insert', parent, idx, *hash_kv(keys)))
  #   end
  # end
  def insert(parent, idx='end', keys={})
    Tk::Tile::Treeview::Item.new(self, parent, idx, keys)
  end

  def move(item, parent, idx)
    tk_send('move', item, parent, idx)
    self
  end

  def next_item(item)
    id = tk_send('next', item)
    (id.empty?)? nil: Tk::Tile::Treeview::Item.id2obj(self, id)
  end

  def parent_item(item)
    if (id = tk_send('parent', item)).empty?
      Tk::Tile::Treeview::Root.new(self)
    else
      Tk::Tile::Treeview::Item.id2obj(self, id)
    end
  end

  def prev_item(item)
    id = tk_send('prev', item)
    (id.empty?)? nil: Tk::Tile::Treeview::Item.id2obj(self, id)
  end

  def see(item)
    tk_send('see', item)
    self
  end

  def selection
    simplelist(tk_send('selection')).collect{|id|
      Tk::Tile::Treeview::Item.id2obj(self, id)
    }
  end
  alias selection_get selection

  def selection_add(*items)
    tk_send('selection', 'add', array2tk_list(items.flatten, true))
    self
  end
  def selection_remove(*items)
    tk_send('selection', 'remove', array2tk_list(items.flatten, true))
    self
  end
  def selection_set(*items)
    tk_send('selection', 'set', array2tk_list(items.flatten, true))
    self
  end
  def selection_toggle(*items)
    tk_send('selection', 'toggle', array2tk_list(items.flatten, true))
    self
  end

  def get_directory(item)
    # tile-0.7+
    ret = []
    lst = simplelist(tk_send('set', item))
    until lst.empty?
      col = lst.shift
      val = lst.shift
      ret << [col, val]
    end
    ret
  end
  alias get_dictionary get_directory

  def get(item, col)
    tk_send('set', item, col)
  end
  def set(item, col, value)
    tk_send('set', item, col, value)
    self
  end

  def tag_has?(tag, item)
    bool(tk_send('tag', 'has', tagid(tag), tagid(item)))
  end
  def tag_has(tag)
    tk_split_simplelist(tk_send('tag', 'has', tagid(tag))).collect{|id|
      Tk::Tile::Treeview::Item.id2obj(self, id)
    }
  end

  def tag_bind(tag, seq, *args, &block)
    if TkComm._callback_entry?(args[0]) || !block
      cmd = args.shift
    else
      cmd = block
    end
    _bind([@path, 'tag', 'bind', tag], seq, cmd, *args)
    self
  end
  alias tagbind tag_bind

  def tag_bind_append(tag, seq, *args, &block)
    if TkComm._callback_entry?(args[0]) || !block
      cmd = args.shift
    else
      cmd = block
    end
    _bind_append([@path, 'tag', 'bind', tag], seq, cmd, *args)
    self
  end
  alias tagbind_append tag_bind_append

  def tag_bind_remove(tag, seq)
    _bind_remove([@path, 'tag', 'bind', tag], seq)
    self
  end
  alias tagbind_remove tag_bind_remove

  def tag_bindinfo(tag, context=nil)
    _bindinfo([@path, 'tag', 'bind', tag], context)
  end
  alias tagbindinfo tag_bindinfo

  def tag_names
    tk_split_simplelist(tk_send('tag', 'names')).collect{|id|
      Tk::Tile::Treeview::Tag.id2obj(self, id)
    }
  end

  def tag_add(tag, *items)
    fail ArgumentError, "no target items" if items.empty?
    tk_send('tag', 'add', tagid(tag), array2tk_list(items.flatten, true))
    self
  end

  def tag_remove(tag, *items)
    tk_send('tag', 'remove', tagid(tag), array2tk_list(items.flatten, true))
    self
  end

end

#Tk.__set_toplevel_aliases__(:Ttk, Tk::Tile::Treeview, :TkTreeview)
Tk.__set_loaded_toplevel_aliases__('tkextlib/tile/treeview.rb',
                                   :Ttk, Tk::Tile::Treeview, :TkTreeview)
