#= require_directory ./gridster

# This file enables gridster integration (http://gridster.net/)
# Delete it if you'd rather handle the layout yourself.
# You'll miss out on a lot if you do, but we won't hold it against you.

Dashing.gridsterLayout = (positions) ->
  Dashing.customGridsterLayout = true
  positions = positions.replace(/^"|"$/g, '')
  positions = $.parseJSON(positions)
  widgets = $("[data-row^=]")
  for widget, index in widgets
    $(widget).attr('data-row', positions[index].row)
    $(widget).attr('data-col', positions[index].col)

Dashing.showGridsterInstructions = ->
    data = $(".gridster ul:first").gridster().data('gridster').serialize()
    $('#save-gridster').slideDown()
    $('#gridster-code').text("
      <script type='text/javascript'>\n
      $(function() {\n
      \ \ Dashing.gridsterLayout('#{JSON.stringify(data)}')\n
      });\n
      </script>
    ")


$ ->
  $('#save-gridster').leanModal()

  $('#save-gridster').click ->
    $('#save-gridster').slideUp()