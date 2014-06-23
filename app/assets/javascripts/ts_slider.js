(function($) {

var bindAll = function(self, names) {
    for (var i = 0, name; (name = names[i]); i++) {
        self[name] = self[name].bind(self);
    }
}

var createDiv = function(className, appendTo) {
    return $("<div/>").addClass(className).appendTo(appendTo);
}

var clientX = function(e) {
    e = e.originalEvent.touches ? e.originalEvent.touches[0] : e;
    return e.clientX;
}

function TimeControl($el, options) {
    var self = this;
    this.$el = $el;
    this.options = $.extend({}, options);
    this.sliders = {};
    
    this.first = null;
    this.last = null;
    
    var prev = null;
    $el.children("[data-step]").each(function(i) {
        var step = this.getAttribute("data-step"),
            slider = self.sliders[step] = new TimeSlider(self, options[step], $(this));
        
        if (self.first == null) {
            self.first = slider;
        }
        
        if (prev) {
            slider.prev = prev;
            prev.next = slider;
        }
        prev = slider;
    });
    
    this.last = prev;
}

TimeControl.prototype.values = function() {
    var values = {};
    for (var step in this.sliders) {
        values[step] = this.sliders[step].value;
    }
    return values;
}

function TimeSlider(control, options, $input) {

    bindAll(this, ["dragStart", "dragEnd", "dragMove",
                   "tick", "keyUp", "input"]);
    this.control = control;
    this.options = options;
    this.$input = $input;
    
    this.show = options.show || function(x) { return x + ""; }
    this.read = options.read || function(x) { return parseInt(x, 10); }
    this.changeBase = options.changeBase || 1;
    this.changeTween = options.changeTween || function(x) { return x; }
    this.value = this.at = this.read($input.val());
    this.tilt = 0;
    this.remainder = 0;
    
    this.$outer = createDiv("ticker-nub-outer", control.$el);
    this.$nub = createDiv("ticker-nub", this.$outer);
    this.reposition();
    
    this.$input.on("keyup", this.keyUp).on("blur", this.input);
    this.$outer.on("mousedown touchstart", this.dragStart);
}

TimeSlider.prototype.set = function(val, silent) {
    var lower = this.getOpt("lower"),
        upper = this.getOpt("upper");
    
    if (val < lower) {
        if (this.prev == null) return this.set(lower);
        
        this.prev.changeBy(-1);
        upper = this.getOpt("upper");
        this.set(upper - (lower - val) + 1);
    }
    else if (val > upper) {
        if (this.prev == null) return this.set(upper);
        
        this.prev.changeBy(1);
        lower = this.getOpt("lower");
        this.set(lower + (val - upper) - 1);
    }
    else {
        var decreasing = (val < this.value);
        if (!silent) this.at = val;
        this.value = val;
        this.$input.val(this.show(this.value));
        
        if (this.getOpt("skip", false)) {
            this.changeBy(decreasing ? -1 : 1, silent);
            return;
        }
    }
    // Check that the current value of the next slider is still valid given
    // the value of this slider
    if (this.next != null) this.next.truncate();
}

TimeSlider.prototype.changeBy = function(amount, silent) {
    this.set(this.value + amount, silent);
}

TimeSlider.prototype.tick = function() {
    var change = this.tilt * this.changeBase + this.remainder,
        round = Math.floor(change);
    
    this.remainder = change - round;
    this.changeBy(round);
}

TimeSlider.prototype.truncate = function() {
    var upper = this.getOpt("upper");
    this.set(Math.min(upper, this.at), true);
}

TimeSlider.prototype.getOpt = function(name, defVal) {
    var opt = this.options[name];
    if (opt == null) return defVal;
    
    if (typeof opt == "function") {
        return opt.call(this);
    } else {
        return opt;
    }
}

// Aligns each slider with its input box
TimeSlider.prototype.reposition = function() {
    var $input = this.$input,
        parentCenter = $input.position().left + ($input.outerWidth() / 2),
        outerHalf = this.$outer.outerWidth() / 2,
        nubHalf = this.$nub.outerWidth() / 2;
    this.$outer.css({left: parentCenter - outerHalf});
    this.$nub.css({left: outerHalf - nubHalf});
    
    this.outerLeft = this.$outer.offset().left;
    this.outerHalf = outerHalf;
    this.nubHalf = nubHalf;
}

TimeSlider.prototype.dragStart = function(e) {
    e.preventDefault();
    $(document)
        .on("mouseup touchend", this.dragEnd)
        .on("mousemove touchmove", this.dragMove);
    this.ticker = setInterval(this.tick, 30);
    this.startX = clientX(e);
}

TimeSlider.prototype.dragEnd = function() {
    this.$nub.css({left: this.outerHalf - this.nubHalf});
    $(document)
        .off("mouseup touchend", this.dragEnd)
        .off("mousemove touchmove", this.dragMove);
    this.tilt = 0;
    clearInterval(this.ticker);
    delete this.ticker;
}

TimeSlider.prototype.dragMove = function(e) {
    var pos = clientX(e) - this.outerLeft - this.outerHalf;
    if (pos > this.outerHalf) pos = this.outerHalf;
    if (pos < -this.outerHalf) pos = -this.outerHalf;
    
    this.tilt = pos / this.outerHalf;
    this.tilt = this.changeTween(this.tilt);
    
    this.$nub.css({left: this.outerHalf + pos - this.nubHalf});
}

TimeSlider.prototype.keyUp = function(e) {
    // Enter hit, unfocus input box
    if (e.keyCode == 13) {
        this.$input.blur();
    }
}

TimeSlider.prototype.input = function(e) {
    this.set(this.read(this.$input.val()));
}

$.fn.timeControl = function(options) {
    if (options == null) {
        return this.data("timeControl");
    } else {
        return this.each(function() {
            var $this = $(this),
                control = new TimeControl($this, options);
            $this.data("timeControl", control);
        });
    }
}

})(jQuery);