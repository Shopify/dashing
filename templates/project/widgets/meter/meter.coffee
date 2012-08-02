class AllTheThings.Meter extends AllTheThings.Widget
  source: 'meter'

  @accessor 'value', Batman.Property.EasingSetter

  constructor: ->
    super
    @observe 'value', (value) ->
      $(@node).find(".meter").val(value).trigger('change')

  ready: ->
    Batman.setImmediate =>
      meter = $(@node).find(".meter")
      meter.attr("data-bgcolor", meter.css("background-color"))
      meter.attr("data-fgcolor", meter.css("color"))
      meter.knob()