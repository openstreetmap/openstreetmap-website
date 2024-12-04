/* extends ohmVectorStyles defined in ohm.style.js */

const spriteSheetUrls_Original = {
  "production": "https://openhistoricalmap.github.io/map-styles/ohm_timeslider_tegola/ohm_spritezero_spritesheet-production",
  "staging": "https://openhistoricalmap.github.io/map-styles/ohm_timeslider_tegola/ohm_spritezero_spritesheet",
};

ohmVectorStyles.Original = {
  "version": 8,
  "name": "ohmbasemap",
  "metadata": { "maputnik:renderer": "mbgljs" },
  "sources": {
    "osm": {
      "type": "vector",
      "tiles": [
        "https://vtiles.staging.openhistoricalmap.org/maps/osm/{z}/{x}/{y}.pbf"
      ]
    },
    "ohm_landcover_hillshade": {
      "type": "raster",
      "tiles": [
        "https://static-tiles-lclu.s3.us-west-1.amazonaws.com/{z}/{x}/{y}.png"
      ],
      "minzoom": 0,
      "maxzoom": 8,
      "tileSize": 256
    },
    "ne": {
      "type": "vector",
      "tiles": [
        "https://vtiles.staging.openhistoricalmap.org/maps/ne/{z}/{x}/{y}.pbf"
      ]
    }
  },
  "sprite": "https://openhistoricalmap.github.io/map-styles/main/main_spritesheet",
  "glyphs": "https://openhistoricalmap.github.io/map-styles/fonts/{fontstack}/{range}.pbf",
  "layers": [
    {
      "id": "background",
      "type": "background",
      "minzoom": 0,
      "maxzoom": 20,
      "filter": ["all"],
      "layout": { "visibility": "visible" },
      "paint": {
        "background-color": [
          "interpolate",
          ["linear"],
          ["zoom"],
          0,
          "rgba(185, 228, 228, 1)",
          10,
          "rgba(126, 218, 218, 1)"
        ]
      }
    },
    {
      "id": "land",
      "type": "fill",
      "source": "osm",
      "source-layer": "land",
      "minzoom": 0,
      "maxzoom": 24,
      "layout": { "visibility": "visible" },
      "paint": { "fill-color": "rgba(255, 255, 255, 1)" }
    },
    {
      "id": "landuse_areas_earth",
      "type": "fill",
      "source": "osm",
      "source-layer": "landuse_areas",
      "minzoom": 0,
      "maxzoom": 24,
      "filter": ["==", ["get", "type"], "earth"],
      "layout": { "visibility": "visible" },
      "paint": { "fill-color": "rgba(248, 247, 242, 1)" }
    },
    {
      "id": "ohm_landcover_hillshade",
      "type": "raster",
      "source": "ohm_landcover_hillshade",
      "maxzoom": 24,
      "layout": { "visibility": "visible" },
      "paint": {
        "raster-opacity": [
          "interpolate",
          ["linear"],
          ["zoom"],
          0,
          1,
          4,
          1,
          8,
          0
        ]
      }
    },
    {
      "id": "landuse_areas_military_overlay",
      "type": "fill",
      "source": "osm",
      "source-layer": "landuse_areas",
      "minzoom": 10,
      "maxzoom": 24,
      "filter": ["==", ["get", "type"], "military"],
      "layout": { "visibility": "visible" },
      "paint": {
        "fill-color": "rgba(178, 194, 157, 1)",
        "fill-antialias": false,
        "fill-pattern": "military-fill"
      }
    },
    {
      "id": "military_landuselow",
      "type": "fill",
      "source": "osm",
      "source-layer": "landuse_areas",
      "minzoom": 4,
      "maxzoom": 10,
      "filter": ["==", ["get", "type"], "military"],
      "layout": { "visibility": "visible" },
      "paint": { "fill-color": "rgba(230, 224, 212, 1)" }
    },
    {
      "id": "military-landusehigh",
      "type": "fill",
      "source": "osm",
      "source-layer": "landuse_areas",
      "minzoom": 10,
      "maxzoom": 24,
      "filter": ["==", ["get", "type"], "military"],
      "layout": { "visibility": "visible" },
      "paint": { "fill-color": "rgba(244, 244, 235, 1)" }
    },
    {
      "id": "military",
      "type": "fill",
      "source": "osm",
      "source-layer": "other_areas",
      "filter": ["==", ["get", "class"], "military"],
      "layout": { "visibility": "visible" },
      "paint": { "fill-color": "rgba(244, 244, 235, 1)" }
    },
    {
      "id": "airports",
      "type": "fill",
      "source": "osm",
      "source-layer": "transport_areas",
      "minzoom": 12,
      "maxzoom": 24,
      "filter": ["==", ["get", "type"], "apron"],
      "layout": { "visibility": "visible" },
      "paint": { "fill-color": "rgba(221, 221, 221, 1)" }
    },
    {
      "id": "landuse_areas_allz",
      "type": "fill",
      "source": "osm",
      "source-layer": "landuse_areas",
      "minzoom": 0,
      "maxzoom": 24,
      "filter": ["in", ["get", "type"], ["literal", ["forest", "nature_reserve", "park", "wood"]]],
      "layout": { "visibility": "visible" },
      "paint": {
        "fill-color": [
          "interpolate",
          ["linear"],
          ["zoom"],
          0,
          "rgba(192, 201, 173, 1)",
          4,
          "rgba(188, 193, 179, 1)",
          5,
          "rgba(203, 214, 183, 1)",
          7,
          "rgba(220, 232, 194, 1)"
        ],
        "fill-opacity": 1
      }
    },
    {
      "id": "landuse_areas_z12_generalized_land_use",
      "type": "fill",
      "source": "osm",
      "source-layer": "landuse_areas",
      "minzoom": 12,
      "maxzoom": 24,
      "layout": { "visibility": "visible" },
      "paint": {
        "fill-color": [
          "interpolate",
          ["linear"],
          ["zoom"],
          0,
          [
            "match",
            ["get", "type"],
            "residential",
            "rgba(241, 238, 238, 1)",
            "retail",
            "rgba(237, 236, 231, 1)",
            "industrial",
            "rgba(245, 230, 230, 1)",
            "transparent"
          ]
        ]
      }
    },
    {
      "id": "landuse_areas_z12_underlying_land_designation",
      "type": "fill",
      "source": "osm",
      "source-layer": "landuse_areas",
      "minzoom": 12,
      "maxzoom": 24,
      "layout": { "visibility": "visible" },
      "paint": {
        "fill-color": [
          "interpolate",
          ["linear"],
          ["zoom"],
          0,
          [
            "match",
            ["get", "type"],
            "park",
            "rgba(208, 220, 174, 1)",
            "nature_reserve",
            "rgba(212, 225, 211, 0.3)",
            "pitch",
            "rgba(69, 150, 7, 0.39)",
            "transparent"
          ]
        ]
      }
    },
    {
      "id": "landuse_areas_z12_localized_land_use",
      "type": "fill",
      "source": "osm",
      "source-layer": "landuse_areas",
      "minzoom": 12,
      "maxzoom": 24,
      "layout": { "visibility": "visible" },
      "paint": {
        "fill-color": [
          "interpolate",
          ["linear"],
          ["zoom"],
          0,
          [
            "match",
            ["get", "type"],
            "quarry",
            "rgba(215, 200, 203, 1)",
            "landfill",
            "rgba(194, 170, 175, 1)",
            "brownfield",
            "rgba(191, 171, 142, 1)",
            "commercial",
            "rgba(245, 237, 231, 1)",
            "construction",
            "rgba(242, 242, 235, 1)",
            "railway",
            "rgba(224, 224, 224, 1)",
            "college",
            "rgba(226, 214, 205, 1)",
            "school",
            "rgba(226, 214, 205, 1)",
            "education",
            "rgba(226, 214, 205, 1)",
            "university",
            "rgba(226, 214, 205, 1)",
            "transparent"
          ]
        ]
      }
    },
    {
      "id": "landuse_areas_z12_landcover_short",
      "type": "fill",
      "source": "osm",
      "source-layer": "landuse_areas",
      "minzoom": 12,
      "maxzoom": 24,
      "layout": { "visibility": "visible" },
      "paint": {
        "fill-color": [
          "interpolate",
          ["linear"],
          ["zoom"],
          0,
          [
            "match",
            ["get", "type"],
            "heath",
            "rgba(225, 233, 214, 1)",
            "meadow",
            "rgba(225, 233, 214, 1)",
            "grass",
            "rgba(208, 220, 174, 1)",
            "grassland",
            "rgba(223, 234, 178, 0.81)",
            "beach",
            "rgba(236, 235, 180, 1)",
            "desert",
            "rgba(238, 229, 178, 1)",
            "basin",
            "rgba(144, 204, 203, 1)",
            "wetland",
            "rgba(227, 233, 226, 1)",
            "salt_pond",
            "rgba(236, 240, 241, 1)",
            "mud",
            "rgba(230, 223, 215, 1)",
            "transparent"
          ]
        ]
      }
    },
    {
      "id": "landuse_areas_z12_park_outlines",
      "type": "line",
      "source": "osm",
      "source-layer": "landuse_areas",
      "minzoom": 12,
      "maxzoom": 24,
      "filter": ["==", ["get", "type"], "park"],
      "layout": { "visibility": "visible" },
      "paint": {
        "line-width": ["interpolate", ["linear"], ["zoom"], 12, 0.75, 16, 1.25],
        "line-color": "rgba(200, 210, 163, 1)"
      }
    },
    {
      "id": "landuse_areas_z12_landcover_tall",
      "type": "fill",
      "source": "osm",
      "source-layer": "landuse_areas",
      "minzoom": 12,
      "maxzoom": 24,
      "filter": ["all"],
      "layout": { "visibility": "visible" },
      "paint": {
        "fill-color": [
          "interpolate",
          ["linear"],
          ["zoom"],
          0,
          [
            "match",
            ["get", "type"],
            "forest",
            "rgba(193, 208, 158, 1)",
            "wood",
            "#C1D09E",
            "scrub",
            "rgba(199, 222, 194, 1)",
            "transparent"
          ]
        ]
      }
    },
    {
      "id": "landuse_areas_z12_watercover",
      "type": "fill",
      "source": "osm",
      "source-layer": "landuse_areas",
      "minzoom": 9,
      "maxzoom": 24,
      "layout": { "visibility": "visible" },
      "paint": {
        "fill-color": [
          "interpolate",
          ["linear"],
          ["zoom"],
          0,
          [
            "match",
            ["get", "type"],
            "wetland",
            "rgba(216, 229, 230, 1)",
            "salt_pond",
            "rgba(236, 240, 241, 1)",
            "glacier",
            "rgba(219, 244, 249, 1)",
            "reservoir",
            "rgba(144, 204, 203, 1)",
            "transparent"
          ]
        ]
      }
    },
    {
      "id": "landuse_areas_z12_glacier-outline",
      "type": "line",
      "source": "osm",
      "source-layer": "landuse_areas",
      "minzoom": 9,
      "maxzoom": 24,
      "filter": ["==", ["get", "type"], "glacier"],
      "layout": { "visibility": "visible" },
      "paint": {
        "line-color": "rgba(180, 211, 218, 1)",
        "line-dasharray": [2, 2],
        "line-width": ["interpolate", ["linear"], ["zoom"], 9, 1, 14, 1.5]
      }
    },
    {
      "id": "landuse_areas_z12_food_and_farming",
      "type": "fill",
      "source": "osm",
      "source-layer": "landuse_areas",
      "minzoom": 12,
      "maxzoom": 24,
      "layout": { "visibility": "visible" },
      "paint": {
        "fill-color": [
          "interpolate",
          ["linear"],
          ["zoom"],
          0,
          [
            "match",
            ["get", "type"],
            "farmland",
            "rgba(239, 234, 182, 0.61)",
            "farm",
            "rgba(239, 234, 182, 0.61)",
            "orchard",
            "rgba(218, 241, 184, 1)",
            "farmyard",
            "rgba(239, 234, 182, 0.61)",
            "vineyard",
            "rgba(180, 172, 199, 1)",
            "allotments",
            "rgba(222, 221, 190, 1)",
            "garden",
            "rgba(228, 244, 202, 1)",
            "transparent"
          ]
        ]
      }
    },
    {
      "id": "landuse_areas_z12_developed_open_space",
      "type": "fill",
      "source": "osm",
      "source-layer": "landuse_areas",
      "minzoom": 12,
      "maxzoom": 24,
      "layout": { "visibility": "visible" },
      "paint": {
        "fill-color": [
          "interpolate",
          ["linear"],
          ["zoom"],
          0,
          [
            "match",
            ["get", "type"],
            "village_green",
            "rgba(208, 220, 174, 1)",
            "cemetery",
            "rgba(214, 222, 210, 1)",
            "grave_yard",
            "rgba(214, 222, 210, 1)",
            "sports_centre",
            "rgba(208, 220, 174, 1)",
            "stadium",
            "rgba(208, 220, 174, 1)",
            "recreation_ground",
            "rgba(208, 220, 174, 1)",
            "picnic_site",
            "rgba(208, 220, 174, 1)",
            "camp_site",
            "rgba(208, 220, 174, 1)",
            "playground",
            "rgba(208, 220, 174, 1)",
            "bleachers",
            "rgba(220, 215, 215, 1)",
            "transparent"
          ]
        ],
        "fill-outline-color": [
          "interpolate",
          ["linear"],
          ["zoom"],
          0,
          [
            "match",
            ["get", "type"],
            "bleachers",
            "rgba(195, 188, 188, 1)",
            "playground",
            "rgba(208, 220, 174, 1)",
            "transparent"
          ]
        ]
      }
    },
    {
      "id": "wetlands_z12",
      "type": "fill",
      "source": "osm",
      "source-layer": "landuse_areas",
      "minzoom": 9,
      "maxzoom": 24,
      "filter": ["==", ["get", "type"], "wetland"],
      "layout": { "visibility": "visible" },
      "paint": {
        "fill-color": "rgba(255, 255, 255, 1)",
        "fill-pattern": "wetland-18"
      }
    },
    {
      "id": "parking_lots",
      "type": "fill",
      "source": "osm",
      "source-layer": "amenity_areas",
      "paint": {
        "fill-color": "rgba(236, 231, 231, 1)",
        "fill-outline-color": "rgba(224, 217, 217, 1)"
      }
    },
    {
      "id": "landuse_naturereserveoutline",
      "type": "line",
      "source": "osm",
      "source-layer": "landuse_areas",
      "minzoom": 10,
      "maxzoom": 24,
      "filter": ["==", ["get", "type"], "nature_reserve"],
      "layout": { "visibility": "visible" },
      "paint": {
        "line-width": ["interpolate", ["linear"], ["zoom"], 10, 2, 20, 3],
        "line-dasharray": [2.5, 1.5],
        "line-color": "rgba(195, 203, 179, 1)"
      }
    },
    {
      "id": "landuse_areas_z12_natural",
      "type": "fill",
      "source": "osm",
      "source-layer": "landuse_areas",
      "minzoom": 12,
      "maxzoom": 24,
      "filter": ["in", ["get", "type"], ["literal", ["bare_rock", "peak", "rock", "scree"]]],
      "layout": { "visibility": "visible" },
      "paint": { "fill-color": "rgba(255, 255, 255, 1)", "fill-pattern": "rock" }
    },
    {
      "id": "place_areas_plot",
      "type": "fill",
      "source": "osm",
      "source-layer": "place_areas",
      "filter": ["==", ["get", "type"], "plot"],
      "layout": { "visibility": "visible" },
      "paint": {
        "fill-color": "rgba(238, 236, 230, 0)",
        "fill-outline-color": "rgba(226, 223, 215, 1)"
      }
    },
    {
      "id": "place_areas_square",
      "type": "fill",
      "source": "osm",
      "source-layer": "place_areas",
      "filter": ["==", ["get", "type"], "square"],
      "layout": { "visibility": "visible" },
      "paint": {
        "fill-color": "rgba(238, 236, 230, 1)",
        "fill-outline-color": "rgba(226, 223, 215, 1)"
      }
    },
    {
      "id": "pedestrian_area",
      "type": "fill",
      "source": "osm",
      "source-layer": "transport_areas",
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["footway", "pedestrian"]]],
        ["==", ["get", "area"], "yes"]
      ],
      "paint": {
        "fill-color": "rgba(234,234,234, 1)",
        "fill-outline-color": "rgba(230,230,230, 1)"
      }
    },
    {
      "id": "amenity_areas",
      "type": "fill",
      "source": "osm",
      "source-layer": "amenity_areas",
      "filter": ["in", ["get", "type"], ["literal", ["school", "university"]]],
      "layout": { "visibility": "visible" },
      "paint": { "fill-color": "rgba(226, 214, 205, 1)" }
    },
    {
      "id": "water_areas",
      "type": "fill",
      "source": "osm",
      "source-layer": "water_areas",
      "minzoom": 8,
      "maxzoom": 24,
      "layout": { "visibility": "visible" },
      "paint": {
        "fill-color": [
          "interpolate",
          ["linear"],
          ["zoom"],
          0,
          "rgba(185, 228, 228, 1)",
          10,
          "rgba(126, 218, 218, 1)"
        ]
      }
    },
    {
      "id": "water_areas-ne",
      "type": "fill",
      "source": "ne",
      "source-layer": "water_areas",
      "minzoom": 0,
      "maxzoom": 8,
      "layout": { "visibility": "visible" },
      "paint": {
        "fill-color": [
          "interpolate",
          ["linear"],
          ["zoom"],
          0,
          "rgba(185, 228, 228, 1)",
          10,
          "rgba(126, 218, 218, 1)"
        ]
      }
    },
    {
      "id": "ferry_lines",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "filter": ["==", ["get", "type"], "ferry"],
      "paint": {
        "line-color": "rgba(115, 191, 191, 1)",
        "line-width": ["interpolate", ["linear"], ["zoom"], 10, 1, 20, 3],
        "line-dasharray": [
          "step",
          ["zoom"],
          ["literal", [2, 1]],
          15,
          ["literal", [4, 1.25]],
          16,
          ["literal", [6, 1.5]],
          17,
          ["literal", [10, 1.75]],
          18,
          ["literal", [16, 2]]
        ]
      }
    },
    {
      "id": "place_areas_islet",
      "type": "fill",
      "source": "osm",
      "source-layer": "place_areas",
      "filter": ["==", ["get", "type"], "islet"],
      "layout": { "visibility": "visible" },
      "paint": {
        "fill-color": "rgba(248, 247, 242, 1)",
        "fill-outline-color": "rgba(226, 223, 215, 1)"
      }
    },
    {
      "id": "water_lines_stream_no_name",
      "type": "line",
      "source": "osm",
      "source-layer": "water_lines",
      "minzoom": 14,
      "maxzoom": 24,
      "filter": [
        "all",
        ["==", ["get", "type"], "stream"],
        ["in", ["get", "name"], ["literal", [""]]]
      ],
      "paint": {
        "line-color": "#7EDADA",
        "line-width": ["interpolate", ["linear"], ["zoom"], 14, 1, 15, 2, 20, 4]
      }
    },
    {
      "id": "water_lines_stream_name",
      "type": "line",
      "source": "osm",
      "source-layer": "water_lines",
      "minzoom": 12,
      "maxzoom": 24,
      "filter": [
        "all",
        ["==", ["get", "type"], "stream"],
        ["!", ["in", "name", ""]]
      ],
      "paint": {
        "line-color": "#7EDADA",
        "line-width": [
          "interpolate",
          ["linear"],
          ["zoom"],
          12,
          0.75,
          13,
          1.25,
          15,
          3,
          20,
          5
        ]
      }
    },
    {
      "id": "water_lines_cliff_line",
      "type": "line",
      "source": "osm",
      "source-layer": "water_lines",
      "minzoom": 15,
      "maxzoom": 24,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["cliff"]]],
        ["!", ["in", "surface", "water"]]
      ],
      "layout": {
        "line-cap": "butt",
        "line-join": "miter",
        "visibility": "visible"
      },
      "paint": {
        "line-color": "rgba(153, 153, 153, 1)",
        "line-translate-anchor": "viewport",
        "line-width": 2
      }
    },
    {
      "id": "water_lines_cliff_line_triangles",
      "type": "line",
      "source": "osm",
      "source-layer": "water_lines",
      "minzoom": 15,
      "maxzoom": 24,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["cliff"]]],
        ["!", ["in", "surface", "water"]]
      ],
      "layout": {
        "line-cap": "butt",
        "line-join": "miter",
        "visibility": "visible"
      },
      "paint": {
        "line-color": "rgba(153, 153, 153, 1)",
        "line-translate-anchor": "viewport",
        "line-width": 3,
        "line-pattern": "cliff-8",
        "line-offset": 2
      }
    },
    {
      "id": "water_lines_waterfall_triangle",
      "type": "line",
      "source": "osm",
      "source-layer": "water_lines",
      "minzoom": 15,
      "maxzoom": 24,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["cliff"]]],
        ["in", ["get", "surface"], ["literal", ["water"]]]
      ],
      "layout": {
        "line-cap": "butt",
        "line-join": "miter",
        "visibility": "visible"
      },
      "paint": {
        "line-color": "rgba(68, 136, 136, 1)",
        "line-translate-anchor": "viewport",
        "line-width": 5,
        "line-offset": 0,
        "line-pattern": "waterfall-8"
      }
    },
    {
      "id": "water_lines_ditch",
      "type": "line",
      "source": "osm",
      "source-layer": "water_lines",
      "minzoom": 15,
      "maxzoom": 24,
      "filter": ["in", ["get", "type"], ["literal", ["ditch", "drain"]]],
      "paint": {
        "line-color": "rgba(144, 204, 203, 1)",
        "line-width": ["interpolate", ["linear"], ["zoom"], 15, 0.2, 20, 1.5]
      }
    },
    {
      "id": "water_lines_canal-casing",
      "type": "line",
      "source": "osm",
      "source-layer": "water_lines",
      "minzoom": 12,
      "maxzoom": 24,
      "filter": ["==", ["get", "type"], "canal"],
      "layout": { "visibility": "visible" },
      "paint": {
        "line-color": "rgba(111, 145, 160, 1)",
        "line-width": [
          "interpolate",
          ["linear"],
          ["zoom"],
          13,
          0.5,
          14,
          2,
          20,
          3
        ],
        "line-gap-width": 4,
        "line-dasharray": [1, 1]
      }
    },
    {
      "id": "water_lines_canal",
      "type": "line",
      "source": "osm",
      "source-layer": "water_lines",
      "minzoom": 8,
      "maxzoom": 24,
      "filter": ["==", ["get", "type"], "canal"],
      "layout": { "visibility": "visible" },
      "paint": {
        "line-color": "rgba(153, 201, 222, 1)",
        "line-width": [
          "interpolate",
          ["linear"],
          ["zoom"],
          8,
          1,
          13,
          2,
          14,
          3,
          20,
          4
        ]
      }
    },
    {
      "id": "water_lines_aqueduct",
      "type": "line",
      "source": "osm",
      "source-layer": "water_lines",
      "minzoom": 8,
      "maxzoom": 24,
      "filter": [
        "all",
        ["==", ["get", "type"], "canal"],
        ["==", ["get", "bridge"], "aqueduct"]
      ],
      "paint": {
        "line-color": "rgba(108, 178, 176, 1)",
        "line-width": [
          "interpolate",
          ["linear"],
          ["zoom"],
          8,
          0.5,
          13,
          0.5,
          14,
          1,
          20,
          3
        ],
        "line-dasharray": [2, 2]
      }
    },
    {
      "id": "water_lines_river",
      "type": "line",
      "source": "osm",
      "source-layer": "water_lines",
      "minzoom": 8,
      "maxzoom": 24,
      "filter": ["==", ["get", "type"], "river"],
      "paint": {
        "line-color": [
          "interpolate",
          ["linear"],
          ["zoom"],
          0,
          "#B9E4E4",
          10,
          "rgba(126, 218, 218, 1)"
        ],
        "line-width": [
          "interpolate",
          ["linear"],
          ["zoom"],
          8,
          1,
          13,
          2,
          14,
          5,
          20,
          12
        ]
      }
    },
    {
      "id": "water_lines_breakwater",
      "type": "line",
      "source": "osm",
      "source-layer": "other_lines",
      "minzoom": 10,
      "maxzoom": 24,
      "filter": ["in", ["get", "type"], ["literal", ["breakwater", "quay"]]],
      "paint": {
        "line-color": "rgba(133, 133, 133, 1)",
        "line-width": ["interpolate", ["linear"], ["zoom"], 14, 1, 20, 4]
      }
    },
    {
      "id": "water_lines_dam",
      "type": "line",
      "source": "osm",
      "source-layer": "water_lines",
      "minzoom": 13,
      "maxzoom": 24,
      "filter": ["==", ["get", "type"], "dam"],
      "paint": {
        "line-color": "rgba(133, 133, 133, 1)",
        "line-width": [
          "interpolate",
          ["linear"],
          ["zoom"],
          13,
          0.5,
          15,
          0.8,
          20,
          2
        ]
      }
    },
    {
      "id": "pier",
      "type": "fill",
      "source": "osm",
      "source-layer": "other_areas",
      "filter": ["==", ["get", "type"], "pier"],
      "layout": { "visibility": "visible" },
      "paint": { "fill-color": "rgba(240, 233, 219, 1)" }
    },
    {
      "id": "pier_line",
      "type": "line",
      "source": "osm",
      "source-layer": "other_lines",
      "minzoom": 12,
      "filter": ["==", ["get", "type"], "pier"],
      "layout": { "visibility": "visible" },
      "paint": {
        "line-color": "rgba(230, 222, 205, 1)",
        "line-width": ["interpolate", ["linear"], ["zoom"], 12, 2, 18, 7]
      }
    },
    {
      "id": "buildings_flat",
      "type": "fill",
      "source": "osm",
      "source-layer": "buildings",
      "minzoom": 14,
      "maxzoom": 24,
      "filter": ["all"],
      "layout": { "visibility": "visible" },
      "paint": {
        "fill-color": "rgba(224, 224, 224, 1)",
        "fill-outline-color": "rgba(208, 200, 200, 1)"
      }
    },
    {
      "id": "buildings_flat_ruins",
      "type": "fill",
      "source": "osm",
      "source-layer": "other_areas",
      "minzoom": 14,
      "maxzoom": 24,
      "filter": [
        "all",
        ["==", ["get", "class"], "historic"],
        ["==", ["get", "type"], "ruins"]
      ],
      "layout": { "visibility": "visible" },
      "paint": { "fill-color": "rgba(224, 224, 224, 1)" }
    },
    {
      "id": "buildings_ruins_outlines",
      "type": "line",
      "source": "osm",
      "source-layer": "other_areas",
      "filter": ["==", ["get", "type"], "ruins"],
      "layout": { "visibility": "visible" },
      "paint": {
        "line-color": "rgba(195, 188, 188, 1)",
        "line-opacity": 1,
        "line-width": ["interpolate", ["linear"], ["zoom"], 10, 1, 16, 2],
        "line-dasharray": [
          "step",
          ["zoom"],
          ["literal", [1, 1]],
          16,
          ["literal", [4, 2]]
        ]
      }
    },
    {
      "id": "historic_fort",
      "type": "fill",
      "source": "osm",
      "source-layer": "other_areas",
      "minzoom": 14,
      "maxzoom": 24,
      "filter": [
        "all",
        ["==", ["get", "class"], "historic"],
        ["==", ["get", "type"], "fort"]
      ],
      "layout": { "visibility": "visible" },
      "paint": {
        "fill-color": "rgba(220, 215, 215, 1)",
        "fill-outline-color": "rgba(195, 188, 188, 1)"
      }
    },
    {
      "id": "aero_heliport_area",
      "type": "fill",
      "source": "osm",
      "source-layer": "transport_areas",
      "minzoom": 14,
      "maxzoom": 24,
      "filter": ["==", ["get", "type"], "helipad"],
      "layout": { "visibility": "visible" },
      "paint": {
        "fill-color": "rgba(240, 240, 240, 1)",
        "fill-outline-color": "rgba(214, 212, 212, 1)"
      }
    },
    {
      "id": "aero_taxiway_lines",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 12,
      "maxzoom": 24,
      "filter": ["==", ["get", "type"], "taxiway"],
      "layout": { "visibility": "visible" },
      "paint": {
        "line-color": "rgba(220, 220, 220, 1)",
        "line-width": [
          "interpolate",
          ["linear"],
          ["zoom"],
          12,
          1,
          13,
          1.5,
          18,
          4
        ]
      }
    },
    {
      "id": "aero_runway_lines",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 12,
      "maxzoom": 24,
      "filter": ["==", ["get", "type"], "runway"],
      "layout": { "visibility": "visible" },
      "paint": {
        "line-color": "rgba(220, 220, 220, 1)",
        "line-width": ["interpolate", ["linear"], ["zoom"], 12, 1.5, 18, 25]
      }
    },
    {
      "id": "man_made_bridge_area",
      "type": "fill",
      "source": "osm",
      "source-layer": "other_areas",
      "filter": [
        "all",
        ["==", ["get", "class"], "man_made"],
        ["==", ["get", "type"], "bridge"]
      ],
      "paint": { "fill-color": "rgba(255, 255, 255, 1)" }
    },
    {
      "id": "man_made_bridge_line",
      "type": "line",
      "source": "osm",
      "source-layer": "other_lines",
      "filter": [
        "all",
        ["==", ["get", "class"], "man_made"],
        ["==", ["get", "type"], "bridge"]
      ],
      "paint": { "line-color": "rgba(255, 255, 255, 1)", "line-width": 3}
    },
    {
      "id": "roads_subways_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 14,
      "filter": [
        "all",
        ["==", ["get", "type"], "construction"],
        ["==", ["get", "construction"], "subway"]
      ],
      "layout": { "visibility": "visible" },
      "paint": {
        "line-color": "rgba(153, 153, 153, 1)",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          11,
          0.5,
          18,
          4
        ],
        "line-dasharray": [4, 1]
      }
    },
    {
      "id": "roads_tertiarytunnel_case_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 9,
      "filter": [
        "all",
        ["==", ["get", "type"], "construction"],
        ["==", ["get", "tunnel"], 1],
        ["==", ["get", "construction"], "tertiary"]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(210, 210, 213, 1)",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          9,
          1,
          18,
          36
        ],
        "line-dasharray": [0.5, 1.25]
      }
    },
    {
      "id": "roads_secondarytunnel_case_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 8,
      "filter": [
        "all",
        ["==", ["get", "type"], "construction"],
        ["==", ["get", "tunnel"], 1],
        ["==", ["get", "construction"], "secondary"]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(210, 210, 213, 1)",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          8,
          1,
          18,
          38
        ],
        "line-dasharray": [0.5, 1.25]
      }
    },
    {
      "id": "roads_primarytunnel_case_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 7,
      "maxzoom": 20,
      "filter": [
        "all",
        ["==", ["get", "type"], "construction"],
        ["==", ["get", "tunnel"], 1],
        ["==", ["get", "construction"], "primary"]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(250, 178, 107, 1)",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          7,
          1,
          18,
          42
        ],
        "line-dasharray": [0.5, 1.25]
      }
    },
    {
      "id": "roads_motorwaytunnel_case_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 5,
      "maxzoom": 20,
      "filter": [
        "all",
        ["==", ["get", "type"], "construction"],
        ["==", ["get", "tunnel"], 1],
        ["in", ["get", "construction"], ["literal", ["motorway", "motorway_link", "trunk", "trunk_link"]]]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(230, 143, 124, 1)",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          5,
          1,
          18,
          46
        ],
        "line-dasharray": [0.5, 1.25]
      }
    },
    {
      "id": "roads_tertiarytunnel_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 9,
      "filter": [
        "all",
        ["==", ["get", "type"], "construction"],
        ["==", ["get", "tunnel"], 1],
        ["==", ["get", "construction"], "tertiary"]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(245, 245, 245, 0.6)",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          9,
          0.8,
          18,
          24
        ]
      }
    },
    {
      "id": "roads_secondarytunnel_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 8,
      "filter": [
        "all",
        ["==", ["get", "type"], "construction"],
        ["==", ["get", "tunnel"], 1],
        ["==", ["get", "construction"], "secondary"]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(245, 245, 245, 0.6)",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          8,
          0.5,
          18,
          30
        ]
      }
    },
    {
      "id": "roads_primarytunnel_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 6,
      "filter": [
        "all",
        ["==", ["get", "type"], "construction"],
        ["==", ["get", "tunnel"], 1],
        ["==", ["get", "construction"], "primary"]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(241, 218, 187, 0.6)",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          6,
          0.75,
          18,
          32
        ]
      }
    },
    {
      "id": "roads_motorwaytunnel_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 5,
      "maxzoom": 20,
      "filter": [
        "all",
        ["==", ["get", "type"], "construction"],
        ["==", ["get", "tunnel"], 1],
        ["in", ["get", "construction"], ["literal", ["motorway", "motorway_link", "trunk", "trunk_link"]]]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(240, 197, 188, 0.6)",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          5,
          1,
          18,
          36
        ]
      }
    },
    {
      "id": "roads_raceways_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 12,
      "maxzoom": 24,
      "filter": [
        "all",
        ["==", ["get", "type"], "construction"],
        ["==", ["get", "construction"], "raceway"]
      ],
      "layout": { "visibility": "visible" },
      "paint": {
        "line-color": "rgba(255, 249, 241, 1)",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          11,
          0.2,
          18,
          12
        ],
        "line-dasharray": [0.75, 0.1]
      }
    },
    {
      "id": "roads_trackfillcase_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 14,
      "maxzoom": 24,
      "filter": [
        "all",
        ["==", ["get", "type"], "construction"],
        ["==", ["get", "construction"], "track"]
      ],
      "layout": { "visibility": "visible" },
      "paint": {
        "line-color": "#b3b3b3",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          11,
          0.5,
          18,
          12
        ]
      }
    },
    {
      "id": "roads_trackfill_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 14,
      "maxzoom": 24,
      "filter": [
        "all",
        ["==", ["get", "type"], "construction"],
        ["==", ["get", "construction"], "track"]
      ],
      "layout": { "visibility": "visible" },
      "paint": {
        "line-color": "rgba(251, 247, 245, 1)",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          11,
          0.5,
          18,
          4
        ]
      }
    },
    {
      "id": "roads_track_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 14,
      "maxzoom": 24,
      "filter": [
        "all",
        ["==", ["get", "type"], "construction"],
        ["==", ["get", "construction"], "track"]
      ],
      "layout": { "visibility": "visible" },
      "paint": {
        "line-color": "#b3b3b3",
        "line-dasharray": [0.3, 1],
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          11,
          0.5,
          18,
          8
        ]
      }
    },
    {
      "id": "roads_living_street_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 14,
      "maxzoom": 24,
      "filter": [
        "all",
        ["==", ["get", "type"], "construction"],
        ["==", ["get", "construction"], "living_street"]
      ],
      "layout": { "visibility": "visible" },
      "paint": {
        "line-color": "rgba(255, 255, 255, 1)",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          11,
          0.2,
          18,
          6
        ]
      }
    },
    {
      "id": "roads_pedestrian_street_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 14,
      "maxzoom": 24,
      "filter": [
        "all",
        ["==", ["get", "type"], "construction"],
        ["==", ["get", "construction"], "pedestrian"]
      ],
      "layout": { "visibility": "visible" },
      "paint": {
        "line-color": "#ffffff",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          11,
          0.2,
          18,
          6
        ]
      }
    },
    {
      "id": "roads_footway_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 14,
      "maxzoom": 24,
      "filter": [
        "all",
        ["==", ["get", "type"], "construction"],
        ["in", ["get", "construction"], ["literal", ["cycleway", "footway", "path"]]]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "square",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(225, 225, 225, 1)",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          11,
          0.2,
          18,
          3
        ],
        "line-dasharray": [2, 1]
      }
    },
    {
      "id": "roads_pier_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 14,
      "maxzoom": 24,
      "filter": [
        "all",
        ["==", ["get", "type"], "construction"],
        ["==", ["get", "construction"], "pier"]
      ],
      "layout": { "visibility": "visible" },
      "paint": {
        "line-color": "#ffffff",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          11,
          0.5,
          18,
          12
        ]
      }
    },
    {
      "id": "roads_steps_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 14,
      "maxzoom": 24,
      "filter": [
        "all",
        ["==", ["get", "type"], "construction"],
        ["==", ["get", "construction"], "steps"]
      ],
      "layout": { "visibility": "visible" },
      "paint": {
        "line-color": "#b3b3b3",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          11,
          0.5,
          18,
          6
        ],
        "line-dasharray": [0.1, 0.3]
      }
    },
    {
      "id": "roads_roadscase_z13_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 13,
      "maxzoom": 24,
      "filter": [
        "all",
        ["==", ["get", "type"], "construction"],
        ["==", ["get", "bridge"], 0],
        ["==", ["get", "construction"], "road"]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(210, 210, 213, 1)",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          13,
          3,
          18,
          15
        ]
      }
    },
    {
      "id": "roads_residentialcase_z13_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 13,
      "maxzoom": 24,
      "filter": [
        "all",
        ["==", ["get", "type"], "construction"],
        ["==", ["get", "bridge"], 0],
        ["in", ["get", "construction"], ["literal", ["residential", "service", "unclassified"]]]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(210, 210, 213, 1)",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          13,
          4,
          18,
          18
        ]
      }
    },
    {
      "id": "roads_tertiary-case_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 10.01,
      "maxzoom": 24,
      "filter": [
        "all",
        ["==", ["get", "type"], "construction"],
        ["!=", ["get", "tunnel"], 1],
        ["==", ["get", "construction"], "tertiary"],
        ["!=", ["get", "bridge"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(210, 210, 213, 1)",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          10,
          2.2,
          18,
          28
        ]
      }
    },
    {
      "id": "roads_secondary-case_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 10,
      "filter": [
        "all",
        ["==", ["get", "type"], "construction"],
        ["!=", ["get", "tunnel"], 1],
        ["==", ["get", "construction"], "secondary"],
        ["!=", ["get", "bridge"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(210, 210, 213, 1)",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          10,
          2.4,
          18,
          35
        ]
      }
    },
    {
      "id": "roads_primarylink-case_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 7,
      "filter": [
        "all",
        ["==", ["get", "type"], "construction"],
        ["!=", ["get", "tunnel"], 1],
        ["==", ["get", "construction"], "primary_link"],
        ["!=", ["get", "bridge"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "#ffffff",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          7,
          2,
          18,
          40
        ]
      }
    },
    {
      "id": "roads_primary-case_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 10,
      "filter": [
        "all",
        ["==", ["get", "type"], "construction"],
        ["!=", ["get", "tunnel"], 1],
        ["!=", ["get", "ford"], "yes"],
        ["==", ["get", "construction"], "primary"],
        ["!=", ["get", "bridge"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(250, 178, 107, 1)",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          7,
          2,
          18,
          40
        ]
      }
    },
    {
      "id": "roads_motorwaylink-case_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 6,
      "maxzoom": 20,
      "filter": [
        "all",
        ["==", ["get", "type"], "construction"],
        ["!=", ["get", "tunnel"], 1],
        ["in", ["get", "construction"], ["literal", ["motorway_link", "trunk_link"]]],
        ["!=", ["get", "bridge"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "#ffffff",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          6,
          2,
          18,
          46
        ]
      }
    },
    {
      "id": "roads_motorway-case_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 9,
      "maxzoom": 20,
      "filter": [
        "all",
        ["==", ["get", "type"], "construction"],
        ["!=", ["get", "tunnel"], 1],
        ["in", ["get", "construction"], ["literal", ["motorway", "trunk"]]],
        ["!=", ["get", "bridge"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(230, 143, 124, 1)",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          6,
          2,
          18,
          46
        ]
      }
    },
    {
      "id": "roads_roads_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 12,
      "maxzoom": 24,
      "filter": [
        "all",
        ["==", ["get", "type"], "construction"],
        ["==", ["get", "construction"], "road"]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "#ffffff",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          12,
          1.5,
          18,
          12
        ],
        "line-dasharray": [3, 1.5]
      }
    },
    {
      "id": "roads_residential_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 12,
      "maxzoom": 24,
      "filter": [
        "all",
        ["==", ["get", "type"], "construction"],
        ["in", ["get", "construction"], ["literal", ["residential", "service", "unclassified"]]]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "#ffffff",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          12,
          1.5,
          18,
          12
        ],
        "line-dasharray": [3, 1.5]
      }
    },
    {
      "id": "roads_secondarylink_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 8,
      "filter": [
        "all",
        ["==", ["get", "type"], "construction"],
        ["!=", ["get", "tunnel"], 1],
        ["==", ["get", "construction"], "secondary_link"],
        ["!=", ["get", "bridge"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": [
          "interpolate",
          ["linear"],
          ["zoom"],
          10,
          "rgba(240, 240, 240, 1)",
          12,
          "#ffffff"
        ],
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          8,
          0.5,
          18,
          30
        ],
        "line-dasharray": [3, 1.5]
      }
    },
    {
      "id": "roads_primarylink_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 6,
      "filter": [
        "all",
        ["==", ["get", "type"], "construction"],
        ["!=", ["get", "tunnel"], 1],
        ["==", ["get", "construction"], "primary_link"],
        ["!=", ["get", "bridge"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(241, 218, 187, 1)",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          6,
          0.75,
          18,
          32
        ],
        "line-dasharray": [3, 1.5]
      }
    },
    {
      "id": "roads_motorwaylink_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 5,
      "maxzoom": 20,
      "filter": [
        "all",
        ["==", ["get", "type"], "construction"],
        ["!=", ["get", "tunnel"], 1],
        ["in", ["get", "construction"], ["literal", ["motorway_link", "trunk_link"]]],
        ["!=", ["get", "bridge"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(240, 197, 188, 1)",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          5,
          1,
          18,
          36
        ],
        "line-dasharray": [3, 1.5]
      }
    },
    {
      "id": "roads_tertiary_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 9,
      "maxzoom": 24,
      "filter": [
        "all",
        ["==", ["get", "type"], "construction"],
        ["!=", ["get", "tunnel"], 1],
        ["==", ["get", "construction"], "tertiary"],
        ["!=", ["get", "bridge"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": [
          "interpolate",
          ["linear"],
          ["zoom"],
          10,
          "rgba(240, 240, 240, 1)",
          12,
          "#ffffff"
        ],
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          9,
          0.8,
          18,
          24
        ],
        "line-dasharray": [3, 1.5]
      }
    },
    {
      "id": "roads_secondary_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 8,
      "filter": [
        "all",
        ["==", ["get", "type"], "construction"],
        ["!=", ["get", "tunnel"], 1],
        ["==", ["get", "construction"], "secondary"],
        ["!=", ["get", "bridge"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": [
          "interpolate",
          ["linear"],
          ["zoom"],
          10,
          "rgba(240, 240, 240, 1)",
          12,
          "#ffffff"
        ],
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          8,
          0.5,
          18,
          30
        ],
        "line-dasharray": [3, 1.5]
      }
    },
    {
      "id": "roads_primary_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 6,
      "filter": [
        "all",
        ["==", ["get", "type"], "construction"],
        ["!=", ["get", "tunnel"], 1],
        ["!=", ["get", "ford"], "yes"],
        ["==", ["get", "construction"], "primary"],
        ["!=", ["get", "bridge"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": [
          "interpolate",
          ["linear"],
          ["zoom"],
          0,
          "rgba(242, 175, 4, 1)",
          12,
          "rgba(255, 236, 211, 1)"
        ],
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          6,
          0.75,
          18,
          32
        ],
        "line-dasharray": [3, 1.5]
      }
    },
    {
      "id": "roads_motorway_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 6,
      "maxzoom": 20,
      "filter": [
        "all",
        ["==", ["get", "type"], "construction"],
        ["!=", ["get", "tunnel"], 1],
        ["in", ["get", "construction"], ["literal", ["motorway", "trunk"]]],
        ["!=", ["get", "bridge"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": [
          "step",
          ["zoom"],
          "rgba(252, 194, 182, 1)",
          9,
          "rgba(254, 224, 217, 1)"
        ],
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          5,
          1,
          18,
          36
        ],
        "line-dasharray": [3, 1.5]
      }
    },
    {
      "id": "roads_ford_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 9,
      "filter": ["==", ["get", "ford"], "yes"],
      "layout": { "visibility": "visible" },
      "paint": {
        "line-color": "#ffffff",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          11,
          0.9,
          18,
          30
        ],
        "line-dasharray": [2, 1]
      }
    },
    {
      "id": "roads_residential_bridge_z13-copy_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 13,
      "maxzoom": 24,
      "filter": [
        "all",
        ["==", ["get", "type"], "construction"],
        ["==", ["get", "bridge"], 1],
        ["in", ["get", "construction"], ["literal", ["residential", "service", "unclassified"]]]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "butt",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(210, 210, 210, 1)",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          11,
          2,
          18,
          30
        ]
      }
    },
    {
      "id": "roads_tertiarybridge_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 9,
      "filter": [
        "all",
        ["==", ["get", "type"], "construction"],
        ["==", ["get", "bridge"], 1],
        ["==", ["get", "construction"], "tertiary"]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(210, 210, 210, 1)",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          11,
          4,
          18,
          38
        ]
      }
    },
    {
      "id": "roads_secondarybridge_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 8,
      "filter": [
        "all",
        ["==", ["get", "type"], "construction"],
        ["==", ["get", "bridge"], 1],
        ["==", ["get", "construction"], "secondary"]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "butt",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(210, 210, 210, 1)",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          8,
          3.2,
          18,
          48
        ]
      }
    },
    {
      "id": "roads_primarybridge_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 10,
      "maxzoom": 20,
      "filter": [
        "all",
        ["==", ["get", "type"], "construction"],
        ["==", ["get", "bridge"], 1],
        ["in", ["get", "construction"], ["literal", ["primary", "primary_link"]]]
      ],
      "layout": {
        "line-cap": "round",
        "visibility": "visible",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(248, 187, 127, 1)",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          7,
          3.5,
          18,
          48
        ]
      }
    },
    {
      "id": "roads_motorwaybridge_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 9,
      "maxzoom": 20,
      "filter": [
        "all",
        ["==", ["get", "type"], "construction"],
        ["==", ["get", "bridge"], 1],
        ["in", ["get", "construction"], ["literal", ["motorway", "motorway_link", "trunk", "trunk_link"]]]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(232, 159, 143, 1)",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          5,
          3,
          18,
          50
        ]
      }
    },
    {
      "id": "roads_residential_bridgetop_z13_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 12,
      "maxzoom": 24,
      "filter": [
        "all",
        ["==", ["get", "type"], "construction"],
        ["==", ["get", "bridge"], 1],
        ["in", ["get", "construction"], ["literal", ["residential", "service", "unclassified"]]]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "#ffffff",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          12,
          0.5,
          18,
          12
        ],
        "line-dasharray": [3, 1.5]
      }
    },
    {
      "id": "roads_tertiarybridgetop_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 6,
      "maxzoom": 24,
      "filter": [
        "all",
        ["==", ["get", "type"], "construction"],
        ["==", ["get", "bridge"], 1],
        ["==", ["get", "construction"], "tertiary"]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": [
          "interpolate",
          ["linear"],
          ["zoom"],
          10,
          "rgba(217, 217, 217, 1)",
          11,
          "#ffffff"
        ],
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          9,
          0.8,
          18,
          24
        ],
        "line-dasharray": [3, 1.5]
      }
    },
    {
      "id": "roads_secondarybridgetop_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 8,
      "filter": [
        "all",
        ["==", ["get", "type"], "construction"],
        ["==", ["get", "bridge"], 1],
        ["==", ["get", "construction"], "secondary"]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": [
          "interpolate",
          ["linear"],
          ["zoom"],
          10,
          "rgba(217, 217, 217, 1)",
          11,
          "#ffffff"
        ],
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          8,
          0.5,
          18,
          30
        ],
        "line-dasharray": [3, 1.5]
      }
    },
    {
      "id": "roads_primarybridgetop_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 6,
      "filter": [
        "all",
        ["==", ["get", "type"], "construction"],
        ["==", ["get", "bridge"], 1],
        ["==", ["get", "construction"], "primary"]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": [
          "interpolate",
          ["linear"],
          ["zoom"],
          0,
          "rgba(242, 175, 4, 1)",
          12,
          "rgba(255, 236, 211, 1)"
        ],
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          6,
          0.75,
          18,
          32
        ],
        "line-dasharray": [3, 1.5]
      }
    },
    {
      "id": "roads_motorwaybridgetop_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 6,
      "maxzoom": 20,
      "filter": [
        "all",
        ["==", ["get", "type"], "construction"],
        ["==", ["get", "bridge"], 1],
        ["in", ["get", "construction"], ["literal", ["motorway", "motorway_link", "trunk", "trunk_link"]]]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": [
          "step",
          ["zoom"],
          "rgba(252, 194, 182, 1)",
          9,
          "rgba(254, 224, 217, 1)"
        ],
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          5,
          1,
          18,
          36
        ],
        "line-dasharray": [3, 1.5]
      }
    },
    {
      "id": "roads_rail_tram_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 11,
      "maxzoom": 24,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["funicular", "monorail", "tram"]]],
        ["!", ["in", ["get", "service"], ["literal", ["siding", "yard"]]]]

      ],
      "layout": { "visibility": "visible", "line-cap": "square" },
      "paint": {
        "line-color": "rgba(192, 198, 207, 1)",
        "line-width": [
          "interpolate",
          ["linear"],
          ["zoom"],
          12,
          1,
          13,
          1,
          14,
          1.25,
          20,
          2.25
        ],
        "line-dasharray": [3, 1.5]
      }
    },
    {
      "id": "roads_subways",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 14,
      "filter": ["==", ["get", "type"], "subway"],
      "layout": { "visibility": "visible" },
      "paint": {
        "line-color": "rgba(166, 170, 187, 1)",
        "line-width": [
          "interpolate",
          ["linear"],
          ["zoom"],
          12,
          1,
          13,
          1,
          14,
          1.25,
          20,
          2.25
        ],
        "line-dasharray": [4, 1]
      }
    },
    {
      "id": "roads_tertiarytunnel_case",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 9,
      "filter": [
        "all",
        ["==", ["get", "type"], "tertiary"],
        ["==", ["get", "tunnel"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(210, 210, 213, 1)",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          9,
          1,
          18,
          36
        ],
        "line-dasharray": [0.5, 1.25]
      }
    },
    {
      "id": "roads_secondarytunnel_case",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 8,
      "filter": [
        "all",
        ["==", ["get", "type"], "secondary"],
        ["==", ["get", "tunnel"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(210, 210, 213, 1)",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          8,
          1,
          18,
          38
        ],
        "line-dasharray": [0.5, 1.25]
      }
    },
    {
      "id": "roads_primarytunnel_case",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 7,
      "maxzoom": 20,
      "filter": [
        "all",
        ["==", ["get", "type"], "primary"],
        ["==", ["get", "tunnel"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(250, 178, 107, 1)",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          7,
          1,
          18,
          42
        ],
        "line-dasharray": [0.5, 1.25]
      }
    },
    {
      "id": "roads_motorwaytunnel_case",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 9,
      "maxzoom": 20,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["motorway", "motorway_link", "trunk", "trunk_link"]]],
        ["==", ["get", "tunnel"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(230, 143, 124, 1)",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          5,
          1,
          18,
          46
        ],
        "line-dasharray": [0.5, 1.25]
      }
    },
    {
      "id": "roads_tertiarytunnel",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 9,
      "filter": [
        "all",
        ["==", ["get", "type"], "tertiary"],
        ["==", ["get", "tunnel"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "#f5f5f5",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          9,
          0.8,
          18,
          24
        ]
      }
    },
    {
      "id": "roads_secondarytunnel",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 8,
      "filter": [
        "all",
        ["==", ["get", "type"], "secondary"],
        ["==", ["get", "tunnel"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "#f5f5f5",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          8,
          0.5,
          18,
          30
        ]
      }
    },
    {
      "id": "roads_primarytunnel",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 6,
      "filter": [
        "all",
        ["==", ["get", "type"], "primary"],
        ["==", ["get", "tunnel"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(241, 218, 187, 1)",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          6,
          0.75,
          18,
          32
        ]
      }
    },
    {
      "id": "roads_motorwaytunnel",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 5,
      "maxzoom": 20,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["motorway", "motorway_link", "trunk", "trunk_link"]]],
        ["==", ["get", "tunnel"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "butt",
        "line-join": "miter"
      },
      "paint": {
        "line-color": "rgba(240, 197, 188, 1)",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          5,
          1,
          18,
          36
        ]
      }
    },
    {
      "id": "roads_raceways",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 12,
      "maxzoom": 24,
      "filter": ["==", ["get", "type"], "raceway"],
      "layout": { "visibility": "visible" },
      "paint": {
        "line-color": "rgba(255, 249, 241, 1)",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          11,
          0.2,
          18,
          12
        ],
        "line-dasharray": [0.75, 0.1]
      }
    },
    {
      "id": "roads_trackfillcase",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 14,
      "maxzoom": 24,
      "filter": ["==", ["get", "type"], "track"],
      "layout": { "visibility": "visible" },
      "paint": {
        "line-color": "#b3b3b3",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          11,
          0.5,
          18,
          12
        ]
      }
    },
    {
      "id": "roads_trackfill",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 14,
      "maxzoom": 24,
      "filter": ["==", ["get", "type"], "track"],
      "layout": { "visibility": "visible" },
      "paint": {
        "line-color": "rgba(251, 247, 245, 1)",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          11,
          0.5,
          18,
          4
        ]
      }
    },
    {
      "id": "roads_track",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 14,
      "maxzoom": 24,
      "filter": ["==", ["get", "type"], "track"],
      "layout": { "visibility": "visible" },
      "paint": {
        "line-color": "#b3b3b3",
        "line-dasharray": [0.3, 1],
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          11,
          0.5,
          18,
          8
        ]
      }
    },
    {
      "id": "roads_living_street",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 14,
      "maxzoom": 24,
      "filter": ["==", ["get", "type"], "living_street"],
      "layout": { "visibility": "visible" },
      "paint": {
        "line-color": "rgba(255, 255, 255, 1)",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          11,
          0.2,
          18,
          6
        ]
      }
    },
    {
      "id": "roads_footway",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 14,
      "maxzoom": 24,
      "filter": ["in", ["get", "type"], ["literal", ["cycleway", "footway", "path"]]],
      "layout": {
        "visibility": "visible",
        "line-cap": "square",
        "line-join": "round"
      },
      "paint": {
        "line-color": "#b3b3b3",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          11,
          0.2,
          18,
          3
        ],
        "line-dasharray": [2, 1]
      }
    },
    {
      "id": "roads_pier",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 14,
      "maxzoom": 24,
      "filter": ["==", ["get", "type"], "pier"],
      "layout": { "visibility": "visible" },
      "paint": {
        "line-color": "#ffffff",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          11,
          0.5,
          18,
          12
        ]
      }
    },
    {
      "id": "roads_steps",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 14,
      "maxzoom": 24,
      "filter": ["==", ["get", "type"], "steps"],
      "layout": { "visibility": "visible" },
      "paint": {
        "line-color": "#b3b3b3",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          11,
          0.5,
          18,
          6
        ],
        "line-dasharray": [0.1, 0.3]
      }
    },
    {
      "id": "roads_residentialcase_z13",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 13,
      "maxzoom": 24,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["residential", "service", "unclassified"]]],
        ["!=", ["get", "bridge"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "#D2D2D5",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          13,
          4,
          18,
          18
        ]
      }
    },
    {
      "id": "roads_pedestrian_street-casing",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 14,
      "maxzoom": 24,
      "filter": ["==", ["get", "type"], "pedestrian"],
      "layout": { "visibility": "visible" },
      "paint": {
        "line-color": "#D2D2D5",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          13,
          4,
          18,
          17
        ]
      }
    },
    {
      "id": "roads_tertiarylink-case",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 10.01,
      "maxzoom": 24,
      "filter": [
        "all",
        ["==", ["get", "type"], "tertiary_link"],
        ["!=", ["get", "tunnel"], 1],
        ["!=", ["get", "bridge"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "#D2D2D5",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          10,
          0.5,
          11,
          2.5,
          16,
          14,
          18,
          36
        ]
      }
    },
    {
      "id": "roads_tertiary-case",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 10.01,
      "maxzoom": 24,
      "filter": [
        "all",
        ["==", ["get", "type"], "tertiary"],
        ["!=", ["get", "tunnel"], 1],
        ["!=", ["get", "bridge"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "#D2D2D5",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          10,
          0.5,
          11,
          2.5,
          16,
          14,
          18,
          36
        ]
      }
    },
    {
      "id": "roads_secondary-case",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 10,
      "filter": [
        "all",
        ["==", ["get", "type"], "secondary"],
        ["!=", ["get", "tunnel"], 1],
        ["!=", ["get", "bridge"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "#D2D2D5",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          10,
          0.5,
          11,
          3,
          18,
          39
        ]
      }
    },
    {
      "id": "roads_secondarylink-case",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 8,
      "filter": [
        "all",
        ["==", ["get", "type"], "secondary_link"],
        ["!=", ["get", "tunnel"], 1],
        ["!=", ["get", "bridge"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "#D2D2D5",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          10,
          0.5,
          11,
          3,
          18,
          39
        ]
      }
    },
    {
      "id": "roads_primarylink-case",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 7,
      "filter": [
        "all",
        ["==", ["get", "type"], "primary_link"],
        ["!=", ["get", "tunnel"], 1],
        ["!=", ["get", "bridge"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "#ffffff",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          7,
          2,
          18,
          40
        ]
      }
    },
    {
      "id": "roads_primary-case",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 8,
      "filter": [
        "all",
        ["==", ["get", "type"], "primary"],
        ["!=", ["get", "tunnel"], 1],
        ["!=", ["get", "ford"], "yes"],
        ["!=", ["get", "bridge"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(250, 178, 107, 1)",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          8,
          1,
          9,
          2,
          11,
          3.5,
          18,
          40
        ]
      }
    },
    {
      "id": "roads_motorwaylink-case",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 9,
      "maxzoom": 20,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["motorway_link", "trunk_link"]]],
        ["!=", ["get", "tunnel"], 1],
        ["!=", ["get", "bridge"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(230, 143, 124, 1)",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          10,
          3,
          18,
          46
        ]
      }
    },
    {
      "id": "roads_motorway-case",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 9,
      "maxzoom": 24,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["motorway", "trunk"]]],
        ["!=", ["get", "tunnel"], 1],
        ["!=", ["get", "bridge"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(230, 143, 124, 1)",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          10,
          3,
          18,
          46
        ]
      }
    },
    {
      "id": "roads_proposed",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 12,
      "maxzoom": 24,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["proposed"]]],
        ["!", ["in", ["get", "class"], ["literal", ["railway"]]]]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "#ffffff",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          12,
          1.5,
          18,
          12
        ],
        "line-dasharray": [1, 2]
      }
    },
    {
      "id": "roads_residential",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 12,
      "maxzoom": 24,
      "filter": ["in", ["get", "type"], ["literal", ["residential", "service", "unclassified"]]],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "#ffffff",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          12,
          2,
          18,
          12
        ]
      }
    },
    {
      "id": "roads_pedestrian_street",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 14,
      "maxzoom": 24,
      "filter": ["==", ["get", "type"], "pedestrian"],
      "layout": { "visibility": "visible" },
      "paint": {
        "line-color": "#ffffff",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          12,
          2,
          18,
          12
        ]
      }
    },
    {
      "id": "roads_secondarylink",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 8,
      "filter": [
        "all",
        ["==", ["get", "type"], "secondary_link"],
        ["!=", ["get", "tunnel"], 1],
        ["!=", ["get", "bridge"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(255, 255, 255, 1)",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          8,
          0.5,
          18,
          30
        ]
      }
    },
    {
      "id": "roads_tertiarylink",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 6,
      "filter": [
        "all",
        ["==", ["get", "type"], "tertiary_link"],
        ["!=", ["get", "tunnel"], 1],
        ["!=", ["get", "bridge"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          8,
          0.5,
          16,
          11,
          18,
          28
        ],
        "line-color": [
          "interpolate",
          ["linear"],
          ["zoom"],
          10,
          "rgba(240, 240, 240, 1)",
          12,
          "#ffffff"
        ]
      }
    },
    {
      "id": "roads_primarylink",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 6,
      "filter": [
        "all",
        ["==", ["get", "type"], "primary_link"],
        ["!=", ["get", "tunnel"], 1],
        ["!=", ["get", "bridge"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(241, 218, 187, 1)",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          6,
          0.75,
          18,
          32
        ]
      }
    },
    {
      "id": "roads_motorwaylink",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 6,
      "maxzoom": 20,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["motorway_link", "trunk_link"]]],
        ["!=", ["get", "tunnel"], 1],
        ["!=", ["get", "bridge"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": [
          "step",
          ["zoom"],
          "rgba(254, 194, 182, 1)",
          9,
          "rgba(254, 224, 217, 1)"
        ],
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          6,
          1,
          9,
          2,
          10,
          2.5,
          18,
          36
        ]
      }
    },
    {
      "id": "roads_tertiary",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 9,
      "maxzoom": 24,
      "filter": [
        "all",
        ["==", ["get", "type"], "tertiary"],
        ["!=", ["get", "tunnel"], 1],
        ["!=", ["get", "bridge"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": [
          "interpolate",
          ["linear"],
          ["zoom"],
          10,
          "rgba(240, 240, 240, 1)",
          12,
          "#ffffff"
        ],
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          8,
          0.5,
          16,
          11,
          18,
          28
        ]
      }
    },
    {
      "id": "roads_secondary",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 8,
      "filter": [
        "all",
        ["==", ["get", "type"], "secondary"],
        ["!=", ["get", "tunnel"], 1],
        ["!=", ["get", "bridge"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "#ffffff",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          8,
          0.5,
          18,
          30
        ]
      }
    },
    {
      "id": "roads_primary",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 6,
      "filter": [
        "all",
        ["==", ["get", "type"], "primary"],
        ["!=", ["get", "tunnel"], 1],
        ["!=", ["get", "ford"], "yes"],
        ["!=", ["get", "bridge"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": [
          "interpolate",
          ["linear"],
          ["zoom"],
          0,
          "rgba(242, 167, 4, 1)",
          9,
          "rgba(255, 236, 211, 1)"
        ],
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          6,
          0.5,
          8,
          2,
          18,
          32
        ]
      }
    },
    {
      "id": "roads_motorway",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 6,
      "maxzoom": 24,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["motorway", "trunk"]]],
        ["!=", ["get", "tunnel"], 1],
        ["!=", ["get", "bridge"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": [
          "step",
          ["zoom"],
          "rgba(254, 194, 182, 1)",
          9,
          "rgba(254, 224, 217, 1)"
        ],
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          6,
          1,
          9,
          2,
          10,
          2.5,
          18,
          36
        ]
      }
    },
    {
      "id": "roads_ford",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 9,
      "filter": ["==", ["get", "ford"], "yes"],
      "layout": { "visibility": "visible" },
      "paint": {
        "line-color": "#ffffff",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          11,
          0.9,
          18,
          30
        ],
        "line-dasharray": [2, 1]
      }
    },
    {
      "id": "roads_rail_mini",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 7,
      "maxzoom": 24,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["miniature", "narrow_gauge"]]],
        ["!", ["in", ["get", "service"], ["literal", ["siding", "yard"]]]]
      ],
      "layout": { "visibility": "visible" },
      "paint": {
        "line-color": "rgba(162, 175, 191, 1)",
        "line-width": ["interpolate", ["linear"], ["zoom"], 7, 2, 12, 3, 20, 4]
      }
    },
    {
      "id": "roads_rail_mini-dash",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 7,
      "maxzoom": 24,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["miniature", "narrow_gauge"]]],
        ["!", ["in", ["get", "service"], ["literal", ["siding", "yard"]]]]
      ],
      "layout": { "visibility": "visible" },
      "paint": {
        "line-color": "rgba(255, 255, 255, 1)",
        "line-width": [
          "interpolate",
          ["linear"],
          ["zoom"],
          7,
          0.75,
          12,
          1,
          20,
          2
        ],
        "line-dasharray": [
          "step",
          ["zoom"],
          ["literal", [7, 7]],
          12,
          ["literal", [6, 6]]
        ]
      }
    },
    {
      "id": "roads_rail_mini_cross",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 12,
      "maxzoom": 24,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["miniature", "narrow_gauge"]]],
        ["!", ["in", ["get", "service"], ["literal", ["siding", "yard"]]]]
      ],
      "layout": { "visibility": "none", "line-cap": "square" },
      "paint": {
        "line-color": "#A2AFBF",
        "line-width": [
          "interpolate",
          ["linear"],
          ["zoom"],
          7,
          0,
          11,
          1.5,
          15,
          4
        ],
        "line-dasharray": [
          "step",
          ["zoom"],
          ["literal", [0.2, 2]],
          12,
          ["literal", [0.2, 4]]
        ]
      }
    },
    {
      "id": "roads_rail_old",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 7,
      "maxzoom": 24,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["abandoned", "dismantled", "disused", "razed"]]],
        ["!", ["in", ["get", "service"], ["literal", ["siding", "yard"]]]]
      ],
      "layout": { "visibility": "visible" },
      "paint": {
        "line-color": "rgba(210, 190, 190, 1)",
        "line-width": [
          "interpolate",
          ["linear"],
          ["zoom"],
          12,
          0.5,
          13,
          0.75,
          14,
          1,
          20,
          1.5
        ]
      }
    },
    {
      "id": "roads_rail_old-dash",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 7,
      "maxzoom": 24,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["abandoned", "dismantled", "disused", "razed"]]],
        ["!", ["in", ["get", "service"], ["literal", ["siding", "yard"]]]]
      ],
      "layout": { "visibility": "visible" },
      "paint": {
        "line-color": "rgba(255, 255, 255, 1)",
        "line-width": [
          "interpolate",
          ["linear"],
          ["zoom"],
          12,
          0.5,
          13,
          0.75,
          14,
          1,
          20,
          1.5
        ],
        "line-dasharray": [2, 2]
      }
    },
    {
      "id": "roads_rail_old_cross",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 12,
      "maxzoom": 24,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["abandoned", "dismantled", "disused", "razed"]]],
        ["!", ["in", ["get", "service"], ["literal", ["siding", "yard"]]]]
      ],
      "layout": { "visibility": "none" },
      "paint": {
        "line-color": "rgba(210, 190, 190, 1)",
        "line-width": [
          "interpolate",
          ["linear"],
          ["zoom"],
          7,
          0,
          9,
          0.5,
          12,
          3,
          15,
          5,
          17,
          6
        ],
        "line-dasharray": [
          "step",
          ["zoom"],
          ["literal", [0.2, 2.5]],
          12,
          ["literal", [0.2, 4]],
          13,
          ["literal", [0.2, 6]],
          14,
          ["literal", [0.2, 8]]
        ]
      }
    },
    {
      "id": "roads_rail-main",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 7,
      "maxzoom": 24,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["light_rail", "preserved", "rail"]]],
        ["!", ["in", ["get", "service"], ["literal", ["siding", "yard"]]]],
        ["==", ["get", "usage"], "main"]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "square",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(148, 159, 168, 1)",
        "line-width": ["interpolate", ["linear"], ["zoom"], 7, 3, 12, 4, 20, 5]
      }
    },
    {
      "id": "roads_rail-main-dash",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 7,
      "maxzoom": 24,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["light_rail", "preserved", "rail"]]],
        ["!", ["in", ["get", "service"], ["literal", ["siding", "yard"]]]],
        ["==", ["get", "usage"], "main"]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "square",
        "line-join": "round"
      },
      "paint": {
        "line-color": [
          "interpolate",
          ["linear"],
          ["zoom"],
          6,
          "rgba(223, 223, 223, 1)",
          15,
          "rgba(255, 255, 255, 1)"
        ],
        "line-width": [
          "interpolate",
          ["linear"],
          ["zoom"],
          7,
          1.5,
          12,
          2,
          20,
          3
        ],
        "line-dasharray": [
          "step",
          ["zoom"],
          ["literal", [7, 7]],
          12,
          ["literal", [5, 5]],
          15,
          ["literal", [4, 4]]
        ]
      }
    },
    {
      "id": "roads_rail-yard-siding",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 7,
      "maxzoom": 24,
      "filter": ["in", ["get", "service"], ["literal", ["siding", "yard"]]],
      "layout": {
        "visibility": "visible",
        "line-cap": "square",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(167, 179, 188, 1)",
        "line-width": ["interpolate", ["linear"], ["zoom"], 12, 0.5, 20, 1.25]
      }
    },
    {
      "id": "roads_rail-yard-siding-dash",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 7,
      "maxzoom": 24,
      "filter": ["in", ["get", "service"], ["literal", ["siding", "yard"]]],
      "layout": {
        "visibility": "visible",
        "line-cap": "square",
        "line-join": "round"
      },
      "paint": {
        "line-color": [
          "interpolate",
          ["linear"],
          ["zoom"],
          6,
          "rgba(196, 196, 197, 1)",
          12,
          "rgba(238, 238, 238, 1)",
          15,
          "rgba(244, 244, 244, 1)"
        ],
        "line-width": ["interpolate", ["linear"], ["zoom"], 12, 0.5, 20, 1.25],
        "line-dasharray": [
          "step",
          ["zoom"],
          ["literal", [7, 7]],
          15,
          ["literal", [5, 5]]
        ]
      }
    },
    {
      "id": "roads_rail",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 7,
      "maxzoom": 24,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["light_rail", "preserved", "rail"]]],
        ["!", ["in", ["get", "service"], ["literal", ["siding", "yard"]]]],
        ["!=", ["get", "usage"], "main"]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "square",
        "line-join": "round"
      },
      "paint": {
        "line-color": [
          "interpolate",
          ["linear"],
          ["zoom"],
          7,
          "rgba(193, 203, 211, 1)",
          12,
          "rgba(167, 179, 188, 1)"
        ],
        "line-width": ["interpolate", ["linear"], ["zoom"], 7, 3, 12, 4, 20, 5]
      }
    },
    {
      "id": "roads_rail-dash",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 7,
      "maxzoom": 24,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["light_rail", "preserved", "rail"]]],
        ["!", ["in", ["get", "service"], ["literal", ["siding", "yard"]]]],
        ["!=", ["get", "usage"], "main"]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "square",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(241, 246, 246, 1)",
        "line-width": [
          "interpolate",
          ["linear"],
          ["zoom"],
          7,
          1.5,
          12,
          2,
          20,
          3
        ],
        "line-dasharray": [
          "step",
          ["zoom"],
          ["literal", [6, 6]],
          9,
          ["literal", [5, 5]],
          13,
          ["literal", [4, 4]]
        ]
      }
    },
    {
      "id": "roads_rail_cross-main",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 7,
      "maxzoom": 24,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["light_rail", "preserved", "rail"]]],
        ["!", ["in", ["get", "service"], ["literal", ["siding", "yard"]]]],
        ["==", ["get", "name"], "usage=main"]
      ],
      "layout": { "visibility": "none", "line-cap": "square" },
      "paint": {
        "line-color": "#949FA8",
        "line-width": [
          "interpolate",
          ["linear"],
          ["zoom"],
          7,
          1,
          9,
          1,
          12,
          4,
          15,
          6,
          17,
          7
        ],
        "line-dasharray": [
          "step",
          ["zoom"],
          ["literal", [0.2, 2.5]],
          12,
          ["literal", [0.2, 4]],
          13,
          ["literal", [0.2, 6]],
          14,
          ["literal", [0.2, 8]]
        ]
      }
    },
    {
      "id": "roads_rail_cross",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 12,
      "maxzoom": 24,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["light_rail", "preserved", "rail"]]],
        ["!", ["in", ["get", "service"], ["literal", ["siding", "yard"]]]],
        ["!=", ["get", "name"], "usage=main"]
      ],
      "layout": { "visibility": "none", "line-cap": "square" },
      "paint": {
        "line-color": "rgba(167, 179, 188, 1)",
        "line-width": [
          "interpolate",
          ["linear"],
          ["zoom"],
          7,
          0,
          9,
          0.5,
          12,
          3,
          15,
          5,
          17,
          6
        ],
        "line-dasharray": [
          "step",
          ["zoom"],
          ["literal", [0.2, 2.5]],
          12,
          ["literal", [0.2, 4]],
          13,
          ["literal", [0.2, 6]],
          14,
          ["literal", [0.2, 8]]
        ]
      }
    },
    {
      "id": "roads_rail_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 7,
      "maxzoom": 24,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["construction", "proposed"]]],
        ["==", ["get", "class"], "railway"]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "square",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(199, 204, 213, 1)",
        "line-width": [
          "interpolate",
          ["linear"],
          ["zoom"],
          12,
          0.5,
          13,
          0.75,
          14,
          1,
          20,
          1.5
        ]
      }
    },
    {
      "id": "roads_rail_construction-dash",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 7,
      "maxzoom": 24,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["construction", "proposed"]]],
        ["==", ["get", "class"], "railway"]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "square",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(255, 255, 255, 1)",
        "line-width": [
          "interpolate",
          ["linear"],
          ["zoom"],
          12,
          0.5,
          13,
          0.75,
          14,
          1,
          20,
          1.5
        ],
        "line-dasharray": [2, 2]
      }
    },
    {
      "id": "roads_rail_construction_cross",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 12,
      "maxzoom": 24,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["construction", "proposed"]]],
        ["==", ["get", "class"], "railway"]
      ],
      "layout": { "visibility": "none" },
      "paint": {
        "line-color": "rgba(199, 204, 213, 1)",
        "line-width": [
          "interpolate",
          ["linear"],
          ["zoom"],
          7,
          0,
          9,
          0.5,
          12,
          3,
          15,
          5,
          17,
          6
        ],
        "line-dasharray": [
          "step",
          ["zoom"],
          ["literal", [0.2, 2.5]],
          12,
          ["literal", [0.2, 4]],
          13,
          ["literal", [0.2, 6]],
          14,
          ["literal", [0.2, 8]]
        ]
      }
    },
    {
      "id": "roads_residential_bridge_z13-case",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 13,
      "maxzoom": 24,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["residential", "service", "unclassified"]]],
        ["==", ["get", "bridge"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "butt",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(210, 210, 213, 1)",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          11,
          2,
          18,
          30
        ]
      }
    },
    {
      "id": "roads_tertiarybridge",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 9,
      "filter": [
        "all",
        ["==", ["get", "type"], "tertiary"],
        ["==", ["get", "bridge"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "butt",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(210, 210, 213, 1)",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          11,
          4,
          18,
          38
        ]
      }
    },
    {
      "id": "roads_secondarybridge",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 10,
      "filter": [
        "all",
        ["==", ["get", "type"], "secondary"],
        ["==", ["get", "bridge"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "butt",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(210, 210, 213, 1)",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          8,
          3.2,
          18,
          44
        ]
      }
    },
    {
      "id": "roads_primarybridge",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 10,
      "maxzoom": 20,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["primary", "primary_link"]]],
        ["==", ["get", "bridge"], 1]
      ],
      "layout": {
        "line-cap": "butt",
        "visibility": "visible",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(248, 187, 127, 1)",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          7,
          3.5,
          18,
          48
        ]
      }
    },
    {
      "id": "roads_motorwaybridge",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 9,
      "maxzoom": 20,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["motorway", "motorway_link", "trunk", "trunk_link"]]],
        ["==", ["get", "bridge"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "butt",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(232, 159, 143, 1)",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          5,
          3,
          18,
          50
        ]
      }
    },
    {
      "id": "roads_residential_bridgetop_z13",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 12,
      "maxzoom": 24,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["residential", "service", "unclassified"]]],
        ["==", ["get", "bridge"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "#ffffff",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          12,
          0.5,
          18,
          12
        ]
      }
    },
    {
      "id": "roads_tertiarybridgetop",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 6,
      "maxzoom": 24,
      "filter": [
        "all",
        ["==", ["get", "type"], "tertiary"],
        ["==", ["get", "bridge"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "butt",
        "line-join": "round"
      },
      "paint": {
        "line-color": [
          "interpolate",
          ["linear"],
          ["zoom"],
          10,
          "rgba(217, 217, 217, 1)",
          11,
          "#ffffff"
        ],
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          9,
          0.8,
          18,
          24
        ]
      }
    },
    {
      "id": "roads_secondarybridgetop",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 8,
      "filter": [
        "all",
        ["==", ["get", "type"], "secondary"],
        ["==", ["get", "bridge"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": [
          "interpolate",
          ["linear"],
          ["zoom"],
          10,
          "rgba(217, 217, 217, 1)",
          11,
          "#ffffff"
        ],
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          8,
          0.5,
          18,
          30
        ]
      }
    },
    {
      "id": "roads_primarybridgetop",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 6,
      "filter": [
        "all",
        ["==", ["get", "type"], "primary"],
        ["==", ["get", "bridge"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": [
          "interpolate",
          ["linear"],
          ["zoom"],
          0,
          "rgba(242, 175, 4, 1)",
          12,
          "rgba(255, 236, 211, 1)"
        ],
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          6,
          0.75,
          18,
          32
        ]
      }
    },
    {
      "id": "roads_motorwaybridgetop",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 6,
      "maxzoom": 20,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["motorway", "motorway_link", "trunk", "trunk_link"]]],
        ["==", ["get", "bridge"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": [
          "step",
          ["zoom"],
          "rgba(252, 194, 182, 1)",
          9,
          "rgba(254, 224, 217, 1)"
        ],
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          5,
          1,
          18,
          36
        ]
      }
    },
    {
      "id": "roads_rail_tram",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 11,
      "maxzoom": 24,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["funicular", "monorail", "tram"]]],
        ["!", ["in", ["get", "service"], ["literal", ["siding", "yard"]]]]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "square",
        "line-join": "miter"
      },
      "paint": {
        "line-color": "rgba(167, 179, 188, 1)",
        "line-width": [
          "interpolate",
          ["linear"],
          ["zoom"],
          12,
          1,
          13,
          1,
          14,
          1.25,
          20,
          2.25
        ]
      }
    },
    {
      "id": "barriers-dotted",
      "type": "line",
      "source": "osm",
      "source-layer": "other_lines",
      "filter": ["==", ["get", "type"], "bollard"],
      "paint": {
        "line-color": "rgba(217, 217, 217, 1)",
        "line-width": 3,
        "line-dasharray": [1, 1]
      }
    },
    {
      "id": "barriers",
      "type": "line",
      "source": "osm",
      "source-layer": "other_lines",
      "filter": ["all"],
      "paint": {
        "line-color": [
          "interpolate",
          ["linear"],
          ["zoom"],
          0,
          [
            "match",
            ["get", "type"],
            "wall",
            "rgba(223, 223, 223, 1)",
            "fence",
            "rgba(233, 228, 216, 1)",
            "wood_fence",
            "rgba(241, 224, 200, 1)",
            "hedge",
            "rgba(204, 218, 190, 1)",
            "hedge_bank",
            "rgba(204, 218, 190, 1)",
            "retaining_wall",
            "rgba(223, 223, 223, 1)",
            "city_wall",
            "rgba(223, 223, 223, 1)",
            "transparent"
          ]
        ],
        "line-width": 2
      }
    },
    {
      "id": "power_lines",
      "type": "line",
      "source": "osm",
      "source-layer": "other_lines",
      "filter": [
        "all",
        ["==", ["get", "class"], "power"],
        ["==", ["get", "type"], "line"]
      ],
      "layout": { "visibility": "visible" },
      "paint": { "line-color": "rgba(164, 129, 136, 1)" }
    },
    {
      "id": "city_county_lines_admin7_8",
      "type": "line",
      "source": "osm",
      "source-layer": "land_ohm_lines",
      "minzoom": 10,
      "maxzoom": 20,
      "filter": ["in", ["get", "admin_level"], ["literal", [7, 8]]],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(214, 218, 213, 1)",
        "line-dasharray": [3],
        "line-width": ["interpolate", ["linear"], ["zoom"], 10, 0.75]
      }
    },
    {
      "id": "admin_admin5_6",
      "type": "line",
      "source": "osm",
      "source-layer": "land_ohm_lines",
      "minzoom": 8,
      "maxzoom": 20,
      "filter": ["in", ["get", "admin_level"], ["literal", [5, 6]]],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round",
        "line-miter-limit": 2
      },
      "paint": {
        "line-color": [
          "interpolate",
          ["linear"],
          ["zoom"],
          7,
          "rgba(205, 205, 207, 1)",
          10,
          "rgba(202, 202, 203, 1)"
        ],
        "line-width": ["interpolate", ["linear"], ["zoom"], 8, 0.15, 10, 1.75]
      }
    },
    {
      "id": "state_lines_admin4-case",
      "type": "line",
      "source": "osm",
      "source-layer": "land_ohm_lines",
      "minzoom": 5,
      "maxzoom": 20,
      "filter": [
        "all",
        ["==", ["get", "admin_level"], 4],
        ["==", ["get", "type"], "administrative"]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "square",
        "line-join": "round"
      },
      "paint": {
        "line-color": [
          "interpolate",
          ["linear"],
          ["zoom"],
          4,
          "rgba(163, 169, 163, 0.05)",
          7,
          "rgba(234, 236, 234, 0.1)"
        ],
        "line-width": ["interpolate", ["linear"], ["zoom"], 6, 0, 12, 8, 15, 12]
      }
    },
    {
      "id": "state_lines_admin4",
      "type": "line",
      "source": "osm",
      "source-layer": "land_ohm_lines",
      "minzoom": 5,
      "maxzoom": 20,
      "filter": [
        "all",
        ["==", ["get", "admin_level"], 4],
        ["==", ["get", "type"], "administrative"]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "square",
        "line-join": "round"
      },
      "paint": {
        "line-color": [
          "interpolate",
          ["linear"],
          ["zoom"],
          6,
          "rgba(168, 193, 183, 1)"
        ],
        "line-width": [
          "interpolate",
          ["linear"],
          ["zoom"],
          2,
          0.4,
          6,
          0.75,
          12,
          2,
          15,
          3
        ]
      }
    },
    {
      "id": "admin_admin3",
      "type": "line",
      "source": "osm",
      "source-layer": "land_ohm_lines",
      "minzoom": 5,
      "maxzoom": 20,
      "filter": ["==", ["get", "admin_level"], 3],
      "layout": {
        "visibility": "visible",
        "line-cap": "square",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(168, 193, 183, 1)",
        "line-width": ["interpolate", ["linear"], ["zoom"], 6, 0.75, 12, 2]
      }
    },
    {
      "id": "admin_countrylines_z10_case",
      "type": "line",
      "source": "osm",
      "source-layer": "land_ohm_lines",
      "minzoom": 0,
      "maxzoom": 20,
      "filter": ["in", ["get", "admin_level"], ["literal", [1, 2]]],
      "layout": {
        "visibility": "visible",
        "line-cap": "square",
        "line-join": "round"
      },
      "paint": {
        "line-color": [
          "interpolate",
          ["linear"],
          ["zoom"],
          4,
          "rgba(133, 147, 156, 0.1)",
          6,
          "#e3e6e8",
          9,
          "#f1f3f4"
        ],
        "line-width": ["interpolate", ["linear"], ["zoom"], 6, 0, 12, 7, 15, 11]
      }
    },
    {
      "id": "admin_countrylines_z10",
      "type": "line",
      "source": "osm",
      "source-layer": "land_ohm_lines",
      "minzoom": 0,
      "maxzoom": 20,
      "filter": ["in", ["get", "admin_level"], ["literal", [1, 2]]],
      "layout": {
        "visibility": "visible",
        "line-cap": "square",
        "line-join": "round"
      },
      "paint": {
        "line-color": [
          "interpolate",
          ["linear"],
          ["zoom"],
          4,
          "rgba(126, 144, 127, 1)",
          6,
          "rgba(147, 171, 148, 1)",
          8,
          "rgba(177, 182, 177, 1)",
          12,
          "rgba(203, 212, 203, 1)"
        ],
        "line-width": [
          "interpolate",
          ["linear"],
          ["zoom"],
          0,
          0.25,
          2,
          0.75,
          4,
          1,
          6,
          2,
          12,
          2.5,
          15,
          4
        ]
      }
    },
    {
      "id": "roadlabels_z14",
      "type": "symbol",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 14,
      "filter": ["all"],
      "layout": {
        "text-size": 10,
        "text-allow-overlap": false,
        "symbol-avoid-edges": false,
        "symbol-spacing": 250,
        "text-font": ["OpenHistorical"],
        "symbol-placement": "line",
        "text-padding": 2,
        "text-rotation-alignment": "auto",
        "text-pitch-alignment": "auto",
        "text-field": ["get", "name"]
      },
      "paint": {
        "text-color": "rgba(82, 82, 82, 1)",
        "text-halo-width": 1,
        "text-halo-color": "rgba(255, 255, 255, 0.8)"
      }
    },
    {
      "id": "roadlabels_z11",
      "type": "symbol",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 11,
      "filter": ["in", ["get", "type"], ["literal", ["motorway", "trunk"]]],
      "layout": {
        "text-size": 10,
        "text-allow-overlap": false,
        "symbol-avoid-edges": false,
        "symbol-spacing": 250,
        "text-font": ["OpenHistorical"],
        "symbol-placement": "line",
        "text-padding": 2,
        "text-rotation-alignment": "auto",
        "text-pitch-alignment": "auto",
        "text-field": ["get", "name"]
      },
      "paint": {
        "text-color": "rgba(82, 82, 82, 1)",
        "text-halo-width": 1,
        "text-halo-color": "rgba(255, 255, 255, 0.8)"
      }
    },
    {
      "id": "water_areaslabels_z15",
      "type": "symbol",
      "source": "osm",
      "source-layer": "water_areas_centroids",
      "minzoom": 15,
      "maxzoom": 24,
      "filter": [">", ["get", "area"], 100000],
      "layout": {
        "text-field": ["get", "name"],
        "text-font": ["OpenHistorical Italic"],
        "text-padding": 2,
        "text-allow-overlap": false,
        "text-size": ["interpolate", ["linear"], ["zoom"], 15, 11, 20, 20]
      },
      "paint": {
        "text-color": "rgba(41, 84, 84, 1)",
        "text-halo-width": 1,
        "text-halo-color": "rgba(209, 230, 230, 1)"
      }
    },
    {
      "id": "water_areaslabels_z12",
      "type": "symbol",
      "source": "osm",
      "source-layer": "water_areas_centroids",
      "minzoom": 12,
      "maxzoom": 15,
      "filter": [">", ["get", "area"], 1000000],
      "layout": {
        "text-field": ["get", "name"],
        "text-font": ["OpenHistorical Italic"],
        "text-padding": 2,
        "text-allow-overlap": false,
        "text-size": ["interpolate", ["linear"], ["zoom"], 11, 11, 13, 13],
        "symbol-placement": "point"
      },
      "paint": {
        "text-color": "rgba(83, 147, 147, 1)",
        "text-halo-width": 1,
        "text-halo-color": "rgba(158, 240, 240, 1)"
      }
    },
    {
      "id": "water_pointlabels_ocean_sea",
      "type": "symbol",
      "source": "osm",
      "source-layer": "place_points",
      "minzoom": 0,
      "maxzoom": 24,
      "filter": ["in", ["get", "type"], ["literal", ["ocean", "sea"]]],
      "layout": {
        "text-field": ["get", "name"],
        "text-font": ["OpenHistorical Italic"],
        "text-padding": 2,
        "text-allow-overlap": false,
        "text-size": [
          "interpolate",
          ["linear"],
          ["zoom"],
          8,
          12,
          11,
          13,
          13,
          14
        ],
        "visibility": "visible"
      },
      "paint": {
        "text-color": "rgba(43, 102, 102, 1)",
        "text-halo-width": 1,
        "text-halo-color": "rgba(207, 230, 230, 1)"
      }
    },
    {
      "id": "water_areaslabels_z8",
      "type": "symbol",
      "source": "osm",
      "source-layer": "water_areas_centroids",
      "minzoom": 8,
      "maxzoom": 12,
      "filter": [">", ["get", "area"], 10000000],
      "layout": {
        "text-field": ["get", "name"],
        "text-font": ["OpenHistorical Italic"],
        "text-padding": 2,
        "text-allow-overlap": false,
        "text-size": [
          "interpolate",
          ["linear"],
          ["zoom"],
          8,
          10,
          11,
          11,
          13,
          13
        ]
      },
      "paint": {
        "text-color": "rgba(68, 135, 135, 1)",
        "text-halo-width": 1,
        "text-halo-color": "rgba(173, 244, 244, 1)"
      }
    },
    {
      "id": "water_lineslabels-cliff",
      "type": "symbol",
      "source": "osm",
      "source-layer": "water_lines",
      "filter": ["==", ["get", "type"], "cliff"],
      "layout": {
        "text-size": ["interpolate", ["linear"], ["zoom"], 11, 9, 13, 11],
        "symbol-spacing": 500,
        "text-font": ["OpenHistorical Italic"],
        "symbol-placement": "line",
        "text-rotation-alignment": "auto",
        "text-anchor": "bottom",
        "text-pitch-alignment": "auto",
        "text-field": ["get", "name"],
        "text-letter-spacing": 0
      },
      "paint": {
        "text-color": "rgba(77, 77, 77, 1)",
        "text-halo-color": "rgba(255, 255, 255, 1)",
        "text-halo-width": 1
      }
    },
    {
      "id": "water_lineslabels-dam",
      "type": "symbol",
      "source": "osm",
      "source-layer": "water_lines",
      "filter": ["==", ["get", "type"], "dam"],
      "layout": {
        "text-size": ["interpolate", ["linear"], ["zoom"], 11, 11, 13, 13],
        "symbol-spacing": 500,
        "text-font": ["OpenHistorical Italic"],
        "symbol-placement": "line",
        "text-rotation-alignment": "auto",
        "text-anchor": "bottom",
        "text-pitch-alignment": "auto",
        "text-field": ["get", "name"],
        "text-letter-spacing": 0
      },
      "paint": {
        "text-color": "rgba(77, 77, 77, 1)",
        "text-halo-color": "rgba(207, 230, 230, 1)",
        "text-halo-width": 1
      }
    },
    {
      "id": "water_lineslabels",
      "type": "symbol",
      "source": "osm",
      "source-layer": "water_lines",
      "minzoom": 12,
      "maxzoom": 24,
      "filter": ["!", ["in", ["get", "type"], ["literal", ["cliff", "dam"]]]],
      "layout": {
        "text-size": ["interpolate", ["linear"], ["zoom"], 12, 11, 14, 13],
        "symbol-spacing": 500,
        "text-font": ["OpenHistorical Italic"],
        "symbol-placement": "line",
        "visibility": "visible",
        "text-rotation-alignment": "auto",
        "text-anchor": "bottom",
        "text-pitch-alignment": "auto",
        "text-field": ["get", "name"],
        "text-letter-spacing": 0
      },
      "paint": {
        "text-color": "rgba(83, 147, 147, 1)",
        "text-halo-color": "rgba(231, 251, 251, 1)",
        "text-halo-width": 1
      }
    },
    {
      "id": "landuse_areaslabels_park",
      "type": "symbol",
      "source": "osm",
      "source-layer": "landuse_areas_centroids",
      "minzoom": 14,
      "maxzoom": 24,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", [
          "camp_site",
          "garden",
          "grass",
          "grassland",
          "park",
          "picnic_site",
          "playground",
          "recreation_ground",
          "sports_centre",
          "stadium",
          "village_green"
        ]]
        ],
        [">", ["get", "area"], 12000]
      ],
      "layout": {
        "text-field": ["get", "name"],
        "text-size": ["interpolate", ["linear"], ["zoom"], 14, 11, 20, 14],
        "visibility": "visible",
        "icon-text-fit": "none",
        "text-allow-overlap": false,
        "text-ignore-placement": false,
        "text-font": ["OpenHistorical"]
      },
      "paint": {
        "text-color": "rgba(85, 104, 42, 1)",
        "text-halo-color": "rgba(228, 235, 209, 1)",
        "text-halo-width": 1,
        "icon-translate-anchor": "map"
      }
    },
    {
      "id": "landuse_areaslabels_farming",
      "type": "symbol",
      "source": "osm",
      "source-layer": "landuse_areas_centroids",
      "minzoom": 14,
      "maxzoom": 24,
      "filter": ["in", ["get", "type"], ["literal", [
        "allotmets",
        "farm",
        "farmland",
        "farmyard",
        "garden",
        "orchard",
        "vineyard"
      ]]
      ],
      "layout": {
        "text-field": ["get", "name"],
        "text-size": 11,
        "text-font": ["OpenHistorical"]
      },
      "paint": {
        "text-color": "rgba(107, 101, 71, 1)",
        "text-halo-color": "rgba(255, 254, 249, 1)",
        "text-halo-width": 1
      }
    },
    {
      "id": "landuse_areaslabels_forest",
      "type": "symbol",
      "source": "osm",
      "source-layer": "landuse_areas_centroids",
      "minzoom": 14,
      "maxzoom": 24,
      "filter": ["in", ["get", "type"], ["literal", ["forest", "nature_reserve", "wood"]]],
      "layout": {
        "text-field": ["get", "name"],
        "text-size": 11,
        "text-font": ["OpenHistorical"]
      },
      "paint": {
        "text-color": "rgba(95, 107, 71, 1)",
        "text-halo-color": "rgba(201, 213, 190, 1)",
        "text-halo-width": 1
      }
    },
    {
      "id": "landuse_areaslabels_school",
      "type": "symbol",
      "source": "osm",
      "source-layer": "landuse_areas_centroids",
      "minzoom": 14,
      "maxzoom": 24,
      "filter": ["in", ["get", "type"], ["literal", ["", "college", "education", "school", "university"]]],
      "layout": {
        "text-field": ["get", "name"],
        "text-size": 11,
        "text-font": ["OpenHistorical"]
      },
      "paint": {
        "text-color": "rgba(176, 130, 130, 1)",
        "text-halo-color": "rgba(245, 239, 239, 1)",
        "text-halo-width": 1
      }
    },
    {
      "id": "landuse_areaslabels_z8glacier",
      "type": "symbol",
      "source": "osm",
      "source-layer": "landuse_areas_centroids",
      "minzoom": 10,
      "maxzoom": 22,
      "filter": ["==", ["get", "type"], "glacier"],
      "layout": {
        "text-field": ["get", "name"],
        "text-font": ["OpenHistorical Italic"],
        "text-padding": 2,
        "text-allow-overlap": false,
        "text-size": [
          "interpolate",
          ["linear"],
          ["zoom"],
          10,
          10,
          12,
          11,
          13,
          13
        ]
      },
      "paint": {
        "text-color": "rgba(68, 135, 135, 1)",
        "text-halo-width": 1,
        "text-halo-color": "rgba(173, 244, 244, 1)"
      }
    },
    {
      "id": "placearea_label",
      "type": "symbol",
      "source": "osm",
      "source-layer": "place_areas",
      "minzoom": 14,
      "maxzoom": 24,
      "filter": ["==", ["get", "type"], "square"],
      "layout": {
        "icon-image": "{type}-18",
        "visibility": "visible",
        "text-field": ["get", "name"],
        "text-size": ["interpolate", ["linear"], ["zoom"], 14, 8, 18, 10],
        "text-anchor": "top",
        "text-offset": [0, 0.75],
        "text-font": ["OpenHistorical"],
        "icon-size": ["interpolate", ["linear"], ["zoom"], 14, 0.75, 20, 1.4]
      },
      "paint": {
        "icon-color": "#000000",
        "text-color": "#505050",
        "text-halo-color": "rgba(255, 255, 255, 1)",
        "text-halo-width": 0.5,
        "text-halo-blur": 1,
        "text-opacity": ["interpolate", ["linear"], ["zoom"], 13.99, 0, 14, 1]
      }
    },
    {
      "id": "points_of_interest_frombuildings",
      "type": "symbol",
      "source": "osm",
      "source-layer": "buildings_centroids",
      "minzoom": 16,
      "filter": ["all"],
      "layout": {
        "icon-image": "{tourism}-18",
        "visibility": "visible",
        "text-field": ["get", "name"],
        "text-size": ["interpolate", ["linear"], ["zoom"], 16, 10, 20, 12],
        "text-anchor": "center",
        "text-offset": [0, 0],
        "text-font": ["OpenHistorical"],
        "icon-size": ["interpolate", ["linear"], ["zoom"], 15, 0.7, 20, 1.4]
      },
      "paint": {
        "text-color": "rgba(80, 80, 80, 1)",
        "text-halo-color": "rgba(255, 255, 255, 1)",
        "text-halo-width": 0.5,
        "text-halo-blur": 1,
        "text-opacity": 1
      }
    },
    {
      "id": "points_of_interest_fromareasz14-centroids",
      "type": "symbol",
      "source": "osm",
      "source-layer": "amenity_areas_centroids",
      "minzoom": 14,
      "maxzoom": 16,
      "filter": ["in",
        ["get", "type"],
        ["literal", [
          "bank",
          "border_control",
          "embassy",
          "fire_station",
          "government",
          "hospital",
          "police",
          "school",
          "taxi",
          "townhall",
          "university"
        ]]
      ],
      "layout": {
        "icon-image": "{type}-12",
        "visibility": "visible",
        "text-field": ["get", "name"],
        "text-size": 8,
        "text-anchor": "top",
        "text-offset": [0, 1],
        "text-font": ["OpenHistorical"]
      },
      "paint": {
        "text-color": "#505050",
        "text-halo-color": "rgba(255, 255, 255, 1)",
        "text-halo-width": 0.5,
        "text-halo-blur": 1,
        "text-opacity": 0
      }
    },
    {
      "id": "points_of_interest_fromareasz14",
      "type": "symbol",
      "source": "osm",
      "source-layer": "amenity_areas",
      "minzoom": 14,
      "maxzoom": 16,
      "filter": ["in", ["get", "type"], ["literal", [
        "bank",
        "border_control",
        "embassy",
        "fire_station",
        "government",
        "hospital",
        "police",
        "school",
        "taxi",
        "townhall",
        "university"
      ]]
      ],
      "layout": {
        "icon-image": "{type}-12",
        "visibility": "visible",
        "text-field": ["get", "name"],
        "text-size": 8,
        "text-anchor": "top",
        "text-offset": [0, 1],
        "text-font": ["OpenHistorical"]
      },
      "paint": {
        "text-color": "#505050",
        "text-halo-color": "rgba(255, 255, 255, 1)",
        "text-halo-width": 0.5,
        "text-halo-blur": 1,
        "text-opacity": 0
      }
    },
    {
      "id": "points_of_interest_fromareas",
      "type": "symbol",
      "source": "osm",
      "source-layer": "amenity_areas_centroids",
      "minzoom": 16,
      "maxzoom": 24,
      "filter": ["all"],
      "layout": {
        "icon-image": "{type}-18",
        "visibility": "visible",
        "text-field": ["get", "name"],
        "text-size": [
          "interpolate",
          ["linear"],
          ["zoom"],
          15.99,
          0,
          16,
          10,
          20,
          12
        ],
        "text-anchor": "top",
        "text-offset": [0, 1],
        "text-font": ["OpenHistorical"],
        "icon-size": ["interpolate", ["linear"], ["zoom"], 15, 0.7, 20, 1.4]
      },
      "paint": {
        "text-color": "rgba(80, 80, 80, 1)",
        "text-halo-color": "rgba(255, 255, 255, 1)",
        "text-halo-width": 0.5,
        "text-halo-blur": 1,
        "text-opacity": ["interpolate", ["linear"], ["zoom"], 16.99, 0, 17, 1]
      }
    },
    {
      "id": "points_of_interest_amenity-centroids",
      "type": "symbol",
      "source": "osm",
      "source-layer": "amenity_points_centroids",
      "minzoom": 15,
      "maxzoom": 24,
      "filter": ["all"],
      "layout": {
        "text-line-height": 1.2,
        "text-size": [
          "interpolate",
          ["linear"],
          ["zoom"],
          15.99,
          0,
          16,
          10,
          20,
          12
        ],
        "icon-image": "{type}-18",
        "text-font": ["OpenHistorical"],
        "visibility": "visible",
        "text-offset": [0, 1],
        "icon-size": ["interpolate", ["linear"], ["zoom"], 15, 0.7, 20, 1.4],
        "text-anchor": "top",
        "text-field": ["get", "name"]
      },
      "paint": {
        "text-color": "rgba(80, 80, 80, 1)",
        "text-halo-color": "rgba(255, 255, 255, 1)",
        "text-halo-width": 0.5,
        "text-halo-blur": 1,
        "text-opacity": ["interpolate", ["linear"], ["zoom"], 16.9, 0, 17, 1]
      }
    },
    {
      "id": "points_of_interest_amenity_14",
      "type": "symbol",
      "source": "osm",
      "source-layer": "amenity_points_centroids",
      "minzoom": 14,
      "maxzoom": 16,
      "filter": ["all"],
      "layout": {
        "icon-image": "{type}-18",
        "visibility": "visible",
        "text-field": ["get", "name"],
        "text-size": 8,
        "text-anchor": "top",
        "text-offset": [0, 1],
        "text-font": ["OpenHistorical"]
      },
      "paint": {
        "text-color": "rgba(80, 80, 80, 1)",
        "text-halo-color": "rgba(255, 255, 255, 1)",
        "text-halo-width": 0.5,
        "text-halo-blur": 1
      }
    },
    {
      "id": "points_of_interest_amenity",
      "type": "symbol",
      "source": "osm",
      "source-layer": "amenity_points",
      "minzoom": 15,
      "maxzoom": 24,
      "layout": {
        "text-line-height": 1.2,
        "text-size": [
          "interpolate",
          ["linear"],
          ["zoom"],
          15.99,
          0,
          16,
          10,
          20,
          12
        ],
        "icon-image": "{type}-18",
        "text-font": ["OpenHistorical"],
        "visibility": "visible",
        "text-offset": [0, 1],
        "icon-size": ["interpolate", ["linear"], ["zoom"], 15, 0.7, 20, 1.4],
        "text-anchor": "top",
        "text-field": ["get", "name"]
      },
      "paint": {
        "text-color": "rgba(80, 80, 80, 1)",
        "text-halo-color": "rgba(255, 255, 255, 1)",
        "text-halo-width": 0.5,
        "text-halo-blur": 1,
        "text-opacity": ["interpolate", ["linear"], ["zoom"], 16.9, 0, 17, 1]
      }
    },
    {
      "id": "points_of_interest_other",
      "type": "symbol",
      "source": "osm",
      "source-layer": "other_points",
      "minzoom": 15,
      "maxzoom": 24,
      "filter": ["!", ["in", ["get", "type"], ["literal", ["artwork"]]]],
      "layout": {
        "text-size": [
          "interpolate",
          ["linear"],
          ["zoom"],
          15.99,
          0,
          16,
          10,
          20,
          12
        ],
        "icon-text-fit": "none",
        "icon-image": "{type}-18",
        "icon-keep-upright": false,
        "text-font": ["OpenHistorical"],
        "icon-allow-overlap": false,
        "visibility": "visible",
        "text-offset": [0, 1],
        "icon-optional": false,
        "icon-size": ["interpolate", ["linear"], ["zoom"], 15, 0.7, 20, 1.4],
        "text-anchor": "top",
        "text-field": ["get", "name"],
        "text-max-width": 10,
        "icon-ignore-placement": false
      },
      "paint": {
        "text-color": "#505050",
        "text-halo-color": "rgba(255, 255, 255, 1)",
        "text-halo-width": 0.5,
        "text-halo-blur": 1,
        "text-translate-anchor": "viewport",
        "icon-translate-anchor": "viewport",
        "text-opacity": ["interpolate", ["linear"], ["zoom"], 16.99, 0, 17, 1]
      }
    },
    {
      "id": "points_of_interest_other_archaeology",
      "type": "symbol",
      "source": "osm",
      "source-layer": "other_points",
      "minzoom": 14,
      "maxzoom": 24,
      "filter": ["==", ["get", "type"], "archaeological_site"],
      "layout": {
        "icon-image": "{site_type}-18",
        "visibility": "visible",
        "text-field": ["get", "name"],
        "text-size": [
          "interpolate",
          ["linear"],
          ["zoom"],
          15.99,
          0,
          16,
          10,
          20,
          12
        ],
        "text-anchor": "top",
        "text-offset": [0, 1],
        "text-font": ["OpenHistorical"],
        "icon-size": ["interpolate", ["linear"], ["zoom"], 15, 0.7, 20, 1.4]
      },
      "paint": {
        "text-color": "#505050",
        "text-halo-color": "rgba(255, 255, 255, 1)",
        "text-halo-width": 0.5,
        "text-halo-blur": 1,
        "text-opacity": ["interpolate", ["linear"], ["zoom"], 16.99, 0, 17, 1]
      }
    },
    {
      "id": "points_of_interest_other_artwork",
      "type": "symbol",
      "source": "osm",
      "source-layer": "other_points",
      "minzoom": 15,
      "maxzoom": 24,
      "filter": ["==", ["get", "type"], "artwork"],
      "layout": {
        "icon-image": "{artwork_type}-18",
        "visibility": "visible",
        "text-field": ["get", "name"],
        "text-size": [
          "interpolate",
          ["linear"],
          ["zoom"],
          15.99,
          0,
          16,
          10,
          20,
          12
        ],
        "text-anchor": "top",
        "text-offset": [0, 1],
        "text-font": ["OpenHistorical"],
        "icon-size": ["interpolate", ["linear"], ["zoom"], 15, 0.7, 20, 1.4]
      },
      "paint": {
        "text-color": "#505050",
        "text-halo-color": "rgba(255, 255, 255, 1)",
        "text-halo-width": 0.5,
        "text-halo-blur": 1,
        "text-opacity": ["interpolate", ["linear"], ["zoom"], 16.99, 0, 17, 1]
      }
    },
    {
      "id": "points_powertower",
      "type": "symbol",
      "source": "osm",
      "source-layer": "other_points",
      "minzoom": 15,
      "maxzoom": 24,
      "filter": ["==", ["get", "type"], "tower"],
      "layout": {
        "icon-image": "power_tower-12",
        "visibility": "visible",
        "text-font": ["OpenHistorical"]
      }
    },
    {
      "id": "points_airport",
      "type": "symbol",
      "source": "osm",
      "source-layer": "transport_areas",
      "minzoom": 10,
      "maxzoom": 14,
      "filter": ["==", ["get", "type"], "aerodrome"],
      "layout": { "icon-image": "airport-18", "text-font": ["OpenHistorical"]}
    },
    {
      "id": "transport_points",
      "type": "symbol",
      "source": "osm",
      "source-layer": "transport_points",
      "minzoom": 14,
      "maxzoom": 24,
      "filter": ["all"],
      "layout": {
        "icon-image": "{type}-18",
        "visibility": "visible",
        "text-field": ["get", "name"],
        "text-size": ["interpolate", ["linear"], ["zoom"], 14, 8, 18, 10],
        "text-anchor": "top",
        "text-offset": [0, 0.75],
        "text-font": ["OpenHistorical"],
        "icon-size": ["interpolate", ["linear"], ["zoom"], 14, 0.75, 20, 1.4]
      },
      "paint": {
        "icon-color": "#000000",
        "text-color": "rgba(80, 80, 80, 1)",
        "text-halo-color": "rgba(255, 255, 255, 1)",
        "text-halo-width": 0.5,
        "text-halo-blur": 1,
        "text-opacity": ["interpolate", ["linear"], ["zoom"], 13.99, 0, 14, 1]
      }
    },
    {
      "id": "points_placeofworshipother",
      "type": "symbol",
      "source": "osm",
      "source-layer": "buildings",
      "filter": [
        "all",
        ["==", ["get", "type"], "place_of_worship"],
        ["!", ["in", ["get", "religion"], ["literal", ["christian", "jewish", "muslim"]]]]
      ],
      "layout": {
        "icon-image": "place_of_worship-18",
        "text-font": ["OpenHistorical"],
        "visibility": "visible"
      }
    },
    {
      "id": "points_religion",
      "type": "symbol",
      "source": "osm",
      "source-layer": "buildings",
      "filter": ["all"],
      "layout": {
        "icon-image": "{religion}-18",
        "text-font": ["OpenHistorical"],
        "visibility": "visible"
      }
    },
    {
      "id": "points_fromlanduse-z14",
      "type": "symbol",
      "source": "osm",
      "source-layer": "landuse_points",
      "minzoom": 14,
      "filter": ["==", ["get", "type"], "peak"],
      "layout": {
        "icon-image": "{type}-12",
        "text-font": ["OpenHistorical"],
        "text-field": ["get", "name"],
        "text-size": 8,
        "text-anchor": "top",
        "text-offset": [0, 0.8]
      },
      "paint": {
        "text-color": "rgba(80, 80, 80, 1)",
        "text-halo-color": "rgba(255, 255, 255, 1)",
        "text-halo-width": 0.5,
        "text-opacity": 1
      }
    },
    {
      "id": "points_fromlanduse",
      "type": "symbol",
      "source": "osm",
      "source-layer": "landuse_points",
      "minzoom": 16,
      "layout": {
        "icon-image": "{type}-18",
        "text-font": ["OpenHistorical"],
        "text-field": ["get", "name"],
        "text-size": [
          "interpolate",
          ["linear"],
          ["zoom"],
          6,
          8,
          16,
          10,
          20,
          12
        ],
        "text-anchor": "top",
        "text-offset": [0, 1],
        "visibility": "visible",
        "icon-size": ["interpolate", ["linear"], ["zoom"], 15, 0.7, 20, 1.4]
      },
      "paint": {
        "text-color": "rgba(80, 80, 80, 1)",
        "text-halo-color": "rgba(255, 255, 255, 1)",
        "text-halo-width": 0.5
      }
    },
    {
      "id": "points_fromlanduseareas",
      "type": "symbol",
      "source": "osm",
      "source-layer": "landuse_areas",
      "minzoom": 16,
      "filter": ["!", ["in", ["get", "type"], ["literal", ["garden", "peak", "wetland"]]]],
      "layout": {
        "icon-image": "{type}-18",
        "text-font": ["OpenHistorical"],
        "visibility": "visible"
      }
    },
    {
      "id": "points_acra",
      "type": "symbol",
      "source": "osm",
      "source-layer": "buildings",
      "filter": ["in", ["get", "name"], ["literal", ["ACRA", "Acra"]]],
      "layout": {
        "icon-image": "acra-18",
        "text-font": ["OpenHistorical"],
        "visibility": "visible"
      }
    },
    {
      "id": "points_oxfam",
      "type": "symbol",
      "source": "osm",
      "source-layer": "buildings",
      "filter": ["in", ["get", "name"], ["literal", [
        "Centro di accoglienza Oxfam Italia",
        "Intermon Oxfam",
        "Magasin du monde-Oxfam",
        "OXFAM",
        "OXFAM Latrines",
        "OXFAM Water Tank",
        "OXFAM Water point",
        "Oxfam",
        "Oxfam Book Shop",
        "Oxfam Books",
        "Oxfam Books & Music",
        "Oxfam Bookshop",
        "Oxfam Boutique",
        "Oxfam Buchshop",
        "Oxfam Charity Shop",
        "Oxfam GB",
        "Oxfam Ireland",
        "Oxfam Magasins du monde",
        "Oxfam Music",
        "Oxfam Novib",
        "Oxfam Shop",
        "Oxfam Solidarité",
        "Oxfam Wereldwinkel",
        "Oxfam books",
        "Oxfam wereldwinkel",
        "oxfam"
      ]]
      ],
      "layout": {
        "icon-image": "oxfam-18",
        "text-font": ["OpenHistorical"],
        "visibility": "visible"
      }
    },
    {
      "id": "points_of_interest_shop",
      "type": "symbol",
      "source": "osm",
      "source-layer": "buildings",
      "minzoom": 16,
      "maxzoom": 24,
      "filter": ["has", "shop"],
      "layout": {
        "icon-image": "{shop}-18",
        "visibility": "visible",
        "text-field": ["get", "name"],
        "text-size": 8,
        "text-anchor": "top",
        "text-offset": [0, 1],
        "text-font": ["OpenHistorical"]
      },
      "paint": {
        "text-color": "rgba(108, 132, 137, 1)",
        "text-halo-color": "rgba(255, 255, 255, 1)",
        "text-halo-width": 0.5,
        "text-halo-blur": 1
      }
    },
    {
      "id": "county_labels_z11-centroids",
      "type": "symbol",
      "source": "osm",
      "source-layer": "land_ohm_centroids",
      "minzoom": 8,
      "maxzoom": 20,
      "filter": [
        "all",
        ["==", ["get", "type"], "administrative"],
        ["==", ["get", "admin_level"], 6]
      ],
      "layout": {
        "text-field": ["get", "name"],
        "text-font": ["OpenHistorical"],
        "text-size": [
          "interpolate",
          ["linear"],
          ["zoom"],
          6,
          5,
          10,
          11,
          16,
          13
        ],
        "visibility": "visible",
        "text-transform": "uppercase",
        "symbol-spacing": 250,
        "text-letter-spacing": 0
      },
      "paint": {
        "text-color": "rgba(128, 128, 128, 1)",
        "text-halo-color": "rgba(255, 255, 255, 1)",
        "text-halo-blur": 2,
        "text-halo-width": 1
      }
    },
    {
      "id": "county_labels_z11",
      "type": "symbol",
      "source": "osm",
      "source-layer": "place_points",
      "minzoom": 8,
      "maxzoom": 20,
      "filter": ["==", ["get", "type"], "county"],
      "layout": {
        "text-field": ["get", "name"],
        "text-font": ["OpenHistorical"],
        "text-size": [
          "interpolate",
          ["linear"],
          ["zoom"],
          6,
          5,
          10,
          11,
          16,
          13
        ],
        "visibility": "visible",
        "text-transform": "uppercase",
        "symbol-spacing": 250,
        "text-letter-spacing": 0
      },
      "paint": {
        "text-color": "rgba(128, 128, 128, 1)",
        "text-halo-color": "rgba(255, 255, 255, 1)",
        "text-halo-blur": 2,
        "text-halo-width": 1
      }
    },
    {
      "id": "city_labels_other_z11",
      "type": "symbol",
      "source": "osm",
      "source-layer": "place_points",
      "minzoom": 11,
      "maxzoom": 20,
      "filter": ["in", ["get", "type"], ["literal", ["hamlet", "islet", "locality", "neighborhood", "suburb", "village"]]],
      "layout": {
        "text-field": ["get", "name"],
        "text-font": ["OpenHistorical"],
        "text-size": [
          "interpolate",
          ["linear"],
          ["zoom"],
          6,
          4,
          10,
          10,
          16,
          12
        ],
        "visibility": "visible"
      },
      "paint": {
        "text-color": "rgba(34, 34, 34, 1)",
        "text-halo-color": "rgba(255, 255, 255, 1)",
        "text-halo-blur": 2,
        "text-halo-width": 1
      }
    },
    {
      "id": "city_labels_town_z8",
      "type": "symbol",
      "source": "osm",
      "source-layer": "place_points",
      "minzoom": 8,
      "maxzoom": 20,
      "filter": ["==", ["get", "type"], "town"],
      "layout": {
        "text-field": ["get", "name"],
        "text-font": ["OpenHistorical"],
        "text-size": [
          "interpolate",
          ["linear"],
          ["zoom"],
          6,
          7,
          10,
          12,
          16,
          14
        ],
        "visibility": "visible"
      },
      "paint": {
        "text-color": "rgba(34, 34, 34, 1)",
        "text-halo-color": "rgba(255, 255, 255, 1)",
        "text-halo-blur": 2,
        "text-halo-width": 1
      }
    },
    {
      "id": "city_labels_town_z8_centroids",
      "type": "symbol",
      "source": "osm",
      "source-layer": "land_ohm_centroids",
      "minzoom": 8,
      "maxzoom": 20,
      "filter": ["in", ["get", "admin_level"], ["literal", [7, 8]]],
      "layout": {
        "text-field": ["get", "name"],
        "text-font": ["OpenHistorical"],
        "text-size": [
          "interpolate",
          ["linear"],
          ["zoom"],
          6,
          7,
          10,
          12,
          16,
          14
        ],
        "visibility": "visible"
      },
      "paint": {
        "text-color": "rgba(34, 34, 34, 1)",
        "text-halo-color": "rgba(255, 255, 255, 1)",
        "text-halo-blur": 2,
        "text-halo-width": 1
      }
    },
    {
      "id": "city_labels_z11",
      "type": "symbol",
      "source": "osm",
      "source-layer": "place_points",
      "minzoom": 11,
      "maxzoom": 20,
      "filter": ["==", ["get", "type"], "city"],
      "layout": {
        "text-field": ["get", "name"],
        "text-font": ["OpenHistorical"],
        "text-size": [
          "interpolate",
          ["linear"],
          ["zoom"],
          6,
          8,
          10,
          15,
          16,
          16
        ],
        "visibility": "visible"
      },
      "paint": {
        "text-color": "rgba(34, 34, 34, 1)",
        "text-halo-color": "rgba(255, 255, 255, 1)",
        "text-halo-blur": 2,
        "text-halo-width": 1
      }
    },
    {
      "id": "city_capital_labels_z6",
      "type": "symbol",
      "source": "osm",
      "source-layer": "place_points",
      "minzoom": 6,
      "maxzoom": 11,
      "filter": [
        "all",
        ["==", ["get", "type"], "city"],
        ["==", ["get", "capital"], "yes"]
      ],
      "layout": {
        "text-size": ["interpolate", ["linear"], ["zoom"], 6, 12, 10, 15],
        "icon-offset": [0, 0],
        "icon-image": "capital-18",
        "text-font": ["OpenHistorical"],
        "visibility": "visible",
        "text-offset": [0, 0.25],
        "icon-size": 1,
        "text-anchor": "top",
        "text-field": ["get", "name"]
      },
      "paint": {
        "text-color": "rgba(34, 34, 34, 1)",
        "text-halo-color": "rgba(255, 255, 255, 1)",
        "text-halo-blur": 2,
        "text-halo-width": 1
      }
    },
    {
      "id": "city_labels_z6",
      "type": "symbol",
      "source": "osm",
      "source-layer": "place_points",
      "minzoom": 6,
      "maxzoom": 11,
      "filter": [
        "all",
        ["==", ["get", "type"], "city"],
        ["!=", ["get", "capital"], "yes"]
      ],
      "layout": {
        "text-size": ["interpolate", ["linear"], ["zoom"], 6, 12, 10, 15],
        "icon-offset": [0, 0],
        "icon-image": "city-18",
        "text-font": ["OpenHistorical"],
        "visibility": "visible",
        "text-offset": [0, 0.25],
        "icon-size": 1,
        "text-anchor": "top",
        "text-field": ["get", "name"]
      },
      "paint": {
        "text-color": "rgba(34, 34, 34, 1)",
        "text-halo-color": "rgba(255, 255, 255, 1)",
        "text-halo-blur": 2,
        "text-halo-width": 1
      }
    },
    {
      "id": "state_points_labels_centroids",
      "type": "symbol",
      "source": "osm",
      "source-layer": "land_ohm_centroids",
      "minzoom": 5,
      "maxzoom": 20,
      "filter": [
        "all",
        ["==", ["get", "type"], "administrative"],
        ["==", ["get", "admin_level"], 4]
      ],
      "layout": {
        "text-line-height": 1,
        "text-size": ["interpolate", ["linear"], ["zoom"], 3, 9, 6, 15, 10, 18],
        "symbol-avoid-edges": true,
        "text-transform": "uppercase",
        "symbol-spacing": 25,
        "text-font": ["OpenHistorical"],
        "symbol-placement": "point",
        "visibility": "visible",
        "text-field": ["get", "name"]
      },
      "paint": {
        "text-color": [
          "interpolate",
          ["linear"],
          ["zoom"],
          6,
          "rgba(110, 133, 123, 1)"
        ],
        "text-halo-width": 2,
        "text-halo-blur": 1,
        "text-halo-color": [
          "interpolate",
          ["linear"],
          ["zoom"],
          0,
          "rgba(252, 255, 254, 0.75)",
          3,
          "rgba(240, 244, 216, 1)",
          5,
          "rgba(246,247,227, 1)",
          7,
          "rgba(255, 255, 255, 1)"
        ],
        "text-translate-anchor": "map",
        "icon-translate-anchor": "map"
      }
    },
    {
      "id": "state_points_labels",
      "type": "symbol",
      "source": "osm",
      "source-layer": "place_points",
      "minzoom": 5,
      "maxzoom": 20,
      "filter": ["in", ["get", "type"], ["literal", ["state", "territory"]]],
      "layout": {
        "text-line-height": 1,
        "text-size": ["interpolate", ["linear"], ["zoom"], 3, 9, 6, 15, 10, 18],
        "symbol-avoid-edges": true,
        "text-transform": "uppercase",
        "symbol-spacing": 25,
        "text-font": ["OpenHistorical"],
        "symbol-placement": "point",
        "visibility": "visible",
        "text-field": ["get", "name"]
      },
      "paint": {
        "text-color": [
          "interpolate",
          ["linear"],
          ["zoom"],
          6,
          "rgba(110, 133, 123, 1)"
        ],
        "text-halo-width": 2,
        "text-halo-blur": 1,
        "text-halo-color": [
          "interpolate",
          ["linear"],
          ["zoom"],
          0,
          "rgba(252, 255, 254, 0.75)",
          3,
          "rgba(240, 244, 216, 1)",
          5,
          "rgba(246,247,227, 1)",
          7,
          "rgba(255,255,255, 1)"
        ],
        "text-translate-anchor": "map",
        "icon-translate-anchor": "map"
      }
    },
    {
      "id": "statecapital_labels_z10",
      "type": "symbol",
      "source": "osm",
      "source-layer": "populated_places",
      "minzoom": 10,
      "maxzoom": 20,
      "filter": ["==", ["get", "featurecla"], "Admin-1 capital"],
      "layout": {
        "text-field": ["get", "name"],
        "text-font": ["OpenHistorical Bold"],
        "text-size": 10,
        "text-transform": "uppercase",
        "visibility": "visible"
      },
      "paint": {
        "text-color": "rgba(68, 51, 85, 1)",
        "text-halo-color": "rgba(255, 255, 255, 1)",
        "text-halo-width": 1,
        "text-halo-blur": 1
      }
    },
    {
      "id": "country_points_labels-cen",
      "type": "symbol",
      "source": "osm",
      "source-layer": "land_ohm_centroids",
      "maxzoom": 12,
      "filter": [
        "all",
        ["==", ["get", "type"], "administrative"],
        ["==", ["get", "admin_level"], 2]
      ],
      "layout": {
        "text-line-height": 1,
        "text-size": [
          "interpolate",
          ["linear"],
          ["zoom"],
          0,
          8,
          3,
          12,
          6,
          20,
          10,
          22
        ],
        "symbol-avoid-edges": false,
        "text-font": ["OpenHistorical Bold"],
        "symbol-placement": "point",
        "text-justify": "center",
        "visibility": "visible",
        "text-field": ["get", "name"],
        "text-max-width": 7
      },
      "paint": {
        "text-color": [
          "interpolate",
          ["linear"],
          ["zoom"],
          0,
          "#495049",
          5,
          "#6d786d"
        ],
        "text-halo-width": 1.5,
        "text-halo-color": [
          "interpolate",
          ["linear"],
          ["zoom"],
          0,
          "rgba(252, 255, 254, 0.75)",
          3,
          "rgba(240, 244, 216, 1)",
          5,
          "rgba(246,247,227, 1)",
          7,
          "rgba(255, 255, 255, 1)"
        ],
        "text-halo-blur": 1,
        "text-opacity": 1,
        "text-translate-anchor": "map"
      }
    },
    {
      "id": "country_points_labels",
      "type": "symbol",
      "source": "osm",
      "source-layer": "place_points",
      "minzoom": 0,
      "maxzoom": 12,
      "filter": ["==", ["get", "type"], "country"],
      "layout": {
        "text-line-height": 1,
        "text-size": [
          "interpolate",
          ["linear"],
          ["zoom"],
          0,
          8,
          3,
          12,
          6,
          20,
          10,
          22
        ],
        "symbol-avoid-edges": false,
        "text-font": ["OpenHistorical Bold"],
        "symbol-placement": "point",
        "text-justify": "center",
        "visibility": "visible",
        "text-field": ["get", "name"],
        "text-max-width": 7
      },
      "paint": {
        "text-color": [
          "interpolate",
          ["linear"],
          ["zoom"],
          0,
          "#495049",
          5,
          "#6d786d"
        ],
        "text-halo-width": 1.5,
        "text-halo-color": [
          "interpolate",
          ["linear"],
          ["zoom"],
          0,
          "rgba(252, 255, 254, 0.75)",
          3,
          "rgba(240, 244, 216, 1)",
          5,
          "rgba(246,247,227, 1)",
          7,
          "rgba(255, 255, 255, 1)"
        ],
        "text-halo-blur": 1,
        "text-opacity": 1,
        "text-translate-anchor": "map"
      }
    }
  ],
  "id": "ab271ed3-6fe4-403a-b5ae-07113f8c57ab"
};
