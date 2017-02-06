require 'helper'

class TestTemplate < JekyllUnitTest
  context "jekyll-template" do
    setup do
      @site = Site.new(site_configuration)
      @site.read
      @site.generate
      @site.render
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

    should "render nested templates with sloppy indentation" do
      post = @site.posts.docs[15]
      expected = <<EXPECTED
<div>
            <div>
    <div>
      <h1>Level one</h1> <div class=\"outer\"> <div class=\"meta\">There </div> <div class=\"indentation\"> <h1 id=\"heading\">Heading</h1> <p>Content</p> <h1>Level two</h1> <div class=\"outer\"> <div class=\"meta\">2 </div> <div class=\"indentation\"> <h1 id=\"heading\">Heading</h1> <p>Content</p> </div> </div> <div class=\"outer\"> <div class=\"indentation\"> <p>Also level 2</p> </div> </div> </div> </div>
    </div></div>
</div>
EXPECTED
      assert_equal(expected, post.output)
    end

  end
end
