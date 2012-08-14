/*
 * jquery.draggable
 * https://github.com/ducksboard/gridster.js
 *
 * Copyright (c) 2012 ducksboard
 * Licensed under the MIT licenses.
 */

;(function($, window, document, undefined){

    var defaults = {
        items: '.gs_w',
        distance: 1,
        limit: true,
        offset_left: 0,
        autoscroll: true
        // ,drag: function(e){},
        // start : function(e, ui){},
        // stop : function(e){}
    };

    var $window = $(window);
    var isTouch = !!('ontouchstart' in window);
    var pointer_events = {
        start: isTouch ? 'touchstart' : 'mousedown.draggable',
        move: isTouch ? 'touchmove' : 'mousemove.draggable',
        end: isTouch ? 'touchend' : 'mouseup.draggable'
    };

    /**
    * Basic drag implementation for DOM elements inside a container.
    * Provide start/stop/drag callbacks.
    *
    * @class Draggable
    * @param {HTMLElement} el The HTMLelement that contains all the widgets
    *  to be dragged.
    * @param {Object} [options] An Object with all options you want to
    *        overwrite:
    *    @param {HTMLElement|String} [options.items] Define who will
    *     be the draggable items. Can be a CSS Selector String or a
    *     collection of HTMLElements.
    *    @param {Number} [options.distance] Distance in pixels after mousedown
    *     the mouse must move before dragging should start.
    *    @param {Boolean} [options.limit] Constrains dragging to the width of
    *     the container
    *    @param {offset_left} [options.offset_left] Offset added to the item
    *     that is being dragged.
    *    @param {Number} [options.drag] Executes a callback when the mouse is
    *     moved during the dragging.
    *    @param {Number} [options.start] Executes a callback when the drag
    *     starts.
    *    @param {Number} [options.stop] Executes a callback when the drag stops.
    * @return {Object} Returns `el`.
    * @constructor
    */
    function Draggable(el, options) {
      this.options = $.extend({}, defaults, options);
      this.$body = $(document.body);
      this.$container = $(el);
      this.$dragitems = $(this.options.items, this.$container);
      this.is_dragging = false;
      this.player_min_left = 0 + this.options.offset_left;
      this.init();
    }

    var fn = Draggable.prototype;

    fn.init = function() {
        this.calculate_positions();
        this.$container.css('position', 'relative');
        this.enable();

        $(window).bind('resize',
            throttle($.proxy(this.calculate_positions, this), 200));
    };


    fn.get_actual_pos = function($el) {
        var pos = $el.position();
        return pos;
    };


    fn.get_mouse_pos = function(e) {
        if (isTouch) {
            var oe = e.originalEvent;
            e = oe.touches.length ? oe.touches[0] : oe.changedTouches[0];
        };

        return {
            left: e.clientX,
            top: e.clientY
        };
    };


    fn.get_offset = function(e) {
        e.preventDefault();
        var mouse_actual_pos = this.get_mouse_pos(e);
        var diff_x = Math.round(
            mouse_actual_pos.left - this.mouse_init_pos.left);
        var diff_y = Math.round(mouse_actual_pos.top - this.mouse_init_pos.top);

        var left = Math.round(this.el_init_offset.left + diff_x - this.baseX);
        var top = Math.round(
            this.el_init_offset.top + diff_y - this.baseY + this.scrollOffset);

        if (this.options.limit) {
            if (left > this.player_max_left) {
                left = this.player_max_left;
            }else if(left < this.player_min_left) {
                left = this.player_min_left;
            }
        }

        return {
            left: left,
            top: top,
            mouse_left: mouse_actual_pos.left,
            mouse_top: mouse_actual_pos.top
        };
    };


    fn.manage_scroll = function(offset) {
        /* scroll document */
        var nextScrollTop;
        var scrollTop = $window.scrollTop();
        var min_window_y = scrollTop;
        var max_window_y = min_window_y + this.window_height;

        var mouse_down_zone = max_window_y - 50;
        var mouse_up_zone = min_window_y + 50;

        var abs_mouse_left = offset.mouse_left;
        var abs_mouse_top = min_window_y + offset.mouse_top;

        var max_player_y = (this.doc_height - this.window_height +
            this.player_height);

        if (abs_mouse_top >= mouse_down_zone) {
            nextScrollTop = scrollTop + 30;
            if (nextScrollTop < max_player_y) {
                $window.scrollTop(nextScrollTop);
                this.scrollOffset = this.scrollOffset + 30;
            }
        };

        if (abs_mouse_top <= mouse_up_zone) {
            nextScrollTop = scrollTop - 30;
            if (nextScrollTop > 0) {
                $window.scrollTop(nextScrollTop);
                this.scrollOffset = this.scrollOffset - 30;
            }
        };
    }


    fn.calculate_positions = function(e) {
        this.window_height = $window.height();
    }


    fn.drag_handler = function(e) {
        var node = e.target.nodeName;

        if (e.which !== 1 && !isTouch) {
            return;
        }

        if (node === 'INPUT' || node === 'TEXTAREA' || node === 'SELECT' ||
            node === 'BUTTON') {
            return;
        };

        var self = this;
        var first = true;
        this.$player = $(e.currentTarget);

        this.el_init_pos = this.get_actual_pos(this.$player);
        this.mouse_init_pos = this.get_mouse_pos(e);
        this.offsetY = this.mouse_init_pos.top - this.el_init_pos.top;

        this.$body.on(pointer_events.move, function(mme){
            var mouse_actual_pos = self.get_mouse_pos(mme);
            var diff_x = Math.abs(
                mouse_actual_pos.left - self.mouse_init_pos.left);
            var diff_y = Math.abs(
                mouse_actual_pos.top - self.mouse_init_pos.top);
            if (!(diff_x > self.options.distance ||
                diff_y > self.options.distance)
            ) {
                return false;
            }

            if (first) {
                first = false;
                self.on_dragstart.call(self, mme);
                return false;
            }

            if (self.is_dragging == true) {
                self.on_dragmove.call(self, mme);
            }

            return false;
        });
    };


    fn.on_dragstart = function(e) {
        e.preventDefault();
        this.drag_start = true;
        this.is_dragging = true;
        var offset = this.$container.offset();
        this.baseX = Math.round(offset.left);
        this.baseY = Math.round(offset.top);
        this.doc_height = $(document).height();

        if (this.options.helper === 'clone') {
            this.$helper = this.$player.clone()
                .appendTo(this.$container).addClass('helper');
            this.helper = true;
        }else{
            this.helper = false;
        }
        this.scrollOffset = 0;
        this.el_init_offset = this.$player.offset();
        this.player_width = this.$player.width();
        this.player_height = this.$player.height();
        this.player_max_left = (this.$container.width() - this.player_width +
            this.options.offset_left);

        if (this.options.start) {
            this.options.start.call(this.$player, e, {
                helper: this.helper ? this.$helper : this.$player
            });
        }
        return false;
    };


    fn.on_dragmove = function(e) {
        var offset = this.get_offset(e);

        this.options.autoscroll && this.manage_scroll(offset);

        (this.helper ? this.$helper : this.$player).css({
            'position': 'absolute',
            'left' : offset.left,
            'top' : offset.top
        });

        var ui = {
            'position': {
                'left': offset.left,
                'top': offset.top
            }
        };

        if (this.options.drag) {
            this.options.drag.call(this.$player, e, ui);
        }
        return false;
    };


    fn.on_dragstop = function(e) {
        var offset = this.get_offset(e);
        this.drag_start = false;

        var ui = {
            'position': {
                'left': offset.left,
                'top': offset.top
            }
        };

        if (this.options.stop) {
            this.options.stop.call(this.$player, e, ui);
        }

        if (this.helper) {
            this.$helper.remove();
        }

        return false;
    };


    fn.enable = function(){
        this.$container.on(pointer_events.start, this.options.items, $.proxy(
            this.drag_handler, this));

        this.$body.on(pointer_events.end, $.proxy(function(e) {
            this.is_dragging = false;
            this.$body.off(pointer_events.move);
            if (this.drag_start) {
                this.on_dragstop(e);
            }
        }, this));
    };


    fn.disable = function(){
        this.$container.off(pointer_events.start);
        this.$body.off(pointer_events.end);
    };


    fn.destroy = function(){
        this.disable();
        $.removeData(this.$container, 'draggable');
    };


    //jQuery adapter
    $.fn.drag = function ( options ) {
        return this.each(function () {
            if (!$.data(this, 'drag')) {
                $.data(this, 'drag', new Draggable( this, options ));
            }
        });
    };


}(jQuery, window, document));
