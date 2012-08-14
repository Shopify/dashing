# dashing.js is located in the dashing framework
# It includes jquery & batman for you.
#= require dashing.js

#= require_directory .
#= require_tree ../../widgets

console.log("Yeah! The dashboard has started!")

Dashing.on 'ready', ->
  widget_margins = [5, 5]
  widget_base_dimensions = [240, 330]
  numColumns = 4

  contentWidth = (widget_base_dimensions[0] + widget_margins[0] * 2) * numColumns

  Batman.setImmediate ->
    $('.gridster').width(contentWidth)
    $('.gridster ul:first').gridster
      widget_margins: widget_margins
      widget_base_dimensions: widget_base_dimensions
      avoid_overlapped_widgets: !Dashing.customGridsterLayout
      draggable:
        stop: Dashing.showGridsterInstructions
