require 'test_helper'

require 'js_harmony_cms/scripting'

class ScriptingTest < Minitest::Test
  Scripting = JsHarmonyCms::Scripting

  def test_remote_template_runs
    script = Scripting.remote_template_integration('launcher', 'token')
    assert_match(/script/, script)
    assert_match(/launcher/, script)
    assert_match(/token/, script)
  end

  def test_editor_script_runs
    script = Scripting.editor_script('server')
    assert_match(/script/, script)
    assert_match(/server/, script)
  end
end