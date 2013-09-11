Graphing Widget
===============

The graphing widget shows graphs using the Rickshaw graphing library.  The names of data fields
should be (vaguely) familiar if you've used Rickshaw before.

Supported HTML data fields
--------------------------

* `data-title`: Title to display.
* `data-displayed-value`: If provided, then the value to display overtop of the graph.  If not
  provided, then the most recent value will be used if there is only one series.
* `data-renderer`: Any valid Rickshaw renderer, including 'area', 'line', 'bar', 'scatterplot'.
* `data-stroke`: If "true", then area graphs will be drawn with a stroke.
* `data-unstack`: If "true", then area and bar graphs will be "unstacked".
* `data-colors`: A ":" separated list of colors to use for each plot.  If there are fewer colors
  provided than there are series to graph, then pleasing colors will be automatically chosen.  (e.g.:
  `data-colors="#ccc:#ddd:#eee"`)
* `data-stroke-colors`: A ":" separated list of colors to use for strokes.
* `data-legend`: If "true", then a legend will be added to your graph.
* `data-summary-method` determines how the value shown in the graph is computed.  If
  `data-displayed-value` is set, this is ignored.  Otherwise this should be one of:
  * "last" - Default - If there is only one series, show the most recent value from that series.
  * "sum" - Sum of all values across all series.
  * "sumLast" - Sum of last values across all series.
  * "highest" - For stacked graphs, the highest single data point based on the sum of all series.
    For unstacked graphs, the highest single data point of any series.

Passing Data
------------

Data can be provided in a number of formats.  Data can be passed as a series of points:

    points = [{x:1, y: 4}, {x:2, y:27}, {x:3, y:6}]
    send_event('convergence', points: points)

Note that the `x` values are interpreted as unix timestamps.  Data can also be passed as full-on
Rickshaw-style series:

    series = [
        {
            name: "Convergence",
            data: [{x:1, y: 4}, {x:2, y:27}, {x:3, y:6}]
        },
        {
            name: "Divergence",
            data: [{x:1, y: 5}, {x:2, y:2}, {x:3, y:9}]
        }
    ]
    send_event('convergence', series: series)

You can even provide colors and strokes here, which will override the values defined in the HTML.
Or data can be passed as Graphite-style data:

    graphite = [
      {
        target: "stats_counts.http.ok",
        datapoints: [[10, 1378449600], [40, 1378452000], [53, 1378454400], [63, 1378456800], [27, 1378459200]]
      },
      {
        target: "stats_counts.http.err",
        datapoints: [[0, 1378449600], [4, 1378452000], [nil, 1378454400], [3, 1378456800], [0, 1378459200]]
      }
    ]
    send_event('http', series: graphite)

You can even send data as JSON strings, straight from Graphite:

    require "rest-client"
    SCHEDULER.every '10s', :first_in => 0 do
        target = "aliasSub(summarize(stats_counts.http.*%2C%2720min%27)%2C%27%5E.*http.(%5Cw*).*%27%2C%27%5C1%27)"
        url = "http://graphteserver.local:8000/render?format=json&target=#{target}&from=today"
        graphite_json_data = RestClient.get url
        send_event 'http_counts', { series: graphite_json_data }
    end
