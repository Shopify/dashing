class AllTheThings.Widget extends Batman.View
  constructor:  ->
    super

    @mixin($(@node).data())
    AllTheThings.widgets[@id] ||= []
    AllTheThings.widgets[@id].push(@)
    @mixin(AllTheThings.lastEvents[@id]) # in case the events from the server came before the widget was rendered

    type = Batman.Filters.dashize(@view)
    $(@node).addClass("widget #{type} #{@id}")

  onData: (data) =>
    @mixin(data)