require 'test_helper'

require 'js_harmony_cms/middleware/router'

class RouterTest < Minitest::Test
  extend Declarative

  def app
    ->(env) {
      req = Rack::Request.new(env)

      [200, env, req.path]
    }
  end

  def middleware
    JsHarmonyCms::Middleware::Router.new(app, 'test/fixtures/files/jshcms_redirects.json')
  end

  def env_for(url, opts={})
    Rack::MockRequest.env_for(url, opts)
  end

  test "passthru path - relative" do
    path = middleware.fully_qualified('/random_numbers', env_for('http://localhost/proxy'))

    assert_equal "http://localhost:80/random_numbers", path
  end

  test "passthru path - fully qualified" do
    path = middleware.fully_qualified('https://localhost:3000/random_numbers', env_for('http://localhost/remote'))

    assert_equal "https://localhost:3000/random_numbers", path
  end

  test "unknown url" do
    code, _env, body = middleware.call env_for('http://localhost/some/path')

    assert_equal 200, code
    assert_equal "/some/path", body
  end

  test "301 redirect" do
    code, env, _body = middleware.call env_for('http://localhost/301')

    assert_equal 301, code
    assert_equal '/random_numbers', env['Location']
  end

  test "302 redirect" do
    code, env, _body = middleware.call env_for('http://localhost/302')

    assert_equal 302, code
    assert_equal '/random_numbers', env['Location']
  end

  test "passthru - relative (requires running server)" do
    code, _env, body = middleware.call env_for('http://localhost:3000/proxy')

    assert_equal 200, code
    assert_match "DOCTYPE html", body.first
  end

  test "passthru - fully qualified (requires running server)" do
    code, _env, body = middleware.call env_for('http://localhost/remote')

    assert_equal 200, code
    assert_match "DOCTYPE html", body.first
  end

  test "begins" do
    code, env, _ = middleware.call env_for('http://localhost/beginswith')

    assert_equal 302, code
    assert_equal '/begins/with', env['Location']
  end

  test "begins case insensitive" do
    code, env, _body = middleware.call env_for('http://localhost/Beginswith')

    assert_equal 302, code
    assert_equal '/begins/with/case', env['Location']
  end

  test "exact" do
    code, env, _body = middleware.call env_for('http://localhost/exact')

    assert_equal 302, code
    assert_equal '/exact/match', env['Location']
  end

  test "exact case insensitive" do
    code, env, _body = middleware.call env_for('http://localhost/exact/CASE')

    assert_equal 302, code
    assert_equal '/exact/match/case', env['Location']
  end

  test "regex" do
    code, env, _body = middleware.call env_for('http://localhost/regex/1')

    assert_equal 302, code
    assert_equal '/regex/to/1', env['Location']
  end

  test "regex case insensitive" do
    code, env, _body = middleware.call env_for('http://localhost/Regex/1')

    assert_equal 302, code
    assert_equal '/regex/case/to/1', env['Location']
  end

  test "relative" do
    code, env, _body = middleware.call env_for('http://localhost/relative')

    assert_equal 302, code
    assert_equal 'relative_target', env['Location']
  end
end