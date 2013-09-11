class Dashing.Graph extends Dashing.Widget

  # Retrieve the `current` value of the graph.
  @accessor 'current', ->
    answer = null

    # Return the value supplied if there is one.
    if @get('displayedValue') != null and @get('displayedValue') != undefined
      console.log "Using displayedValue"
      answer = @get('displayedValue')

    if answer == null
      # Compute a value to return based on the summaryMethod
      series = @_parseData {points: @get('points'), series: @get('series')}
      if series?.length > 0
        console.log "Summary Method", @get('summaryMethod')
        switch @get('summaryMethod')
          when "sum"
            answer = 0
            answer += (point?.y or 0) for point in s.data for s in series

          when "sumLast"
            answer = 0
            answer += s.data[s.data.length - 1].y or 0 for s in series

          when "highest"
            answer = 0
            if @get('unstack')
              answer = Math.max(answer, (point?.y or 0)) for point in s.data for s in series
            else
              # Compute the sum of values at each point along the graph
              for index in [0...series[0].data.length]
                value = 0
                for s in series
                  value += s.data[index]?.y or 0
                answer = Math.max(answer, value)

          else
            # Otherwise if there's only one series, pick the most recent value from the series.
            if series.length == 1 and series[0].data?.length > 0
              data = series[0].data
              answer = data[data.length - 1].y
            else
              answer = ''
      else
        answer = '-'

    # Otherwise just return nothing.
    return answer

  ready: ->
    @assignedColors = @get('colors').split(':') if @get('colors')
    @strokeColors = @get('strokeColors').split(':') if @get('strokeColors')

    @graph = @_createGraph()
    @graph.render()

  # Handle new data from Dashing.
  onData: (data) ->
    @_parseData data
    @graph?.render()

  # Create a new Rickshaw graph.
  _createGraph: ->
    $node = $(@node)
    $container = $node.parent()
    # Gross hacks. Let's fix this.
    width = (Dashing.widget_base_dimensions[0] * $container.data("sizex")) + Dashing.widget_margins[0] * 2 * ($container.data("sizex") - 1)
    height = (Dashing.widget_base_dimensions[1] * $container.data("sizey"))

    if @get("legend")
      # Shave 20px off the bottom of the graph for the legend
      height -= 20

    $graph = $("<div style='height: #{height}px;'></div>")
    $node.append $graph
    graph = new Rickshaw.Graph(
      element:  $graph.get(0),
      renderer: @get('renderer') or @get('graphtype') or 'area',
      stroke:   !!@get('stroke'),
      width:  width,
      height:   height,
      series:   @_parseData {points: @get('points'), series: @get('series')}
    )
    graph.renderer.unstack = !!@get('unstack')

    x_axis = new Rickshaw.Graph.Axis.Time(graph: graph)
    y_axis = new Rickshaw.Graph.Axis.Y(graph: graph, tickFormat: Rickshaw.Fixtures.Number.formatKMBT)

    if @get("legend")
      # Add a legend
      $legendDiv = $("<div style='width: #{width}px;'></div>")
      $node.append($legendDiv)
      legend = new Rickshaw.Graph.Legend {
        graph: graph
        element: $legendDiv.get(0)
      }

    return graph

  # Parse a {series, points} object with new data from Dashing.
  #
  # If there is a graph, this will update it.  If not, this will return a new `series` object,
  # suitable for creating a new graph.
  _parseData: (data) ->
    series = @graph?.series or []

    # Figure out what kind of data we've been passed
    if data.series
      dataSeries = if isString(data.series) then JSON.parse data.series else data.series
      for subseries, index in dataSeries
        series[index] = @_parseSeries subseries

    else if data.points
      points = data.points
      if isString(points) then points = JSON.parse points

      if points[0]? and !points[0].x?
        # Not already in Rickshaw format; assume graphite data
        points = graphiteDataToRickshaw(points)

      series[0] = {data: points}
    else
      # No data - create a dummy series to keep Rickshaw happy
      series = [{data: [{x:0, y:0}]}]

    @_updateColors(series)

    return series

  # Parse a series of data from an array passed to `_parseData()`.
  # This accepts both Graphite and Rickshaw style data sets.
  _parseSeries: (series) ->
    if series.datapoints?
      # This is a Graphite series
      answer = {
        name: series.target
        data: graphiteDataToRickshaw series.datapoints
        color: series.color
        stroke: series.stroke
      }
    else if series.data?
      # Rickshaw data.  Need to clone, otherwise we could end up with multiple graphs sharing
      # the same data, and Rickshaw really doesn't like that.
      answer = {
        name:   series.name
        data:   series.data
        color:  series.color
        stroke: series.stroke
      }
    else
      throw new Error("Unknown data series: #{series}")

  # Update the color assignments for a series.  This will assign colors to any data that
  # doesn't have a color already.
  _updateColors: (series) ->
    # If no colors were provided, or of there aren't enough colors, then generate a set of
    # colors to use.
    if !@defaultColors or @defaultColors?.length != series.length
      @defaultColors = computeDefaultColors @node, series

    for subseries, index in series
      # Preferentially pick supplied colors instead of defaults, but don't overwrite a color
      # if one was supplied with the data.
      subseries.color ?= @assignedColors?[index] or @defaultColors[index]
      subseries.stroke ?= @strokeColors?[index] or "#000"

  # Convert a collection of Graphite data points into data that Rickshaw will understand.
  graphiteDataToRickshaw = (datapoints) ->
    answer = []
    for datapoint in datapoints
      # Need to convert potential nulls from Graphite into a real number for Rickshaw.
      answer.push {x: datapoint[1], y: (datapoint[0] or 0)}
    answer

  # Compute a pleasing set of default colors.  This works by starting with the background color,
  # and picking colors of intermediate luminance between the background and white (or the
  # background and black, for light colored backgrounds.)  We use the brightest color for the
  # first series, because then multiple series will appear to blend in to the background.
  computeDefaultColors = (node, series) ->
    defaultColors = []

    # Use a neutral color if we can't get the background-color for some reason.
    backgroundColor = parseColor($(node).css('background-color')) or [50, 50, 50, 1.0]
    if backgroundColor
      hsl = rgbToHsl backgroundColor
      luminance = hsl[2]

      # `quotient` should be at least `series.length + 1`, since we want to avoid pure
      # black or pure white bars.  Larger values result in graphs that are harder to read.
      quotient = (series.length + 1)
      if luminance < 0.6
        # Choose colors that are lighter than the background
        delta = (1.0 - luminance) / quotient
      else
        # Choose colors that are darker than the background
        delta = -(luminance / quotient)

      for index in [0...series.length]
        hsl[2] = luminance + (series.length - index) * delta
        defaultColors[index] = rgbToColor hslToRgb(hsl)

    return defaultColors



