<div>
            <div>
    <div>
      {% template indentation-title.html %}
        ---
        title: "Level one"
        ---

        # Heading

        Content

        {% template indentation-title.html %}
          ---
          title: "Level two"
          meta: "2"
          ---
          # Heading

          Content
        {% endtemplate %}
        {% template indentation.html %}
                Also level 2
        {% endtemplate %}
      {% endtemplate %}
    </div></div>
</div>
