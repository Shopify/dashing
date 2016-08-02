class Dashing.Meter extends Dashing.Widget

  @accessor 'value', Dashing.AnimatedValue

  constructor: ->
    super
    @observe 'value', (value) ->
      $(@node).find(".meter").val(value).trigger('change')

  ready: ->
    meter = $(@node).find(".meter")
    meter.attr("data-bgcolor", meter.css("background-color"))
    meter.attr("data-fgcolor", meter.css("color"))
    meter.knob()
