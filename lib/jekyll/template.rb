require "htmlcompressor"
require "jekyll"
require "jekyll/template/version"

module Jekyll
  module Tags
    class TemplateBlock < Liquid::Block
      include Liquid::StandardFilters

      CONTEXT_NAME = "template"
      CONTEXT_CACHE_NAME = :cached_templates
      CONTEXT_DATA_NAME = :template_data
      CONTEXT_SCOPE_NAME = :template_data_scope
      CONTEXT_STORE_NAME = :template_data_store

      PROPS_NAME = "props"
      TEMPLATE_DIR = "_templates"

      LIQUID_SYNTAX_REGEXP = /(#{Liquid::QuotedFragment}+)?/
      PROPS_REGEXP = /#{PROPS_NAME}\./
      WHITESPACE_REGEXP = %r!^\s*!m
      # Source
      # https://github.com/jekyll/jekyll/blob/35c5e073625100b0f8f8eab6f7da6cb6d5734930/lib/jekyll/document.rb
      YAML_FRONT_MATTER_REGEXP = %r!(---\s*\n.*?\n?)^((---|\.\.\.)\s*$\n?)!m

      # initialize
      # Description: Extends Liquid's default initialize method.
      def initialize(tag_name, markup, tokens)
        super

        if markup =~ LIQUID_SYNTAX_REGEXP
          @attributes = {}
          @context = false
          @id = rand(36**8).to_s(36).freeze
          @props = {}
          @sanitize = false
          @site = false
          @template_name = $1.freeze

          @compressor = HtmlCompressor::Compressor.new({
            :remove_comments => true
          }).freeze

          # Parse parameters
          # Source: https://gist.github.com/jgatjens/8925165
          markup.scan(Liquid::TagAttributes) do |key, value|
            if (value =~ PROPS_REGEXP) != nil
              @attributes[key] = value
            else
              @attributes[key] = Liquid::Expression.parse(value)
            end
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

      # template_store_data(data = Array)
      # Description: Stores/updates the template data in cache
      # Returns: Hash of the template store data
      def template_store_data(data = {})
        @context.registers[CONTEXT_STORE_NAME] ||= {}
        unless @context.registers[CONTEXT_STORE_NAME].key?(@id)
          @context.registers[CONTEXT_STORE_NAME][@id] = {
            "id": @id,
            "index": @context.registers[CONTEXT_STORE_NAME].length,
            "template_name": @template_name
          }
        end
        @context.registers[CONTEXT_STORE_NAME][@id] = @context.registers[CONTEXT_STORE_NAME][@id].merge(data)
      end

      # prop?
      # Description: Determines if the variable is a template.props key
      # Return: Boolean
      def prop?(variable = "")
        (variable =~ PROPS_REGEXP) != nil
      end

      # prop(data = Hash, value = String)
      # Description: Returns the props value
      def prop(data, value = "")
        index = data[:index]
        value = data[value.gsub(PROPS_REGEXP, "")]
        if value and prop?(value) and index > 0
          store = @context.registers[CONTEXT_STORE_NAME]
          previous_scope = store[store.keys[index - 1]]
          prop(previous_scope, value)
        else
          value
        end
      end

      # evaluate_props
      # Description: Evaluates props that are being passed into the template.
      def evaluate_props()
        store = @context.registers[CONTEXT_STORE_NAME]
        data = store[@id]
        index = data[:index]

        if (index > 0)
          parent = store[store.keys[index - 1]]
          # Update the data scope
          @context[CONTEXT_SCOPE_NAME] = parent
          data.each do |key, value|
            if prop?(value)
              value = prop(parent, value)
              if value
                @props[key] = value
              end
            end
          end
        end
      end

      # render
      # Description: Extends Liquid's default render method. This method also
      # adds additional features:
      # - YAML front-matter parsing and handling
      # - properly handles indentation and whitespace (resolves rendering issues)
      # - ability to parse content as markdown vs. html
      # - supports custom attributes to be used in template
      def render(context)
        @context = context
        @site = @context.registers[:site]

        template_store_data(@attributes)

        # This allows for Jekyll intelligently re-render markup during
        # incremental builds.
        add_template_to_dependency(@template_name)
        # Loading the template from cache/template directory
        template = load_cached_template(@template_name)

        # Props must be evaluated before super is initialized.
        # This allows for props to be evaluated before they're parsed by Liquid.
        evaluate_props()

        content = super

        # Return the parsed/normalized content
        render_template(template, content)
      end

      # render_template(template = Liquid::Template, content = String)
      # Description: Serializes the context to be rendered by Liquid. Also
      # resets the context to ensure template data doesn't leak from
      # the scope.
      # Returns: String
      def render_template(template, content)
        # Define the default template attributes
        # Source:
        # https://github.com/Shopify/liquid/blob/9a7778e52c37965f7b47673da09cfb82856a6791/lib/liquid/tags/include.rb
        @context[CONTEXT_NAME] = Hash.new

        # Parse and extend template's front-matter with content front-matter
        update_attributes(get_front_matter(content))
        # Add props
        update_attributes(@props)
        # Update the template's store data
        template_store_data(@attributes)

        # Setting context's template attributes from @attributes
        # This allows for @attributes to be used within the template as
        # {{ template.atttribute_name }}
        if @attributes.length
          @attributes.each do |key, value|
            val = @context.evaluate(value)
            @context[CONTEXT_NAME][key] = val

            # Adjust sanitize if parse: html
            if (key == "parse") && (val == "html")
              @sanitize = true
            end
          end
        end

        # puts @attributes
        @context[CONTEXT_NAME]["content"] = sanitize(strip_front_matter(content))
        store_template_data()
        content = @compressor.compress(template.render(@context))
        reset_template_data()

        content
      end

      # update_attributes(data = Hash)
      # Description: Merges data with @attributes.
      def update_attributes(data)
        if data
          @attributes.merge!(data)
        end
      end

      # store_template_data()
      # Description: Works with reset_template_data. This is a work-around
      # to ensure data stays in scope and isn't leaked from child->parent
      # template.
      def store_template_data()
        @context.registers[CONTEXT_DATA_NAME] ||= {}
        unless @context.registers[CONTEXT_DATA_NAME].key?(@id)
          @context.registers[CONTEXT_DATA_NAME][@id] = @context[CONTEXT_NAME]
        end
      end

      # reset_template_data()
      # Description: Works with store_template_data. This is a work-around
      # to ensure data stays in scope and isn't leaked from child->parent
      # template.
      def reset_template_data()
        @context.registers[CONTEXT_DATA_NAME] ||= {}
        store = @context.registers[CONTEXT_DATA_NAME]
        if store.keys.length
          if store.keys[0] == @id
            # Resets template data
            @context.registers[CONTEXT_DATA_NAME] = false
            @context.registers[CONTEXT_SCOPE_NAME] = false
          else
            @context[CONTEXT_NAME] = store[store.keys[0]]
          end
        end
      end

      # add_template_to_dependency(path = String)
      # source: https://github.com/jekyll/jekyll/blob/e509cf2139d1a7ee11090b09721344608ecf48f6/lib/jekyll/tags/include.rb
      def add_template_to_dependency(path)
        if @context.registers[:page] && @context.registers[:page].key?("path")
          @site.regenerator.add_dependency(
            @site.in_source_dir(@context.registers[:page]["path"]),
            template_path(path)
          )
        end
      end

      # load_cached_template(path = String)
      # source: https://github.com/jekyll/jekyll/blob/e509cf2139d1a7ee11090b09721344608ecf48f6/lib/jekyll/tags/include.rb
      # Returns: Liquid template from Jekyll's cache.
      def load_cached_template(path)
        @context.registers[CONTEXT_CACHE_NAME] ||= {}
        cached_templates = @context.registers[CONTEXT_CACHE_NAME]

        unless cached_templates.key?(path)
          cached_templates[path] = load_template()
        end
        template = cached_templates[path]

        update_attributes(template["data"])
        template["template"]
      end

      # template_path(path = String)
      # Returns: A full file path of the template
      def template_path(path)
        File.join(@site.source.to_s, TEMPLATE_DIR, path.to_s)
      end

      # template_content(template_name = String)
      # Description: Opens, reads, and returns template content as string.
      # Returns: Template content
      def template_content(template_name)
        File.read(template_path(template_name).strip)
      end

      # load_template()
      # Description: Extends Liquid's default load_template method. Also provides
      # extra enhancements:
      # - parses and sets template front-matter content
      # Returns: Template class
      def load_template()
        file = @site
          .liquid_renderer
          .file(template_path(@template_name))

        content = template_content(@template_name)

        template = Hash.new
        data = get_front_matter(content)
        markup = strip_front_matter(content)

        if content
          template["data"] = data
          template["template"] = file.parse(markup)
          template
        else
          raise Liquid::SyntaxError, "Could not find #{file_path} in your templates"
        end
      end

      # sanitize(content = String)
      # Description: Renders the content as markdown or HTML based on the
      # "parse" attribute.
      # Returns: Content (string).
      def sanitize(content)
        unless @sanitize
          converter = @site.find_converter_instance(::Jekyll::Converters::Markdown)
          converter.convert(unindent(content))
        else
          unindent(content)
        end
      end

      # unindent(content = String)
      # Description: Removes initial indentation.
      # Returns: Content (string).
      def unindent(content)
        # Remove initial whitespace
        content.gsub!(/\A^\s*\n/, "")
        # Remove indentations
        if content =~ WHITESPACE_REGEXP
          indentation = Regexp.last_match(0).length
          content.gsub!(/^\ {#{indentation}}/, "")
        end
        content
      end

      # get_front_matter(content = String)
      # Returns: A hash of data parsed from the content's YAML
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

      # strip_front_matter(content = String)
      # Description: Removes the YAML front-matter content.
      # Returns: Template content, with front-matter removed.
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
