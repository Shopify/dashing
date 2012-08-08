class Dashing.List extends Dashing.Widget
  @accessor 'current', Dashing.AnimatedValue

  @accessor 'arrow', ->
    if @get('last')
      if parseInt(@get('current')) > parseInt(@get('last')) then 'arrow-up' else 'arrow-down'

  ready: ->
    Batman.setImmediate =>
      if @get('unordered')
        $(@node).find('ol').remove()
      else
        $(@node).find('ul').remove()