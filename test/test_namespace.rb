# frozen_string_literal: true

# Test for TkNamespace and TkNamespace::Ensemble.
# Runs in a single subprocess to minimize overhead.
#
# Note: Ensemble is NOT a widget - it wraps Tcl's "namespace ensemble" command.
# See: https://www.tcl-lang.org/man/tcl8.6/TclCmd/namespace.htm#M28

require_relative 'test_helper'
require_relative 'tk_test_helper'

class TestNamespace < Minitest::Test
  include TkTestHelper

  def test_namespace_ensemble
    assert_tk_app("Namespace Ensemble test", method(:namespace_app))
  end

  def namespace_app
    require 'tk'
    require 'tk/namespace'

    errors = []

    # --- Create ensemble with explicit command name ---
    # (without -command, it tries to create for :: which fails)
    ensemble = TkNamespace::Ensemble.new(command: "testensemble")

    errors << "ensemble should have path" unless ensemble.path
    errors << "path should be ::testensemble" unless ensemble.path == "::testensemble"

    # --- Test prefixes option (boolean) ---
    ensemble.configure(prefixes: true)
    errors << "prefixes true failed" unless ensemble.cget(:prefixes) == true

    ensemble.configure(prefixes: false)
    errors << "prefixes false failed" unless ensemble.cget(:prefixes) == false

    # --- Test subcommands option (list) ---
    ensemble.configure(subcommands: ["cmd1", "cmd2"])
    subcmds = ensemble.cget(:subcommands)
    errors << "subcommands should be array" unless subcmds.is_a?(Array)
    errors << "subcommands count wrong" unless subcmds.size == 2

    # --- Ensemble.exist? ---
    errors << "exist? should return true" unless TkNamespace::Ensemble.exist?(ensemble.path)
    errors << "exists? should return true" unless ensemble.exists?

    raise "Namespace test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end

  # --- TkNamespace creation and basic queries ---

  def test_namespace_create
    assert_tk_app("Namespace creation", method(:namespace_create_app))
  end

  def namespace_create_app
    require 'tk'
    require 'tk/namespace'

    errors = []

    # Create a named namespace
    ns = TkNamespace.new("mytest")
    errors << "namespace should have fullname" unless ns.path
    errors << "fullname should end with mytest, got #{ns.path}" unless ns.path.end_with?("mytest")

    # Check it exists
    errors << "namespace should exist" unless TkNamespace.exist?(ns.path)

    # Current path
    errors << "current_path should return fullname" unless ns.current_path == ns.path

    # Parent
    parent_path = ns.parent
    errors << "parent should be a string" unless parent_path.is_a?(String)

    raise errors.join("\n") unless errors.empty?
  end

  def test_namespace_with_parent
    assert_tk_app("Namespace with parent", method(:namespace_with_parent_app))
  end

  def namespace_with_parent_app
    require 'tk'
    require 'tk/namespace'

    errors = []

    # Create parent namespace
    parent = TkNamespace.new("parent_ns")
    # Create child with parent
    child = TkNamespace.new("child_ns", parent.path)

    errors << "child fullname should include parent" unless child.path.include?("parent_ns")
    errors << "child fullname should include child_ns" unless child.path.include?("child_ns")

    raise errors.join("\n") unless errors.empty?
  end

  def test_namespace_children
    assert_tk_app("Namespace children", method(:namespace_children_app))
  end

  def namespace_children_app
    require 'tk'
    require 'tk/namespace'

    errors = []

    # Create parent with children
    parent = TkNamespace.new("parent_with_kids")
    TkNamespace.new("kid1", parent.path)
    TkNamespace.new("kid2", parent.path)

    children = parent.children
    errors << "children should be Array, got #{children.class}" unless children.is_a?(Array)
    errors << "should have 2 children, got #{children.size}" unless children.size == 2

    # Class method variant
    all_children = TkNamespace.children(parent.path)
    errors << "class method should also return 2 children" unless all_children.size == 2

    raise errors.join("\n") unless errors.empty?
  end

  def test_namespace_current
    assert_tk_app("Namespace current", method(:namespace_current_app))
  end

  def namespace_current_app
    require 'tk'
    require 'tk/namespace'

    errors = []

    cur_path = TkNamespace.current_path
    errors << "current_path should be String" unless cur_path.is_a?(String)
    errors << "current_path should start with ::" unless cur_path.start_with?("::")

    cur = TkNamespace.current
    errors << "current should return something" if cur.nil?

    raise errors.join("\n") unless errors.empty?
  end

  def test_namespace_qualifiers_and_tail
    assert_tk_app("Namespace qualifiers and tail", method(:namespace_qualifiers_tail_app))
  end

  def namespace_qualifiers_tail_app
    require 'tk'
    require 'tk/namespace'

    errors = []

    # qualifiers extracts the parent path
    qual = TkNamespace.qualifiers("::foo::bar::baz")
    errors << "qualifiers of ::foo::bar::baz should be ::foo::bar, got '#{qual}'" unless qual == "::foo::bar"

    # tail extracts the last component
    tail = TkNamespace.tail("::foo::bar::baz")
    errors << "tail of ::foo::bar::baz should be baz, got '#{tail}'" unless tail == "baz"

    raise errors.join("\n") unless errors.empty?
  end

  def test_namespace_which
    assert_tk_app("Namespace which", method(:namespace_which_app))
  end

  def namespace_which_app
    require 'tk'
    require 'tk/namespace'

    errors = []

    # which finds fully qualified name
    result = TkNamespace.which("set")
    errors << "which 'set' should return ::set, got '#{result}'" unless result == "::set"

    # which_command
    cmd_result = TkNamespace.which_command("puts")
    errors << "which_command 'puts' should return ::puts, got '#{cmd_result}'" unless cmd_result == "::puts"

    raise errors.join("\n") unless errors.empty?
  end

  def test_namespace_delete
    assert_tk_app("Namespace delete", method(:namespace_delete_app))
  end

  def namespace_delete_app
    require 'tk'
    require 'tk/namespace'

    errors = []

    ns = TkNamespace.new("to_delete")
    errors << "namespace should exist before delete" unless TkNamespace.exist?(ns.path)

    TkNamespace.delete(ns)
    errors << "namespace should not exist after delete" if TkNamespace.exist?(ns.path)

    raise errors.join("\n") unless errors.empty?
  end

  def test_namespace_eval
    assert_tk_app("Namespace eval", method(:namespace_eval_app))
  end

  def namespace_eval_app
    require 'tk'
    require 'tk/namespace'

    errors = []

    ns = TkNamespace.new("eval_test")

    # eval executes Ruby code in the namespace context via instance_eval
    # The block/string is Ruby code, not Tcl
    result = ns.eval { 40 + 2 }
    errors << "eval result should be 42, got '#{result}'" unless result == 42

    raise errors.join("\n") unless errors.empty?
  end

  def test_namespace_code
    assert_tk_app("Namespace code", method(:namespace_code_app))
  end

  def namespace_code_app
    require 'tk'
    require 'tk/namespace'

    errors = []

    ns = TkNamespace.new("code_test")

    # code with a block returns an NsCode object
    code_obj = ns.code { |args| "hello" }
    errors << "code should return NsCode" unless code_obj.is_a?(TkNamespace::NsCode)
    errors << "NsCode should have path" unless code_obj.path

    raise errors.join("\n") unless errors.empty?
  end

  def test_namespace_id2obj
    assert_tk_app("Namespace id2obj", method(:namespace_id2obj_app))
  end

  def namespace_id2obj_app
    require 'tk'
    require 'tk/namespace'

    errors = []

    ns = TkNamespace.new("id2obj_test")

    # id2obj should return the namespace object
    found = TkNamespace.id2obj(ns.path)
    errors << "id2obj should return the namespace" unless found == ns

    # Unknown id returns the id itself
    unknown = TkNamespace.id2obj("::nonexistent")
    errors << "id2obj for unknown should return id string" unless unknown == "::nonexistent"

    raise errors.join("\n") unless errors.empty?
  end

  def test_namespace_parent_class_method
    assert_tk_app("Namespace parent class method", method(:namespace_parent_class_app))
  end

  def namespace_parent_class_app
    require 'tk'
    require 'tk/namespace'

    errors = []

    ns = TkNamespace.new("child_for_parent_test", "::")
    parent = TkNamespace.parent(ns.path)

    # parent may be TkNamespace object or string depending on whether it's registered
    if parent.is_a?(TkNamespace)
      errors << "parent path should be ::, got '#{parent.path}'" unless parent.path == "::"
    else
      errors << "parent should be :: or empty, got '#{parent}'" unless parent == "::" || parent == ""
    end

    raise errors.join("\n") unless errors.empty?
  end

  def test_namespace_export_import
    assert_tk_app("Namespace export/import", method(:namespace_export_import_app))
  end

  def namespace_export_import_app
    require 'tk'
    require 'tk/namespace'

    errors = []

    # Test class methods with valid patterns
    # export/import work with glob patterns for command names
    TkNamespace.export("testcmd*")
    TkNamespace.export_with_clear("testcmd*")

    # forget with nonexistent namespace should raise TclError
    begin
      TkNamespace.forget("::nonexistent::*")
      errors << "forget with nonexistent namespace should raise TclError"
    rescue TclTkLib::TclError => e
      errors << "wrong error message" unless e.message.include?("unknown namespace")
    end

    raise errors.join("\n") unless errors.empty?
  end

  def test_namespace_path
    assert_tk_app("Namespace path", method(:namespace_path_app))
  end

  def namespace_path_app
    require 'tk'
    require 'tk/namespace'

    errors = []

    # get_path returns current namespace path
    path = TkNamespace.get_path
    errors << "get_path should return String, got #{path.class}" unless path.is_a?(String)

    raise errors.join("\n") unless errors.empty?
  end

  def test_namespace_global
    assert_tk_app("Namespace Global constant", method(:namespace_global_app))
  end

  def namespace_global_app
    require 'tk'
    require 'tk/namespace'

    errors = []

    # TkNamespace::Global should be the root namespace
    global = TkNamespace::Global
    errors << "Global should be TkNamespace" unless global.is_a?(TkNamespace)
    errors << "Global path should be ::, got '#{global.path}'" unless global.path == "::"

    raise errors.join("\n") unless errors.empty?
  end

  def test_nscode
    assert_tk_app("NsCode class", method(:nscode_app))
  end

  def nscode_app
    require 'tk'
    require 'tk/namespace'

    errors = []

    ns = TkNamespace.new("nscode_test")
    code_obj = ns.code("return 123")

    errors << "NsCode path should not be empty" if code_obj.path.empty?
    errors << "NsCode to_eval should equal path" unless code_obj.to_eval == code_obj.path

    raise errors.join("\n") unless errors.empty?
  end

  def test_scope_args
    assert_tk_app("ScopeArgs class", method(:scope_args_app))
  end

  def scope_args_app
    require 'tk'
    require 'tk/namespace'

    errors = []

    scope = TkNamespace::ScopeArgs.new("::test", "arg1", "arg2")
    errors << "ScopeArgs should be Array" unless scope.is_a?(Array)
    errors << "ScopeArgs should have 2 args" unless scope.size == 2
    errors << "ScopeArgs first arg should be arg1" unless scope[0] == "arg1"

    raise errors.join("\n") unless errors.empty?
  end
end
