require 'test_helper'

require 'js_harmony_cms/middleware/clientjs_server'

class ClientjsServerTest < Minitest::Test
  extend Declarative

  def app
    ->(env) {
      req = Rack::Request.new(env)

      [200, env, req.path]
    }
  end

  def middleware
    JsHarmonyCms::Middleware::ClientjsServer.new(app, '/.jsHarmonyCMS/jsHarmonyCmsEditor.js')
  end

  def env_for(url, opts={})
    Rack::MockRequest.env_for(url, opts)
  end

  test "unknown url" do
    code, _env, body = middleware.call env_for('http://localhost/some/path')

    assert_equal 200, code
    assert_equal "/some/path", body
  end

  test "js url" do
    code, env, body = middleware.call env_for('.jsHarmonyCMS/jsHarmonyCmsEditor.js')

    body = body&&body.join('')

    assert_equal 200, code
    assert_includes env, 'Content-Type'
    assert_match(/jsHarmonyCmsEditor=/, body)
  end
end