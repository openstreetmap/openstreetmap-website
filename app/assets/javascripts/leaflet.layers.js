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
        const miniMap = new OSM.MapLibre.Map({
          container,
          style: layer.options.style,
          interactive: false,
          attributionControl: false,
          fadeDuration: 0,
          zoomSnap: layer.options.isVectorStyle ? 0 : 1
        });

        if (layer.options.layerId === "openmaptiles_osm") {
          OSM.MapLibre.setOMTMapLanguage(miniMap);
        }

        $ui
          .on("show", shown)
          .on("hide", hide);

        function shown() {
          miniMap.resize();
          setView(false);
          map.on("moveend", moved);
        }

        function hide() {
          map.off("moveend", moved);
        }

        function moved() {
          setView();
        }

        function setView(animate = true) {
          const center = map.getCenter();
          const zoom = Math.max(Math.floor(map.getZoom() - 3), -1);
          if (animate) {
            miniMap.easeTo({ center: [center.lng, center.lat], zoom });
          } else {
            miniMap.jumpTo({ center: [center.lng, center.lat], zoom });
          }
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

        let checked = map.hasLayer(layer);

        input.checked = checked;

        $(input).on("change", function () {
          checked = input.checked;
          layer.cancelLoading?.();

          if (checked) {
            map.addLayer(layer);
          } else {
            map.removeLayer(layer);
            $(`#layers-${name}-loading`).remove();
          }
        });

        map.on("overlayadd overlayremove", function () {
          input.checked = map.hasLayer(layer);
        });

        map.on("zoomend", function () {
          const disabled = map.getBounds().getSize() >= item.dataset.maxArea;
          input.disabled = disabled;

          if (disabled && input.checked) {
            input.click();
            checked = true;
          } else if (!disabled && !input.checked && checked) {
            input.click();
          }

          item.classList.toggle("disabled", disabled);
          $(item).tooltip(disabled ? "enable" : "disable");
        });
      });
    }
  };

  return control;
};
