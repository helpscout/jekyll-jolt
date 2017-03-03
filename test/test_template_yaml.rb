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

    should "render nested templates while preserving scope of YAML data" do
      post = @site.posts.docs[20]
      expected = <<EXPECTED
<h1>Level 3</h1>
<h1>Default title</h1>
<h1>Level 1</h1>
<h1>Level 1 Dupe</h1>
<h1>Hello</h1>
EXPECTED
      assert_equal(expected, post.output)
    end

    should "render multiple nested templates while preserving scope of YAML data" do
      post = @site.posts.docs[21]
      expected = <<EXPECTED
<h1>Level 3</h1>
<h1>Default title</h1>
<h1>Level 1</h1>
<h1>Level 1 Dupe</h1>
<h1>You</h1>

<h1>Level 3</h1>
<h1>Default title</h1>
<h1>Level 1</h1>
<h1>Level 1 Dupe</h1>
<h1>WUT M8</h1>
EXPECTED
      assert_equal(expected, post.output)
    end
  end
end
