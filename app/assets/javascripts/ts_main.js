var leapYear = function(year) {
    if (year < 0) year = -year + 1;
    return year % 400 == 0 || (!(year % 100 == 0) && year % 4 == 0);
}

var daysOfMonth = function(month, year) {
    switch (month) {
    case 1: case 3: case 5: case 7: case 8: case 10: case 12:
        return 31;
    
    case 4: case 6: case 9: case 11:
        return 30;
    
    case 2:
        return leapYear(year) ? 29 : 28; 
    }
}

var changeTween = function(x) {
    var tween = Math.pow(Math.abs(x), 2);
    return (x >= 0) ? tween : -tween;
}
$(document).ready( function() {
    console.log("in ts_main, document ready, about to try slider-wrapper");
    $(".slider-wrapper").timeControl({    
    year: {
        lower: -4000,
        upper: 2014,
        changeBase: 10,
        changeTween: changeTween,
        skip: function() { return this.value == 0; },
        show: function() {
            if (this.value >= 0) {
                return this.value + " CE";
            } else {
                return -this.value + " BCE";
            }
        },
        read: function(val) {
            if (val.indexOf("BCE") != -1) {
                return -parseInt(val, 10);
            } else {
                return parseInt(val, 10);
            }
        }
    },
    
    month: {
        lower: 1,
        upper: 12,
        changeTween: changeTween
    },
    
    day: {
        lower: 1,
        upper: function() {
            var year = this.prev.prev.value,
                month = this.prev.value;
            return daysOfMonth(month, year);
        },
        changeTween: changeTween,
        skip: function() {
            var year = this.prev.prev.value,
                month = this.prev.value;
            return year == 1752 && month == 9 &&
                   this.value < 14 && this.value > 2;
        }
    }
});
});