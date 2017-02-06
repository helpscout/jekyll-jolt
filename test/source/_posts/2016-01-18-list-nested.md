{% template list.html %}
  ---
  items:
    -
      title: "Super"
    -
      title: "Effective"
  ---

  {% template list.html %}
  ---
  items:
    -
      title: "Double"
    -
      title: "Trouble"
  ---

  {% template list.html %}
        ---
        items:
          -
            title: "Triple"
          -
            title: "Dribble"
        ---
  {% endtemplate %}
  {% endtemplate %}
{% endtemplate %}
