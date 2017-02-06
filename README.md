# jekyll-template [![Build Status](https://travis-ci.org/helpscout/jekyll-template.svg?branch=master)](https://travis-ci.org/helpscout/jekyll-template) [![Gem Version](https://badge.fury.io/rb/jekyll-template.svg)](https://badge.fury.io/rb/jekyll-template)

Custom template block with YAML front matter support for Jekyll


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'jekyll-template'
```

And then execute:
```
bundle
```

Or install it yourself as:
```
gem install jekyll-template
```



---



## Documentation

Templates (`{% template %}`) work similarly to Jekyll's `{% include %}` tag. It references an existing `.html` file for markup. However, the biggest difference (and most awesome feature) between `{% template %}` vs. `{% include %}` is that templates allow for content to be used inside the block.

### Setting up the template directory

The first thing you have to do to allow for template blocks to work is to create a new directory called `_templates` within your Jekyll site's source directory:

```
my-jekyll-site/
├── _data/
├── _includes/
├── _plugins/
├── _posts/
├── _templates/ <-- Right here!
└── index.md
```

Once you have your directory created, add template files as regular `.html` files (just like you would `_includes/` files).


### Creating a template file

Let's create a template file called `awesome.html`, which will be added to `_templates`.
(Full path is `_templates/awesome.html`)

```markdown
<div class="awesome">
  {{ template.content }}
</div>
```

You can write whatever markup you would like inside a template file. The most important thing is to include a `{{ template.content }}` tag. This destinates where your content will be rendered.


### Using a template block

After creating our `awesome.html` template, we can use it in any of our Jekyll pages (or posts… heck even in `_include` files).

For this example, let's add it to our `index.md` file:

```markdown
# Hello
{% template awesome.html %}
I am content!
{% endtemplate %}
```

Your template content needs to begin with `{% template %}` and end with `{% endtemplate %}`. Be sure to include the path/name of the template file you wish to use.

The final rendered `.html` will look like this:

```html
<h1 id="hello">Hello</h1>
<div class="awesome"> <p>I am content!</p> </div>
```


## Rendering template content as HTML

By default, templates parse and render content as **markdown**. To force templates to render content as HTML, all the `parse: "html"` attribute to your `{% template %}` tag.

```markdown
{% template awesome.html parse: "html" %}
# Title
I am content! As HTML!
{% endtemplate %}
```

The final rendered `.html` will look like this:

```html
<div class="awesome"> # Title I am content! As HTML! </div>
```



## Using YAML front matter

You can add YAML front matter to both your template files, just like Jekyll pages and posts.

```
---
title: Awesome title
---
<div class="awesome">
  <h1>{{ template.title</h1>

  {{ template.content }}
</div>
```

Front matter can also be defined in your `{% template %}` block. Any front matter data defined here will override the data defined in your original template.

```
{% template awesome.html %}
---
title: Best title
---
I am content!
{% endtemplate %}
```

```html
<div class="awesome">
  <h1>Best title</h1>
  <p>I am content!</p>
</div>
```


## Using templates within templates

Yo dawg. I heard you liked templates! The template block supports nesting 👏

```markdown
{% template outer.html %}
  {% template inner.html %}
    Hi!
  {% endtemplate %}
{% endtemplate %}
```


---


More documentation coming soon!


---


## Note

I am **not** a Ruby developer. (My background is mostly with Javascript). I wrote this plugin based on experimentation and combing through [Jekyll's](https://github.com/jekyll/jekyll) and [Liquid's](https://github.com/Shopify/liquid) source code + documentation. I'm sure there's probably code in there somewhere that's offensive to Ruby devs.

We've been using `{% template %}` for many months now on the [Help Scout website](https://www.helpscout.net/), and it's been working great! We haven't noticed any slowdowns in build times (and we use **a lot** of templates).


---


## Thanks ❤️
Many thanks to [@alisdair](https://github.com/alisdair) for his help with code review/testing + [@hownowstephen](https://github.com/hownowstephen) for his help with Ruby things.