# Helper functions
# ================
isString = (obj) ->
  return toString.call(obj) is "[object String]"

# Parse a `rgb(x,y,z)` or `rgba(x,y,z,a)` string.
parseRgbaColor = (colorString) ->
  match = /^rgb\(\s*([\d]+)\s*,\s*([\d]+)\s*,\s*([\d]+)\s*\)/.exec(colorString)
  if match
    return [parseInt(match[1]), parseInt(match[2]), parseInt(match[3]), 1.0]

  match = /^rgba\(\s*([\d]+)\s*,\s*([\d]+)\s*,\s*([\d]+)\s*,\s*([\d]+)\s*\)/.exec(colorString)
  if match
    return [parseInt(match[1]), parseInt(match[2]), parseInt(match[3]), parseInt(match[4])]

  return null

# Parse a color string as RGBA
parseColor = (colorString) ->
  answer = null

  # Try to use the browser to parse the color for us.
  div = document.createElement('div')
  div.style.color = colorString
  if div.style.color
    answer = parseRgbaColor div.style.color

  if !answer
    match = /^#([\da-fA-F]{2})([\da-fA-F]{2})([\da-fA-F]{2})/.exec(colorString)
    if match then answer = [parseInt(match[1], 16), parseInt(match[2], 16), parseInt(match[3], 16), 1.0]

  if !answer
    match = /^#([\da-fA-F])([\da-fA-F])([\da-fA-F])/.exec(colorString)
    if match then answer = [parseInt(match[1], 16) * 0x11, parseInt(match[2], 16) * 0x11, parseInt(match[3], 16) * 0x11, 1.0]

  if !answer then answer = parseRgbaColor colorString

  return answer

# Convert an RGB or RGBA color to a CSS color.
rgbToColor = (rgb) ->
  if (!3 of rgb) or (rgb[3] == 1.0)
    return "rgb(#{rgb[0]},#{rgb[1]},#{rgb[2]})"
  else
    return "rgba(#{rgb[0]},#{rgb[1]},#{rgb[2]},#{rgb[3]})"

# Adapted from http://axonflux.com/handy-rgb-to-hsl-and-rgb-to-hsv-color-model-c
#
# Converts an RGBA color value to HSLA. Conversion formula
# adapted from http://en.wikipedia.org/wiki/HSL_color_space.
# Assumes r, g, and b are contained in the set [0, 255] and
# a in [0, 1].  Returns h, s, l, a in the set [0, 1].
#
# Returns the HSLA representation as an array.
rgbToHsl = (rgba) ->
  [r,g,b,a] = rgba
  r /= 255
  g /= 255
  b /= 255
  max = Math.max(r, g, b)
  min = Math.min(r, g, b)
  l = (max + min) / 2

  if max == min
    h = s = 0 # achromatic
  else
    d = max - min
    s = if l > 0.5 then d / (2 - max - min) else d / (max + min)
    switch max
      when r then h = (g - b) / d + (g < b ? 6 : 0)
      when g then h = (b - r) / d + 2
      when b then h = (r - g) / d + 4
    h /= 6;

  return [h, s, l, a]

# Adapted from http://axonflux.com/handy-rgb-to-hsl-and-rgb-to-hsv-color-model-c
#
# Converts an HSLA color value to RGBA. Conversion formula
# adapted from http://en.wikipedia.org/wiki/HSL_color_space.
# Assumes h, s, l, and a are contained in the set [0, 1] and
# returns r, g, and b in the set [0, 255] and a in [0, 1].
#
# Retunrs the RGBA representation as an array.
hslToRgb = (hsla) ->
  [h,s,l,a] = hsla
  if s is 0
    r = g = b = l # achromatic
  else
    hue2rgb = (p, q, t) ->
      if(t < 0)   then t += 1
      if(t > 1)   then t -= 1
      if(t < 1/6) then return p + (q - p) * 6 * t
      if(t < 1/2) then return q
      if(t < 2/3) then return p + (q - p) * (2/3 - t) * 6
      return p

    q = if l < 0.5 then l * (1 + s) else l + s - l * s
    p = 2 * l - q;
    r = hue2rgb(p, q, h + 1/3)
    g = hue2rgb(p, q, h)
    b = hue2rgb(p, q, h - 1/3)

  return [Math.round(r * 255), Math.round(g * 255), Math.round(b * 255), a]

