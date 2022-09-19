L.OSM.locate = function (options) {
  var control = L.control.locate(Object.assign({
    icon: "icon geolocate",
    iconLoading: "icon geolocate",
    strings: {
      title: I18n.t("javascripts.map.locate.title"),
      popup: function (options) {
        return I18n.t("javascripts.map.locate." + options.unit + "Popup", { count: options.distance });
      }
    }
  }, options));

  control.onAdd = function (map) {
    var container = Object.getPrototypeOf(this).onAdd.apply(this, [map]);
    $(container)
      .removeClass("leaflet-control-locate leaflet-bar")
      .addClass("control-locate")
      .children("a")
      .attr("href", "#")
      .removeClass("leaflet-bar-part leaflet-bar-part-single")
      .addClass("control-button");
    return container;
  };

  return control;
};
