L.OSM.layers = function (options) {
  const control = L.OSM.sidebarPane(options, "layers", "javascripts.map.layers.title", "javascripts.map.layers.header");

  control.onAddPane = function (map, button, $ui, toggle) {
    const layers = options.layers;

    const baseSection = $("<div>")
      .attr("class", "base-layers d-grid gap-3 p-3 border-bottom border-secondary-subtle")
      .appendTo($ui);

    layers.forEach(function (layer, i) {
      const id = "map-ui-layer-" + i;

      const buttonContainer = $("<div class='position-relative'>")
        .appendTo(baseSection);

      const mapContainer = $("<div class='position-absolute top-0 start-0 bottom-0 end-0 z-0 bg-body-secondary'>")
        .appendTo(buttonContainer);

      const input = $("<input type='radio' class='btn-check' name='layer'>")
        .prop("id", id)
        .prop("checked", map.hasLayer(layer))
        .appendTo(buttonContainer);

      const item = $("<label class='btn btn-outline-primary border-4 rounded-3 bg-transparent position-absolute p-0 h-100 w-100 overflow-hidden'>")
        .prop("for", id)
        .append($("<span class='badge position-absolute top-0 start-0 rounded-top-0 rounded-start-0 py-1 px-2 bg-body bg-opacity-75 text-body text-wrap text-start fs-6 lh-base'>").append(layer.options.name))
        .appendTo(buttonContainer);

      map.whenReady(function () {
        const miniMap = L.map(mapContainer[0], { attributionControl: false, zoomControl: false, keyboard: false })
          .addLayer(new layer.constructor(layer.options));

        miniMap.dragging.disable();
        miniMap.touchZoom.disable();
        miniMap.doubleClickZoom.disable();
        miniMap.scrollWheelZoom.disable();

        $ui
          .on("show", shown)
          .on("hide", hide);

        function shown() {
          miniMap.invalidateSize();
          setView({ animate: false });
          map.on("moveend", moved);
        }

        function hide() {
          map.off("moveend", moved);
        }

        function moved() {
          setView();
        }

        function setView(options) {
          miniMap.setView(map.getCenter(), Math.max(map.getZoom() - 2, 0), options);
        }
      });

      input.on("click", function () {
        for (const other of layers) {
          if (other !== layer) {
            map.removeLayer(other);
          }
        }
        map.addLayer(layer);
      });

      item.on("dblclick", toggle);

      map.on("baselayerchange", function () {
        input.prop("checked", map.hasLayer(layer));
      });
    });

    if (OSM.STATUS !== "api_offline" && OSM.STATUS !== "database_offline") {
      const overlaySection = $("<div>")
        .attr("class", "overlay-layers p-3")
        .appendTo($ui);

      $("<p>")
        .text(OSM.i18n.t("javascripts.map.layers.overlays"))
        .attr("class", "text-body-secondary small mb-2")
        .appendTo(overlaySection);

      const overlays = $("<ul class='list-unstyled form-check'>")
        .appendTo(overlaySection);

      const addOverlay = function (layer, name, maxArea) {
        const item = $("<li>")
          .appendTo(overlays);

        if (name === "notes" || name === "data") {
          item
            .attr("title", OSM.i18n.t("javascripts.site.map_" + name + "_zoom_in_tooltip"))
            .tooltip("disable");
        }

        const label = $("<label>")
          .attr("class", "form-check-label")
          .attr("id", `label-layers-${name}`)
          .appendTo(item);

        let checked = map.hasLayer(layer);

        const input = $("<input>")
          .attr("type", "checkbox")
          .attr("class", "form-check-input")
          .prop("checked", checked)
          .appendTo(label);

        label.append(OSM.i18n.t("javascripts.map.layers." + name));

        input.on("change", function () {
          checked = input.is(":checked");
          if (layer.cancelLoading) {
            layer.cancelLoading();
          }

          if (checked) {
            map.addLayer(layer);
          } else {
            map.removeLayer(layer);
            $(`#layers-${name}-loading`).remove();
          }
        });

        map.on("overlayadd overlayremove", function () {
          input.prop("checked", map.hasLayer(layer));
        });

        map.on("zoomend", function () {
          const disabled = map.getBounds().getSize() >= maxArea;
          $(input).prop("disabled", disabled);

          if (disabled && $(input).is(":checked")) {
            $(input).prop("checked", false)
              .trigger("change");
            checked = true;
          } else if (!disabled && !$(input).is(":checked") && checked) {
            $(input).prop("checked", true)
              .trigger("change");
          }

          $(item)
            .attr("class", disabled ? "disabled" : "")
            .tooltip(disabled ? "enable" : "disable");
        });
      };

      addOverlay(map.noteLayer, "notes", OSM.MAX_NOTE_REQUEST_AREA);
      addOverlay(map.dataLayer, "data", OSM.MAX_REQUEST_AREA);
      addOverlay(map.gpsLayer, "gps", Number.POSITIVE_INFINITY);
    }
  };

  return control;
};
