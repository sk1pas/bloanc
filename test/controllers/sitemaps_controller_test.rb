require 'test_helper'

class SitemapsControllerTest < ActionDispatch::IntegrationTest
  test 'serves sitemap with locale urls and hreflang links' do
    get sitemap_path

    assert_response :success
    assert_includes response.media_type, 'application/xml'

    assert_includes response.body, root_url(locale: :pl)
    assert_includes response.body, root_url(locale: :en)
    assert_includes response.body, root_url(locale: :ua)
    assert_includes response.body, 'hreflang="pl"'
    assert_includes response.body, 'hreflang="en"'
    assert_includes response.body, 'hreflang="ua"'
    assert_includes response.body, 'hreflang="x-default"'
    refute_includes response.body, '/admin'
  end
end
