#= require jquery
#= require es5-shim
#= require batman
#= require batman.jquery


Batman.Filters.prettyNumber = (num) ->
  num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",") unless isNaN(num)

Batman.Filters.dashize = (str) ->
  dashes_rx1 = /([A-Z]+)([A-Z][a-z])/g;
  dashes_rx2 = /([a-z\d])([A-Z])/g;

  return str.replace(dashes_rx1, '$1_$2').replace(dashes_rx2, '$1_$2').replace('_', '-').toLowerCase()

Batman.Filters.shortenedNumber = (num) ->
  return num if isNaN(num)
  if num >= 1000000000
    (num / 1000000000).toFixed(1) + 'B'
  else if num >= 1000000
    (num / 1000000).toFixed(1) + 'M'
  else if num >= 1000
    (num / 1000).toFixed(1) + 'K'
  else
    num

class window.Dashing extends Batman.App
  @root ->
Dashing.params = Batman.URI.paramsFromQuery(window.location.search.slice(1));

class Dashing.Widget extends Batman.View
  constructor:  ->
    # Set the view path
    @constructor::source = Batman.Filters.underscore(@constructor.name)
    super

    @mixin($(@node).data())
    Dashing.widgets[@id] ||= []
    Dashing.widgets[@id].push(@)
    @mixin(Dashing.lastEvents[@id]) # in case the events from the server came before the widget was rendered

    type = Batman.Filters.dashize(@view)
    $(@node).addClass("widget widget-#{type} #{@id}")

  @accessor 'updatedAtMessage', ->
    if updatedAt = @get('updatedAt')
      timestamp = updatedAt.toString().match(/\d*:\d*/)[0]
      "Last updated at #{timestamp}"

  @::on 'ready', ->
    Dashing.Widget.fire 'ready'

  receiveData: (data) =>
    @mixin(data)
    @onData(data)

  onData: (data) =>
    # Widgets override this to handle incoming data

Dashing.AnimatedValue =
  get: Batman.Property.defaultAccessor.get
  set: (k, to) ->
    if !to? || isNaN(to)
      @[k] = to
    else
      timer = "interval_#{k}"
      num = if (!isNaN(@[k]) && @[k]?) then @[k] else 0
      unless @[timer] || num == to
        to = parseFloat(to)
        num = parseFloat(num)
        up = to > num
        num_interval = Math.abs(num - to) / 90
        @[timer] =
          setInterval =>
            num = if up then Math.ceil(num+num_interval) else Math.floor(num-num_interval)
            if (up && num > to) || (!up && num < to)
              num = to
              clearInterval(@[timer])
              @[timer] = null
              delete @[timer]
            @[k] = num
            @set k, to
          , 10
      @[k] = num

Dashing.widgets = widgets = {}
Dashing.lastEvents = lastEvents = {}
Dashing.debugMode = false

source = new EventSource('/events')
source.addEventListener 'open', (e) ->
  console.log("Connection opened")

source.addEventListener 'error', (e)->
  console.log("Connection error")
  if (e.readyState == EventSource.CLOSED)
    console.log("Connection closed")

source.addEventListener 'message', (e) =>
  data = JSON.parse(e.data)
  if Dashing.debugMode
    console.log("Received data for #{data.id}", data)
  lastEvents[data.id] = data
  if widgets[data.id]?.length > 0
    for widget in widgets[data.id]
      widget.receiveData(data)


$(document).ready ->
  Dashing.run()
