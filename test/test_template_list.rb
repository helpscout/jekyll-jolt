require 'helper'

class TestTemplate < JekyllUnitTest
  context "jekyll-template" do
    setup do
      @site = Site.new(site_configuration)
      @site.read
      @site.generate
      @site.render
    end

    should "render templates with list in YAML" do
      post = @site.posts.docs[16]
      expected = <<EXPECTED
<h1>Title</h1>
<ul> <li>Two</li> <li>Three</li> </ul>
EXPECTED
      assert_equal(expected, post.output)
    end

    should "render nested templates with list in YAML" do
      post = @site.posts.docs[17]
      expected = <<EXPECTED
<h1>Title</h1>
<ul> <li>Super</li> <li>Effective</li> </ul>
<h1>Title</h1>
<ul> <li>Double</li> <li>Trouble</li> </ul>
<h1>Title</h1>
<ul> <li>Triple</li> <li>Dribble</li> </ul>
EXPECTED
      assert_equal(expected, post.output)
    end


  end
end
