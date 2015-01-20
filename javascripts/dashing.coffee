#= require jquery
#= require es5-shim
#= require batman
#= require batman.jquery
#= require configuration



Batman.Filters.prettyNumber = (num) ->
  num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",") unless isNaN(num)

Batman.Filters.dashize = (str) ->
  dashes_rx1 = /([A-Z]+)([A-Z][a-z])/g;
  dashes_rx2 = /([a-z\d])([A-Z])/g;

  return str.replace(dashes_rx1, '$1_$2').replace(dashes_rx2, '$1_$2').replace(/_/g, '-').toLowerCase()

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
  @on 'reload', (data) ->
    window.location.reload(true)


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
      timestamp = new Date(updatedAt * 1000)
      hours = timestamp.getHours()
      minutes = ("0" + timestamp.getMinutes()).slice(-2)
      "Last updated at #{hours}:#{minutes}"

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

class DashingEvents
  constructor: ->
    @initdone=false

  message: (data) ->
   if lastEvents[data.id]?.updatedAt != data.updatedAt
    if Dashing.debugMode
      console.log("Received data for #{data.id}", data)
    if widgets[data.id]?.length > 0
      lastEvents[data.id] = data
      for widget in widgets[data.id]
        widget.receiveData(data)
  dashboards: (data) ->
    if Dashing.debugMode
      console.log("Received data for dashboards", data)
    if data.dashboard is '*' or window.location.pathname is "/#{data.dashboard}"
      Dashing.fire data.event, data
  onerror: (err) ->
    setTimeout (->
      window.location.reload()
    ), 5*60*1000


createEventsSource = -> 
  source=null
  switch Configuration.EventEngine 
    when "SSE"
      source = new EventSource(Configuration.SSEUrl)
      source.sender=new DashingEvents
      source.addEventListener 'open', (e) ->
        if Dashing.debugMode
          console.log("Connection opened", e)

      source.addEventListener 'error', (e)->
        if Dashing.debugMode
          console.log("Connection error", e)
        if (e.currentTarget.readyState == EventSource.CLOSED)
          @sender.onerror(e)

      source.addEventListener 'message', (e) ->
        data = JSON.parse(e.data)
        @sender.message(data)

      source.addEventListener 'dashboards', (e) ->
        data = JSON.parse(e.data)
        @sender.dashboards(data)

      source.subscribe = (widgets) ->
        if Dashing.debugMode
          console.log("widgets")


    when "WSBI","WS"
      source = new WebSocket(Configuration.WSUrl)
      source.sender=new DashingEvents
      source.onopen = (evt) -> 
        if Dashing.debugMode
          console.log("ws opened")
          console.log(Dashing.widgets)
        @subscribe(Dashing.widgets)          
      source.onclose = (evt) -> 
        if Dashing.debugMode
          console.log("ws closed");
          console.log(evt)
      source.onmessage = (evt) -> 
        if Dashing.debugMode
          console.log("ws message:")
          console.log(evt)
        msgdata=JSON.parse(evt.data)
        switch msgdata.type
          when 'event'
            if Array.isArray(msgdata.data)
              for data in msgdata.data
                @sender.message(data)
            else
              @sender.message(msgdata.data)
          when 'dashboards'
            @sender.dashboards(msgdata.data)
          when 'ack'
            @subscribe(widgets)

      source.onerror = (evt) -> 
        if (evt.currentTarget.readyState == WebSocket.CLOSED)
          @sender.onerror(e)
      source.subscribe = (widgets) ->
        if @readyState == WebSocket.CONNECTING
          if Dashing.debugMode
            console.log("ws is still connecting")
          return
        if widgets.size==0
          if Dashing.debugMode
            console.log("empty widgets")
          return
        if @sender.initdone==true
          return
        @sender.initdone=true
        msg = {type: 'subscribe',data: {events: Object.keys(widgets)}}
        jmsg=JSON.stringify(msg)       
        @send(jmsg)

    

  source



$(document).ready ->
  Dashing.source=createEventsSource()
  Dashing.run()

