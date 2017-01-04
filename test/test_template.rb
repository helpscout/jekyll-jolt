require 'helper'

class TestTemplate < JekyllUnitTest
  context "jekyll-template" do
    setup do
      @site = Site.new(site_configuration)
      @site.read
      @site.generate
      @site.render
    end

    should "render content into the template" do
      post = @site.posts.docs[0]
      expected = <<EXPECTED
<div class="awesome"> <p>I am content!</p> </div>
EXPECTED
      assert_equal(expected, post.output)
    end


    should "render templates without affecting content before/after it" do
      post = @site.posts.docs[1]
      expected = <<EXPECTED
<h1 id="hello">Hello</h1>

<div class="awesome"> <p>I am content!</p> </div>

<p>Other content is here!</p>
EXPECTED
      assert_equal(expected, post.output)
    end


    should "render nested templates" do
      post = @site.posts.docs[2]
      expected = <<EXPECTED
<div class="awesome"> <div class="better"> <p>Content</p> </div> </div>
EXPECTED
      assert_equal(expected, post.output)
    end


    should "render with YAML front matter data" do
      post = @site.posts.docs[3]
      expected = <<EXPECTED
<h1>MILK!</h1>
<div class="milk"> <p>Content</p> </div>
EXPECTED
      assert_equal(expected, post.output)
    end


    should "render default YAML front matter data when none is passed in template block" do
      post = @site.posts.docs[4]
      expected = <<EXPECTED
<h1>Milk</h1>
<div class=\"milk\"> <!-- Front matter test --> </div>
EXPECTED
      assert_equal(expected, post.output)
    end


    should "render as HTML with parse: \"html\" attribute" do
      post = @site.posts.docs[5]
      expected = <<EXPECTED
<div class="awesome"> # Heading Content </div>
EXPECTED
      assert_equal(expected, post.output)
    end


    should "render templates regardless of indentation amount" do
      post = @site.posts.docs[6]
      expected = <<EXPECTED
<div>
  <div>
    <div>
      <div class="outer"> <div class="indentation"> <h1 id="heading">Heading</h1> <p>Content</p> </div> </div>
    </div>
  </div>
</div>
EXPECTED
      assert_equal(expected, post.output)
    end
  end
end
