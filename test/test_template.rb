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
<div class=\"milk\"> </div>
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


    should "render templates regardless of HTML comments" do
      post = @site.posts.docs[7]
      expected = <<EXPECTED
<div>
  <div>
    <div>
      <div class="outer"> <div class="indentation"> <h1 id="heading">Heading</h1> <p>Content</p> </div> </div>
    </div>
  </div>
  <!-- /div -->
</div>
<!-- /div -->
EXPECTED
      assert_equal(expected, post.output)
    end


    should "render content with markdown's --- for <hr>" do
      post = @site.posts.docs[8]
      expected = <<EXPECTED
<div> <p>Content</p> <hr /> <p>Content</p> </div>
EXPECTED
      assert_equal(expected, post.output)
    end


    should "render content with markdown's --- for <hr> when YAML is present" do
      post = @site.posts.docs[9]
      expected = <<EXPECTED
<div> <p>Content</p> <hr /> <p>Content</p> </div>
EXPECTED
      assert_equal(expected, post.output)
    end


    should "render content with multiple markdown --- for <hr>" do
      post = @site.posts.docs[10]
      expected = <<EXPECTED
<div> <p>Content</p> <hr /> <p>Content</p> <hr /> <p>Content</p> <hr /> </div>
EXPECTED
      assert_equal(expected, post.output)
    end


    should "render markdown title with ---" do
      post = @site.posts.docs[11]
      expected = <<EXPECTED
<div> <h2 id="title">title</h2> <p>Content</p> </div>
EXPECTED
      assert_equal(expected, post.output)
    end


    should "render templates that are used multiple times" do
      post = @site.posts.docs[12]
      expected = <<EXPECTED
<div class="outer"> <div class="inner"> <h1>Super Milk</h1> <div class="milk"> <p>Content</p> </div> </div> </div>

<h2 id="content">Content</h2>
<p>Buffer content</p>

<div class="outer"> <div class="inner"> <h1>Milk</h1> <div class="milk"> </div> </div> </div>

<h2 id="title">Title</h2>
<p>Buffer content</p>
EXPECTED
      assert_equal(expected, post.output)
    end


    should "render templates that contain style tags" do
      post = @site.posts.docs[13]
      expected = <<EXPECTED
<div class="content"> <h1 id="title">Super Milk</h1> <p>Content</p> </div>
<style>
  #title {
    color: #222;
  }
  .content {
    color: #333;
  }
</style>

<h2 id="content">Content</h2>
<p>Buffer content</p>

<div class="content"> <h1 id="title">Title</h1> </div>
<style>
  #title {
    color: #222;
  }
  .content {
    color: #333;
  }
</style>

<h2 id="title">Title</h2>
<p>Buffer content</p>
EXPECTED
      assert_equal(expected, post.output)
    end


    should "render links with inner divs correctly" do
      post = @site.posts.docs[14]
      expected = <<EXPECTED
<div> <a href="/test"> <div> Content </div> </a> </div>
EXPECTED
      assert_equal(expected, post.output)
    end

    should "render template without inner content" do
      post = @site.posts.docs[19]
      expected = <<EXPECTED
<h1>Milk</h1>
<div class="milk"> </div>
EXPECTED
      assert_equal(expected, post.output)
    end

  end
end
