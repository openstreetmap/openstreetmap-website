/* extends ohmVectorStyles defined in ohm.style.js */

ohmVectorStyles.Railway = {
  "version": 8,
  "name": "ohmbasemap",
  "metadata": {"maputnik:renderer": "mbgljs"},
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
  "sprite": "https://openhistoricalmap.github.io/map-styles/rail/rail_spritesheet",
  "glyphs": "https://openhistoricalmap.github.io/map-styles/fonts/{fontstack}/{range}.pbf",
  "layers": [
    {
      "id": "background",
      "type": "background",
      "minzoom": 0,
      "maxzoom": 20,
      "filter": ["all"],
      "layout": {"visibility": "visible"},
      "paint": {"background-color": "#D5EAEA"}
    },
    {
      "id": "land",
      "type": "fill",
      "source": "osm",
      "source-layer": "land",
      "minzoom": 0,
      "maxzoom": 24,
      "layout": {"visibility": "visible"},
      "paint": {"fill-color": "rgba(255, 255, 255, 1)"}
    },
    {
      "id": "landuse_areas_earth",
      "type": "fill",
      "source": "osm",
      "source-layer": "landuse_areas",
      "minzoom": 0,
      "maxzoom": 24,
      "filter": ["==", ["get", "type"], "earth"],
      "layout": {"visibility": "visible"},
      "paint": {"fill-color": "rgba(248, 247, 242, 1)"}
    },
    {
      "id": "ohm_landcover_hillshade",
      "type": "raster",
      "source": "ohm_landcover_hillshade",
      "maxzoom": 24,
      "layout": {"visibility": "none"},
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
      "id": "military_landuselow",
      "type": "fill",
      "source": "osm",
      "source-layer": "landuse_areas",
      "minzoom": 4,
      "maxzoom": 10,
      "filter": ["==", ["get", "type"], "military"],
      "layout": {"visibility": "none"},
      "paint": {"fill-color": "rgba(230, 224, 212, 1)"}
    },
    {
      "id": "military-landusehigh",
      "type": "fill",
      "source": "osm",
      "source-layer": "landuse_areas",
      "minzoom": 10,
      "maxzoom": 24,
      "filter": ["==", ["get", "type"], "military"],
      "layout": {"visibility": "none"},
      "paint": {"fill-color": "rgba(244, 244, 235, 1)"}
    },
    {
      "id": "military",
      "type": "fill",
      "source": "osm",
      "source-layer": "other_areas",
      "filter": ["==", ["get", "class"], "military"],
      "layout": {"visibility": "none"},
      "paint": {"fill-color": "rgba(244, 244, 235, 1)"}
    },
    {
      "id": "landuse_areas_military_overlay",
      "type": "fill",
      "source": "osm",
      "source-layer": "landuse_areas",
      "minzoom": 10,
      "maxzoom": 24,
      "filter": ["==", ["get", "type"], "military"],
      "layout": {"visibility": "none"},
      "paint": {
        "fill-color": "rgba(178, 194, 157, 1)",
        "fill-antialias": false,
        "fill-pattern": "military-fill"
      }
    },
    {
      "id": "airports",
      "type": "fill",
      "source": "osm",
      "source-layer": "transport_areas",
      "minzoom": 12,
      "maxzoom": 24,
      "filter": ["==", ["get", "type"], "apron"],
      "layout": {"visibility": "none"},
      "paint": {"fill-color": "rgba(221, 221, 221, 1)"}
    },
    {
      "id": "landuse_areas_z12_generalized_land_use",
      "type": "fill",
      "source": "osm",
      "source-layer": "landuse_areas",
      "minzoom": 12,
      "maxzoom": 24,
      "layout": {"visibility": "none"},
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
            "rgba(238, 238, 238, 1)",
            "retail",
            "rgba(232, 231, 227, 1)",
            "industrial",
            "rgba(209, 200, 200, 1)",
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
      "layout": {"visibility": "none"},
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
            "rgba(226, 227, 220, 1)",
            "nature_reserve",
            "rgba(212, 225, 211, 0.3)",
            "pitch",
            "rgba(69, 143, 13, 0.39)",
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
      "layout": {"visibility": "none"},
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
            "rgba(203, 195, 197, 1)",
            "brownfield",
            "rgba(191, 171, 142, 1)",
            "commercial",
            "rgba(210, 202, 196, 1)",
            "construction",
            "rgba(242, 242, 235, 1)",
            "railway",
            "rgba(218, 204, 204, 1)",
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
      "layout": {"visibility": "none"},
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
            "rgba(215, 220, 203, 1)",
            "grassland",
            "rgba(216, 222, 191, 0.81)",
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
      "layout": {"visibility": "none"},
      "paint": {
        "line-width": ["interpolate", ["linear"], ["zoom"], 12, 0.75, 16, 1.25],
        "line-color": "rgba(201, 203, 188, 1)"
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
      "layout": {"visibility": "none"},
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
            "rgba(204, 211, 177, 1)",
            "wood",
            "rgba(192, 199, 175, 1)",
            "scrub",
            "rgba(189, 203, 186, 1)",
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
      "layout": {"visibility": "none"},
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
            "rgba(255, 255, 255, 1)",
            "reservoir",
            "rgba(144, 204, 203, 1)",
            "transparent"
          ]
        ]
      }
    },
    {
      "id": "landuse_areas_z12_food_and_farming",
      "type": "fill",
      "source": "osm",
      "source-layer": "landuse_areas",
      "minzoom": 12,
      "maxzoom": 24,
      "layout": {"visibility": "none"},
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
            "rgba(244, 237, 186, 0.61)",
            "farm",
            "rgba(234, 229, 184, 0.61)",
            "orchard",
            "rgba(223, 234, 206, 1)",
            "farmyard",
            "rgba(239, 234, 182, 0.61)",
            "vineyard",
            "rgba(215, 210, 224, 1)",
            "allotments",
            "rgba(222, 221, 190, 1)",
            "garden",
            "rgba(227, 237, 210, 1)",
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
      "layout": {"visibility": "none"},
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
            "rgba(216, 221, 201, 1)",
            "cemetery",
            "rgba(214, 222, 210, 1)",
            "grave_yard",
            "rgba(214, 222, 210, 1)",
            "sports_centre",
            "rgba(211, 218, 192, 1)",
            "stadium",
            "rgba(211, 218, 189, 1)",
            "recreation_ground",
            "rgba(217, 225, 194, 1)",
            "picnic_site",
            "rgba(217, 223, 199, 1)",
            "camp_site",
            "rgba(208, 220, 174, 1)",
            "playground",
            "rgba(206, 213, 187, 1)",
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
            "rgba(223, 231, 197, 1)",
            "transparent"
          ]
        ]
      }
    },
    {
      "id": "landuse_areas_z10",
      "type": "fill",
      "source": "osm",
      "source-layer": "landuse_areas",
      "minzoom": 10,
      "maxzoom": 12,
      "layout": {"visibility": "none"},
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
            "rgba(222, 223, 213, 1)",
            "forest",
            "rgba(222, 228, 208, 1)",
            "wood",
            "rgba(200, 207, 182, 1)",
            "nature_reserve",
            "rgba(212, 225, 211, 0.3)",
            "landfill",
            "rgba(194, 170, 175, 1)",
            "transparent"
          ]
        ]
      }
    },
    {
      "id": "landuse_areas_z7",
      "type": "fill",
      "source": "osm",
      "source-layer": "landuse_areas",
      "minzoom": 7,
      "maxzoom": 10,
      "filter": [
        "in",
        ["get", "type"],
        ["literal", ["forest", "nature_reserve", "park", "wood"]]
      ],
      "layout": {"visibility": "none"},
      "paint": {
        "fill-color": [
          "interpolate",
          ["linear"],
          ["zoom"],
          6,
          "rgba(178, 194, 157, 0.2)",
          9,
          "rgba(212, 225, 211, 0.3)"
        ]
      }
    },
    {
      "id": "landuse_areas_z5",
      "type": "fill",
      "source": "osm",
      "source-layer": "landuse_areas",
      "minzoom": 5,
      "maxzoom": 7,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["forest", "wood"]]],
        [">", ["get", "area"], 50000000]
      ],
      "layout": {"visibility": "none"},
      "paint": {"fill-color": "rgba(178, 194, 157, 1)"}
    },
    {
      "id": "landuse_areas_z3",
      "type": "fill",
      "source": "osm",
      "source-layer": "landuse_areas",
      "minzoom": 3,
      "maxzoom": 5,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["forest", "wood"]]],
        [">", ["get", "area"], 500000000]
      ],
      "layout": {"visibility": "none"},
      "paint": {"fill-color": "rgba(178, 194, 157, 1)"}
    },
    {
      "id": "parking_lots",
      "type": "fill",
      "source": "osm",
      "source-layer": "amenity_areas",
      "paint": {
        "fill-color": "rgba(229, 230, 226, 1)",
        "fill-outline-color": "rgba(224, 217, 217, 1)"
      }
    },
    {
      "id": "wetlands_z12",
      "type": "fill",
      "source": "osm",
      "source-layer": "landuse_areas",
      "minzoom": 12,
      "maxzoom": 24,
      "filter": ["==", ["get", "type"], "wetland"],
      "layout": {"visibility": "none"},
      "paint": {
        "fill-color": "rgba(255, 255, 255, 1)",
        "fill-pattern": "wetland-18"
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
      "layout": {"visibility": "visible"},
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
      "filter": [
        "in",
        ["get", "type"],
        ["literal", ["bare_rock", "peak", "rock", "scree"]]
      ],
      "layout": {"visibility": "none"},
      "paint": {"fill-color": "rgba(255, 255, 255, 1)", "fill-pattern": "rock"}
    },
    {
      "id": "place_areas_plot",
      "type": "fill",
      "source": "osm",
      "source-layer": "place_areas",
      "filter": ["==", ["get", "type"], "plot"],
      "layout": {"visibility": "none"},
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
      "layout": {"visibility": "none"},
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
      "layout": {"visibility": "none"},
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
      "filter": [
        "in",
        ["get", "type"],
        ["literal", ["school", "university"]]
      ],
      "layout": {"visibility": "none"},
      "paint": {"fill-color": "rgba(226, 214, 205, 1)"}
    },
    {
      "id": "water_areas",
      "type": "fill",
      "source": "osm",
      "source-layer": "water_areas",
      "minzoom": 8,
      "maxzoom": 24,
      "layout": {"visibility": "visible"},
      "paint": {"fill-color": "rgba(213, 234, 234, 1)"}
    },
    {
      "id": "water_areas-ne",
      "type": "fill",
      "source": "ne",
      "source-layer": "water_areas",
      "minzoom": 0,
      "maxzoom": 8,
      "layout": {"visibility": "visible"},
      "paint": {"fill-color": "rgba(213, 234, 234, 1)"}
    },
    {
      "id": "place_areas_islet",
      "type": "fill",
      "source": "osm",
      "source-layer": "place_areas",
      "filter": ["==", ["get", "type"], "islet"],
      "layout": {"visibility": "visible"},
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
        ["!", ["in", ["get", "name"], ["literal", [""]]]]
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
        ["!", ["in", ["get", "surface"], ["literal", ["water"]]]]
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
        ["!", ["in", ["get", "surface"], ["literal", ["water"]]]]
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
      "id": "water_lines_canal",
      "type": "line",
      "source": "osm",
      "source-layer": "water_lines",
      "minzoom": 8,
      "maxzoom": 24,
      "filter": ["==", ["get", "type"], "canal"],
      "paint": {
        "line-color": "rgba(192, 234, 234, 1)",
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
        "line-color": "#D5EAEA",
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
      "layout": {"visibility": "none"},
      "paint": {"fill-color": "rgba(240, 233, 219, 1)"}
    },
    {
      "id": "pier_line",
      "type": "line",
      "source": "osm",
      "source-layer": "other_lines",
      "minzoom": 12,
      "filter": ["==", ["get", "type"], "pier"],
      "layout": {"visibility": "none"},
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
      "layout": {"visibility": "visible"},
      "paint": {
        "fill-color": "rgba(241, 241, 241, 1)",
        "fill-outline-color": "rgba(206, 206, 206, 1)"
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
      "layout": {"visibility": "visible"},
      "paint": {"fill-color": "rgba(224, 224, 224, 1)"}
    },
    {
      "id": "buildings_ruins_outlines",
      "type": "line",
      "source": "osm",
      "source-layer": "other_areas",
      "filter": ["==", ["get", "type"], "ruins"],
      "layout": {"visibility": "visible"},
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
      "layout": {"visibility": "visible"},
      "paint": {
        "fill-color": "rgba(220, 215, 215, 1)",
        "fill-outline-color": "rgba(195, 188, 188, 1)"
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
      "layout": {"visibility": "none"},
      "paint": {
        "line-color": "rgba(216, 201, 201, 1)",
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
      "layout": {"visibility": "none"},
      "paint": {
        "line-color": "rgba(203, 198, 198, 1)",
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
      "paint": {"fill-color": "rgba(255, 255, 255, 1)"}
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
      "paint": {"line-color": "rgba(255, 255, 255, 1)", "line-width": 3}
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
        ["in", ["get", "type"], ["literal", ["construction"]]],
        ["==", ["get", "tunnel"], 1],
        ["==", ["get", "construction"], "primary"]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(176, 175, 173, 1)",
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
        ["in", ["get", "type"], ["literal", ["construction"]]],
        ["==", ["get", "tunnel"], 1],
        [
          "in",
          ["get", "construction"],
          ["literal", ["motorway", "motorway_link", "trunk", "trunk_link"]]
        ]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(180, 176, 176, 1)",
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
        "line-color": "rgba(222, 222, 222, 0.6)",
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
        ["in", ["get", "type"], ["literal", ["construction"]]],
        ["==", ["get", "tunnel"], 1],
        [
          "in",
          ["get", "construction"],
          ["literal", ["motorway", "motorway_link", "trunk", "trunk_link"]]
        ]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(197, 197, 197, 0.6)",
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
        ["in", ["get", "type"], ["literal", ["construction"]]],
        ["==", ["get", "construction"], "raceway"]
      ],
      "layout": {"visibility": "visible"},
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
      "layout": {"visibility": "visible"},
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
      "layout": {"visibility": "visible"},
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
      "layout": {"visibility": "visible"},
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
        ["in", ["get", "type"], ["literal", ["construction"]]],
        ["in", ["get", "construction"], ["literal", ["living_street"]]]
      ],
      "layout": {"visibility": "visible"},
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
        ["in", ["get", "type"], ["literal", ["construction"]]],
        ["==", ["get", "construction"], "pedestrian"]
      ],
      "layout": {"visibility": "visible"},
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
        ["in", ["get", "type"], ["literal", ["construction"]]],
        [
          "in",
          ["get", "construction"],
          ["literal", ["cycleway", "footway", "path"]]
        ]
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
      "layout": {"visibility": "visible"},
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
        ["in", ["get", "type"], ["literal", ["construction"]]],
        ["in", ["get", "construction"], ["literal", ["steps"]]]
      ],
      "layout": {"visibility": "visible"},
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
        ["in", ["get", "type"], ["literal", ["construction"]]],
        ["==", ["get", "bridge"], 0],
        ["in", ["get", "construction"], ["literal", ["road"]]]
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
        ["in", ["get", "type"], ["literal", ["construction"]]],
        ["==", ["get", "bridge"], 0],
        [
          "in",
          ["get", "construction"],
          ["literal", ["residential", "service", "unclassified"]]
        ]
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
        ["in", ["get", "type"], ["literal", ["construction"]]],
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
        ["in", ["get", "type"], ["literal", ["construction"]]],
        ["!=", ["get", "tunnel"], 1],
        ["!=", ["get", "ford"], "yes"],
        ["in", ["get", "construction"], ["literal", ["primary"]]],
        ["!=", ["get", "bridge"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(176, 175, 173, 1)",
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
        ["in", ["get", "type"], ["literal", ["construction"]]],
        ["!=", ["get", "tunnel"], 1],
        [
          "in",
          ["get", "construction"],
          ["literal", ["motorway_link", "trunk_link"]]
        ],
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
        ["in", ["get", "type"], ["literal", ["construction"]]],
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
        "line-color": "rgba(180, 176, 176, 1)",
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
        ["in", ["get", "type"], ["literal", ["construction"]]],
        ["in", ["get", "construction"], ["literal", ["road"]]]
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
      "id": "roads_residential_construction-copy",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 12,
      "maxzoom": 24,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["construction"]]],
        [
          "in",
          ["get", "construction"],
          ["literal", ["residential", "service", "unclassified"]]
        ]
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
        ["in", ["get", "type"], ["literal", ["construction"]]],
        [
          "in",
          ["get", "construction"],
          ["literal", ["residential", "service", "unclassified"]]
        ]
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
        ["in", ["get", "type"], ["literal", ["construction"]]],
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
        ["in", ["get", "type"], ["literal", ["construction"]]],
        ["!=", ["get", "tunnel"], 1],
        [
          "in",
          ["get", "construction"],
          ["literal", ["motorway_link", "trunk_link"]]
        ],
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
        ["in", ["get", "type"], ["literal", ["construction"]]],
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
        "line-color": "rgba(240, 239, 238, 1)",
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
        ["in", ["get", "type"], ["literal", ["construction"]]],
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
        "line-color": "rgba(211, 211, 211, 1)",
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
      "layout": {"visibility": "visible"},
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
        ["in", ["get", "type"], ["literal", ["construction"]]],
        ["==", ["get", "bridge"], 1],
        [
          "in",
          ["get", "construction"],
          ["literal", ["residential", "service", "unclassified"]]
        ]
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
        ["in", ["get", "type"], ["literal", ["construction"]]],
        ["==", ["get", "bridge"], 1],
        [
          "in",
          ["get", "construction"],
          ["literal", ["primary", "primary_link"]]
        ]
      ],
      "layout": {
        "line-cap": "round",
        "visibility": "visible",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(176, 175, 173, 1)",
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
        ["in", ["get", "type"], ["literal", ["construction"]]],
        ["==", ["get", "bridge"], 1],
        [
          "in",
          ["get", "construction"],
          ["literal", ["motorway", "motorway_link", "trunk", "trunk_link"]]
        ]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(180, 176, 176, 1)",
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
        ["in", ["get", "type"], ["literal", ["construction"]]],
        ["==", ["get", "bridge"], 1],
        [
          "in",
          ["get", "construction"],
          ["literal", ["residential", "service", "unclassified"]]
        ]
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
        ["in", ["get", "type"], ["literal", ["construction"]]],
        ["==", ["get", "bridge"], 1],
        ["in", ["get", "construction"], ["literal", ["primary"]]]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(240, 239, 238, 1)",
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
        ["in", ["get", "type"], ["literal", ["construction"]]],
        ["==", ["get", "bridge"], 1],
        [
          "in",
          ["get", "construction"],
          ["literal", ["motorway", "motorway_link", "trunk", "trunk_link"]]
        ]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(211, 211, 211, 1)",
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
      "id": "roads_subway-tunnels-halo",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 7,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["subway"]]],
        ["==", ["get", "tunnel"], 1]
      ],
      "layout": {"visibility": "visible"},
      "paint": {
        "line-color": "rgba(204, 217, 242, 1)",
        "line-width": [
          "interpolate",
          ["linear"],
          ["zoom"],
          12,
          2.5,
          14,
          4.5,
          20,
          7
        ]
      }
    },
    {
      "id": "roads_subways-tunnel-tick",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 10,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["subway"]]],
        ["==", ["get", "tunnel"], 1]
      ],
      "layout": {"visibility": "none"},
      "paint": {
        "line-color": "rgba(156, 164, 197, 1)",
        "line-width": ["interpolate", ["linear"], ["zoom"], 16, 3, 20, 9],
        "line-dasharray": [
          "step",
          ["zoom"],
          ["literal", [0.3, 3]],
          18,
          ["literal", [0.15, 3]]
        ]
      }
    },
    {
      "id": "roads_subway-tunnels",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 7,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["subway"]]],
        ["==", ["get", "tunnel"], 1]
      ],
      "layout": {"visibility": "visible"},
      "paint": {
        "line-color": "rgba(91, 107, 217, 1)",
        "line-width": ["interpolate", ["linear"], ["zoom"], 14, 1, 20, 3],
        "line-dasharray": [3, 2]
      }
    },
    {
      "id": "roads_light_rail-tunnel-halo",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 7,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["light_rail"]]],
        ["==", ["get", "tunnel"], 1],
        ["!=", ["get", "bridge"], 1]
      ],
      "layout": {"visibility": "visible"},
      "paint": {
        "line-color": "rgba(252, 241, 216, 1)",
        "line-width": [
          "interpolate",
          ["linear"],
          ["zoom"],
          12,
          2.5,
          14,
          4.5,
          20,
          7
        ]
      }
    },
    {
      "id": "roads_light_rail-tunnel",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 7,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["light_rail"]]],
        ["==", ["get", "tunnel"], 1],
        ["!=", ["get", "bridge"], 1]
      ],
      "layout": {"visibility": "visible"},
      "paint": {
        "line-color": "rgba(246, 183, 64, 1)",
        "line-width": ["interpolate", ["linear"], ["zoom"], 14, 1, 20, 3],
        "line-dasharray": [6, 4]
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
        ["in", ["get", "type"], ["literal", ["primary"]]],
        ["==", ["get", "tunnel"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(176, 175, 173, 1)",
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
        [
          "in",
          ["get", "type"],
         ["literal", ["motorway", "motorway_link", "trunk", "trunk_link"]]
        ],
        ["==", ["get", "tunnel"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(180, 176, 176, 1)",
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
      "id": "roads_tertiarytunnel-copy",
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
        "line-color": "rgba(222, 222, 222, 1)",
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
        [
          "in",
          ["get", "type"],
          ["literal", ["motorway", "motorway_link", "trunk", "trunk_link"]]
        ],
        ["==", ["get", "tunnel"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "butt",
        "line-join": "miter"
      },
      "paint": {
        "line-color": "rgba(197, 197, 197, 1)",
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
      "id": "roads_rail-tunnel",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 11,
      "maxzoom": 24,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["preserved", "rail"]]],
        ["==", ["get", "tunnel"], 1]
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
          10.5,
          "#5A6064",
          15,
          "rgba(224, 224, 224, 1)"
        ],
        "line-width": ["interpolate", ["linear"], ["zoom"], 6, 3.5, 7, 4, 20, 9]
      }
    },
    {
      "id": "roads_rail-tunnel-dash",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 11,
      "maxzoom": 24,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["preserved", "rail"]]],
        ["==", ["get", "tunnel"], 1]
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
          10.5,
          "rgba(255, 255, 255, 1)",
          14,
          "rgba(207, 207, 207, 1)",
          15,
          "rgba(184, 184, 184, 1)"
        ],
        "line-width": [
          "interpolate",
          ["linear"],
          ["zoom"],
          6,
          2,
          7,
          2.5,
          20,
          7
        ],
        "line-dasharray": [
          "step",
          ["zoom"],
          ["literal", [0.75, 2]],
          11,
          ["literal", [0.75, 2.5]],
          14,
          ["literal", [0.75, 3]]
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
      "filter": ["in", ["get", "type"], ["literal", ["raceway"]]],
      "layout": {"visibility": "visible"},
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
      "layout": {"visibility": "visible"},
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
      "layout": {"visibility": "visible"},
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
      "layout": {"visibility": "visible"},
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
      "filter": ["in", ["get", "type"], ["literal", ["living_street"]]],
      "layout": {"visibility": "visible"},
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
      "filter": [
        "in",
        ["get", "type"],
        ["literal", ["cycleway", "footway", "path"]]
      ],
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
      "layout": {"visibility": "visible"},
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
      "filter": ["in", ["get", "type"], ["literal", ["steps"]]],
      "layout": {"visibility": "visible"},
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
        [
          "in",
          ["get", "type"],
          ["literal", ["residential", "service", "unclassified"]]
        ],
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
      "filter": ["in", ["get", "type"], ["literal", ["pedestrian"]]],
      "layout": {"visibility": "visible"},
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
        "line-cap": "butt",
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
        ["in", ["get", "type"], ["literal", ["primary_link"]]],
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
        ["in", ["get", "type"], ["literal", ["primary"]]],
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
        "line-color": "rgba(176, 175, 173, 1)",
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
      "minzoom": 6,
      "maxzoom": 20,
      "filter": [
        "all",
        [
          "in",
          ["get", "type"],
          ["literal", ["motorway_link", "trunk_link"]]
        ],
        ["!=", ["get", "tunnel"], 1],
        ["!=", ["get", "bridge"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(180, 176, 176, 1)",
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
        "line-color": "rgba(180, 176, 176, 1)",
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
      "filter": [
        "in",
        ["get", "type"],
        ["literal", ["residential", "service", "unclassified"]]
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
      "filter": ["in", ["get", "type"], ["literal", ["pedestrian"]]],
      "layout": {"visibility": "visible"},
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
        ["in", ["get", "type"], ["literal", ["tertiary_link"]]],
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
        ["in", ["get", "type"], ["literal", ["primary_link"]]],
        ["!=", ["get", "tunnel"], 1],
        ["!=", ["get", "bridge"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(240, 239, 238, 1)",
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
        [
          "in",
          ["get", "type"],
          ["literal", ["motorway_link", "trunk_link"]]
        ],
        ["!=", ["get", "tunnel"], 1],
        ["!=", ["get", "bridge"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "#D3D3D3",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          6,
          1.5,
          7,
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
        "line-cap": "butt",
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
        ["in", ["get", "type"], ["literal", ["primary"]]],
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
        "line-color": "rgba(240, 239, 238, 1)",
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
        "line-color": "rgba(211, 211, 211, 1)",
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
      "layout": {"visibility": "visible"},
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
      "id": "roads_rail-subway-bridge-case",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 11,
      "maxzoom": 24,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["subway"]]],
        ["==", ["get", "bridge"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "square",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(73, 85, 158, 1)",
        "line-width": ["interpolate", ["linear"], ["zoom"], 11, 1, 20, 2],
        "line-gap-width": 5
      }
    },
    {
      "id": "roads_rail-bridge-case",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 11,
      "maxzoom": 24,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["preserved", "rail"]]],
        ["==", ["get", "bridge"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "square",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(46, 46, 46, 1)",
        "line-width": ["interpolate", ["linear"], ["zoom"], 9, 5, 11, 8, 20, 14]
      }
    },
    {
      "id": "roads_subways_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 14,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["construction"]]],
        ["in", ["get", "construction"], ["literal", ["subway"]]]
      ],
      "layout": {"visibility": "visible"},
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
      "id": "roads_subways-bridge",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 7,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["subway"]]],
        ["!=", ["get", "tunnel"], 1],
        ["==", ["get", "bridge"], 1]
      ],
      "layout": {"visibility": "visible"},
      "paint": {
        "line-color": "rgba(121, 145, 248, 1)",
        "line-width": ["interpolate", ["linear"], ["zoom"], 14, 1, 20, 3],
        "line-dasharray": [3, 2]
      }
    },
    {
      "id": "roads_light-rail-bridge-case",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 7,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["light_rail"]]],
        ["!=", ["get", "tunnel"], 1],
        ["==", ["get", "bridge"], 1]
      ],
      "layout": {"visibility": "visible"},
      "paint": {
        "line-color": "rgba(201, 139, 25, 1)",
        "line-width": ["interpolate", ["linear"], ["zoom"], 14, 1, 20, 2],
        "line-gap-width": 6
      }
    },
    {
      "id": "roads_light-rail-bridge",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 7,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["light_rail"]]],
        ["!=", ["get", "tunnel"], 1],
        ["==", ["get", "bridge"], 1]
      ],
      "layout": {"visibility": "visible"},
      "paint": {
        "line-color": "rgba(246, 183, 64, 1)",
        "line-width": ["interpolate", ["linear"], ["zoom"], 14, 1, 20, 3],
        "line-dasharray": [6, 4]
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
        [
          "in",
          ["get", "type"],
          ["literal", ["residential", "service", "unclassified"]]
        ],
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
        "line-color": "rgba(176, 175, 173, 1)",
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
        [
          "in",
          ["get", "type"],
          ["literal", ["motorway", "motorway_link", "trunk", "trunk_link"]]
        ],
        ["==", ["get", "bridge"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "butt",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(180, 176, 176, 1)",
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
        [
          "in",
          ["get", "type"],
          ["literal", ["residential", "service", "unclassified"]]
        ],
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
        ["in", ["get", "type"], ["literal", ["primary"]]],
        ["==", ["get", "bridge"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(240, 239, 238, 1)",
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
        [
          "in",
          ["get", "type"],
          ["literal", ["motorway", "motorway_link", "trunk", "trunk_link"]]
        ],
        ["==", ["get", "bridge"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(211, 211, 211, 1)",
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
      "id": "roads_subways-tick",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 10,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["subway"]]],
        ["!=", ["get", "tunnel"], 1]
      ],
      "layout": {"visibility": "none"},
      "paint": {
        "line-color": "rgba(138, 156, 234, 1)",
        "line-width": [
          "interpolate",
          ["linear"],
          ["zoom"],
          13,
          4,
          14,
          5,
          20,
          9
        ],
        "line-dasharray": [
          "step",
          ["zoom"],
          ["literal", [0.15, 3]],
          14,
          ["literal", [0.15, 4]]
        ]
      }
    },
    {
      "id": "roads_light_rail",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 7,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["light_rail"]]],
        ["!=", ["get", "tunnel"], 1],
        ["!=", ["get", "bridge"], 1]
      ],
      "layout": {"visibility": "visible"},
      "paint": {
        "line-color": "rgba(246, 183, 64, 1)",
        "line-width": ["interpolate", ["linear"], ["zoom"], 14, 1, 20, 3],
        "line-dasharray": [6, 4]
      }
    },
    {
      "id": "roads_subways",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 7,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["subway"]]],
        ["!=", ["get", "tunnel"], 1],
        ["!=", ["get", "bridge"], 1]
      ],
      "layout": {"visibility": "visible"},
      "paint": {
        "line-color": "rgba(121, 145, 248, 1)",
        "line-width": ["interpolate", ["linear"], ["zoom"], 14, 1, 20, 3],
        "line-dasharray": [3, 2]
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
        ["!", ["in", ["get", "service"], ["literal", ["siding", "spur", "yard"]]]]
      ],
      "layout": {"visibility": "visible"},
      "paint": {
        "line-color": "rgba(90, 96, 100, 1)",
        "line-width": ["interpolate", ["linear"], ["zoom"], 6, 2, 7, 3, 20, 7]
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
        ["!", ["in", ["get", "service"], ["literal", ["siding", "spur", "yard"]]]]
      ],
      "layout": {"visibility": "visible"},
      "paint": {
        "line-color": "rgba(255, 255, 255, 1)",
        "line-width": ["interpolate", ["linear"], ["zoom"], 6, 1, 20, 5],
        "line-dasharray": [
          "step",
          ["zoom"],
          ["literal", [1.15, 3]],
          10,
          ["literal", [1.25, 4]]
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
        [
          "in",
          ["get", "type"],
          ["literal", ["abandoned", "dismantled", "disused", "razed"]]
        ],
        ["!", ["in", ["get", "service"], ["literal", ["siding", "yard"]]]]
      ],
      "layout": {"visibility": "visible"},
      "paint": {
        "line-color": "rgba(209, 192, 192, 1)",
        "line-width": ["interpolate", ["linear"], ["zoom"], 6, 2, 7, 3, 20, 7]
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
        [
          "in",
          ["get", "type"],
          ["literal", ["abandoned", "dismantled", "disused", "razed"]]
        ],
        ["!", ["in", ["get", "service"], ["literal", ["siding", "yard"]]]]
      ],
      "layout": {"visibility": "visible"},
      "paint": {
        "line-color": "rgba(255, 255, 255, 1)",
        "line-width": ["interpolate", ["linear"], ["zoom"], 6, 1, 20, 5],
        "line-dasharray": [
          "step",
          ["zoom"],
          ["literal", [1.15, 3]],
          10,
          ["literal", [1.25, 4]]
        ]
      }
    },
    {
      "id": "roads_rail-main",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 0,
      "maxzoom": 24,
      "filter": [
        "all",
        ["==", ["get", "usage"], "main"],
        ["!", ["in", ["get", "service"], ["literal", ["siding", "spur", "yard"]]]],
        ["in", ["get", "type"], ["literal", ["preserved", "rail"]]]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "square",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(90, 96, 100, 1)",
        "line-width": ["interpolate", ["linear"], ["zoom"], 6, 4, 7, 6, 20, 12]
      }
    },
    {
      "id": "roads_rail-main-dash",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 0,
      "maxzoom": 24,
      "filter": [
        "all",
        ["==", ["get", "usage"], "main"],
        ["in", ["get", "type"], ["literal", ["preserved", "rail"]]],
        ["!", ["in", ["get", "service"], ["literal",["siding", "spur", "yard"]]]]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "square",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(255, 255, 255, 1)",
        "line-width": ["interpolate", ["linear"], ["zoom"], 6, 2, 7, 3, 20, 9],
        "line-dasharray": [
          "step",
          ["zoom"],
          ["literal", [0.5, 2]],
          11,
          ["literal", [0.75, 2.5]],
          14,
          ["literal", [0.75, 3]]
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
        "line-color": "rgba(168, 168, 168, 1)",
        "line-width": [
          "interpolate",
          ["linear"],
          ["zoom"],
          12,
          0.5,
          14,
          0.75,
          20,
          2
        ]
      }
    },
    {
      "id": "roads_rail-yard-siding-tick",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 13,
      "maxzoom": 24,
      "filter": ["in", ["get", "service"], ["literal", ["siding", "yard"]]],
      "layout": {
        "visibility": "visible",
        "line-cap": "square",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(174, 175, 176, 1)",
        "line-width": ["interpolate", ["linear"], ["zoom"], 12, 1, 20, 6],
        "line-dasharray": [
          "step",
          ["zoom"],
          ["literal", [0.15, 3]],
          16,
          ["literal", [0.15, 2]]
        ]
      }
    },
    {
      "id": "roads_rail-spur",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 0,
      "maxzoom": 24,
      "filter": [
        "all",
        [
          "in",
          ["get", "type"],
          ["literal", ["light_rail", "preserved", "rail"]]
        ],
        ["!", ["in", ["get", "service"], ["literal", ["siding", "yard"]]]],
        ["==", ["get", "service"], "spur"]
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
          13,
          "rgba(168, 168, 168, 1)",
          14,
          "rgba(148, 149, 153, 1)"
        ],
        "line-width": [
          "interpolate",
          ["linear"],
          ["zoom"],
          12,
          0.5,
          14,
          0.75,
          20,
          2
        ]
      }
    },
    {
      "id": "roads_rail-spur-tick",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 13,
      "maxzoom": 24,
      "filter": [
        "all",
        [
          "in",
          ["get", "type"],
          ["literal", ["light_rail", "preserved", "rail"]]
        ],
        ["!", ["in", ["get", "service"], ["literal", ["siding", "yard"]]]],
        ["==", ["get", "service"], "spur"]
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
          13,
          "#DBDBDB",
          14,
          "#949599"
        ],
        "line-width": ["interpolate", ["linear"], ["zoom"], 12, 1, 20, 6],
        "line-dasharray": [
          "step",
          ["zoom"],
          ["literal", [0.15, 3]],
          16,
          ["literal", [0.15, 2]]
        ]
      }
    },
    {
      "id": "roads_rail-tourism",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 0,
      "maxzoom": 24,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["preserved", "rail"]]],
        ["!", ["in", ["get", "service"], ["literal", ["siding", "spur", "yard"]]]],
        ["==", ["get", "usage"], "tourism"]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "square",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(242, 210, 156, 1)",
        "line-width": [
          "interpolate",
          ["linear"],
          ["zoom"],
          6,
          3,
          7,
          3.5,
          20,
          8.5
        ]
      }
    },
    {
      "id": "roads_rail-tourism-dash",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 0,
      "maxzoom": 24,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["preserved", "rail"]]],
        ["!", ["in", ["get", "service"], ["literal", ["siding", "spur", "yard"]]]],
        ["==", ["get", "usage"], "tourism"]
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
          6,
          1.5,
          7,
          2,
          20,
          6
        ],
        "line-dasharray": [
          "step",
          ["zoom"],
          ["literal", [0.5, 2]],
          11,
          ["literal", [0.75, 2.5]],
          14,
          ["literal", [0.75, 3]]
        ]
      }
    },
    {
      "id": "roads_rail-military",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 0,
      "maxzoom": 24,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["preserved", "rail"]]],
        ["!", ["in", ["get", "service"], ["literal", ["siding", "spur", "yard"]]]],
        ["==", ["get", "usage"], "military"]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "square",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(188, 137, 139, 1)",
        "line-width": [
          "interpolate",
          ["linear"],
          ["zoom"],
          6,
          3,
          7,
          3.5,
          20,
          8.5
        ]
      }
    },
    {
      "id": "roads_rail-military-dash",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 0,
      "maxzoom": 24,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["preserved", "rail"]]],
        ["!", ["in", ["get", "service"], ["literal", ["siding", "spur", "yard"]]]],
        ["==", ["get", "usage"], "military"]
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
          6,
          1.5,
          7,
          2,
          20,
          6
        ],
        "line-dasharray": [
          "step",
          ["zoom"],
          ["literal", [0.5, 2]],
          11,
          ["literal", [0.75, 2.5]],
          14,
          ["literal", [0.75, 3]]
        ]
      }
    },
    {
      "id": "roads_rail-branch",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 0,
      "maxzoom": 24,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal" ,["preserved", "rail"]]],
        ["!", ["in", ["get", "service"], ["literal", ["siding", "spur", "yard"]]]],
        ["==", ["get", "usage"], "branch"]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "square",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(129, 135, 139, 1)",
        "line-width": ["interpolate", ["linear"], ["zoom"], 6, 3, 7, 4, 20, 10]
      }
    },
    {
      "id": "roads_rail-branch-dash",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 0,
      "maxzoom": 24,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["preserved", "rail"]]],
        ["!", ["in", ["get", "service"], ["literal", ["siding", "spur", "yard"]]]],
        ["==", ["get", "usage"], "branch"]
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
          6,
          1.5,
          7,
          2.5,
          20,
          7
        ],
        "line-dasharray": [
          "step",
          ["zoom"],
          ["literal", [0.5, 2]],
          11,
          ["literal", [0.75, 2.5]],
          14,
          ["literal", [0.75, 3]]
        ]
      }
    },
    {
      "id": "roads_rail-industrial",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 0,
      "maxzoom": 24,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["preserved", "rail"]]],
        ["!", ["in", ["get", "service"], ["literal", ["siding", "spur", "yard"]]]],
        ["==", ["get", "usage"], "industrial"]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "square",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(155, 221, 174, 1)",
        "line-width": [
          "interpolate",
          ["linear"],
          ["zoom"],
          6,
          3,
          7,
          3.5,
          20,
          8.5
        ]
      }
    },
    {
      "id": "roads_rail-industrial-dash",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 0,
      "maxzoom": 24,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["preserved", "rail"]]],
        ["!", ["in", ["get", "service"], ["literal", ["siding", "spur", "yard"]]]],
        ["==", ["get", "usage"], "industrial"]
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
          6,
          1.5,
          7,
          2,
          20,
          6
        ],
        "line-dasharray": [
          "step",
          ["zoom"],
          ["literal", [0.5, 2]],
          11,
          ["literal", [0.75, 2.5]],
          14,
          ["literal", [0.75, 3]]
        ]
      }
    },
    {
      "id": "roads_rail",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 0,
      "maxzoom": 24,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["preserved", "rail"]]],
        ["!", ["in", ["get", "service"], ["literal", ["siding", "spur", "yard"]]]],
        ["!=", ["get", "usage"], "main"],
        ["!=", ["get", "usage"], "industrial"],
        ["!=", ["get", "usage"], "branch"],
        ["!=", ["get", "usage"], "military"],
        ["!=", ["get", "usage"], "tourism"],
        ["!=", ["get", "service"], "spur"],
        ["!=", ["get", "tunnel"], 1],
        ["!=", ["get", "service"], "siding"],
        ["!=", ["get", "bridge"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "square",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(90, 96, 100, 1)",
        "line-width": ["interpolate", ["linear"], ["zoom"], 6, 3.5, 7, 4, 20, 9]
      }
    },
    {
      "id": "roads_rail-bridge",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 0,
      "maxzoom": 24,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["preserved", "rail"]]],
        ["!", ["in", ["get", "service"], ["literal", ["siding", "spur", "yard"]]]],
        ["!=", ["get", "usage"], "main"],
        ["!=", ["get", "usage"], "industrial"],
        ["!=", ["get", "usage"], "branch"],
        ["!=", ["get", "usage"], "military"],
        ["!=", ["get", "usage"], "tourism"],
        ["!=", ["get", "service"], "spur"],
        ["!=", ["get", "tunnel"], 1],
        ["!=", ["get", "service"], "siding"],
        ["==", ["get", "bridge"], 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "square",
        "line-join": "round"
      },
      "paint": {
        "line-color": "#5A6064",
        "line-width": ["interpolate", ["linear"], ["zoom"], 6, 3.5, 7, 4, 20, 9]
      }
    },
    {
      "id": "roads_rail-dash",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 0,
      "maxzoom": 24,
      "filter": [
        "all",
        ["in", ["get", "type"], ["literal", ["preserved", "rail"]]],
        ["!", ["in", ["get", "service"], ["literal", ["siding", "spur", "yard"]]]],
        ["!=", ["get", "usage"], "main"],
        ["!=", ["get", "usage"], "ndustrial"],
        ["!=", ["get", "usage"], "branch"],
        ["!=", ["get", "usage"], "tourism"],
        ["!=", ["get", "service"], "spur"],
        ["!=", ["get", "service"], "siding"],
        ["!=", ["get", "tunnel"], 1],
        ["!=", ["get", "usage"], "military"]
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
          6,
          2,
          7,
          2.5,
          20,
          7
        ],
        "line-dasharray": [
          "step",
          ["zoom"],
          ["literal", [0.5, 2]],
          11,
          ["literal", [0.75, 2.5]],
          14,
          ["literal", [0.75, 3]]
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
        ["in", ["get", "class"], ["literal", ["railway"]]]
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
          13,
          "rgba(166, 169, 175, 1)",
          14,
          "rgba(199, 204, 213, 1)"
        ],
        "line-width": ["interpolate", ["linear"], ["zoom"], 6, 1, 20, 5],
        "line-dasharray": [
          "step",
          ["zoom"],
          ["literal", [1.15, 2]],
          10,
          ["literal", [1.25, 2]]
        ]
      }
    },
    {
      "id": "roads_rail_tram",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 7,
      "maxzoom": 24,
      "filter": [
        "all",
        [
          "in",
          ["get", "type"],
          ["literal", ["funicular", "monorail", "tram"]]
        ],
        ["!", ["in", ["get", "service"], ["literal", ["siding", "spur", "yard"]]]]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "square",
        "line-join": "miter"
      },
      "paint": {
        "line-color": "rgba(192, 123, 236, 1)",
        "line-width": [
          "interpolate",
          ["linear"],
          ["zoom"],
          13,
          1,
          14,
          0.5,
          20,
          2.25
        ],
        "line-dasharray": [
          "step",
          ["zoom"],
          ["literal", [3, 2]],
          14,
          ["literal", [3, 2]]
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
      "layout": {"visibility": "visible"},
      "paint": {"line-color": "rgba(164, 129, 136, 1)"}
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
        "line-color": "rgba(177, 181, 176, 1)",
        "line-dasharray": [3],
        "line-width": ["interpolate", ["linear"], ["zoom"], 10, 0.3, 12, 0.5]
      }
    },
    {
      "id": "admin_admin5_6",
      "type": "line",
      "source": "osm",
      "source-layer": "land_ohm_lines",
      "minzoom": 7,
      "maxzoom": 20,
      "filter": ["in", ["get", "admin_level"], ["literal", [5, 6]]],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round",
        "line-miter-limit": 2
      },
      "paint": {
        "line-color": "rgba(179, 179, 179, 1)",
        "line-dasharray": [],
        "line-width": ["interpolate", ["linear"], ["zoom"], 6, 0.25, 10, 2]
      }
    },
    {
      "id": "state_lines_admin4-case",
      "type": "line",
      "source": "osm",
      "source-layer": "land_ohm_lines",
      "minzoom": 3,
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
          "rgba(163, 165, 169, 0.05)",
          7,
          "rgba(234, 235, 236, 0.1)"
        ],
        "line-width": ["interpolate", ["linear"], ["zoom"], 6, 0, 12, 8, 15, 7]
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
          4,
          "rgba(154, 160, 166, 1)",
          7,
          "rgba(189, 190, 191, 1)"
        ],
        "line-width": [
          "interpolate",
          ["linear"],
          ["zoom"],
          2,
          0.4,
          12,
          2,
          15,
          0.75
        ]
      }
    },
    {
      "id": "admin_admin3",
      "type": "line",
      "source": "osm",
      "source-layer": "land_ohm_lines",
      "minzoom": 3,
      "maxzoom": 20,
      "filter": ["==", ["get", "admin_level"], 3],
      "layout": {
        "visibility": "visible",
        "line-cap": "square",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(181, 195, 199, 1)",
        "line-width": ["interpolate", ["linear"], ["zoom"], 2, 0.25, 7, 2]
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
          "rgba(242, 242, 242, 0.28)",
          7,
          "rgba(255, 255, 255, 0.24)"
        ],
        "line-width": ["interpolate", ["linear"], ["zoom"], 6, 0, 12, 10, 15, 8]
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
          0,
          "rgba(180, 191, 191, 1)",
          14,
          "rgba(174, 185, 185, 1)",
          15,
          "rgba(131, 150, 150, 1)"
        ],
        "line-width": [
          "interpolate",
          ["linear"],
          ["zoom"],
          0,
          0.25,
          2,
          0.75,
          10,
          1,
          13,
          2.5,
          17,
          1.5
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
        "text-field": ["to-string", ["get", "name"]],
        "symbol-placement": "line",
        "symbol-spacing": 250,
        "symbol-avoid-edges": false,
        "text-size": 10,
        "text-padding": 2,
        "text-allow-overlap": false,
        "text-pitch-alignment": "auto",
        "text-rotation-alignment": "auto",
        "text-font": ["OpenHistorical"],
        "visibility": "none"
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
        "text-field": ["to-string", ["get", "name"]],
        "symbol-placement": "line",
        "symbol-spacing": 250,
        "symbol-avoid-edges": false,
        "text-size": 10,
        "text-padding": 2,
        "text-allow-overlap": false,
        "text-pitch-alignment": "auto",
        "text-rotation-alignment": "auto",
        "text-font": ["OpenHistorical"],
        "visibility": "none"
      },
      "paint": {
        "text-color": "rgba(82, 82, 82, 1)",
        "text-halo-width": 1,
        "text-halo-color": "rgba(255, 255, 255, 0.8)"
      }
    },
    {
      "id": "raillabels_z14",
      "type": "symbol",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 6,
      "filter": ["==", ["get", "class"], "railway"],
      "layout": {
        "text-field": ["to-string", ["get", "name"]],
        "symbol-placement": "line",
        "symbol-spacing": 250,
        "symbol-avoid-edges": false,
        "text-size": ["interpolate", ["linear"], ["zoom"], 11, 9, 14, 11],
        "text-padding": 2,
        "text-allow-overlap": false,
        "text-pitch-alignment": "auto",
        "text-rotation-alignment": "auto",
        "text-font": ["OpenHistorical"],
        "visibility": "visible"
      },
      "paint": {
        "text-color": "rgba(78, 78, 78, 1)",
        "text-halo-width": 12,
        "text-halo-color": "rgba(255, 255, 255, 1)",
        "text-opacity": 0.85
      }
    },
    {
      "id": "water_areaslabels_z15",
      "type": "symbol",
      "source": "osm",
      "source-layer": "water_areas",
      "minzoom": 15,
      "maxzoom": 24,
      "filter": [">", ["get", "area"], 100000],
      "layout": {
        "text-field": ["to-string", ["get", "name"]],
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
      "source-layer": "water_areas",
      "minzoom": 12,
      "maxzoom": 15,
      "filter": [">", ["get", "area"], 1000000],
      "layout": {
        "text-field": ["to-string", ["get", "name"]],
        "text-font": ["OpenHistorical Italic"],
        "text-padding": 2,
        "text-allow-overlap": false,
        "text-size": ["interpolate", ["linear"], ["zoom"], 11, 11, 13, 13],
        "symbol-placement": "point"
      },
      "paint": {
        "text-color": "rgba(125, 158, 158, 1)",
        "text-halo-width": 1,
        "text-halo-color": "rgba(231, 251, 251, 1)"
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
        "text-field": ["to-string", ["get", "name"]],
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
      "source-layer": "water_areas",
      "minzoom": 8,
      "maxzoom": 12,
      "filter": [">", ["get", "area"], 10000000],
      "layout": {
        "text-field": ["to-string", ["get", "name"]],
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
        "text-color": "rgba(125, 158, 158, 1)",
        "text-halo-width": 1,
        "text-halo-color": "rgba(231, 251, 251, 1)"
      }
    },
    {
      "id": "water_lineslabels-cliff",
      "type": "symbol",
      "source": "osm",
      "source-layer": "water_lines",
      "filter": ["in", ["get", "type"], ["literal", ["cliff"]]],
      "layout": {
        "text-field": ["to-string", ["get", "name"]],
        "text-font": ["OpenHistorical Italic"],
        "symbol-placement": "line",
        "symbol-spacing": 500,
        "text-anchor": "bottom",
        "text-pitch-alignment": "auto",
        "text-rotation-alignment": "auto",
        "text-size": ["interpolate", ["linear"], ["zoom"], 11, 9, 13, 11],
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
      "filter": ["in", ["get", "type"], ["literal", ["dam"]]],
      "layout": {
        "text-field": ["to-string", ["get", "name"]],
        "text-font": ["OpenHistorical Italic"],
        "symbol-placement": "line",
        "symbol-spacing": 500,
        "text-anchor": "bottom",
        "text-pitch-alignment": "auto",
        "text-rotation-alignment": "auto",
        "text-size": ["interpolate", ["linear"], ["zoom"], 11, 11, 13, 13],
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
        "text-field": ["to-string", ["get", "name"]],
        "text-font": ["OpenHistorical Italic"],
        "symbol-placement": "line",
        "symbol-spacing": 500,
        "text-anchor": "bottom",
        "text-pitch-alignment": "auto",
        "text-rotation-alignment": "auto",
        "text-size": ["interpolate", ["linear"], ["zoom"], 12, 11, 14, 13],
        "text-letter-spacing": 0,
        "visibility": "visible"
      },
      "paint": {
        "text-color": "rgba(125, 158, 158, 1)",
        "text-halo-color": "rgba(231, 251, 251, 1)",
        "text-halo-width": 1
      }
    },
    {
      "id": "landuse_areaslabels_park",
      "type": "symbol",
      "source": "osm",
      "source-layer": "landuse_areas",
      "minzoom": 14,
      "maxzoom": 24,
      "filter": [
        "all",
        [
          "in",
          ["get", "type"],
          ["literal", [
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
        "text-field": ["to-string", ["get", "name"]],
        "text-size": ["interpolate", ["linear"], ["zoom"], 14, 11, 20, 14],
        "visibility": "none",
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
      "source-layer": "landuse_areas",
      "minzoom": 14,
      "maxzoom": 24,
      "filter": [
        "in",
        ["get", "type"],
        ["literal", [
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
        "text-field": ["to-string", ["get", "name"]],
        "text-size": 11,
        "text-font": ["OpenHistorical"],
        "visibility": "none"
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
      "source-layer": "landuse_areas",
      "minzoom": 14,
      "maxzoom": 24,
      "filter": [
        "in",
        ["get", "type"],
        ["literal", ["forest", "nature_reserve", "wood"]]
      ],
      "layout": {
        "text-field": ["to-string", ["get", "name"]],
        "text-size": 11,
        "text-font": ["OpenHistorical"],
        "visibility": "none"
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
      "source-layer": "landuse_areas",
      "minzoom": 14,
      "maxzoom": 24,
      "filter": [
        "in",
        ["get", "type"],
        ["literal", ["", "college", "education", "school", "university"]]
      ],
      "layout": {
        "text-field": ["to-string", ["get", "name"]],
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
      "id": "points_of_interest_place_areas",
      "type": "symbol",
      "source": "osm",
      "source-layer": "place_areas",
      "minzoom": 16,
      "filter": [
        "!", ["in",
        ["get", "type"],
        ["literal", ["country", "state", "territory"]]]
      ],
      "layout": {
        "visibility": "visible",
        "text-field": ["to-string", ["get", "name"]],
        "text-size": 9,
        "text-anchor": "center",
        "text-offset": [0, 0],
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
      "id": "points_of_interest_frombuildings",
      "type": "symbol",
      "source": "osm",
      "source-layer": "buildings",
      "minzoom": 16,
      "filter": ["all"],
      "layout": {
        "icon-image": ["concat", ["get", "tourism"], "-18"],
        "visibility": "visible",
        "text-field": ["to-string", ["get", "name"]],
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
      "id": "points_of_interest_fromareasz14",
      "type": "symbol",
      "source": "osm",
      "source-layer": "amenity_areas",
      "minzoom": 14,
      "maxzoom": 16,
      "filter": [
        "in",
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
        "icon-image": ["concat", ["get", "type"], "-12"],
        "visibility": "visible",
        "text-field": ["to-string", ["get", "name"]],
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
      "source-layer": "amenity_areas",
      "minzoom": 16,
      "maxzoom": 24,
      "filter": ["all"],
      "layout": {
        "icon-image": ["concat", ["get", "type"], "-18"],
        "visibility": "visible",
        "text-field": ["to-string", ["get", "name"]],
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
      "id": "points_of_interest_amenity_14",
      "type": "symbol",
      "source": "osm",
      "source-layer": "amenity_points",
      "minzoom": 14,
      "maxzoom": 16,
      "filter": ["all"],
      "layout": {
        "icon-image": ["concat", ["get", "type"], "-18"],
        "visibility": "visible",
        "text-field": ["to-string", ["get", "name"]],
        "text-size": 8,
        "text-anchor": "top",
        "text-offset": [0, 1],
        "text-font": ["OpenHistorical"],
        "icon-size": 0.9
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
      "filter": ["all"],
      "layout": {
        "icon-image": ["concat", ["get", "type"], "-18"],
        "visibility": "visible",
        "text-field": ["to-string", ["get", "name"]],
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
        "icon-size": ["interpolate", ["linear"], ["zoom"], 15, 0.7, 20, 1.4],
        "text-line-height": 1.2
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
        "icon-image": ["concat", ["get", "type"], "-18"],
        "visibility": "visible",
        "text-field": ["to-string", ["get", "name"]],
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
        "text-offset": [0, 1],
        "text-font": ["OpenHistorical"],
        "icon-size": ["interpolate", ["linear"], ["zoom"], 15, 0.7, 20, 1.4],
        "icon-keep-upright": false,
        "text-anchor": "top",
        "icon-text-fit": "none",
        "icon-optional": false,
        "icon-ignore-placement": false,
        "icon-allow-overlap": false,
        "text-max-width": 10
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
        "icon-image": ["concat", ["get", "site_type"], "-18"],
        "visibility": "visible",
        "text-field": ["to-string", ["get", "name"]],
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
        "icon-image": ["concat", ["get", "artwork_type"], "-18"],
        "visibility": "visible",
        "text-field": ["to-string", ["get", "name"]],
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
      "layout": {"icon-image": "airport-18", "text-font": ["OpenHistorical"]}
    },
    {
      "id": "transport_railstation_points",
      "type": "symbol",
      "source": "osm",
      "source-layer": "transport_points",
      "minzoom": 14,
      "maxzoom": 24,
      "filter": [
        "all",
        ["==", ["get", "class"], "railway"],
        ["==", ["get", "type"], "station"]
      ],
      "layout": {
        "icon-image": "railstation-18",
        "visibility": "visible",
        "text-field": ["to-string", ["get", "name"]],
        "text-size": [
          "interpolate",
          ["linear"],
          ["zoom"],
          13.99,
          0,
          14,
          8,
          20,
          10
        ],
        "text-anchor": "top",
        "text-offset": [0, 1],
        "text-font": ["OpenHistorical"],
        "icon-size": 1
      },
      "paint": {
        "icon-color": "#000000",
        "text-color": "rgba(80, 80, 80, 1)",
        "text-halo-color": "rgba(255, 255, 255, 1)",
        "text-halo-width": 2,
        "text-halo-blur": 1,
        "text-opacity": ["interpolate", ["linear"], ["zoom"], 13.99, 0, 14, 1]
      }
    },
    {
      "id": "transport_points",
      "type": "symbol",
      "source": "osm",
      "source-layer": "transport_points",
      "minzoom": 14,
      "maxzoom": 24,
      "filter": [
        "all",
        ["!=", ["get", "class"], "railway"],
        ["==", ["get", "name"], ""]
      ],
      "layout": {
        "icon-image": ["concat", ["get", "type"], "-18"],
        "visibility": "visible",
        "text-field": ["to-string", ["get", "name"]],
        "text-size": [
          "interpolate",
          ["linear"],
          ["zoom"],
          13.99,
          0,
          14,
          8,
          20,
          10
        ],
        "text-anchor": "top",
        "text-offset": [0, 1],
        "text-font": ["OpenHistorical"],
        "icon-size": ["interpolate", ["linear"], ["zoom"], 16, 1, 20, 1.4]
      },
      "paint": {
        "icon-color": "#000000",
        "text-color": "rgba(80, 80, 80, 1)",
        "text-halo-color": "rgba(255, 255, 255, 1)",
        "text-halo-width": 2,
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
        [
          "!", ["in",
          ["get", "religion"],
          ["literal", ["christian", "jewish", "muslim"]]]
        ]
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
        "icon-image": ["concat", ["get", "religion"], "-18"],
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
      "filter": ["in", ["get", "type"], ["literal", ["peak"]]],
      "layout": {
        "icon-image": ["concat", ["get", "type"], "-12"],
        "text-font": ["OpenHistorical"],
        "text-field": ["to-string", ["get", "name"]],
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
        "icon-image": ["concat", ["get", "type"], "-18"],
        "text-font": ["OpenHistorical"],
        "text-field": ["to-string", ["get", "name"]],
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
      "filter": [
        "!", ["in",
        ["get", "type"],
        ["literal", ["garden", "peak", "wetland"]]]
      ],
      "layout": {
        "icon-image": ["concat", ["get", "type"], "-18"],
        "text-font": ["OpenHistorical"],
        "visibility": "visible"
      }
    },
    {
      "id": "points_acra",
      "type": "symbol",
      "source": "osm",
      "source-layer": "buildings",
      "filter": ["match", ["get", "name"], ["ACRA", "Acra"], true, false],
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
      "filter": [
        "in",
        ["get", "name"],
        ["literal", [
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
      "filter": ["all", ["has", "shop"]],
      "layout": {
        "icon-image": ["concat", ["get", "shop"], "-18"],
        "visibility": "visible",
        "text-field": ["to-string", ["get", "name"]],
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
      "minzoom": 9,
      "maxzoom": 20,
      "filter": [
        "all",
        ["==", ["get", "type"], "administrative"],
        ["==", ["get", "admin_level"], 6]
      ],
      "layout": {
        "text-field": ["to-string", ["get", "name"]],
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
      "minzoom": 9,
      "maxzoom": 20,
      "filter": ["in", ["get", "type"], ["literal", ["county"]]],
      "layout": {
        "text-field": ["to-string", ["get", "name"]],
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
      "filter": [
        "in",
        ["get", "type"],
        ["literal", ["hamlet", "islet", "locality", "neighborhood", "suburb", "village"]]
      ],
      "layout": {
        "text-field": ["to-string", ["get", "name"]],
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
      "filter": ["in", ["get", "type"], ["literal", ["town"]]],
      "layout": {
        "text-field": ["to-string", ["get", "name"]],
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
      "filter": ["in", ["get", "type"], ["literal", ["city"]]],
      "layout": {
        "text-field": ["to-string", ["get", "name"]],
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
        "text-field": ["to-string", ["get", "name"]],
        "text-font": ["OpenHistorical"],
        "text-size": ["interpolate", ["linear"], ["zoom"], 6, 12, 10, 15],
        "visibility": "visible",
        "icon-image": "capital-18",
        "icon-offset": [0, 0],
        "icon-size": 1,
        "text-offset": [0, 0.25],
        "text-anchor": "top"
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
        "text-field": ["to-string", ["get", "name"]],
        "text-font": ["OpenHistorical"],
        "text-size": ["interpolate", ["linear"], ["zoom"], 6, 12, 10, 15],
        "visibility": "visible",
        "icon-image": "city-18",
        "icon-offset": [0, 0],
        "icon-size": 1,
        "text-offset": [0, 0.25],
        "text-anchor": "top"
      },
      "paint": {
        "text-color": "rgba(34, 34, 34, 1)",
        "text-halo-color": "rgba(255, 255, 255, 1)",
        "text-halo-blur": 2,
        "text-halo-width": 3
      }
    },
    {
      "id": "state_points_labels-centroids",
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
        "visibility": "visible",
        "text-field": ["to-string", ["get", "name"]],
        "text-font": ["OpenHistorical"],
        "text-size": ["interpolate", ["linear"], ["zoom"], 3, 9, 6, 15, 10, 18],
        "text-line-height": 1,
        "text-transform": "uppercase",
        "symbol-spacing": 25,
        "symbol-avoid-edges": true,
        "symbol-placement": "point"
      },
      "paint": {
        "text-color": "rgba(69, 72, 84, 1)",
        "text-halo-width": 3,
        "text-halo-blur": 2,
        "text-halo-color": "rgba(255, 255, 255, 0.97)",
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
        "visibility": "visible",
        "text-field": ["to-string", ["get", "name"]],
        "text-font": ["OpenHistorical"],
        "text-size": ["interpolate", ["linear"], ["zoom"], 3, 9, 6, 15, 10, 18],
        "text-line-height": 1,
        "text-transform": "uppercase",
        "symbol-spacing": 25,
        "symbol-avoid-edges": true,
        "symbol-placement": "point"
      },
      "paint": {
        "text-color": "rgba(69, 72, 84, 1)",
        "text-halo-width": 3,
        "text-halo-blur": 2,
        "text-halo-color": "rgba(255, 255, 255, 0.97)",
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
        "text-field": ["to-string", ["get", "name"]],
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
      "id": "country_points_labels-centroids",
      "type": "symbol",
      "source": "osm",
      "source-layer": "land_ohm_centroids",
      "minzoom": 0,
      "maxzoom": 12,
      "filter": [
        "all",
        ["==", ["get", "type"], "administrative"],
        ["==", ["get", "admin_level"], 2]
      ],
      "layout": {
        "visibility": "visible",
        "text-field": ["to-string", ["get", "name"]],
        "text-size": [
          "interpolate",
          ["linear"],
          ["zoom"],
          0,
          8,
          3,
          10,
          5,
          12,
          6,
          20,
          10,
          22
        ],
        "text-font": ["OpenHistorical Bold"],
        "symbol-placement": "point",
        "text-justify": "center",
        "symbol-avoid-edges": false
      },
      "paint": {
        "text-color": "rgba(74, 92, 92, 1)",
        "text-halo-width": 3,
        "text-halo-color": "rgba(255, 255, 255, 0.88)",
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
        "visibility": "visible",
        "text-field": ["to-string", ["get", "name"]],
        "text-size": [
          "interpolate",
          ["linear"],
          ["zoom"],
          0,
          8,
          3,
          10,
          5,
          12,
          6,
          20,
          10,
          22
        ],
        "text-font": ["OpenHistorical Bold"],
        "symbol-placement": "point",
        "text-justify": "center",
        "symbol-avoid-edges": false
      },
      "paint": {
        "text-color": "rgba(74, 92, 92, 1)",
        "text-halo-width": 3,
        "text-halo-color": "rgba(255, 255, 255, 0.88)",
        "text-halo-blur": 1,
        "text-opacity": 1,
        "text-translate-anchor": "map"
      }
    }
  ],
  "id": "io6r61fxt"
};
