OSM.Layers = function (map) {
  var page = {},
      layersButton = $(".control-layers .control-button"),
      layers = map.baseLayers,
      miniMaps = [],
      baseLayerSwitchListeners = [];

  layersButton.on("click", function (e) {
    e.preventDefault();
    e.stopPropagation();

    OSM.router.route("/layers");
  });

  function setViewOfMiniMaps(options) {
    miniMaps.forEach(function (miniMap) {
      miniMap.setView(map.getCenter(), Math.max(map.getZoom() - 2, 0), options);
    });
  }

  function initMiniMaps() {
    miniMaps.forEach(function (miniMap) {
      miniMap.invalidateSize();
    });
    setViewOfMiniMaps({ animate: false });
  }

  function updateMiniMaps() {
    setViewOfMiniMaps();
  }

  function toggleDisableOverlayCheckbox(item, disabled) {
    var input = item.find("input");
    input.prop("disabled", disabled);

    if (disabled && input.prop("checked")) {
      input
        .prop("checked", false)
        .data("checked", true)
        .trigger("change");
    } else if (!disabled && input.data("checked")) {
      input
        .prop("checked", true)
        .removeData("checked")
        .trigger("change");
    }

    item
      .attr("class", disabled ? "disabled" : "")
      .tooltip(disabled ? "enable" : "disable");
  }

  function updateDisableOverlayCheckboxes() {
    toggleDisableOverlayCheckbox(
      $("#layers_contents .overlay-layers ul li[data-name=notes]"),
      map.getBounds().getSize() >= OSM.MAX_NOTE_REQUEST_AREA
    );
    toggleDisableOverlayCheckbox(
      $("#layers_contents .overlay-layers ul li[data-name=data]"),
      map.getBounds().getSize() >= OSM.MAX_REQUEST_AREA
    );
  }

  function updateCheckOverlayCheckboxes() {
    $("#layers_contents .overlay-layers ul li[data-name=notes] input")
      .prop("checked", map.hasLayer(map.noteLayer));
    $("#layers_contents .overlay-layers ul li[data-name=data] input")
      .prop("checked", map.hasLayer(map.dataLayer));
    $("#layers_contents .overlay-layers ul li[data-name=gps] input")
      .prop("checked", map.hasLayer(map.gpsLayer));
  }

  page.pushstate = page.popstate = function (path) {
    OSM.loadSidebarContent(path, page.load);
  };

  page.load = function () {
    layersButton.addClass("active");

    var baseLayers = $("#layers_contents .base-layers ul");

    layers.forEach(function (layer) {
      var item = $("<li>")
        .attr("class", "rounded-3")
        .appendTo(baseLayers);

      if (map.hasLayer(layer)) {
        item.addClass("active");
      }

      var div = $("<div>")
        .appendTo(item);

      var miniMap = L.map(div[0], { attributionControl: false, zoomControl: false, keyboard: false })
        .addLayer(new layer.constructor({ apikey: layer.options.apikey }));

      miniMap.dragging.disable();
      miniMap.touchZoom.disable();
      miniMap.doubleClickZoom.disable();
      miniMap.scrollWheelZoom.disable();

      miniMaps.push(miniMap);

      var label = $("<label>")
        .appendTo(item);

      var input = $("<input>")
        .attr("type", "radio")
        .prop("checked", map.hasLayer(layer))
        .appendTo(label);

      label.append(layer.options.name);

      item.on("click", function () {
        layers.forEach(function (other) {
          if (other === layer) {
            map.addLayer(other);
          } else {
            map.removeLayer(other);
          }
        });
        map.fire("baselayerchange", { layer: layer });
      });

      item.on("dblclick", function () {
        OSM.router.route("/" + OSM.formatHash(map));
      });

      var baseLayerSwitchListener = function () {
        item.toggleClass("active", map.hasLayer(layer));
        input.prop("checked", map.hasLayer(layer));
      };
      baseLayerSwitchListeners.push(baseLayerSwitchListener);
      map.on("layeradd layerremove", baseLayerSwitchListener);
    });

    map.whenReady(initMiniMaps);
    map.on("moveend", updateMiniMaps);

    if (OSM.STATUS !== "api_offline" && OSM.STATUS !== "database_offline") {
      $("#layers_contents .overlay-layers ul li input").on("change", function () {
        var checked = $(this).prop("checked"),
            name = $(this).closest("li").attr("data-name"),
            layer;

        if (name === "notes") {
          layer = map.noteLayer;
        } else if (name === "data") {
          layer = map.dataLayer;
        } else if (name === "gps") {
          layer = map.gpsLayer;
        }

        if (layer) {
          if (checked) {
            map.addLayer(layer);
          } else {
            map.removeLayer(layer);
          }
          map.fire("overlaylayerchange", { layer: layer });
        }
      });

      map.on("zoomend", updateDisableOverlayCheckboxes);
      updateDisableOverlayCheckboxes();

      map.on("layeradd layerremove", updateCheckOverlayCheckboxes);
      updateCheckOverlayCheckboxes();
    }
  };

  page.unload = function () {
    if (OSM.STATUS !== "api_offline" && OSM.STATUS !== "database_offline") {
      map.off("layeradd layerremove", updateCheckOverlayCheckboxes);
      map.off("zoomend", updateDisableOverlayCheckboxes);
    }
    map.off("moveend", updateMiniMaps);
    map.off("load", initMiniMaps);

    baseLayerSwitchListeners.forEach(function (baseLayerSwitchListener) {
      map.off("layeradd layerremove", baseLayerSwitchListener);
    });
    baseLayerSwitchListeners = [];
    miniMaps.forEach(function (miniMap) {
      miniMap.remove();
    });
    miniMaps = [];
    layersButton.removeClass("active");
  };

  return page;
};
