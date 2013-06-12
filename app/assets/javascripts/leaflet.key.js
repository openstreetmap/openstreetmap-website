L.OSM.Key = L.Control.extend({
  onAdd: function (map) {
    this._map = map;
    this._initLayout();
    return this.$container[0];
  },

  _initLayout: function () {
    var map = this._map;

    this.$container = $('<div>')
      .attr('class', 'control-key');

    var link = $('<a>')
      .attr('class', 'control-button')
      .attr('href', '#')
      .attr('title', 'Map Key')
      .html('<span class="icon key"></span>')
      .appendTo(this.$container);
  }
});

L.OSM.key = function(options) {
  return new L.OSM.Key(options);
};
