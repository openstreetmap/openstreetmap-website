//= require leaflet.locatecontrol/dist/L.Control.Locate.umd

L.OSM.locate = function (options) {
  const control = L.control.locate({
    strings: {
      title: OSM.i18n.t("javascripts.map.geolocate_control.find_my_location"),
      popup: function (options) {
        return OSM.i18n.t("javascripts.map.geolocate_control." + options.unit + "Popup", { count: options.distance });
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
      .addClass("control-button")
      .empty()
      .append($("<i>").addClass("fs-5 bi bi-cursor-fill"));
    return container;
  };

  return control;
};
