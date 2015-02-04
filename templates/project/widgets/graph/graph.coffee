class Dashing.Graph extends Dashing.Widget

  @accessor 'current', ->
    return @get('displayedValue') if @get('displayedValue')
    points = @get('points')
    if points
      points[points.length - 1].y

  ready: ->
    container = $(@node).parent()
    # Gross hacks. Let's fix this.
    width = (Dashing.widget_base_dimensions[0] * container.data("sizex")) + Dashing.widget_margins[0] * 2 * (container.data("sizex") - 1)
    height = (Dashing.widget_base_dimensions[1] * container.data("sizey"))

    y_scale_type = @get("yscale")

    # If log scale is requested or required, we need to know the range to populate the axis
    min = Number.MAX_VALUE
    max = Number.MIN_VALUE
    data = [ {x:0, y:0} ]
    data = @get('points') if @get('points')

    for d in data
       min = Math.min(min, d.y)
       max = Math.max(max, d.y)

    if (!y_scale_type)
       if ((min>0 && max>0 && max/min>500) || (min<0 && max<0 && min/max>500))
          y_scale_type = 'log'
       else
          y_scale_type = 'linear'

    if y_scale_type.match ///log(?:\(((?:\d+(?:\.\d+)?)|e)\))?///
       y_base=RegExp.$1 || 10
       (y_base=="e") && (y_base=Math.E)
       y_scale=d3.scale.log().base(y_base).domain([min, max])
       log_y_scale_base=Math.log(y_scale.base())
       tickValues=[]
       for p in [Math.ceil(Math.log(min)/log_y_scale_base)..Math.floor(Math.log(max)/log_y_scale_base)] by 1
           tickValues.push(Math.pow(y_base,p))
    else
       y_scale=d3.scale.linear()
       tickValues=null

    @graph = new Rickshaw.Graph(
      element: @node
      width: width
      height: height
      renderer: @get("graphtype")
      series: [
        {
        color: "#fff",
        data: data
        scale: y_scale
        }
      ]
    )

    @graph.series[0].data = @get('points') if @get('points')

    x_axis = new Rickshaw.Graph.Axis.Time(graph: @graph, timeFixture: new Rickshaw.Fixtures.Time.Local())
    y_axis = new Rickshaw.Graph.Axis.Y.Scaled(graph: @graph, tickFormat: Rickshaw.Fixtures.Number.formatKMBT, scale:y_scale, tickValues: tickValues)
    @graph.render()

  onData: (data) ->
    if @graph
      @graph.series[0].data = data.points
      @graph.render()
