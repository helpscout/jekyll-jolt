require "htmlcompressor"
require "jekyll"
require "jekyll/template/version"

module Jekyll
  module Tags
    class TemplateBlock < Liquid::Block
      include Liquid::StandardFilters
      Syntax = /(#{Liquid::QuotedFragment}+)?/

      # YAML REGEXP
      # https://github.com/jekyll/jekyll/blob/35c5e073625100b0f8f8eab6f7da6cb6d5734930/lib/jekyll/document.rb
      YAML_FRONT_MATTER_REGEXP = %r!(---\s*\n.*?\n?)^((---|\.\.\.)\s*$\n?)!m

      # initialize
      # Description: Extends Liquid's default initialize method.
      def initialize(tag_name, markup, tokens)
        super
        @site = false

        # @template_name = markup
        if markup =~ Syntax

          @template_name = $1.freeze
          @attributes = {}
          @sanitize = false

          # Parse parameters
          # Source: https://gist.github.com/jgatjens/8925165
          markup.scan(Liquid::TagAttributes) do |key, value|
            @attributes[key] = Liquid::Expression.parse(value)
          end
        else
          raise SyntaxError.new(options[:locale].t("errors.syntax.include".freeze))
        end
      end

      # blank?
      # Description: Override's Liquid's default blank checker. This allows
      # for templates to be used without passing inner content.
      def blank?
        false
      end

      # render
      # Description: Extends Liquid's default render method. This method also
      # adds additional features:
      # - YAML front-matter parsing and handling
      # - properly handles indentation and whitespace (resolves renderin issues)
      # - ability to parse content as markdown vs. html
      # - supports custom attributes to be used in template
      def render(context)
        content = super
        @site = context.registers[:site]
        # Remove leading whitespace
        # content = content.lstrip
        compressor = HtmlCompressor::Compressor.new({
          :remove_comments => true
        })

        add_template_to_dependency(@template_name, context)

        template = load_cached_template(@template_name, context)

        # Define the default template attributes
        # Source:
        # https://github.com/Shopify/liquid/blob/9a7778e52c37965f7b47673da09cfb82856a6791/lib/liquid/tags/include.rb
        context["template_name"] = @template_name
        context["partial"] = true
        context["template"] = Hash.new

        # Parse and extend template's front-matter with content front-matter
        update_attributes(get_front_matter(content))
        
        # Setting template attributes from @attributes
        # This allows for @attributes to be used within the template as
        # {{ template.atttribute_name }}
        if @attributes
          @attributes.each do |key, value|
            val = context.evaluate(value)
            context["template"][key] = val

            # Adjust sanitize if parse: html
            if (key == "parse") && (val == "html")
              @sanitize = true
            end
          end
        end

        context["template"]["content"] = sanitize(strip_front_matter(content))

        compressor.compress(template.render(context))
      end

      # update_attributes(data)
      # Description: Merges data with @attributes.
      # @param    data    { hash }
      def update_attributes(data)
        if data
          @attributes.merge!(data)
        end
      end

      # add_template_to_dependency(path, context)
      # source: https://github.com/jekyll/jekyll/blob/e509cf2139d1a7ee11090b09721344608ecf48f6/lib/jekyll/tags/include.rb
      def add_template_to_dependency(path, context)
        if context.registers[:page] && context.registers[:page].key?("path")
          @site.regenerator.add_dependency(
            @site.in_source_dir(context.registers[:page]["path"]),
            get_template_path(path)
          )
        end
      end

      # load_cached_template(path, context)
      # source: https://github.com/jekyll/jekyll/blob/e509cf2139d1a7ee11090b09721344608ecf48f6/lib/jekyll/tags/include.rb
      def load_cached_template(path, context)
        context.registers[:cached_templates] ||= {}
        cached_templates = context.registers[:cached_templates]

        unless cached_templates.key?(path)
          cached_templates[path] = load_template()
        end
        template = cached_templates[path]

        update_attributes(template["data"])
        template["template"]
      end

      # get_template_path(path)
      # Returns: A full file path of the template
      # @param    path    { string }
      def get_template_path(path)
        File.join(@site.source.to_s, "_templates", path.to_s)
      end

      # get_template_content(template)
      # Description: Opens, reads, and returns template content as string.
      # Returns: Template content
      # @param    template    { string }
      def get_template_content(template)
        File.read(get_template_path(template).strip)
      end

      # load_template()
      # Description: Extends Liquid's default load_template method. Also provides
      # extra enhancements:
      # - parses and sets template front-matter content
      # Returns: Template class
      def load_template()
        file = @site
          .liquid_renderer
          .file(get_template_path(@template_name))
        # Set the template_content
        template_content = get_template_content(@template_name)

        template_obj = Hash.new
        data = get_front_matter(template_content)
        content = strip_front_matter(template_content)

        if template_content
          template_obj["data"] = data 
          template_obj["template"] = file.parse(content)
          template_obj
        else
          raise Liquid::SyntaxError, "Could not find #{file_path} in your templates"
        end
      end

      # sanitize(content)
      # Description: Renders the content as markdown or HTML based on the
      # "parse" attribute.
      # Returns: Content (string).
      # @param    content   { string }
      def sanitize(content)
        unless @sanitize
          converter = @site.find_converter_instance(::Jekyll::Converters::Markdown)
          converter.convert(unindent(content))
        else
          unindent(content)
        end
      end

      # unindent(content)
      # Description: Removes initial indentation.
      # Returns: Content (string).
      # @param    content    { string }
      def unindent(content)
        # Remove initial whitespace
        content.gsub!(/\A^\s*\n/, "")

        # Remove indentations
        whitespace_regex = %r!^\s*!m
        if content =~ whitespace_regex
          indentation = Regexp.last_match(0).length
          content.gsub!(/^\ {#{indentation}}/, "")
        end

        content
      end

      # get_front_matter(content)
      # Returns: A hash of data parsed from the content's YAML
      # @param    content    { string }
      def get_front_matter(content)
        # Strip leading white-spaces
        content = unindent(content)
        if content =~ YAML_FRONT_MATTER_REGEXP
          front_matter = Regexp.last_match(0)
          values = SafeYAML.load(front_matter)
        else
          Hash.new
        end
      end

      # strip_front_matter(content)
      # Description: Removes the YAML front-matter content.
      # Returns: Template content, with front-matter removed.
      # @param    content    { string }
      def strip_front_matter(content)
        # Strip leading white-spaces
        content = unindent(content)

        if content =~ YAML_FRONT_MATTER_REGEXP
          front_matter = Regexp.last_match(0)
          # Returns content with stripped front-matter
          content.gsub!(front_matter, "")
        end

        content
      end

    end
  end
end

Liquid::Template.register_tag("template", Jekyll::Tags::TemplateBlock)
