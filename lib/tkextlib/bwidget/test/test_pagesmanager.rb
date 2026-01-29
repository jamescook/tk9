# frozen_string_literal: true

# Test for Tk::BWidget::PagesManager widget options.

require_relative '../../../../test/test_helper'
require_relative '../../../../test/tk_test_helper'

class TestBWidgetPagesManager < Minitest::Test
  include TkTestHelper

  def test_pagesmanager_comprehensive
    assert_tk_app("BWidget PagesManager test", method(:pagesmanager_app))
  end

  def pagesmanager_app
    require 'tk'
    require 'tkextlib/bwidget'

    errors = []

    # --- Create pages manager ---
    pm = Tk::BWidget::PagesManager.new(root)
    pm.pack(fill: "both", expand: true, padx: 10, pady: 10)

    # --- Add pages ---
    page1 = pm.add("page1")
    page2 = pm.add("page2")

    errors << "add page1 failed" if page1.nil?
    errors << "add page2 failed" if page2.nil?

    # --- Add content to pages ---
    TkLabel.new(page1, text: "Page 1 Content").pack
    TkLabel.new(page2, text: "Page 2 Content").pack

    # --- Raise page ---
    pm.raise("page1")

    # --- Get page list ---
    pages = pm.pages
    errors << "pages failed" if pages.nil? || pages.empty?

    raise "BWidget PagesManager test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
