require "htmlcompressor"
require "jekyll"
require "jekyll/template/version"
require "unindent"
# require "yui-compressor"

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
        @root_path = false
        @template_content = false

        # @template_name = markup
        if markup =~ Syntax

          @template_name = $1
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

      # parse_content
      # Description: Extends Liquid's default parse_content method.
      def parse_content(context, content)
        content
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
        # Remove leading whitespace
        # content = content.lstrip
        compressor = HtmlCompressor::Compressor.new({
          :compress_javascript => true,
          :javascript_compressor => :yui,
          :compress_css => true,
          :css_compressor => :yui,
          :remove_comments => true
        })
        site = context.registers[:site]
        template = load_template(context)

        # Define the default template attributes
        # Source:
        # https://github.com/Shopify/liquid/blob/9a7778e52c37965f7b47673da09cfb82856a6791/lib/liquid/tags/include.rb
        context["template_name"] = context.evaluate(@template_name)
        context["partial"] = true
        context["template"] = Hash.new

        # Parse and extend template's front-matter with content front-matter
        content = parse_front_matter(content)

        # Setting template attributes from @attributes
        # This allows for @attributes to be used within the template as
        # {{ template.atttribute_name }}
        if @attributes
          @attributes.each do |key, value|
            # Render the attribute(s) with context
            if value.instance_of? Liquid::VariableLookup
              # val = value.name
              val = context.evaluate(value)
            else
              val = context.evaluate(value)
            end
            context["template"][key] = val

            # Adjust sanitize if parse: html
            if (key == "parse") && (val == "html")
              @sanitize = true
            end
          end
        end

        content = parse_content(context, content)

        # sanitize
        # Determines whether to parse as HTML or markdown
        unless @sanitize
          converter = site.find_converter_instance(::Jekyll::Converters::Markdown)
          content = content.to_s.unindent
          @content = converter.convert(content)
        else
          @content = content.to_s.unindent
        end

        # handling empty content
        if @content.empty?
          @content = "<!-- Template: #{ @template_name } -->"
        end

        # setting the template content
        context["template"]["content"] = @content

        # rendering the template with the content
        @output = template.render( context )
        # normalizes whitespace and indentation
        @output = compressor.compress(@output)
      end

      # get_template_content(template)
      # Description: Opens, reads, and returns template content as string.
      # Returns: Template content
      # @param    template    { string }
      def get_template_content(template)
        # default template path
        view = "_templates/" + template
        file_path = File.join(@root_path, view)
        path = File.read(file_path.strip)
        # returns template content
        path
      end

      # load_template(template)
      # Description: Extends Liquid's default load_template method. Also provides
      # extra enhancements:
      # - parses and sets template front-matter content
      # Returns: Template class
      def load_template(context)
        # Set the root_path
        @root_path = context.registers[:site].source
        # Set the template_content
        @template_content = get_template_content(@template_name)
        # Parse front matter
        @template_content = parse_front_matter(@template_content)

        if @template_content
          Liquid::Template.parse(@template_content)
        else
          raise Liquid::SyntaxError, "Could not find #{view} in your templates"
        end
      end

      # unindent(content)
      # Description: Removes initial indentation.
      # Returns: Content (string).
      # @param    content    { string }
      def unindent(content)
        # Remove initial whitespace
        content = content.gsub(/\A^\s*\n/, "")

        # Remove indentations
        whitespace_regex = %r!^\s*!m
        if content =~ whitespace_regex
          indentation = Regexp.last_match(0)
          content = content.gsub(indentation, "")
        end

        content
      end

      # parse_front_matter(content)
      # Description: Parses and sets YAML front-matter content.
      # Returns: Template content, with front-matter removed.
      # @param    content    { string }
      def parse_front_matter(content)
        # Strip leading white-spaces
        content = unindent(content)

        if content =~ YAML_FRONT_MATTER_REGEXP
          front_matter = Regexp.last_match(0)
          # Push YAML data to the template's attributes
          values = SafeYAML.load(front_matter)
          # Set YAML data to @attributes
          values.each do |key, value|
            @attributes[key] = value
          end
          # Returns content with stripped front-matter
          content = content.gsub(front_matter, "")
        end

        content
      end

    end
  end
end

Liquid::Template.register_tag("template", Jekyll::Tags::TemplateBlock)
