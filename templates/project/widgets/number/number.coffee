class Dashing.Number extends Dashing.Widget
  @accessor 'current', Dashing.AnimatedValue

  @accessor 'difference', ->
    if @get('last')
      last = parseInt(@get('last'))
      current = parseInt(@get('current'))
      if last != 0
        diff = Math.abs(Math.round((current - last) / last * 100))
        "#{diff}%"
    else
      ""

  @accessor 'arrow', ->
    if @get('last')
      arrow_direction = 'none'
      if parseInt(@get('current')) > parseInt(@get('last'))
        arrow_direction ='up' 
      else if parseInt(@get('current')) < parseInt(@get('last'))
        arrow_direction = 'down'
      return 'icon-arrow-' + arrow_direction 

  onData: (data) ->
    if data.status
      # clear existing "status-*" classes
      $(@get('node')).attr 'class', (i,c) ->
        c.replace /\bstatus-\S+/g, ''
      # add new class
      $(@get('node')).addClass "status-#{data.status}"
