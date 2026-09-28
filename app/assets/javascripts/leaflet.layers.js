//= require @maptiler/maplibre-gl-omt-language
//= require maplibre/map
//= require maplibre/i18n

L.OSM.layers = function (options) {
  const control = L.OSM.sidebarPane(options, "layers", "javascripts.map.layers.title", "javascripts.map.layers.header");

  control.onAddPane = function (map, button, $ui, toggle) {
    const layers = options.layers;

    control.onContentLoaded = function () {
      $ui.find(".base-layers>div").each(initBaseLayer);
      initOverlays();
    };
    control.loadContent();

    function initBaseLayer() {
      const [container, input, item] = this.children;
      const layer = layers.find(l => l.options.layerId === container.dataset.layer);
      input.checked = map.hasLayer(layer);

      map.whenReady(function () {
        let miniMap;
        $ui
          .on("show", shown)
          .on("hide", hide);

        function shown() {
          const center = map.getCenter();
          try {
            miniMap = new OSM.MapLibre.Map({
              container,
              style: layer.options.style,
              interactive: false,
              attributionControl: false,
              fadeDuration: 0,
              zoomSnap: layer.options.isVectorStyle ? 0 : 1,
              center: [center.lng, center.lat],
              zoom: getZoomForMiniMap()
            });
          } catch (error) {
            return;
          }

          if (layer.options.layerId === "openmaptiles_osm") {
            OSM.MapLibre.setOMTMapLanguage(miniMap);
          }

          map.on("moveend", moved);
        }

        function hide() {
          // miniMap can be falsy if webgl is not supported
          if (miniMap) {
            map.off("moveend", moved);
            miniMap.remove();
          }
        }

        function moved() {
          const center = map.getCenter();
          const zoom = getZoomForMiniMap();
          miniMap.easeTo({ center: [center.lng, center.lat], zoom });
        }

        function getZoomForMiniMap() {
          return Math.max(Math.floor(map.getZoom() - 3), -1);
        }
      });

      $(input).on("click", function () {
        for (const other of layers) {
          if (other !== layer) {
            map.removeLayer(other);
          }
        }
        map.addLayer(layer);
      });

      $(item).on("dblclick", toggle);

      map.on("baselayerchange", function () {
        input.checked = map.hasLayer(layer);
      });
    }

    function initOverlays() {
      $ui.find(".overlay-layers div.form-check").each(function () {
        const item = this;
        const layer = map[this.dataset.layerId];
        const input = this.firstElementChild.firstElementChild;
        $(item).tooltip("disable");

        function updateOverlay() {
          input.checked = map.hasLayer(layer);
          input.disabled = map.getBounds().getSize() >= item.dataset.maxArea && !input.checked;

          item.classList.toggle("disabled", input.disabled);
          $(item).tooltip(input.disabled ? "enable" : "disable");
        }

        $(input).on("change", function () {
          layer.cancelLoading?.();

          if (input.checked) {
            map.addLayer(layer);
          } else {
            map.removeLayer(layer);
            $(`#layers-${name}-loading`).remove();
          }
        });

        map.on("zoomend overlayadd overlayremove", updateOverlay);
        updateOverlay();
      });
    }
  };

  return control;
};
