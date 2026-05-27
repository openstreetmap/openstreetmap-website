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
          coordinates: {
            midpoints: { draggable: true },
            draggable: true,
            snappable: true,
            deletable: true,

            // Disallow resizing of the geometry from a given origin.
            resizable: false
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
});
