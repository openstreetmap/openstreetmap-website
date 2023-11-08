OSM.Layers = function (map) {
  var page = {},
      layersButton = $(".control-layers .control-button"),
      layers = map.baseLayers,
      miniMaps = [];

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

  function toggleDisableOverlayCheckboxes(item, disabled) {
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

  function updateOverlayCheckboxes() {
    toggleDisableOverlayCheckboxes(
      $("#layers_contents .overlay-layers ul li[data-name=notes]"),
      map.getBounds().getSize() >= OSM.MAX_NOTE_REQUEST_AREA
    );
    toggleDisableOverlayCheckboxes(
      $("#layers_contents .overlay-layers ul li[data-name=data]"),
      map.getBounds().getSize() >= OSM.MAX_REQUEST_AREA
    );
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

      map.on("layeradd layerremove", function () {
        item.toggleClass("active", map.hasLayer(layer));
        input.prop("checked", map.hasLayer(layer));
      });
    });

    map.whenReady(initMiniMaps);
    map.on("moveend", updateMiniMaps);

    if (OSM.STATUS !== "api_offline" && OSM.STATUS !== "database_offline") {
      var overlays = $("#layers_contents .overlay-layers ul");

      var addOverlay = function (layer, name) {
        var item = overlays.find("li[data-name='"+ name + "']");

        if (name === "notes" || name === "data") {
          item.tooltip("disable");
        }

        var label = item.find("label");

        var checked = map.hasLayer(layer);

        var input = label.find("input")
          .prop("checked", checked);

        input.on("change", function () {
          checked = input.is(":checked");
          if (checked) {
            map.addLayer(layer);
          } else {
            map.removeLayer(layer);
          }
          map.fire("overlaylayerchange", { layer: layer });
        });

        map.on("layeradd layerremove", function () {
          input.prop("checked", map.hasLayer(layer));
        });
      };

      addOverlay(map.noteLayer, "notes");
      addOverlay(map.dataLayer, "data");
      addOverlay(map.gpsLayer, "gps");

      map.on("zoomend", updateOverlayCheckboxes);
      updateOverlayCheckboxes();
    }
  };

  page.unload = function () {
    if (OSM.STATUS !== "api_offline" && OSM.STATUS !== "database_offline") {
      map.off("zoomend", updateOverlayCheckboxes);
    }
    map.off("moveend", updateMiniMaps);
    map.off("load", initMiniMaps);

    miniMaps.forEach(function (miniMap) {
      miniMap.remove();
    });
    miniMaps = [];
    layersButton.removeClass("active");
  };

  return page;
};
