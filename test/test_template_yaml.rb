require 'helper'

class TestTemplate < JekyllUnitTest
  context "jekyll-template" do
    setup do
      @site = Site.new(site_configuration)
      @site.read
      @site.generate
      @site.render
    end

    should "render nested templates with same YAML keys" do
      post = @site.posts.docs[18]
      expected = <<EXPECTED
<h1>One</h1>
<div class=\"milk\"> <p>Content</p> <h1>Two</h1> <div class=\"milk\"> <h1>Three</h1> <div class=\"milk\"> </div> </div> <h1>Also two</h1> <div class=\"milk\"> </div> </div>
EXPECTED
      assert_equal(expected, post.output)
    end

  end
end
