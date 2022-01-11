require 'test_helper'

require "js_harmony_cms"

class JsHarmonyCmsTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::JsHarmonyCms::VERSION
  end

  extend Declarative

  def cms
    JsHarmonyCms.new({
      :content_path => 'test/fixtures/files',
      :cms_server_urls => ['*'],
    })
  end

  def params_display
    {}
  end

  def params_editor
    {
      "jshcms_token" => "xxxx",
      "jshcms_url" => cms_server_url,
    }
  end

  def cms_server_url
    '//cms.server'
  end

  test "not in editor" do
    assert_equal false, cms.is_in_editor?(params_display)
  end

  test "in editor" do
    assert_equal true, cms.is_in_editor?(params_editor)
  end

  test "editor tag display mode" do
    assert_equal '', cms.get_editor_script(params_display)
  end

  test "editor tag editor mode" do
    script = cms.get_editor_script(params_editor)

    assert_match cms_server_url, script
  end

  test "server url security" do
    assert_equal '', JsHarmonyCms.new({:cms_server_urls => ['//elsewhere']}).get_editor_script(params_editor)
  end

  test "page: display, missing" do
    page = cms.get_page('/not/found', params_display)

    assert_equal '', page.editor_script
  end

  test "page: editor, missing" do
    page = cms.get_page('/not/found', params_editor)

    refute_equal '', page.editor_script
  end

  test "page: display, found" do
    page = cms.get_page('/test.html', params_display)

    assert_equal '', page.editor_script
    assert_equal 'Random Numbers - with CMS content', page.title
  end

  test "page: editor, found" do
    page = cms.get_page('/test.html', params_editor)

    refute_equal '', page.editor_script
    assert_equal '', page.title
  end
end