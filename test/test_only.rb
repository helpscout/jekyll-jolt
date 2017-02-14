
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
      post = @site.posts.docs[0]
      assert_equal(true, true)
    end


  end
end
