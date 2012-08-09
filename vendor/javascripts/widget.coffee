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


  @::on 'ready', ->
    Dashing.Widget.fire 'ready'

  onData: (data) =>
    @mixin(data)