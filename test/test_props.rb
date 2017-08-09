require 'helper'

class TestProps < JekyllUnitTest
  should 'render prop data over default template data' do
    @joule.render(%Q[
      {% template data-prop.html title: 'Yup' %}
        Test content
      {% endtemplate %}
    ])

    el = @joule.find('h1')

    assert_equal(el.text, 'Yup')
  end

  should 'render Ruby object passed into prop' do
    title = 'Yasssssssssss'
    @site.data['test-title'] = title

    @joule.render(%Q[
      {% template data-prop.html title: site.data.test-title %}
        Test content
      {% endtemplate %}
    ])

    el = @joule.find('h1')

    assert_equal(el.text, title)
  end
end
