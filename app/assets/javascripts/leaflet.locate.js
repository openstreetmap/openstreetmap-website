L.OSM.locate = function (options) {
  const control = L.control.locate({
    icon: "icon geolocate",
    iconLoading: "icon geolocate",
    strings: {
      title: OSM.i18n.t("javascripts.map.locate.title"),
      popup: function (options) {
        return OSM.i18n.t("javascripts.map.locate." + options.unit + "Popup", { count: options.distance });
      }
    },
    ...options
  });

  control.onAdd = function (map) {
    const container = Object.getPrototypeOf(this).onAdd.apply(this, [map]);
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
