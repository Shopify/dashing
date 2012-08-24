class Dashing.Number extends Dashing.Widget
  @accessor 'current', Dashing.AnimatedValue

  @accessor 'difference', ->
    if @get('last')
      last = parseInt(@get('last'))
      current = parseInt(@get('current'))
      if last != 0
        diff = Math.abs(Math.round((current - last) / last * 100))
        "#{diff}%"

  @accessor 'arrow', ->
    if @get('last')
      if parseInt(@get('current')) > parseInt(@get('last')) then 'icon-arrow-up' else 'icon-arrow-down'

  @accessor 'statusStyle', ->
    "status-#{@get('status')}"

  @accessor 'needsAttention', ->
    @get('status') == 'warning' || @get('status') == 'danger'

  onData: (data) ->
    if data.status
      $(@get('node')).addClass("status-#{data.status}")