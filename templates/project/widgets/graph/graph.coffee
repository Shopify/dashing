class Dashing.Graph extends Dashing.Widget

  @accessor 'current', ->
    points = @get('points')
    if points
      points[points.length - 1].y

  ready: ->
    @graph = new Rickshaw.Graph(
      element: @node
      width: $(@node).parent().width()
      series: [
        {
        color: "#fff",
        data: [{ x: 0, y: 0}]
        }
      ]
    )
    x_axis = new Rickshaw.Graph.Axis.Time(graph: @graph)
    @graph.render()

  onData: (data) ->
    super
    if @graph
      @graph.series[0].data = data.points
      @graph.render()
