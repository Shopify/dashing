Dashing.remoteViewURL = "http://localhost:8000"

loadCSS = (url) ->
  link = document.createElement('link')
  link.type = 'text/css'
  link.rel = 'stylesheet'
  link.href = url
  document.getElementsByTagName('head')[0].appendChild(link)

$ ->
  $("[data-remoteview]").each (index, node) ->
    type = node.getAttribute('data-remoteview')
    name = type.toLowerCase()
    path = Batman.URI.encodeComponent("#{Dashing.remoteViewURL}/#{name}/#{name}")
    loadCSS("remote_views/#{path}.scss")
    require ["remote_views/#{path}.coffee?="], ->
      _viewPrefix = Batman.config.viewPrefix
      Batman.config.viewPrefix = 'remote_views'

      new Dashing[type]
        source: Batman.URI.encodeComponent("#{path}")
        node: node
        view: type
      Batman.config.viewPrefix = _viewPrefix

