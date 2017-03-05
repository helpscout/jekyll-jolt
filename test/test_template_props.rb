require 'helper'

class TestTemplate < JekyllUnitTest
  context "jekyll-template" do
    setup do
      @site = Site.new(site_configuration)
      @site.read
      @site.generate
      @site.render
    end

    should "render templates with props data being passed to child templates" do
      post = @site.posts.docs[22]
      expected = <<EXPECTED
<h1>One</h1>
<h1>Two</h1>
<h1>Three</h1>
<h1>Four</h1>
EXPECTED
      assert_equal(expected, post.output)
    end
  end
end
