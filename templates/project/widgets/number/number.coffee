class Dashing.Number extends Dashing.Widget
  @accessor 'current', Dashing.AnimatedValue

  @accessor 'difference', ->
    if @get('last')
      last = @parseValue(@get('last'))
      current = @parseValue(@get('current'))
      if last != 0
        diff = Math.abs(Math.round((current - last) / last * 100))
        "#{diff}%"
    else
      ""

  @accessor 'arrow', ->
    if @get('last')
      if @parseValue(@get('current')) > @parseValue(@get('last')) then 'icon-arrow-up' else 'icon-arrow-down'

  onData: (data) ->
    if data.status
      # clear existing "status-*" classes
      $(@get('node')).attr 'class', (i,c) ->
        c.replace /\bstatus-\S+/g, ''
      # add new class
      $(@get('node')).addClass "status-#{data.status}"

  parseValue: (number) ->
    if number == parseInt(number, 10) then parseInt(number) else parseFloat(number)


