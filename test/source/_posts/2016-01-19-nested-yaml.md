{% template milk.html %}
---
title: "One"
---
Content

  {% template milk.html %}
  ---
  title: "Two"
  ---

    {% template milk.html %}
    ---
    title: "Three"
    ---

    {% endtemplate %}
  {% endtemplate %}

  {% template milk.html %}
  ---
  title: "Also two"
  ---

  {% endtemplate %}
{% endtemplate %}
