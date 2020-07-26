module Jekyll
  class CategoryFeedGenerator < Generator
    def generate(site)
      site.categories.each do |category, posts|
        Jekyll.logger.info("cat-feeds:", "found category: '#{category}'")
        site.pages << CategoryFeedPage.new(site, site.source, category, posts)
      end
    end
  end

  class CategoryFeedPage < Page
    def initialize(site, base, category, posts)
      @site = site
      @base = base
      @dir = ""
      @name = "feed.#{category}.xml"

      self.process(@name)
      self.read_yaml(File.join(base, "_layouts"), "cat-feed.xml")
      self.data["category"] = category
      self.data["posts"] = posts

      if site.config["category_descriptions"] && site.config["category_descriptions"][category]
        self.data["description"] = site.config["category_descriptions"][category]
      end
    end
  end
end
