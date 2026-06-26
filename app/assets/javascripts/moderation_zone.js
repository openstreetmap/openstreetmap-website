//= require maplibre/map
//= require terra-draw/dist/terra-draw.umd
//= require terra-draw-maplibre-gl-adapter/dist/terra-draw-maplibre-gl-adapter.umd

/* globals terraDraw, terraDrawMaplibreGlAdapter */

$(function () {
  const COORDINATES_FIELD_ID = "moderation_zone_zone";
  const SELECT_MODE_OPTIONS = {
    flags: {
      polygon: {
        feature: {
          draggable: false,

          // Individual coordinates that make up the Feature...
          coordinates: {
            // Midpoint be added
            midpoints: {
              // Midpoint be dragged
              draggable: true
            },

            // Can be moved
            draggable: true,

            // Can snap to other coordinates from geometries _of the same mode_
            snappable: true,

            // Allow resizing of the geometry from a given origin.
            // center will allow resizing of the aspect ratio from the center
            // and opposite allows resizing from the opposite corner of the
            // bounding box of the geometry.
            resizable: false,

            // Can be deleted
            deletable: true
          }
        }
      }
    }
  };

  const baseMap = new OSM.MapLibre.SecondaryMap();

  baseMap.once("style.load", () => {
    try {
      const draw = createTerraDrawInstance(baseMap);
      draw.on("finish", createTerraDrawFinishHandler(draw));
      loadData(baseMap, draw);
      setupMapStyleSelector(baseMap);
    } catch (e) {
      // MapLibre is swallowing these exceptions silently, so I had
      // to add this to know why my code was failing as I went.
      console.error(e); // eslint-disable-line no-console
      throw e;
    }
  });

  function createTerraDrawInstance(map) {
    return new terraDraw.TerraDraw({
      adapter: new terraDrawMaplibreGlAdapter.TerraDrawMapLibreGLAdapter({
        map,
        lib: maplibregl
      }),
      modes: [
        new terraDraw.TerraDrawPolygonMode(),
        new terraDraw.TerraDrawSelectMode(SELECT_MODE_OPTIONS)
      ]
    });
  }

  function createTerraDrawFinishHandler(draw) {
    return function (id, { mode, action }) {
      if (mode === "polygon") {
        draw.setMode("select");
      } else if (mode === "select") {
        // Nothing to do
      } else {
        throw new Error(`Unexpected mode "${mode}" (action: "${action}")`);
      }

      const feature = draw.getSnapshotFeature(id);
      if (!feature) {
        throw new Error(`Could not find feature with id ${id}`);
      }

      writeFormField(COORDINATES_FIELD_ID, feature);
    };
  }

  function loadData(map, draw) {
    const feature = readFormField(COORDINATES_FIELD_ID);
    if (feature) {
      startTerraDrawForEdit(draw, feature);
      map.fitBounds(featureToBox(feature), { radius: 100 });
    } else {
      startTerraDrawForNew(draw);
    }
  }

  function readFormField(fieldId) {
    const target = document.getElementById(fieldId);
    if (!target) {
      throw new Error(`Could not find field with id ${fieldId}`);
    }

    const re = /[0-9-][ 0-9.,-]+/;
    const match = re.exec(target.value);
    if (!match) {
      return null;
    }

    const coordinatesString = match[0];
    const pointStrings = coordinatesString.split(",").map(s => s.trim());
    const points = pointStrings.map(s => s.split(" ")).map(pairs => pairs.map(parseFloat));
    return {
      type: "Feature",
      geometry: {
        type: "Polygon",
        coordinates: [points]
      },
      properties: {
        mode: "polygon"
      }
    };
  }

  function startTerraDrawForEdit(draw, feature) {
    draw.start();
    draw.setMode("polygon");
    const results = draw.addFeatures([feature]);
    const invalidFeatures = [];
    results.forEach(r => {
      if (!r.valid) {
        invalidFeatures.push(r);
      }
    });
    if (invalidFeatures.length > 0) {
      const invalidFeaturesString = invalidFeatures.map(JSON.stringify).join("\n");
      throw new Error(`Failed to load features into TerraDraw:\n${invalidFeaturesString}`);
    }
    draw.setMode("select");
  }

  function startTerraDrawForNew(draw) {
    draw.start();
    draw.setMode("polygon");
  }

  function writeFormField(fieldId, feature) {
    const coordinatesString = feature.geometry.coordinates[0]
      .map(([lon, lat]) => `${lon} ${lat}`)
      .join(",\n");
    const target = document.getElementById(fieldId);
    target.value = `POLYGON((\n${coordinatesString}\n))`;
  }

  function featureToBox(feature) {
    const points = feature.geometry.coordinates[0];
    const seed = new maplibregl.LngLatBounds(points[0], points[0]);
    return points.reduce((bounds, point) => bounds.extend(point), seed);
  }

  function setupMapStyleSelector(map) {
    $("#map_style").on("change", function (evt) {
      const desiredLayerName = evt.target.value;
      const desiredLayer = OSM.LAYER_DEFINITIONS.find(def => def.layerId === desiredLayerName);
      map.setStyle(desiredLayer.style, { transformStyle: transformStyleWorkaround });
    });
  }

  // Known issue with MapLibre that affects TerraDraw. This is a workaround
  // as described at https://github.com/JamesLMilner/terra-draw/issues/590#issuecomment-3923366056
  function transformStyleWorkaround(previousStyle, nextStyle) {
    const terraDrawPrefix = "td-";

    const previousLayers = previousStyle && Array.isArray(previousStyle.layers) ? previousStyle.layers : [];
    const nextLayers = nextStyle && Array.isArray(nextStyle.layers) ? nextStyle.layers : [];

    const terraDrawLayers = previousLayers.filter((layer) => {
      return typeof layer?.id === "string" && layer.id.startsWith(terraDrawPrefix);
    });

    // Ensure Terra Draw layers end up on top by appending them at the end,
    // and avoid duplicates if the incoming style already has td-* layers.
    const nextLayersWithoutTerraDraw = nextLayers.filter((layer) => {
      return typeof layer?.id !== "string" || !layer.id.startsWith(terraDrawPrefix);
    });

    const mergedLayers = [...nextLayersWithoutTerraDraw, ...terraDrawLayers];

    // Carry over Terra Draw sources from the previous style
    const nextSources = nextStyle?.sources ?? {};
    const previousSources = previousStyle?.sources ?? {};

    const mergedSources = { ...nextSources };

    for (const [sourceId, sourceValue] of Object.entries(previousSources)) {
      if (sourceId.startsWith(terraDrawPrefix)) {
        mergedSources[sourceId] = sourceValue;
      }
    }

    return {
      ...nextStyle,
      sources: mergedSources,
      layers: mergedLayers
    };
  }
});
