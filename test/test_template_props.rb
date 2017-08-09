require 'helper'

class TestTemplate < JekyllUnitTest
  should "render templates with props data being passed to child templates" do

    @joule.render(%Q[
      {% template data-prop.html
        props.title: "Two"
        props.heading: "Four"
      %}
      ---
      title: "One"
      ---
      {% template data-prop.html
        title: props.title
        heading: props.heading
      %}
        {% template data-prop.html
          props.heading: props.heading
        %}
          ---
          title: "Three"
          ---
          {% template data-prop.html
            title: props.heading
          %}
          {% endtemplate %}
        {% endtemplate %}
      {% endtemplate %}
    {% endtemplate %}
    ])

    el = @joule.find('div h1')
    el2 = @joule.find('div div h1')
    el3 = @joule.find('div div div h1')
    el4 = @joule.find('div div div div h1')

    assert_equal(el.text, 'One')
    assert_equal(el2.text, 'Two')
    assert_equal(el3.text, 'Three')
    assert_equal(el4.text, 'Four')
  end
end
