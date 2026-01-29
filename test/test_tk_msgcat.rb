# encoding: utf-8
# frozen_string_literal: true

# Test for TkMsgCatalog (Tcl message catalog wrapper)
# Wraps Tcl's msgcat package for internationalization (i18n)
#
# Sample files for e2e testing:
#   sample/tkmsgcat-load_rb.rb  - loads Ruby .msg files (sample/msgs_rb/)
#   sample/tkmsgcat-load_tk.rb  - loads Tcl .msg files (sample/msgs_tk/)
#   sample/tkmsgcat-load_rb2.rb - loads Ruby .msg files with encoding (sample/msgs_rb2/)

require_relative 'test_helper'
require_relative 'tk_test_helper'

class TestTkMsgCatalog < Minitest::Test
  include TkTestHelper

  # ---------------------------------------------------------
  # Basic creation and locale
  # ---------------------------------------------------------

  def test_msgcat_creation
    assert_tk_app("TkMsgCatalog creation", method(:msgcat_creation_app))
  end

  def msgcat_creation_app
    require 'tk'
    require 'tk/msgcat'

    errors = []

    # Create with explicit namespace
    msgcat = TkMsgCatalog.new('::testns')
    errors << "msgcat should not be nil" if msgcat.nil?

    # Create with default namespace (global)
    msgcat_global = TkMsgCatalog.new
    errors << "global msgcat should not be nil" if msgcat_global.nil?

    raise errors.join("\n") unless errors.empty?
  end

  def test_locale_get_set
    assert_tk_app("TkMsgCatalog locale get/set", method(:locale_get_set_app))
  end

  def locale_get_set_app
    require 'tk'
    require 'tk/msgcat'

    errors = []

    msgcat = TkMsgCatalog.new('::testns')

    # Get default locale (system-dependent, but should not be nil/empty)
    default_locale = msgcat.locale
    errors << "locale should not be empty, got #{default_locale.inspect}" if default_locale.nil? || default_locale.empty?

    # Set locale - Tcl normalizes to lowercase
    msgcat.locale = 'en_US'
    errors << "locale should be 'en_us', got '#{msgcat.locale}'" unless msgcat.locale == 'en_us'

    # Set another locale
    msgcat.locale = 'ja_JP'
    errors << "locale should be 'ja_jp', got '#{msgcat.locale}'" unless msgcat.locale == 'ja_jp'

    raise errors.join("\n") unless errors.empty?
  end

  def test_preferences
    assert_tk_app("TkMsgCatalog preferences", method(:preferences_app))
  end

  def preferences_app
    require 'tk'
    require 'tk/msgcat'

    errors = []

    msgcat = TkMsgCatalog.new('::testns')
    msgcat.locale = 'en_US'

    prefs = msgcat.preferences
    # For en_US, preferences should include fallbacks like 'en_us', 'en', ''
    errors << "preferences should include 'en_us', got #{prefs.inspect}" unless prefs&.include?('en_us')
    errors << "preferences should include 'en'" unless prefs.include?('en')

    raise errors.join("\n") unless errors.empty?
  end

  # ---------------------------------------------------------
  # Setting and getting translations
  # ---------------------------------------------------------

  def test_set_translation
    assert_tk_app("TkMsgCatalog set_translation", method(:set_translation_app))
  end

  def set_translation_app
    require 'tk'
    require 'tk/msgcat'

    errors = []

    # Use unique namespace to avoid collision with other tests
    msgcat = TkMsgCatalog.new('::test_set_translation')
    msgcat.locale = 'de'

    # Set a translation
    msgcat.set_translation('de', 'Hello', 'Hallo')

    # Translate
    result = msgcat.mc('Hello')
    errors << "expected 'Hallo', got '#{result}'" unless result == 'Hallo'

    # Untranslated string should return itself (use unique key)
    result2 = msgcat.mc('UniqueUntranslatedKey12345')
    errors << "untranslated should return source, got '#{result2}'" unless result2 == 'UniqueUntranslatedKey12345'

    raise errors.join("\n") unless errors.empty?
  end

  def test_translate_with_format
    assert_tk_app("TkMsgCatalog translate with format", method(:translate_format_app))
  end

  def translate_format_app
    require 'tk'
    require 'tk/msgcat'

    errors = []

    msgcat = TkMsgCatalog.new('::testns')
    msgcat.locale = 'en'

    # Set a translation with format placeholder
    msgcat.set_translation('en', 'Hello, %s!', 'Hello, %s!')

    # Translate with format args
    result = msgcat.mc('Hello, %s!', 'World')
    errors << "expected 'Hello, World!', got '#{result}'" unless result == 'Hello, World!'

    raise errors.join("\n") unless errors.empty?
  end

  def test_bracket_syntax
    assert_tk_app("TkMsgCatalog [] syntax", method(:bracket_syntax_app))
  end

  def bracket_syntax_app
    require 'tk'
    require 'tk/msgcat'

    errors = []

    msgcat = TkMsgCatalog.new('::testns')
    msgcat.locale = 'fr'

    msgcat.set_translation('fr', 'Yes', 'Oui')

    # Use [] syntax (alias for translate/mc)
    result = msgcat['Yes']
    errors << "expected 'Oui', got '#{result}'" unless result == 'Oui'

    raise errors.join("\n") unless errors.empty?
  end

  def test_set_translation_list
    assert_tk_app("TkMsgCatalog set_translation_list", method(:set_translation_list_app))
  end

  def set_translation_list_app
    require 'tk'
    require 'tk/msgcat'

    errors = []

    msgcat = TkMsgCatalog.new('::testns')
    msgcat.locale = 'es'

    # Set multiple translations at once
    translations = [
      ['Yes', 'Si'],
      ['No', 'No'],
      ['Cancel', 'Cancelar']
    ]
    msgcat.set_translation_list('es', translations)

    errors << "Yes != Si" unless msgcat.mc('Yes') == 'Si'
    errors << "No != No" unless msgcat.mc('No') == 'No'
    errors << "Cancel != Cancelar" unless msgcat.mc('Cancel') == 'Cancelar'

    raise errors.join("\n") unless errors.empty?
  end

  # ---------------------------------------------------------
  # method_missing DSL (used in .msg files)
  # ---------------------------------------------------------

  def test_method_missing_set_locale
    assert_tk_app("TkMsgCatalog method_missing set locale", method(:method_missing_locale_app))
  end

  def method_missing_locale_app
    require 'tk'
    require 'tk/msgcat'

    errors = []

    msgcat = TkMsgCatalog.new('::testns')

    # method_missing with 0 args sets locale
    # ja() should set locale to 'ja'
    msgcat.ja
    errors << "expected locale 'ja', got '#{msgcat.locale}'" unless msgcat.locale == 'ja'

    # Tcl normalizes locale to lowercase
    msgcat.en_US
    errors << "expected locale 'en_us', got '#{msgcat.locale}'" unless msgcat.locale == 'en_us'

    raise errors.join("\n") unless errors.empty?
  end

  def test_method_missing_set_translation
    assert_tk_app("TkMsgCatalog method_missing set translation", method(:method_missing_translation_app))
  end

  def method_missing_translation_app
    require 'tk'
    require 'tk/msgcat'

    errors = []

    msgcat = TkMsgCatalog.new('::testns')
    msgcat.locale = 'de'

    # method_missing with 2 args: locale(src, trans)
    msgcat.de('Hello', 'Hallo')
    msgcat.de('Goodbye', 'Auf Wiedersehen')

    errors << "Hello != Hallo" unless msgcat.mc('Hello') == 'Hallo'
    errors << "Goodbye != Auf Wiedersehen" unless msgcat.mc('Goodbye') == 'Auf Wiedersehen'

    raise errors.join("\n") unless errors.empty?
  end

  def test_method_missing_source_only
    assert_tk_app("TkMsgCatalog method_missing source only", method(:method_missing_source_app))
  end

  def method_missing_source_app
    require 'tk'
    require 'tk/msgcat'

    errors = []

    msgcat = TkMsgCatalog.new('::testns')
    msgcat.locale = 'en'

    # method_missing with 1 arg: registers source string (trans = source)
    # This is used in English .msg files where source == translation
    msgcat.en('Hello')

    result = msgcat.mc('Hello')
    # When only source is given, Tcl msgcat uses source as the translation
    errors << "expected 'Hello', got '#{result}'" unless result == 'Hello'

    raise errors.join("\n") unless errors.empty?
  end

  def test_method_missing_array_translations
    assert_tk_app("TkMsgCatalog method_missing array translations", method(:method_missing_array_app))
  end

  def method_missing_array_app
    require 'tk'
    require 'tk/msgcat'

    errors = []

    msgcat = TkMsgCatalog.new('::testns')
    msgcat.locale = 'it'

    # method_missing with array arg: set_translation_list
    msgcat.it([['Yes', 'Si'], ['No', 'No']])

    errors << "Yes != Si" unless msgcat.mc('Yes') == 'Si'
    errors << "No != No" unless msgcat.mc('No') == 'No'

    raise errors.join("\n") unless errors.empty?
  end

  def test_block_dsl
    assert_tk_app("TkMsgCatalog block DSL", method(:block_dsl_app))
  end

  def block_dsl_app
    require 'tk'
    require 'tk/msgcat'

    errors = []

    # This is how .msg files work - block is instance_exec'd
    msgcat = TkMsgCatalog.new('::test_block_dsl') {
      ja 'Hello', 'こんにちは'
      ja 'Goodbye', 'さようなら'
    }

    msgcat.locale = 'ja'

    errors << "Hello != こんにちは" unless msgcat.mc('Hello') == 'こんにちは'
    errors << "Goodbye != さようなら" unless msgcat.mc('Goodbye') == 'さようなら'

    raise errors.join("\n") unless errors.empty?
  end

  # ---------------------------------------------------------
  # Unknown proc (fallback for missing translations)
  # ---------------------------------------------------------

  def test_def_unknown_proc
    assert_tk_app("TkMsgCatalog def_unknown_proc", method(:def_unknown_proc_app))
  end

  def def_unknown_proc_app
    require 'tk'
    require 'tk/msgcat'

    errors = []

    msgcat = TkMsgCatalog.new('::test_unknown_proc')
    msgcat.locale = 'zz'  # Non-existent locale

    # Track unknown lookups
    unknown_calls = []
    msgcat.def_unknown_proc { |locale, src|
      unknown_calls << [locale, src]
      "[MISSING: #{src}]"
    }

    # Request a translation that doesn't exist
    result = msgcat.mc('NonExistentKey')

    # Verify the unknown proc was called and its return value was used
    errors << "unknown_calls should not be empty" if unknown_calls.empty?
    errors << "expected locale 'zz', got '#{unknown_calls[0][0]}'" unless unknown_calls.empty? || unknown_calls[0][0] == 'zz'
    errors << "expected src 'NonExistentKey', got '#{unknown_calls[0][1]}'" unless unknown_calls.empty? || unknown_calls[0][1] == 'NonExistentKey'
    errors << "expected '[MISSING: NonExistentKey]', got '#{result}'" unless result == '[MISSING: NonExistentKey]'

    raise errors.join("\n") unless errors.empty?
  end

  # ---------------------------------------------------------
  # maxlen
  # ---------------------------------------------------------

  def test_maxlen
    assert_tk_app("TkMsgCatalog maxlen", method(:maxlen_app))
  end

  def maxlen_app
    require 'tk'
    require 'tk/msgcat'

    errors = []

    msgcat = TkMsgCatalog.new('::testns')
    msgcat.locale = 'en'

    msgcat.set_translation('en', 'Short', 'Short')
    msgcat.set_translation('en', 'Medium text', 'Medium text')
    msgcat.set_translation('en', 'This is longer text', 'This is longer text')

    # maxlen returns max length of translated strings (longest is 19 chars)
    max = msgcat.maxlen('Short', 'Medium text', 'This is longer text')
    errors << "maxlen should be >= 19 (length of longest), got #{max}" unless max >= 19

    raise errors.join("\n") unless errors.empty?
  end

  # ---------------------------------------------------------
  # Class methods (global namespace)
  # ---------------------------------------------------------

  def test_class_method_locale
    assert_tk_app("TkMsgCatalog class locale", method(:class_locale_app))
  end

  def class_locale_app
    require 'tk'
    require 'tk/msgcat'

    errors = []

    # Class method affects global namespace
    original = TkMsgCatalog.locale

    TkMsgCatalog.locale = 'fr'
    errors << "class locale should be 'fr', got #{TkMsgCatalog.locale.inspect}" unless TkMsgCatalog.locale == 'fr'

    # Restore
    TkMsgCatalog.locale = original

    raise errors.join("\n") unless errors.empty?
  end

  def test_class_method_translate
    assert_tk_app("TkMsgCatalog class translate", method(:class_translate_app))
  end

  def class_translate_app
    require 'tk'
    require 'tk/msgcat'

    errors = []

    TkMsgCatalog.locale = 'en'
    TkMsgCatalog.set_translation('en', 'GlobalTest', 'Global Test Value')

    # Class methods work on global namespace
    result = TkMsgCatalog.mc('GlobalTest')
    errors << "expected 'Global Test Value', got '#{result}'" unless result == 'Global Test Value'

    result2 = TkMsgCatalog['GlobalTest']
    errors << "[] syntax should work" unless result2 == 'Global Test Value'

    raise errors.join("\n") unless errors.empty?
  end

  def test_class_method_preferences
    assert_tk_app("TkMsgCatalog class preferences", method(:class_preferences_app))
  end

  def class_preferences_app
    require 'tk'
    require 'tk/msgcat'

    errors = []

    TkMsgCatalog.locale = 'ja_JP'
    prefs = TkMsgCatalog.preferences

    errors << "preferences should include 'ja_jp', got #{prefs.inspect}" unless prefs&.include?('ja_jp')
    errors << "preferences should include 'ja', got #{prefs.inspect}" unless prefs&.include?('ja')

    raise errors.join("\n") unless errors.empty?
  end

  # ---------------------------------------------------------
  # Alias TkMsgCat
  # ---------------------------------------------------------

  def test_alias_tkmsgcat
    assert_tk_app("TkMsgCat alias", method(:alias_tkmsgcat_app))
  end

  def alias_tkmsgcat_app
    require 'tk'
    require 'tk/msgcat'

    errors = []

    # TkMsgCat should be an alias for TkMsgCatalog
    errors << "TkMsgCat should equal TkMsgCatalog" unless TkMsgCat == TkMsgCatalog

    # Should work the same
    msgcat = TkMsgCat.new('::testns')
    errors << "TkMsgCat.new should work" if msgcat.nil?

    raise errors.join("\n") unless errors.empty?
  end

  # ---------------------------------------------------------
  # Namespace isolation
  # ---------------------------------------------------------

  def test_namespace_isolation
    assert_tk_app("TkMsgCatalog namespace isolation", method(:namespace_isolation_app))
  end

  def namespace_isolation_app
    require 'tk'
    require 'tk/msgcat'

    errors = []

    # Create two msgcats in different namespaces with unique names
    cat1 = TkMsgCatalog.new('::isolation_ns1')
    cat2 = TkMsgCatalog.new('::isolation_ns2')

    cat1.locale = 'en'
    cat2.locale = 'en'

    # Set different translations for same key in different namespaces
    cat1.set_translation('en', 'IsolationTest', 'ValueFromNs1')
    cat2.set_translation('en', 'IsolationTest', 'ValueFromNs2')

    result1 = cat1.mc('IsolationTest')
    result2 = cat2.mc('IsolationTest')

    errors << "cat1 should have 'ValueFromNs1', got '#{result1}'" unless result1 == 'ValueFromNs1'
    errors << "cat2 should have 'ValueFromNs2', got '#{result2}'" unless result2 == 'ValueFromNs2'

    raise errors.join("\n") unless errors.empty?
  end

  # ---------------------------------------------------------
  # msgcat_ext attribute
  # ---------------------------------------------------------

  def test_msgcat_ext
    assert_tk_app("TkMsgCatalog msgcat_ext", method(:msgcat_ext_app))
  end

  def msgcat_ext_app
    require 'tk'
    require 'tk/msgcat'

    errors = []

    msgcat = TkMsgCatalog.new('::testns')

    # Default extension
    errors << "default ext should be '.msg'" unless msgcat.msgcat_ext == '.msg'

    # Can be changed
    msgcat.msgcat_ext = '.translations'
    errors << "ext should be changeable" unless msgcat.msgcat_ext == '.translations'

    raise errors.join("\n") unless errors.empty?
  end
end
