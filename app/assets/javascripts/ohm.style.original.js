/* extends ohmVectorStyles defined in ohm.style.js */

const spriteSheetUrls_Original = {
  "production": "https://openhistoricalmap.github.io/map-styles/ohm_timeslider_tegola/ohm_spritezero_spritesheet-production",
  "staging": "https://openhistoricalmap.github.io/map-styles/ohm_timeslider_tegola/ohm_spritezero_spritesheet",
};

ohmVectorStyles.Original = {
  "version": 8,
  "name": "ohmbasemap",
  "metadata": {"maputnik:renderer": "mbgljs"},
  "sources": {
    "osm": {
      "type": "vector",
      "tiles": ohmTileServicesLists[ohmTileServiceName],
    }
  },
  "sprite": spriteSheetUrls_Original[ohmTileServiceName],
  "glyphs": "https://openhistoricalmap.github.io/map-styles/fonts/{fontstack}/{range}.pbf",
  "layers": [
    {
      "id": "background",
      "type": "background",
      "minzoom": 0,
      "maxzoom": 20,
      "filter": [
        "all"
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "background-color": "rgba(144, 204, 203, 1)"
      }
    },
    {
      "id": "land",
      "type": "fill",
      "source": "osm",
      "source-layer": "land",
      "minzoom": 0,
      "maxzoom": 24,
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "fill-color": "rgba(248, 247, 242, 1)"
      }
    },
    {
      "id": "military_landuselow",
      "type": "fill",
      "source": "osm",
      "source-layer": "landuse_areas",
      "minzoom": 4,
      "maxzoom": 10,
      "filter": [
        "all",
        [
          "==",
          "type",
          "military"
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "fill-color": "rgba(230, 224, 212, 1)"
      }
    },
    {
      "id": "military-landusehigh",
      "type": "fill",
      "source": "osm",
      "source-layer": "landuse_areas",
      "minzoom": 10,
      "maxzoom": 24,
      "filter": [
        "all",
        [
          "==",
          "type",
          "military"
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "fill-color": "rgba(244, 244, 235, 1)"
      }
    },
    {
      "id": "military",
      "type": "fill",
      "source": "osm",
      "source-layer": "other_areas",
      "filter": [
        "all",
        [
          "==",
          "class",
          "military"
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "fill-color": "rgba(244, 244, 235, 1)"
      }
    },
    {
      "id": "landuse_areas_military_overlay",
      "type": "fill",
      "source": "osm",
      "source-layer": "landuse_areas",
      "minzoom": 10,
      "maxzoom": 24,
      "filter": [
        "all",
        [
          "==",
          "type",
          "military"
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
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
      "filter": [
        "all",
        [
          "==",
          "type",
          "apron"
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "fill-color": "rgba(221, 221, 221, 1)"
      }
    },
    {
      "id": "landuse_areas_park_overlay",
      "type": "fill",
      "source": "osm",
      "source-layer": "landuse_areas",
      "minzoom": 10,
      "maxzoom": 24,
      "filter": [
        "all",
        [
          "==",
          "type",
          "park"
        ]
      ],
      "layout": {
        "visibility": "none"
      },
      "paint": {
        "fill-color": "rgba(208, 220, 174, 1)"
      }
    },
    {
      "id": "landuse_areas_z12_generalized_land_use",
      "type": "fill",
      "source": "osm",
      "source-layer": "landuse_areas",
      "minzoom": 12,
      "maxzoom": 24,
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "fill-color": {
          "property": "type",
          "type": "categorical",
          "stops": [
            [
              {
                "zoom": 0,
                "value": "residential"
              },
              "rgba(241, 238, 238, 1)"
            ],
            [
              {
                "zoom": 0,
                "value": "retail"
              },
              "rgba(237, 236, 231, 1)"
            ],
            [
              {
                "zoom": 0,
                "value": "industrial"
              },
              "rgba(204, 197, 197, 1)"
            ]
          ],
          "default": "transparent"
        }
      }
    },
    {
      "id": "landuse_areas_z12_underlying_land_designation",
      "type": "fill",
      "source": "osm",
      "source-layer": "landuse_areas",
      "minzoom": 12,
      "maxzoom": 24,
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "fill-color": {
          "property": "type",
          "type": "categorical",
          "default": "transparent",
          "stops": [
            [
              {
                "zoom": 0,
                "value": "park"
              },
              "rgba(208, 220, 174, 1)"
            ],
            [
              {
                "zoom": 0,
                "value": "nature_reserve"
              },
              "rgba(178, 194, 157, 0.2)"
            ],
            [
              {
                "zoom": 0,
                "value": "pitch"
              },
              "rgba(69, 150, 7, 0.39)"
            ]
          ]
        }
      }
    },
    {
      "id": "landuse_areas_z12_localized_land_use",
      "type": "fill",
      "source": "osm",
      "source-layer": "landuse_areas",
      "minzoom": 12,
      "maxzoom": 24,
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "fill-color": {
          "property": "type",
          "type": "categorical",
          "stops": [
            [
              {
                "zoom": 0,
                "value": "quarry"
              },
              "rgba(215, 200, 203, 1)"
            ],
            [
              {
                "zoom": 0,
                "value": "landfill"
              },
              "rgba(194, 170, 175, 1)"
            ],
            [
              {
                "zoom": 0,
                "value": "brownfield"
              },
              "rgba(191, 171, 142, 1)"
            ],
            [
              {
                "zoom": 0,
                "value": "commercial"
              },
              "rgba(215, 200, 203, 1)"
            ],
            [
              {
                "zoom": 0,
                "value": "construction"
              },
              "rgba(235, 235, 235, 1)"
            ],
            [
              {
                "zoom": 0,
                "value": "railway"
              },
              "rgba(224, 224, 224, 1)"
            ],
            [
              {
                "zoom": 0,
                "value": "college"
              },
              "rgba(226, 214, 205, 1)"
            ],
            [
              {
                "zoom": 0,
                "value": "school"
              },
              "rgba(226, 214, 205, 1)"
            ],
            [
              {
                "zoom": 0,
                "value": "education"
              },
              "rgba(226, 214, 205, 1)"
            ],
            [
              {
                "zoom": 0,
                "value": "university"
              },
              "rgba(226, 214, 205, 1)"
            ]
          ],
          "default": "transparent"
        }
      }
    },
    {
      "id": "landuse_areas_z12_landcover_short",
      "type": "fill",
      "source": "osm",
      "source-layer": "landuse_areas",
      "minzoom": 12,
      "maxzoom": 24,
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "fill-color": {
          "property": "type",
          "type": "categorical",
          "stops": [
            [
              {
                "zoom": 0,
                "value": "heath"
              },
              "rgba(225, 233, 214, 1)"
            ],
            [
              {
                "zoom": 0,
                "value": "meadow"
              },
              "rgba(225, 233, 214, 1)"
            ],
            [
              {
                "zoom": 0,
                "value": "grass"
              },
              "rgba(208, 220, 174, 1)"
            ],
            [
              {
                "zoom": 0,
                "value": "grassland"
              },
              "rgba(183, 214, 96, 0.81)"
            ],
            [
              {
                "zoom": 0,
                "value": "beach"
              },
              "rgba(236, 235, 180, 1)"
            ],
            [
              {
                "zoom": 0,
                "value": "desert"
              },
              "rgba(238, 229, 178, 1)"
            ],
            [
              {
                "zoom": 0,
                "value": "basin"
              },
              "rgba(144, 204, 203, 1)"
            ],
            [
              {
                "zoom": 0,
                "value": "wetland"
              },
              "rgba(227, 233, 226, 1)"
            ],
            [
              {
                "zoom": 0,
                "value": "salt_pond"
              },
              "rgba(236, 240, 241, 1)"
            ],
            [
              {
                "zoom": 0,
                "value": "mud"
              },
              "rgba(230, 223, 215, 1)"
            ]
          ],
          "default": "transparent"
        }
      }
    },
    {
      "id": "landuse_areas_z12_landcover_tall",
      "type": "fill",
      "source": "osm",
      "source-layer": "landuse_areas",
      "minzoom": 12,
      "maxzoom": 24,
      "filter": [
        "all"
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "fill-color": {
          "property": "type",
          "type": "categorical",
          "stops": [
            [
              {
                "zoom": 0,
                "value": "forest"
              },
              "rgba(178, 194, 157, 1)"
            ],
            [
              {
                "zoom": 0,
                "value": "wood"
              },
              "rgba(178, 194, 157, 1)"
            ],
            [
              {
                "zoom": 0,
                "value": "scrub"
              },
              "rgba(166, 185, 162, 1)"
            ]
          ],
          "default": "transparent"
        }
      }
    },
    {
      "id": "landuse_areas_z12_watercover",
      "type": "fill",
      "source": "osm",
      "source-layer": "landuse_areas",
      "minzoom": 12,
      "maxzoom": 24,
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "fill-color": {
          "property": "type",
          "type": "categorical",
          "default": "transparent",
          "stops": [
            [
              {
                "zoom": 0,
                "value": "wetland"
              },
              "rgba(216, 229, 230, 1)"
            ],
            [
              {
                "zoom": 0,
                "value": "salt_pond"
              },
              "rgba(236, 240, 241, 1)"
            ],
            [
              {
                "zoom": 0,
                "value": "glacier"
              },
              "rgba(255, 255, 255, 1)"
            ],
            [
              {
                "zoom": 0,
                "value": "reservoir"
              },
              "rgba(144, 204, 203, 1)"
            ]
          ]
        }
      }
    },
    {
      "id": "landuse_areas_z12_food_and_farming",
      "type": "fill",
      "source": "osm",
      "source-layer": "landuse_areas",
      "minzoom": 12,
      "maxzoom": 24,
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "fill-color": {
          "property": "type",
          "type": "categorical",
          "default": "transparent",
          "stops": [
            [
              {
                "zoom": 0,
                "value": "farmland"
              },
              "rgba(232, 219, 126, 0.61)"
            ],
            [
              {
                "zoom": 0,
                "value": "farm"
              },
              "rgba(222, 221, 190, 1)"
            ],
            [
              {
                "zoom": 0,
                "value": "orchard"
              },
              "rgba(218, 241, 184, 1)"
            ],
            [
              {
                "zoom": 0,
                "value": "farmyard"
              },
              "rgba(232, 219, 126, 1)"
            ],
            [
              {
                "zoom": 0,
                "value": "vineyard"
              },
              "rgba(180, 172, 199, 1)"
            ],
            [
              {
                "zoom": 0,
                "value": "allotments"
              },
              "rgba(222, 221, 190, 1)"
            ],
            [
              {
                "zoom": 0,
                "value": "garden"
              },
              "rgba(228, 244, 202, 1)"
            ]
          ]
        }
      }
    },
    {
      "id": "landuse_areas_z12_developed_open_space",
      "type": "fill",
      "source": "osm",
      "source-layer": "landuse_areas",
      "minzoom": 12,
      "maxzoom": 24,
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "fill-color": {
          "property": "type",
          "type": "categorical",
          "stops": [
            [
              {
                "zoom": 0,
                "value": "village_green"
              },
              "rgba(208, 220, 174, 1)"
            ],
            [
              {
                "zoom": 0,
                "value": "cemetery"
              },
              "rgba(214, 222, 210, 1)"
            ],
            [
              {
                "zoom": 0,
                "value": "grave_yard"
              },
              "rgba(214, 222, 210, 1)"
            ],
            [
              {
                "zoom": 0,
                "value": "sports_centre"
              },
              "rgba(208, 220, 174, 1)"
            ],
            [
              {
                "zoom": 0,
                "value": "stadium"
              },
              "rgba(208, 220, 174, 1)"
            ],
            [
              {
                "zoom": 0,
                "value": "recreation_ground"
              },
              "rgba(208, 220, 174, 1)"
            ],
            [
              {
                "zoom": 0,
                "value": "picnic_site"
              },
              "rgba(208, 220, 174, 1)"
            ],
            [
              {
                "zoom": 0,
                "value": "camp_site"
              },
              "rgba(208, 220, 174, 1)"
            ],
            [
              {
                "zoom": 0,
                "value": "playground"
              },
              "rgba(208, 220, 174, 1)"
            ],
            [
              {
                "zoom": 0,
                "value": "bleachers"
              },
              "rgba(220, 215, 215, 1)"
            ]
          ],
          "default": "transparent"
        },
        "fill-outline-color": {
          "property": "type",
          "type": "categorical",
          "stops": [
            [
              {
                "zoom": 0,
                "value": "bleachers"
              },
              "rgba(195, 188, 188, 1)"
            ],
            [
              {
                "zoom": 0,
                "value": "playground"
              },
              "rgba(208, 220, 174, 1)"
            ]
          ],
          "default": "transparent"
        }
      }
    },
    {
      "id": "landuse_areas_z10",
      "type": "fill",
      "source": "osm",
      "source-layer": "landuse_areas",
      "minzoom": 10,
      "maxzoom": 12,
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "fill-color": {
          "property": "type",
          "type": "categorical",
          "stops": [
            [
              {
                "zoom": 0,
                "value": "park"
              },
              "rgba(208, 220, 174, 1)"
            ],
            [
              {
                "zoom": 0,
                "value": "forest"
              },
              "rgba(178, 194, 157, 1)"
            ],
            [
              {
                "zoom": 0,
                "value": "wood"
              },
              "rgba(178, 194, 157, 1)"
            ],
            [
              {
                "zoom": 0,
                "value": "nature_reserve"
              },
              "rgba(178, 194, 157, 0.3)"
            ],
            [
              {
                "zoom": 0,
                "value": "landfill"
              },
              "rgba(194, 170, 175, 1)"
            ]
          ],
          "default": "transparent"
        }
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
        "all",
        [
          "in",
          "type",
          "forest",
          "wood",
          "nature_reserve",
          "park"
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "fill-color": {
          "stops": [
            [
              6,
              "rgba(178, 194, 157, 0.2)"
            ],
            [
              9,
              "rgba(178, 194, 157, 0.3)"
            ]
          ]
        }
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
        [
          "in",
          "type",
          "forest",
          "wood"
        ],
        [
          ">",
          "area",
          50000000
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "fill-color": "rgba(178, 194, 157, 1)"
      }
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
        [
          "in",
          "type",
          "forest",
          "wood"
        ],
        [
          ">",
          "area",
          500000000
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "fill-color": "rgba(178, 194, 157, 1)"
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
      "id": "wetlands_z12",
      "type": "fill",
      "source": "osm",
      "source-layer": "landuse_areas",
      "minzoom": 12,
      "maxzoom": 24,
      "filter": [
        "all",
        [
          "==",
          "type",
          "wetland"
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "fill-color": "rgba(255, 255, 255, 1)",
        "fill-pattern": "wetland-18"
      }
    },
    {
      "id": "place_areas_plot",
      "type": "fill",
      "source": "osm",
      "source-layer": "place_areas",
      "filter": [
        "all",
        [
          "==",
          "type",
          "plot"
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
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
      "filter": [
        "all",
        [
          "==",
          "type",
          "square"
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
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
        [
          "in",
          "type",
          "pedestrian",
          "footway"
        ],
        [
          "==",
          "area",
          "yes"
        ]
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
      "filter": [
        "all",
        [
          "in",
          "type",
          "school",
          "university"
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "fill-color": "rgba(226, 214, 205, 1)"
      }
    },
    {
      "id": "landuse_naturereserveoutline",
      "type": "line",
      "source": "osm",
      "source-layer": "landuse_areas",
      "minzoom": 10,
      "maxzoom": 24,
      "filter": [
        "all",
        [
          "==",
          "type",
          "nature_reserve"
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "line-width": {
          "stops": [
            [
              10,
              2
            ],
            [
              20,
              3
            ]
          ]
        },
        "line-dasharray": [
          2.5,
          1.5
        ],
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
        "all",
        [
          "in",
          "type",
          "scree",
          "peak",
          "rock",
          "bare_rock"
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "fill-color": "rgba(255, 255, 255, 1)",
        "fill-pattern": "rock"
      }
    },
    {
      "id": "water_areas",
      "type": "fill",
      "source": "osm",
      "source-layer": "water_areas",
      "minzoom": 3,
      "maxzoom": 24,
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "fill-color": "rgba(144, 204, 203, 1)"
      }
    },
    {
      "id": "place_areas_islet",
      "type": "fill",
      "source": "osm",
      "source-layer": "place_areas",
      "filter": [
        "all",
        [
          "==",
          "type",
          "islet"
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "fill-color": "rgba(248, 247, 242, 1)",
        "fill-outline-color": "rgba(226, 223, 215, 1)"
      }
    },
    {
      "id": "water_lines_stream",
      "type": "line",
      "source": "osm",
      "source-layer": "water_lines",
      "minzoom": 13,
      "maxzoom": 24,
      "filter": [
        "all",
        [
          "==",
          "type",
          "stream"
        ]
      ],
      "paint": {
        "line-color": "rgba(144, 204, 203, 1)",
        "line-width": {
          "stops": [
            [
              13,
              0.5
            ],
            [
              15,
              0.8
            ],
            [
              20,
              2
            ]
          ]
        }
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
        [
          "in",
          "type",
          "cliff"
        ],
        [
          "!in",
          "surface",
          "water"
        ]
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
        [
          "in",
          "type",
          "cliff"
        ],
        [
          "!in",
          "surface",
          "water"
        ]
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
      "id": "water_lines_waterfall_line-copy",
      "type": "line",
      "source": "osm",
      "source-layer": "water_lines",
      "minzoom": 15,
      "maxzoom": 24,
      "filter": [
        "all",
        [
          "in",
          "type",
          "cliff"
        ],
        [
          "in",
          "surface",
          "water"
        ]
      ],
      "layout": {
        "line-cap": "butt",
        "line-join": "miter",
        "visibility": "none"
      },
      "paint": {
        "line-color": "rgba(68, 136, 136, 1)",
        "line-translate-anchor": "viewport",
        "line-width": 1,
        "line-offset": 1
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
        [
          "in",
          "type",
          "cliff"
        ],
        [
          "in",
          "surface",
          "water"
        ]
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
      "filter": [
        "all",
        [
          "in",
          "type",
          "ditch",
          "drain"
        ]
      ],
      "paint": {
        "line-color": "rgba(144, 204, 203, 1)",
        "line-width": {
          "stops": [
            [
              15,
              0.2
            ],
            [
              20,
              1.5
            ]
          ]
        }
      }
    },
    {
      "id": "water_lines_canal",
      "type": "line",
      "source": "osm",
      "source-layer": "water_lines",
      "minzoom": 8,
      "maxzoom": 24,
      "filter": [
        "all",
        [
          "==",
          "type",
          "canal"
        ]
      ],
      "paint": {
        "line-color": "rgba(144, 204, 203, 1)",
        "line-width": {
          "stops": [
            [
              8,
              0.5
            ],
            [
              13,
              0.5
            ],
            [
              14,
              1
            ],
            [
              20,
              3
            ]
          ]
        }
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
        [
          "==",
          "type",
          "canal"
        ],
        [
          "==",
          "bridge",
          "aqueduct"
        ]
      ],
      "paint": {
        "line-color": "rgba(108, 178, 176, 1)",
        "line-width": {
          "stops": [
            [
              8,
              0.5
            ],
            [
              13,
              0.5
            ],
            [
              14,
              1
            ],
            [
              20,
              3
            ]
          ]
        },
        "line-dasharray": [
          2,
          2
        ]
      }
    },
    {
      "id": "water_lines_river",
      "type": "line",
      "source": "osm",
      "source-layer": "water_lines",
      "minzoom": 8,
      "maxzoom": 24,
      "filter": [
        "all",
        [
          "==",
          "type",
          "river"
        ]
      ],
      "paint": {
        "line-color": "rgba(144, 204, 203, 1)",
        "line-width": {
          "stops": [
            [
              8,
              1
            ],
            [
              12,
              1.5
            ],
            [
              13,
              2
            ],
            [
              14,
              5
            ],
            [
              20,
              12
            ]
          ]
        }
      }
    },
    {
      "id": "water_lines_dam",
      "type": "line",
      "source": "osm",
      "source-layer": "water_lines",
      "minzoom": 13,
      "maxzoom": 24,
      "filter": [
        "all",
        [
          "==",
          "type",
          "dam"
        ]
      ],
      "paint": {
        "line-color": "rgba(133, 133, 133, 1)",
        "line-width": {
          "stops": [
            [
              13,
              0.5
            ],
            [
              15,
              0.8
            ],
            [
              20,
              2
            ]
          ]
        }
      }
    },
    {
      "id": "pier",
      "type": "fill",
      "source": "osm",
      "source-layer": "other_areas",
      "filter": [
        "all",
        [
          "==",
          "type",
          "pier"
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "fill-color": "rgba(240, 233, 219, 1)"
      }
    },
    {
      "id": "pier_line",
      "type": "line",
      "source": "osm",
      "source-layer": "other_lines",
      "minzoom": 12,
      "filter": [
        "all",
        [
          "==",
          "type",
          "pier"
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "line-color": "rgba(230, 222, 205, 1)",
        "line-width": {
          "stops": [
            [
              12,
              2
            ],
            [
              18,
              7
            ]
          ]
        }
      }
    },
    {
      "id": "buildings_flat",
      "type": "fill",
      "source": "osm",
      "source-layer": "buildings",
      "minzoom": 14,
      "maxzoom": 24,
      "filter": [
        "all"
      ],
      "layout": {
        "visibility": "visible"
      },
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
        [
          "==",
          "class",
          "historic"
        ],
        [
          "==",
          "type",
          "ruins"
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "fill-color": "rgba(224, 224, 224, 1)"
      }
    },
    {
      "id": "buildings_ruins_outlines",
      "type": "line",
      "source": "osm",
      "source-layer": "other_areas",
      "filter": [
        "all",
        [
          "==",
          "type",
          "ruins"
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "line-color": "rgba(195, 188, 188, 1)",
        "line-opacity": 1,
        "line-width": {
          "stops": [
            [
              10,
              1
            ],
            [
              16,
              2
            ]
          ]
        },
        "line-dasharray": {
          "stops": [
            [
              10,
              [
                1,
                1
              ]
            ],
            [
              16,
              [
                4,
                2
              ]
            ]
          ]
        }
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
        [
          "==",
          "class",
          "historic"
        ],
        [
          "==",
          "type",
          "fort"
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
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
      "filter": [
        "all",
        [
          "==",
          "type",
          "taxiway"
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "line-color": "rgba(220, 220, 220, 1)",
        "line-width": {
          "stops": [
            [
              12,
              1
            ],
            [
              13,
              1.5
            ],
            [
              18,
              4
            ]
          ]
        }
      }
    },
    {
      "id": "aero_runway_lines",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 12,
      "maxzoom": 24,
      "filter": [
        "all",
        [
          "==",
          "type",
          "runway"
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "line-color": "rgba(220, 220, 220, 1)",
        "line-width": {
          "stops": [
            [
              12,
              1.5
            ],
            [
              18,
              25
            ]
          ]
        }
      }
    },
    {
      "id": "city_county_lines_admin7_8",
      "type": "line",
      "source": "osm",
      "source-layer": "land_ohm",
      "minzoom": 10,
      "maxzoom": 20,
      "filter": [
        "all",
        [
          "in",
          "admin_level",
          7,
          8
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "line-color": "rgba(210, 210, 210, 1)",
        "line-dasharray": [
          2,
          2
        ],
        "line-width": {
          "stops": [
            [
              10,
              1
            ],
            [
              12,
              1.5
            ]
          ]
        }
      }
    },
    {
      "id": "admin_admin5_6",
      "type": "line",
      "source": "osm",
      "source-layer": "land_ohm",
      "minzoom": 7,
      "maxzoom": 20,
      "filter": [
        "all",
        [
          "in",
          "admin_level",
          5,
          6
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "line-color": "rgba(179, 179, 179, 1)",
        "line-dasharray": [
          2,
          2
        ],
        "line-width": {
          "stops": [
            [
              6,
              0.5
            ],
            [
              10,
              1.5
            ]
          ]
        }
      }
    },
    {
      "id": "state_lines_admin4",
      "type": "line",
      "source": "osm",
      "source-layer": "land_ohm",
      "minzoom": 3,
      "maxzoom": 20,
      "filter": [
        "all",
        [
          "==",
          "admin_level",
          4
        ],
        [
          "==",
          "type",
          "administrative"
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "line-color": "rgba(202, 196, 196, 1)",
        "line-dasharray": [
          3,
          2
        ],
        "line-width": {
          "stops": [
            [
              2,
              0.25
            ],
            [
              14,
              2
            ]
          ]
        }
      }
    },
    {
      "id": "man_made_bridge_area",
      "type": "fill",
      "source": "osm",
      "source-layer": "other_areas",
      "filter": [
        "all",
        [
          "==",
          "class",
          "man_made"
        ],
        [
          "==",
          "type",
          "bridge"
        ]
      ],
      "paint": {
        "fill-color": "rgba(255, 255, 255, 1)"
      }
    },
    {
      "id": "man_made_bridge_line",
      "type": "line",
      "source": "osm",
      "source-layer": "other_lines",
      "filter": [
        "all",
        [
          "==",
          "class",
          "man_made"
        ],
        [
          "==",
          "type",
          "bridge"
        ]
      ],
      "paint": {
        "line-color": "rgba(255, 255, 255, 1)",
        "line-width": 3
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
        [
          "in",
          "type",
          "construction"
        ],
        [
          "in",
          "construction",
          "subway"
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "line-color": "rgba(153, 153, 153, 1)",
        "line-width": [
          "interpolate",
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          11,
          0.5,
          18,
          4
        ],
        "line-dasharray": [
          4,
          1
        ]
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
        [
          "==",
          "type",
          "construction"
        ],
        [
          "==",
          "tunnel",
          1
        ],
        [
          "==",
          "construction",
          "tertiary"
        ]
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
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          9,
          1,
          18,
          36
        ],
        "line-dasharray": [
          0.5,
          1.25
        ]
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
        [
          "==",
          "type",
          "construction"
        ],
        [
          "==",
          "tunnel",
          1
        ],
        [
          "==",
          "construction",
          "secondary"
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
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          8,
          1,
          18,
          38
        ],
        "line-dasharray": [
          0.5,
          1.25
        ]
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
        [
          "in",
          "type",
          "construction"
        ],
        [
          "==",
          "tunnel",
          1
        ],
        [
          "==",
          "construction",
          "primary"
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
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          7,
          1,
          18,
          42
        ],
        "line-dasharray": [
          0.5,
          1.25
        ]
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
        [
          "in",
          "type",
          "construction"
        ],
        [
          "==",
          "tunnel",
          1
        ],
        [
          "in",
          "construction",
          "motorway",
          "motorway_link",
          "trunk",
          "trunk_link"
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
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          5,
          1,
          18,
          46
        ],
        "line-dasharray": [
          0.5,
          1.25
        ]
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
        [
          "==",
          "type",
          "construction"
        ],
        [
          "==",
          "tunnel",
          1
        ],
        [
          "==",
          "construction",
          "tertiary"
        ]
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
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
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
        [
          "==",
          "type",
          "construction"
        ],
        [
          "==",
          "tunnel",
          1
        ],
        [
          "==",
          "construction",
          "secondary"
        ]
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
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
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
        [
          "==",
          "type",
          "construction"
        ],
        [
          "==",
          "tunnel",
          1
        ],
        [
          "==",
          "construction",
          "primary"
        ]
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
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
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
        [
          "in",
          "type",
          "construction"
        ],
        [
          "==",
          "tunnel",
          1
        ],
        [
          "in",
          "construction",
          "motorway",
          "motorway_link",
          "trunk",
          "trunk_link"
        ]
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
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
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
        [
          "in",
          "type",
          "construction"
        ],
        [
          "==",
          "construction",
          "raceway"
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "line-color": "rgba(255, 249, 241, 1)",
        "line-width": [
          "interpolate",
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          11,
          0.2,
          18,
          12
        ],
        "line-dasharray": [
          0.75,
          0.1
        ]
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
        [
          "==",
          "type",
          "construction"
        ],
        [
          "==",
          "construction",
          "track"
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "line-color": "#b3b3b3",
        "line-width": [
          "interpolate",
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
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
        [
          "==",
          "type",
          "construction"
        ],
        [
          "==",
          "construction",
          "track"
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "line-color": "rgba(251, 247, 245, 1)",
        "line-width": [
          "interpolate",
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
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
        [
          "==",
          "type",
          "construction"
        ],
        [
          "==",
          "construction",
          "track"
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "line-color": "#b3b3b3",
        "line-dasharray": [
          0.3,
          1
        ],
        "line-width": [
          "interpolate",
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
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
        [
          "in",
          "type",
          "construction"
        ],
        [
          "in",
          "construction",
          "living_street"
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "line-color": "rgba(255, 255, 255, 1)",
        "line-width": [
          "interpolate",
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
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
        [
          "in",
          "type",
          "construction"
        ],
        [
          "==",
          "construction",
          "pedestrian"
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "line-color": "#ffffff",
        "line-width": [
          "interpolate",
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
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
        [
          "in",
          "type",
          "construction"
        ],
        [
          "in",
          "construction",
          "footway",
          "cycleway",
          "path"
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "line-color": "rgba(225, 225, 225, 1)",
        "line-width": [
          "interpolate",
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          11,
          0.2,
          18,
          3
        ],
        "line-dasharray": [
          2,
          1
        ]
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
        [
          "==",
          "type",
          "construction"
        ],
        [
          "==",
          "construction",
          "pier"
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "line-color": "#ffffff",
        "line-width": [
          "interpolate",
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
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
        [
          "in",
          "type",
          "construction"
        ],
        [
          "in",
          "construction",
          "steps"
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "line-color": "#b3b3b3",
        "line-width": [
          "interpolate",
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          11,
          0.5,
          18,
          6
        ],
        "line-dasharray": [
          0.1,
          0.3
        ]
      }
    },
    {
      "id": "roads_other_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 14,
      "maxzoom": 24,
      "filter": [
        "all",
        [
          "in",
          "type",
          "construction"
        ],
        [
          "in",
          "construction",
          "unclassified",
          "living_street",
          "raceway"
        ]
      ],
      "layout": {
        "visibility": "none"
      },
      "paint": {
        "line-color": "rgba(255, 207, 0, 1)",
        "line-width": {
          "stops": [
            [
              14,
              4
            ],
            [
              18,
              16
            ]
          ]
        }
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
        [
          "in",
          "type",
          "construction"
        ],
        [
          "==",
          "bridge",
          0
        ],
        [
          "in",
          "construction",
          "residential",
          "service",
          "unclassified"
        ]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "#E6E6E6",
        "line-width": [
          "interpolate",
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          13,
          3,
          18,
          15
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
        [
          "==",
          "type",
          "construction"
        ],
        [
          "!=",
          "tunnel",
          1
        ],
        [
          "==",
          "construction",
          "tertiary"
        ],
        [
          "!=",
          "bridge",
          1
        ]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "#E6E6E6",
        "line-width": [
          "interpolate",
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
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
        [
          "==",
          "type",
          "construction"
        ],
        [
          "!=",
          "tunnel",
          1
        ],
        [
          "==",
          "construction",
          "secondary"
        ],
        [
          "!=",
          "bridge",
          1
        ]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(230, 230, 230, 1)",
        "line-width": [
          "interpolate",
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
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
        [
          "in",
          "type",
          "construction"
        ],
        [
          "!=",
          "tunnel",
          1
        ],
        [
          "==",
          "construction",
          "primary_link"
        ],
        [
          "!=",
          "bridge",
          1
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
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
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
      "minzoom": 7,
      "filter": [
        "all",
        [
          "in",
          "type",
          "construction"
        ],
        [
          "!=",
          "tunnel",
          1
        ],
        [
          "!=",
          "ford",
          "yes"
        ],
        [
          "in",
          "construction",
          "primary"
        ],
        [
          "!=",
          "bridge",
          1
        ]
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
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
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
        [
          "in",
          "type",
          "construction"
        ],
        [
          "!=",
          "tunnel",
          1
        ],
        [
          "in",
          "construction",
          "motorway_link",
          "trunk_link"
        ],
        [
          "!=",
          "bridge",
          1
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
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
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
      "minzoom": 6,
      "maxzoom": 20,
      "filter": [
        "all",
        [
          "in",
          "type",
          "construction"
        ],
        [
          "!=",
          "tunnel",
          1
        ],
        [
          "in",
          "construction",
          "motorway",
          "trunk"
        ],
        [
          "!=",
          "bridge",
          1
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
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
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
        [
          "in",
          "type",
          "construction"
        ],
        [
          "in",
          "construction",
          "road"
        ]
      ],
      "layout": {
        "visibility": "none",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(255, 0, 0, 1)",
        "line-width": [
          "interpolate",
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          12,
          0.5,
          18,
          5
        ],
        "line-dasharray": [
          3,
          1.5
        ]
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
        [
          "in",
          "type",
          "construction"
        ],
        [
          "in",
          "construction",
          "residential",
          "service",
          "unclassified"
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
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          12,
          1.5,
          18,
          12
        ],
        "line-dasharray": [
          3,
          1.5
        ]
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
        [
          "==",
          "type",
          "construction"
        ],
        [
          "!=",
          "tunnel",
          1
        ],
        [
          "==",
          "construction",
          "secondary_link"
        ],
        [
          "!=",
          "bridge",
          1
        ]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": {
          "stops": [
            [
              10,
              "rgba(240, 240, 240, 1)"
            ],
            [
              12,
              "#ffffff"
            ]
          ]
        },
        "line-width": [
          "interpolate",
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          8,
          0.5,
          18,
          30
        ],
        "line-dasharray": [
          3,
          1.5
        ]
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
        [
          "in",
          "type",
          "construction"
        ],
        [
          "!=",
          "tunnel",
          1
        ],
        [
          "==",
          "construction",
          "primary_link"
        ],
        [
          "!=",
          "bridge",
          1
        ]
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
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          6,
          0.75,
          18,
          32
        ],
        "line-dasharray": [
          3,
          1.5
        ]
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
        [
          "in",
          "type",
          "construction"
        ],
        [
          "!=",
          "tunnel",
          1
        ],
        [
          "in",
          "construction",
          "motorway_link",
          "trunk_link"
        ],
        [
          "!=",
          "bridge",
          1
        ]
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
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          5,
          1,
          18,
          36
        ],
        "line-dasharray": [
          3,
          1.5
        ]
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
        [
          "==",
          "type",
          "construction"
        ],
        [
          "!=",
          "tunnel",
          1
        ],
        [
          "==",
          "construction",
          "tertiary"
        ],
        [
          "!=",
          "bridge",
          1
        ]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": {
          "stops": [
            [
              10,
              "rgba(240, 240, 240, 1)"
            ],
            [
              12,
              "#ffffff"
            ]
          ]
        },
        "line-width": [
          "interpolate",
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          9,
          0.8,
          18,
          24
        ],
        "line-dasharray": [
          3,
          1.5
        ]
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
        [
          "==",
          "type",
          "construction"
        ],
        [
          "!=",
          "tunnel",
          1
        ],
        [
          "==",
          "construction",
          "secondary"
        ],
        [
          "!=",
          "bridge",
          1
        ]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": {
          "stops": [
            [
              10,
              "rgba(240, 240, 240, 1)"
            ],
            [
              12,
              "#ffffff"
            ]
          ]
        },
        "line-width": [
          "interpolate",
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          8,
          0.5,
          18,
          30
        ],
        "line-dasharray": [
          3,
          1.5
        ]
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
        [
          "in",
          "type",
          "construction"
        ],
        [
          "!=",
          "tunnel",
          1
        ],
        [
          "!=",
          "ford",
          "yes"
        ],
        [
          "==",
          "construction",
          "primary"
        ],
        [
          "!=",
          "bridge",
          1
        ]
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
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          6,
          0.75,
          18,
          32
        ],
        "line-dasharray": [
          3,
          1.5
        ]
      }
    },
    {
      "id": "roads_motorway_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 5,
      "maxzoom": 20,
      "filter": [
        "all",
        [
          "in",
          "type",
          "construction"
        ],
        [
          "!=",
          "tunnel",
          1
        ],
        [
          "in",
          "construction",
          "motorway",
          "trunk"
        ],
        [
          "!=",
          "bridge",
          1
        ]
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
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          5,
          1,
          18,
          36
        ],
        "line-dasharray": [
          3,
          1.5
        ]
      }
    },
    {
      "id": "roads_ford_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 9,
      "filter": [
        "all",
        [
          "==",
          "ford",
          "yes"
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "line-color": "#ffffff",
        "line-width": [
          "interpolate",
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          11,
          0.9,
          18,
          30
        ],
        "line-dasharray": [
          2,
          1
        ]
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
        [
          "in",
          "type",
          "construction"
        ],
        [
          "==",
          "bridge",
          1
        ],
        [
          "in",
          "construction",
          "residential",
          "service",
          "unclassified"
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
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
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
        [
          "==",
          "type",
          "construction"
        ],
        [
          "==",
          "bridge",
          1
        ],
        [
          "==",
          "construction",
          "tertiary"
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
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          11,
          4,
          18,
          48
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
        [
          "==",
          "type",
          "construction"
        ],
        [
          "==",
          "bridge",
          1
        ],
        [
          "==",
          "construction",
          "secondary"
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
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          8,
          3.2,
          18,
          50
        ]
      }
    },
    {
      "id": "roads_primarybridge_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 7,
      "maxzoom": 20,
      "filter": [
        "all",
        [
          "in",
          "type",
          "construction"
        ],
        [
          "==",
          "bridge",
          1
        ],
        [
          "in",
          "construction",
          "primary",
          "primary_link"
        ]
      ],
      "layout": {
        "line-cap": "butt",
        "visibility": "visible",
        "line-join": "round"
      },
      "paint": {
        "line-color": "#ffffff",
        "line-width": [
          "interpolate",
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          7,
          3.5,
          18,
          52
        ]
      }
    },
    {
      "id": "roads_motorwaybridge_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 5,
      "maxzoom": 20,
      "filter": [
        "all",
        [
          "in",
          "type",
          "construction"
        ],
        [
          "==",
          "bridge",
          1
        ],
        [
          "in",
          "construction",
          "motorway",
          "motorway_link",
          "trunk",
          "trunk_link"
        ]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "butt",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(255, 255, 255, 1)",
        "line-width": [
          "interpolate",
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          5,
          3,
          18,
          58
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
        [
          "in",
          "type",
          "construction"
        ],
        [
          "==",
          "bridge",
          1
        ],
        [
          "in",
          "construction",
          "residential",
          "service",
          "unclassified"
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
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          12,
          0.5,
          18,
          12
        ],
        "line-dasharray": [
          3,
          1.5
        ]
      }
    },
    {
      "id": "roads_tertiarybridgetop_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 9,
      "maxzoom": 24,
      "filter": [
        "all",
        [
          "==",
          "type",
          "construction"
        ],
        [
          "==",
          "bridge",
          1
        ],
        [
          "==",
          "construction",
          "tertiary"
        ]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": {
          "stops": [
            [
              10,
              "rgba(217, 217, 217, 1)"
            ],
            [
              11,
              "#ffffff"
            ]
          ]
        },
        "line-width": [
          "interpolate",
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          9,
          0.8,
          18,
          24
        ],
        "line-dasharray": [
          3,
          1.5
        ]
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
        [
          "==",
          "type",
          "construction"
        ],
        [
          "==",
          "bridge",
          1
        ],
        [
          "==",
          "construction",
          "secondary"
        ]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": {
          "stops": [
            [
              10,
              "rgba(217, 217, 217, 1)"
            ],
            [
              11,
              "#ffffff"
            ]
          ]
        },
        "line-width": [
          "interpolate",
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          8,
          0.5,
          18,
          30
        ],
        "line-dasharray": [
          3,
          1.5
        ]
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
        [
          "in",
          "type",
          "construction"
        ],
        [
          "==",
          "bridge",
          1
        ],
        [
          "in",
          "construction",
          "primary"
        ]
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
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          6,
          0.75,
          18,
          32
        ],
        "line-dasharray": [
          3,
          1.5
        ]
      }
    },
    {
      "id": "roads_motorwaybridgetop_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 5,
      "maxzoom": 20,
      "filter": [
        "all",
        [
          "in",
          "type",
          "construction"
        ],
        [
          "==",
          "bridge",
          1
        ],
        [
          "in",
          "construction",
          "motorway",
          "motorway_link",
          "trunk",
          "trunk_link"
        ]
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
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          5,
          1,
          18,
          36
        ],
        "line-dasharray": [
          3,
          1.5
        ]
      }
    },
    {
      "id": "roads_rail_tram_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 7,
      "maxzoom": 24,
      "filter": [
        "all",
        [
          "in",
          "type",
          "tram",
          "funicular",
          "monorail"
        ],
        [
          "!in",
          "service",
          "yard",
          "siding"
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "line-color": "rgba(197, 197, 197, 1)",
        "line-width": {
          "stops": [
            [
              12,
              1
            ],
            [
              13,
              1
            ],
            [
              14,
              1.25
            ],
            [
              20,
              2.25
            ]
          ]
        },
        "line-dasharray": [
          3,
          1.5
        ]
      }
    },
    {
      "id": "roads_subways",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 14,
      "filter": [
        "all",
        [
          "in",
          "type",
          "subway"
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "line-color": "rgba(153, 153, 153, 1)",
        "line-width": [
          "interpolate",
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          11,
          0.5,
          18,
          4
        ],
        "line-dasharray": [
          4,
          1
        ]
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
        [
          "==",
          "type",
          "tertiary"
        ],
        [
          "==",
          "tunnel",
          1
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
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          9,
          1,
          18,
          36
        ],
        "line-dasharray": [
          0.5,
          1.25
        ]
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
        [
          "==",
          "type",
          "secondary"
        ],
        [
          "==",
          "tunnel",
          1
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
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          8,
          1,
          18,
          38
        ],
        "line-dasharray": [
          0.5,
          1.25
        ]
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
        [
          "in",
          "type",
          "primary"
        ],
        [
          "==",
          "tunnel",
          1
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
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          7,
          1,
          18,
          42
        ],
        "line-dasharray": [
          0.5,
          1.25
        ]
      }
    },
    {
      "id": "roads_motorwaytunnel_case",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 5,
      "maxzoom": 20,
      "filter": [
        "all",
        [
          "in",
          "type",
          "motorway",
          "motorway_link",
          "trunk",
          "trunk_link"
        ],
        [
          "==",
          "tunnel",
          1
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
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          5,
          1,
          18,
          46
        ],
        "line-dasharray": [
          0.5,
          1.25
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
        [
          "==",
          "type",
          "tertiary"
        ],
        [
          "==",
          "tunnel",
          1
        ]
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
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
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
        [
          "==",
          "type",
          "secondary"
        ],
        [
          "==",
          "tunnel",
          1
        ]
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
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
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
        [
          "==",
          "type",
          "primary"
        ],
        [
          "==",
          "tunnel",
          1
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "line-color": "rgba(241, 218, 187, 1)",
        "line-width": [
          "interpolate",
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
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
          "type",
          "motorway",
          "motorway_link",
          "trunk",
          "trunk_link"
        ],
        [
          "==",
          "tunnel",
          1
        ]
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
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
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
      "filter": [
        "in",
        "type",
        "raceway"
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "line-color": "rgba(255, 249, 241, 1)",
        "line-width": [
          "interpolate",
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          11,
          0.2,
          18,
          12
        ],
        "line-dasharray": [
          0.75,
          0.1
        ]
      }
    },
    {
      "id": "roads_trackfillcase",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 14,
      "maxzoom": 24,
      "filter": [
        "all",
        [
          "==",
          "type",
          "track"
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "line-color": "#b3b3b3",
        "line-width": [
          "interpolate",
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
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
      "filter": [
        "all",
        [
          "==",
          "type",
          "track"
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "line-color": "rgba(251, 247, 245, 1)",
        "line-width": [
          "interpolate",
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
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
      "filter": [
        "all",
        [
          "==",
          "type",
          "track"
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "line-color": "#b3b3b3",
        "line-dasharray": [
          0.3,
          1
        ],
        "line-width": [
          "interpolate",
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
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
      "filter": [
        "all",
        [
          "in",
          "type",
          "living_street"
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "line-color": "rgba(255, 255, 255, 1)",
        "line-width": [
          "interpolate",
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          11,
          0.2,
          18,
          6
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
      "filter": [
        "all",
        [
          "in",
          "type",
          "pedestrian"
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "line-color": "#ffffff",
        "line-width": [
          "interpolate",
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
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
        "all",
        [
          "in",
          "type",
          "footway",
          "cycleway",
          "path"
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "line-color": "#b3b3b3",
        "line-width": [
          "interpolate",
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          11,
          0.2,
          18,
          3
        ],
        "line-dasharray": [
          2,
          1
        ]
      }
    },
    {
      "id": "roads_pier",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 14,
      "maxzoom": 24,
      "filter": [
        "all",
        [
          "==",
          "type",
          "pier"
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "line-color": "#ffffff",
        "line-width": [
          "interpolate",
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
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
      "filter": [
        "all",
        [
          "in",
          "type",
          "steps"
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "line-color": "#b3b3b3",
        "line-width": [
          "interpolate",
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          11,
          0.5,
          18,
          6
        ],
        "line-dasharray": [
          0.1,
          0.3
        ]
      }
    },
    {
      "id": "roads_other",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 14,
      "maxzoom": 24,
      "filter": [
        "all",
        [
          "in",
          "type",
          "unclassified",
          "living_street",
          "raceway"
        ]
      ],
      "layout": {
        "visibility": "none"
      },
      "paint": {
        "line-color": "rgba(255, 207, 0, 1)",
        "line-width": {
          "stops": [
            [
              14,
              4
            ],
            [
              18,
              16
            ]
          ]
        }
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
          "type",
          "residential",
          "service",
          "unclassified"
        ],
        [
          "!=",
          "bridge",
          1
        ]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "#E6E6E6",
        "line-width": [
          "interpolate",
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          13,
          3,
          18,
          15
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
        [
          "==",
          "type",
          "tertiary"
        ],
        [
          "!=",
          "tunnel",
          1
        ],
        [
          "!=",
          "bridge",
          1
        ]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "#E6E6E6",
        "line-width": [
          "interpolate",
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          10,
          2.2,
          18,
          28
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
        [
          "==",
          "type",
          "secondary"
        ],
        [
          "!=",
          "tunnel",
          1
        ],
        [
          "!=",
          "bridge",
          1
        ]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(230, 230, 230, 1)",
        "line-width": [
          "interpolate",
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          10,
          2.4,
          18,
          35
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
        [
          "in",
          "type",
          "primary_link"
        ],
        [
          "!=",
          "tunnel",
          1
        ],
        [
          "!=",
          "bridge",
          1
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
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
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
      "minzoom": 7,
      "filter": [
        "all",
        [
          "in",
          "type",
          "primary"
        ],
        [
          "!=",
          "tunnel",
          1
        ],
        [
          "!=",
          "ford",
          "yes"
        ],
        [
          "!=",
          "bridge",
          1
        ]
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
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          7,
          2,
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
          "type",
          "motorway_link",
          "trunk_link"
        ],
        [
          "!=",
          "tunnel",
          1
        ],
        [
          "!=",
          "bridge",
          1
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
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          6,
          2,
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
      "minzoom": 6,
      "maxzoom": 20,
      "filter": [
        "all",
        [
          "in",
          "type",
          "motorway",
          "trunk"
        ],
        [
          "!=",
          "tunnel",
          1
        ],
        [
          "!=",
          "bridge",
          1
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
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          6,
          2,
          18,
          46
        ]
      }
    },
    {
      "id": "roads_roads",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 12,
      "maxzoom": 24,
      "filter": [
        "all",
        [
          "in",
          "type",
          "road"
        ]
      ],
      "layout": {
        "visibility": "none",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(255, 0, 0, 1)",
        "line-width": [
          "interpolate",
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          12,
          0.5,
          18,
          5
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
        [
          "in",
          "type",
          "proposed"
        ],
        [
          "!in",
          "class",
          "railway"
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
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          12,
          1.5,
          18,
          12
        ],
        "line-dasharray": [
          1,
          2
        ]
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
        "all",
        [
          "in",
          "type",
          "residential",
          "service",
          "unclassified"
        ],
        [
          "==",
          "name",
          ""
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
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          12,
          1.5,
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
        [
          "==",
          "type",
          "secondary_link"
        ],
        [
          "!=",
          "tunnel",
          1
        ],
        [
          "!=",
          "bridge",
          1
        ]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": {
          "stops": [
            [
              10,
              "rgba(240, 240, 240, 1)"
            ],
            [
              12,
              "#ffffff"
            ]
          ]
        },
        "line-width": [
          "interpolate",
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          8,
          0.5,
          18,
          30
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
        [
          "in",
          "type",
          "primary_link"
        ],
        [
          "!=",
          "tunnel",
          1
        ],
        [
          "!=",
          "bridge",
          1
        ]
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
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
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
      "minzoom": 5,
      "maxzoom": 20,
      "filter": [
        "all",
        [
          "in",
          "type",
          "motorway_link",
          "trunk_link"
        ],
        [
          "!=",
          "tunnel",
          1
        ],
        [
          "!=",
          "bridge",
          1
        ]
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
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          5,
          1,
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
        [
          "==",
          "type",
          "tertiary"
        ],
        [
          "!=",
          "tunnel",
          1
        ],
        [
          "!=",
          "bridge",
          1
        ]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": {
          "stops": [
            [
              10,
              "rgba(240, 240, 240, 1)"
            ],
            [
              12,
              "#ffffff"
            ]
          ]
        },
        "line-width": [
          "interpolate",
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          9,
          0.8,
          18,
          24
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
        [
          "==",
          "type",
          "secondary"
        ],
        [
          "!=",
          "tunnel",
          1
        ],
        [
          "!=",
          "bridge",
          1
        ]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": {
          "stops": [
            [
              10,
              "rgba(240, 240, 240, 1)"
            ],
            [
              12,
              "#ffffff"
            ]
          ]
        },
        "line-width": [
          "interpolate",
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
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
        [
          "in",
          "type",
          "primary"
        ],
        [
          "!=",
          "tunnel",
          1
        ],
        [
          "!=",
          "ford",
          "yes"
        ],
        [
          "!=",
          "bridge",
          1
        ]
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
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          6,
          0.75,
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
      "minzoom": 5,
      "maxzoom": 20,
      "filter": [
        "all",
        [
          "in",
          "type",
          "motorway",
          "trunk"
        ],
        [
          "!=",
          "tunnel",
          1
        ],
        [
          "!=",
          "bridge",
          1
        ]
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
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          5,
          1,
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
      "filter": [
        "all",
        [
          "==",
          "ford",
          "yes"
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "line-color": "#ffffff",
        "line-width": [
          "interpolate",
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          11,
          0.9,
          18,
          30
        ],
        "line-dasharray": [
          2,
          1
        ]
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
        [
          "in",
          "type",
          "miniature",
          "narrow_gauge"
        ],
        [
          "!in",
          "service",
          "yard",
          "siding"
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "line-color": "rgba(179, 179, 179, 1)",
        "line-width": {
          "stops": [
            [
              12,
              1
            ],
            [
              13,
              1
            ],
            [
              14,
              1.25
            ],
            [
              20,
              2.25
            ]
          ]
        }
      }
    },
    {
      "id": "roads_rail_mini_cross",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 7,
      "maxzoom": 24,
      "filter": [
        "all",
        [
          "in",
          "type",
          "miniature",
          "narrow_gauge"
        ],
        [
          "!in",
          "service",
          "yard",
          "siding"
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "line-color": "rgba(179, 179, 179, 1)",
        "line-width": 4,
        "line-dasharray": [
          0.2,
          2
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
          "type",
          "dismantled",
          "abandoned",
          "disused",
          "razed"
        ],
        [
          "!in",
          "service",
          "yard",
          "siding"
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "line-color": "rgba(210, 190, 190, 1)",
        "line-width": {
          "stops": [
            [
              12,
              1
            ],
            [
              13,
              1
            ],
            [
              14,
              1.25
            ],
            [
              20,
              2.25
            ]
          ]
        }
      }
    },
    {
      "id": "roads_rail_old_cross",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 7,
      "maxzoom": 24,
      "filter": [
        "all",
        [
          "in",
          "type",
          "dismantled",
          "abandoned",
          "disused",
          "razed"
        ],
        [
          "!in",
          "service",
          "yard",
          "siding"
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "line-color": "rgba(210, 190, 190, 1)",
        "line-width": 6,
        "line-dasharray": [
          0.2,
          2
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
        [
          "in",
          "type",
          "rail",
          "light_rail",
          "preserved"
        ],
        [
          "!in",
          "service",
          "yard",
          "siding"
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "line-color": "rgba(179, 179, 179, 1)",
        "line-width": {
          "stops": [
            [
              12,
              1
            ],
            [
              13,
              1
            ],
            [
              14,
              1.25
            ],
            [
              20,
              2.25
            ]
          ]
        }
      }
    },
    {
      "id": "roads_rail_cross",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 7,
      "maxzoom": 24,
      "filter": [
        "all",
        [
          "in",
          "type",
          "rail",
          "light_rail",
          "preserved"
        ],
        [
          "!in",
          "service",
          "yard",
          "siding"
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "line-color": "rgba(179, 179, 179, 1)",
        "line-width": {
          "stops": [
            [
              6,
              2
            ],
            [
              7,
              3
            ],
            [
              8,
              4
            ],
            [
              9,
              5
            ],
            [
              10,
              6
            ]
          ]
        },
        "line-dasharray": [
          0.2,
          2
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
        [
          "in",
          "type",
          "construction",
          "proposed"
        ],
        [
          "in",
          "class",
          "railway"
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "line-color": "rgba(215, 215, 215, 1)",
        "line-width": {
          "stops": [
            [
              12,
              1
            ],
            [
              13,
              1
            ],
            [
              14,
              1.25
            ],
            [
              20,
              2.25
            ]
          ]
        }
      }
    },
    {
      "id": "roads_rail_construction_cross",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 7,
      "maxzoom": 24,
      "filter": [
        "all",
        [
          "in",
          "type",
          "construction",
          "proposed"
        ],
        [
          "in",
          "class",
          "railway"
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "line-color": "rgba(215, 215, 215, 1)",
        "line-width": 6,
        "line-dasharray": [
          0.2,
          2
        ]
      }
    },
    {
      "id": "roads_residential_bridge_z13-copy",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 13,
      "maxzoom": 24,
      "filter": [
        "all",
        [
          "in",
          "type",
          "residential",
          "service",
          "unclassified"
        ],
        [
          "==",
          "bridge",
          1
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
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
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
        [
          "==",
          "type",
          "tertiary"
        ],
        [
          "==",
          "bridge",
          1
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
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          11,
          4,
          18,
          48
        ]
      }
    },
    {
      "id": "roads_secondarybridge",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 8,
      "filter": [
        "all",
        [
          "==",
          "type",
          "secondary"
        ],
        [
          "==",
          "bridge",
          1
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
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          8,
          3.2,
          18,
          50
        ]
      }
    },
    {
      "id": "roads_primarybridge",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 7,
      "maxzoom": 20,
      "filter": [
        "all",
        [
          "in",
          "type",
          "primary",
          "primary_link"
        ],
        [
          "==",
          "bridge",
          1
        ]
      ],
      "layout": {
        "line-cap": "butt",
        "visibility": "visible",
        "line-join": "round"
      },
      "paint": {
        "line-color": "#ffffff",
        "line-width": [
          "interpolate",
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          7,
          3.5,
          18,
          52
        ]
      }
    },
    {
      "id": "roads_motorwaybridge",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 5,
      "maxzoom": 20,
      "filter": [
        "all",
        [
          "in",
          "type",
          "motorway",
          "motorway_link",
          "trunk",
          "trunk_link"
        ],
        [
          "==",
          "bridge",
          1
        ]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "butt",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(255, 255, 255, 1)",
        "line-width": [
          "interpolate",
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          5,
          3,
          18,
          58
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
          "type",
          "residential",
          "service",
          "unclassified"
        ],
        [
          "==",
          "bridge",
          1
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
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
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
      "minzoom": 9,
      "maxzoom": 24,
      "filter": [
        "all",
        [
          "==",
          "type",
          "tertiary"
        ],
        [
          "==",
          "bridge",
          1
        ]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": {
          "stops": [
            [
              10,
              "rgba(217, 217, 217, 1)"
            ],
            [
              11,
              "#ffffff"
            ]
          ]
        },
        "line-width": [
          "interpolate",
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
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
        [
          "==",
          "type",
          "secondary"
        ],
        [
          "==",
          "bridge",
          1
        ]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": {
          "stops": [
            [
              10,
              "rgba(217, 217, 217, 1)"
            ],
            [
              11,
              "#ffffff"
            ]
          ]
        },
        "line-width": [
          "interpolate",
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
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
        [
          "in",
          "type",
          "primary"
        ],
        [
          "==",
          "bridge",
          1
        ]
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
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
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
      "minzoom": 5,
      "maxzoom": 20,
      "filter": [
        "all",
        [
          "in",
          "type",
          "motorway",
          "motorway_link",
          "trunk",
          "trunk_link"
        ],
        [
          "==",
          "bridge",
          1
        ]
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
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
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
      "minzoom": 7,
      "maxzoom": 24,
      "filter": [
        "all",
        [
          "in",
          "type",
          "tram",
          "funicular",
          "monorail"
        ],
        [
          "!in",
          "service",
          "yard",
          "siding"
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "line-color": "rgba(197, 197, 197, 1)",
        "line-width": {
          "stops": [
            [
              12,
              1
            ],
            [
              13,
              1
            ],
            [
              14,
              1.25
            ],
            [
              20,
              2.25
            ]
          ]
        }
      }
    },
    {
      "id": "roads_secondary_z8",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 8,
      "maxzoom": 9,
      "filter": [
        "all",
        [
          "in",
          "type",
          "secondary"
        ]
      ],
      "layout": {
        "visibility": "none"
      },
      "paint": {
        "line-color": {
          "stops": [
            [
              7,
              "#b3b3b3"
            ],
            [
              8,
              "rgba(210, 210, 210, 1)"
            ]
          ]
        },
        "line-width": [
          "interpolate",
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          7,
          0.1,
          9,
          0.6
        ]
      }
    },
    {
      "id": "roads_trunk_z7",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 7,
      "maxzoom": 9,
      "filter": [
        "all",
        [
          "in",
          "type",
          "trunk",
          "primary"
        ]
      ],
      "layout": {
        "visibility": "none"
      },
      "paint": {
        "line-color": {
          "stops": [
            [
              7,
              "#b3b3b3"
            ],
            [
              9,
              "#EAEAEA"
            ]
          ]
        },
        "line-width": [
          "interpolate",
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          7,
          0.25,
          9,
          1
        ]
      }
    },
    {
      "id": "roads_motorway_z7",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 6,
      "maxzoom": 9,
      "filter": [
        "all",
        [
          "==",
          "type",
          "motorway"
        ]
      ],
      "layout": {
        "visibility": "none"
      },
      "paint": {
        "line-color": {
          "stops": [
            [
              6,
              "#b3b3b3"
            ],
            [
              9,
              "#EAEAEA"
            ]
          ]
        },
        "line-width": [
          "interpolate",
          [
            "exponential",
            1.5
          ],
          [
            "zoom"
          ],
          6,
          0.5,
          9,
          1.5
        ]
      }
    },
    {
      "id": "admin_admin3",
      "type": "line",
      "source": "osm",
      "source-layer": "land_ohm",
      "minzoom": 3,
      "maxzoom": 20,
      "filter": [
        "all",
        [
          "==",
          "admin_level",
          3
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "line-color": "rgba(181, 195, 199, 1)",
        "line-width": {
          "stops": [
            [
              2,
              0.25
            ],
            [
              7,
              2
            ]
          ]
        }
      }
    },
    {
      "id": "admin_countrylines_z10",
      "type": "line",
      "source": "osm",
      "source-layer": "land_ohm",
      "minzoom": 0,
      "maxzoom": 20,
      "filter": [
        "all",
        [
          "in",
          "admin_level",
          1,
          2
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "line-color": "rgba(157, 169, 174, 1)",
        "line-width": {
          "stops": [
            [
              2,
              0.25
            ],
            [
              14,
              3
            ]
          ]
        }
      }
    },
    {
      "id": "roadlabels_z14",
      "type": "symbol",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 14,
      "filter": [
        "all"
      ],
      "layout": {
        "text-field": "{name}",
        "symbol-placement": "line",
        "symbol-spacing": 250,
        "symbol-avoid-edges": false,
        "text-size": 10,
        "text-padding": 2,
        "text-allow-overlap": false,
        "text-pitch-alignment": "auto",
        "text-rotation-alignment": "auto",
        "text-font": [
          "OpenHistorical"
        ]
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
      "filter": [
        "all",
        [
          "in",
          "type",
          "motorway",
          "trunk"
        ]
      ],
      "layout": {
        "text-field": "{name}",
        "symbol-placement": "line",
        "symbol-spacing": 250,
        "symbol-avoid-edges": false,
        "text-size": 10,
        "text-padding": 2,
        "text-allow-overlap": false,
        "text-pitch-alignment": "auto",
        "text-rotation-alignment": "auto",
        "text-font": [
          "OpenHistorical"
        ]
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
      "source-layer": "water_areas",
      "minzoom": 15,
      "maxzoom": 24,
      "filter": [
        "all",
        [
          ">",
          "area",
          100000
        ]
      ],
      "layout": {
        "text-field": "{name}",
        "text-font": [
          "OpenHistorical Italic"
        ],
        "text-padding": 2,
        "text-allow-overlap": false,
        "text-size": {
          "stops": [
            [
              15,
              11
            ],
            [
              20,
              20
            ]
          ]
        }
      },
      "paint": {
        "text-color": "rgba(68, 136, 136, 1)",
        "text-halo-width": 1,
        "text-halo-color": "rgba(178, 220, 220, 1)"
      }
    },
    {
      "id": "water_areaslabels_z12",
      "type": "symbol",
      "source": "osm",
      "source-layer": "water_areas",
      "minzoom": 12,
      "maxzoom": 15,
      "filter": [
        "all",
        [
          ">",
          "area",
          1000000
        ]
      ],
      "layout": {
        "text-field": "{name}",
        "text-font": [
          "OpenHistorical Italic"
        ],
        "text-padding": 2,
        "text-allow-overlap": false,
        "text-size": {
          "stops": [
            [
              11,
              11
            ],
            [
              13,
              13
            ]
          ]
        },
        "symbol-placement": "point"
      },
      "paint": {
        "text-color": "rgba(43, 102, 102, 1)",
        "text-halo-width": 1,
        "text-halo-color": "rgba(207, 230, 230, 1)"
      }
    },
    {
      "id": "water_pointlabels_ocean_sea",
      "type": "symbol",
      "source": "osm",
      "source-layer": "place_points",
      "minzoom": 0,
      "maxzoom": 24,
      "filter": [
        "all",
        [
          "in",
          "type",
          "ocean",
          "sea"
        ]
      ],
      "layout": {
        "text-field": "{name}",
        "text-font": [
          "OpenHistorical Italic"
        ],
        "text-padding": 2,
        "text-allow-overlap": false,
        "text-size": {
          "stops": [
            [
              8,
              12
            ],
            [
              11,
              13
            ],
            [
              13,
              14
            ]
          ]
        },
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
      "filter": [
        "all",
        [
          ">",
          "area",
          10000000
        ]
      ],
      "layout": {
        "text-field": "{name}",
        "text-font": [
          "OpenHistorical Italic"
        ],
        "text-padding": 2,
        "text-allow-overlap": false,
        "text-size": {
          "stops": [
            [
              8,
              10
            ],
            [
              11,
              11
            ],
            [
              13,
              13
            ]
          ]
        }
      },
      "paint": {
        "text-color": "rgba(43, 102, 102, 1)",
        "text-halo-width": 1,
        "text-halo-color": "rgba(207, 230, 230, 1)"
      }
    },
    {
      "id": "water_lineslabels-cliff",
      "type": "symbol",
      "source": "osm",
      "source-layer": "water_lines",
      "filter": [
        "all",
        [
          "in",
          "type",
          "cliff"
        ]
      ],
      "layout": {
        "text-field": "{name}",
        "text-font": [
          "OpenHistorical Italic"
        ],
        "symbol-placement": "line",
        "symbol-spacing": 500,
        "text-anchor": "bottom",
        "text-pitch-alignment": "auto",
        "text-rotation-alignment": "auto",
        "text-size": {
          "stops": [
            [
              11,
              9
            ],
            [
              13,
              11
            ]
          ]
        },
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
      "filter": [
        "all",
        [
          "in",
          "type",
          "dam"
        ]
      ],
      "layout": {
        "text-field": "{name}",
        "text-font": [
          "OpenHistorical Italic"
        ],
        "symbol-placement": "line",
        "symbol-spacing": 500,
        "text-anchor": "bottom",
        "text-pitch-alignment": "auto",
        "text-rotation-alignment": "auto",
        "text-size": {
          "stops": [
            [
              11,
              11
            ],
            [
              13,
              13
            ]
          ]
        },
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
      "filter": [
        "all",
        [
          "!in",
          "type",
          "dam",
          "cliff"
        ]
      ],
      "layout": {
        "text-field": "{name}",
        "text-font": [
          "OpenHistorical Italic"
        ],
        "symbol-placement": "line",
        "symbol-spacing": 500,
        "text-anchor": "bottom",
        "text-pitch-alignment": "auto",
        "text-rotation-alignment": "auto",
        "text-size": {
          "stops": [
            [
              11,
              11
            ],
            [
              13,
              13
            ]
          ]
        },
        "text-letter-spacing": 0,
        "visibility": "visible"
      },
      "paint": {
        "text-color": "rgba(109, 146, 146, 1)",
        "text-halo-color": "rgba(233, 244, 244, 1)",
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
          "type",
          "park",
          "sports_centre",
          "stadium",
          "grass",
          "grassland",
          "garden",
          "village_green",
          "recreation_ground",
          "picnic_site",
          "camp_site",
          "playground"
        ],
        [
          ">",
          "area",
          12000
        ]
      ],
      "layout": {
        "text-field": "{name}",
        "text-size": {
          "stops": [
            [
              14,
              11
            ],
            [
              20,
              14
            ]
          ]
        },
        "visibility": "visible",
        "icon-text-fit": "none",
        "text-allow-overlap": false,
        "text-ignore-placement": false,
        "text-font": [
          "OpenHistorical"
        ]
      },
      "paint": {
        "text-color": "rgba(122, 143, 61, 1)",
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
        "all",
        [
          "in",
          "type",
          "farmland",
          "farm",
          "orchard",
          "farmyard",
          "vineyard",
          "allotmets",
          "garden"
        ]
      ],
      "layout": {
        "text-field": "{name}",
        "text-size": 11,
        "text-font": [
          "OpenHistorical"
        ]
      },
      "paint": {
        "text-color": "rgba(107, 101, 71, 1)",
        "text-halo-color": "rgba(213, 211, 190, 1)",
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
        "all",
        [
          "in",
          "type",
          "forest",
          "wood",
          "nature_reserve"
        ]
      ],
      "layout": {
        "text-field": "{name}",
        "text-size": 11,
        "text-font": [
          "OpenHistorical"
        ]
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
        "all",
        [
          "in",
          "type",
          "college",
          "school",
          "education",
          "university",
          ""
        ]
      ],
      "layout": {
        "text-field": "{name}",
        "text-size": 11,
        "text-font": [
          "OpenHistorical"
        ]
      },
      "paint": {
        "text-color": "rgba(176, 130, 130, 1)",
        "text-halo-color": "rgba(245, 239, 239, 1)",
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
        "all",
        [
          "in",
          "type",
          "village",
          "suburb",
          "locality",
          "hamlet",
          "islet"
        ]
      ],
      "layout": {
        "text-field": "{name}",
        "text-font": [
          "OpenHistorical"
        ],
        "text-size": {
          "stops": [
            [
              6,
              4
            ],
            [
              10,
              10
            ],
            [
              16,
              12
            ]
          ]
        },
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
      "filter": [
        "all",
        [
          "in",
          "type",
          "town"
        ]
      ],
      "layout": {
        "text-field": "{name}",
        "text-font": [
          "OpenHistorical"
        ],
        "text-size": {
          "stops": [
            [
              6,
              6
            ],
            [
              10,
              12
            ],
            [
              16,
              14
            ]
          ]
        },
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
      "filter": [
        "all",
        [
          "in",
          "type",
          "city"
        ]
      ],
      "layout": {
        "text-field": "{name}",
        "text-font": [
          "OpenHistorical"
        ],
        "text-size": {
          "stops": [
            [
              6,
              8
            ],
            [
              10,
              14
            ],
            [
              16,
              16
            ]
          ]
        },
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
        [
          "==",
          "type",
          "city"
        ],
        [
          "==",
          "capital",
          "yes"
        ]
      ],
      "layout": {
        "text-field": "{name}",
        "text-font": [
          "OpenHistorical"
        ],
        "text-size": {
          "stops": [
            [
              6,
              8
            ],
            [
              10,
              14
            ]
          ]
        },
        "visibility": "visible",
        "icon-image": "capital-18",
        "icon-offset": [
          0,
          0
        ],
        "icon-size": 1,
        "text-offset": {
          "stops": [
            [
              6,
              [
                0,
                1.2
              ]
            ],
            [
              10,
              [
                0,
                1
              ]
            ]
          ]
        }
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
        [
          "==",
          "type",
          "city"
        ],
        [
          "!=",
          "capital",
          "yes"
        ]
      ],
      "layout": {
        "text-field": "{name}",
        "text-font": [
          "OpenHistorical"
        ],
        "text-size": {
          "stops": [
            [
              6,
              8
            ],
            [
              10,
              14
            ]
          ]
        },
        "visibility": "visible",
        "icon-image": "city-18",
        "icon-offset": [
          0,
          0
        ],
        "icon-size": 1,
        "text-offset": {
          "stops": [
            [
              6,
              [
                0,
                1.2
              ]
            ],
            [
              10,
              [
                0,
                1
              ]
            ]
          ]
        }
      },
      "paint": {
        "text-color": "rgba(34, 34, 34, 1)",
        "text-halo-color": "rgba(255, 255, 255, 1)",
        "text-halo-blur": 2,
        "text-halo-width": 1
      }
    },
    {
      "id": "state_labels",
      "type": "symbol",
      "source": "osm",
      "source-layer": "state_label_points",
      "minzoom": 5,
      "maxzoom": 10,
      "filter": [
        "all",
        [
          "==",
          "scalerank",
          2
        ]
      ],
      "layout": {
        "text-field": "{name}",
        "text-font": [
          "OpenHistorical"
        ],
        "text-size": {
          "stops": [
            [
              4,
              7
            ],
            [
              10,
              16
            ]
          ]
        },
        "visibility": "none"
      },
      "paint": {
        "text-color": "rgba(166, 166, 170, 1)",
        "text-halo-color": "rgba(255, 255, 255, 1)",
        "text-halo-width": 1,
        "text-halo-blur": 1
      }
    },
    {
      "id": "state_points_labels",
      "type": "symbol",
      "source": "osm",
      "source-layer": "place_points",
      "minzoom": 3,
      "maxzoom": 20,
      "filter": [
        "all",
        [
          "in",
          "type",
          "state",
          "territory"
        ]
      ],
      "layout": {
        "visibility": "visible",
        "text-field": "{name}",
        "text-font": [
          "OpenHistorical"
        ],
        "text-size": {
          "stops": [
            [
              6,
              10
            ],
            [
              10,
              14
            ]
          ]
        },
        "text-line-height": 1,
        "text-transform": "uppercase",
        "symbol-spacing": 25,
        "symbol-avoid-edges": true,
        "symbol-placement": "point"
      },
      "paint": {
        "text-color": "rgba(101, 108, 108, 1)",
        "text-halo-width": 1,
        "text-halo-blur": 2,
        "text-halo-color": "rgba(220, 231, 232, 1)"
      }
    },
    {
      "id": "state_lines_labels",
      "type": "symbol",
      "source": "osm",
      "source-layer": "land_ohm",
      "minzoom": 4,
      "maxzoom": 20,
      "filter": [
        "all",
        [
          "==",
          "admin_level",
          4
        ],
        [
          "==",
          "type",
          "administrative"
        ]
      ],
      "layout": {
        "visibility": "none",
        "text-field": "{name}",
        "text-font": [
          "OpenHistorical"
        ],
        "text-size": {
          "stops": [
            [
              6,
              10
            ],
            [
              10,
              14
            ]
          ]
        },
        "text-line-height": 1,
        "text-transform": "uppercase",
        "symbol-spacing": 25,
        "symbol-avoid-edges": true,
        "symbol-placement": "point"
      },
      "paint": {
        "text-color": "rgba(101, 108, 108, 1)",
        "text-halo-width": 1,
        "text-halo-blur": 2,
        "text-halo-color": "rgba(220, 231, 232, 1)"
      }
    },
    {
      "id": "statecapital_labels_z10",
      "type": "symbol",
      "source": "osm",
      "source-layer": "populated_places",
      "minzoom": 10,
      "maxzoom": 20,
      "filter": [
        "all",
        [
          "==",
          "featurecla",
          "Admin-1 capital"
        ]
      ],
      "layout": {
        "text-field": "{name}",
        "text-font": [
          "OpenHistorical Bold"
        ],
        "text-size": 10,
        "text-transform": "uppercase",
        "visibility": "none"
      },
      "paint": {
        "text-color": "rgba(68, 51, 85, 1)",
        "text-halo-color": "rgba(255, 255, 255, 1)",
        "text-halo-width": 1,
        "text-halo-blur": 1
      }
    },
    {
      "id": "statecapital_labels_z4",
      "type": "symbol",
      "source": "osm",
      "source-layer": "populated_places",
      "minzoom": 4,
      "maxzoom": 10,
      "filter": [
        "all",
        [
          "==",
          "featurecla",
          "Admin-1 capital"
        ]
      ],
      "layout": {
        "text-field": "{name}",
        "text-font": [
          "OpenHistorical Bold"
        ],
        "text-size": {
          "stops": [
            [
              4,
              7
            ],
            [
              10,
              10
            ]
          ]
        },
        "visibility": "none"
      },
      "paint": {
        "text-color": "rgba(68, 51, 85, 1)",
        "text-halo-color": "rgba(255, 255, 255, 1)",
        "text-halo-width": 1,
        "text-halo-blur": 1
      }
    },
    {
      "id": "capital_labels_z10",
      "type": "symbol",
      "source": "osm",
      "source-layer": "populated_places",
      "minzoom": 10,
      "maxzoom": 20,
      "filter": [
        "all",
        [
          "==",
          "featurecla",
          "Admin-0 capital"
        ]
      ],
      "layout": {
        "text-field": "{name}",
        "text-font": [
          "OpenHistorical Bold"
        ],
        "text-size": 11,
        "text-transform": "uppercase",
        "visibility": "none"
      },
      "paint": {
        "text-color": "rgba(68, 51, 85, 1)",
        "text-halo-color": "rgba(255, 255, 255, 1)",
        "text-halo-width": 1,
        "text-halo-blur": 1
      }
    },
    {
      "id": "capital_labels_z3",
      "type": "symbol",
      "source": "osm",
      "source-layer": "populated_places",
      "minzoom": 3,
      "maxzoom": 10,
      "filter": [
        "all",
        [
          "==",
          "featurecla",
          "Admin-0 capital"
        ]
      ],
      "layout": {
        "text-field": "{name}",
        "text-font": [
          "OpenHistorical Bold"
        ],
        "text-size": {
          "stops": [
            [
              3,
              9
            ],
            [
              10,
              11
            ]
          ]
        },
        "visibility": "none"
      },
      "paint": {
        "text-color": "rgba(68, 51, 85, 1)",
        "text-halo-color": "rgba(255, 255, 255, 1)",
        "text-halo-width": 1,
        "text-halo-blur": 1
      }
    },
    {
      "id": "country_labels",
      "type": "symbol",
      "source": "osm",
      "source-layer": "country_label_points",
      "minzoom": 3,
      "maxzoom": 7,
      "filter": [
        "all",
        [
          "==",
          "scalerank",
          0
        ]
      ],
      "layout": {
        "text-field": "{sr_subunit}",
        "text-font": [
          "OpenHistorical Bold"
        ],
        "text-size": {
          "stops": [
            [
              3,
              11
            ],
            [
              7,
              13
            ]
          ]
        },
        "visibility": "none"
      },
      "paint": {
        "text-color": "rgba(68, 51, 85, 1)",
        "text-halo-color": "rgba(255, 255, 255, 1)",
        "text-halo-width": 1,
        "text-halo-blur": 5
      }
    },
    {
      "id": "country_points_labels",
      "type": "symbol",
      "source": "osm",
      "source-layer": "place_points",
      "minzoom": 0,
      "maxzoom": 14,
      "filter": [
        "all",
        [
          "==",
          "type",
          "country"
        ]
      ],
      "layout": {
        "visibility": "visible",
        "text-field": "{name}",
        "text-size": {
          "stops": [
            [
              4,
              12
            ],
            [
              6,
              14
            ],
            [
              8,
              16
            ]
          ]
        },
        "text-font": [
          "OpenHistorical Bold"
        ],
        "symbol-placement": "point",
        "text-justify": "center",
        "symbol-avoid-edges": false
      },
      "paint": {
        "text-color": "rgba(101, 108, 108, 1)",
        "text-halo-width": 1,
        "text-halo-color": "rgba(220, 231, 232, 1)",
        "text-halo-blur": 2,
        "text-opacity": 1,
        "text-translate-anchor": "map"
      }
    },
    {
      "id": "admin_countryl_labels",
      "type": "symbol",
      "source": "osm",
      "source-layer": "land_ohm",
      "minzoom": 0,
      "maxzoom": 14,
      "filter": [
        "all",
        [
          "==",
          "admin_level",
          2
        ]
      ],
      "layout": {
        "visibility": "none",
        "text-field": "{name}",
        "text-size": {
          "stops": [
            [
              4,
              10
            ],
            [
              6,
              12
            ],
            [
              8,
              14
            ]
          ]
        },
        "text-font": [
          "OpenHistorical Bold"
        ],
        "symbol-placement": "point",
        "text-justify": "center",
        "symbol-avoid-edges": false
      },
      "paint": {
        "text-color": "rgba(101, 108, 108, 1)",
        "text-halo-width": 1,
        "text-halo-color": "rgba(220, 231, 232, 1)",
        "text-halo-blur": 2,
        "text-opacity": 1,
        "text-translate-anchor": "map"
      }
    },
    {
      "id": "power_lines",
      "type": "line",
      "source": "osm",
      "source-layer": "other_lines",
      "filter": [
        "all",
        [
          "==",
          "class",
          "power"
        ],
        [
          "==",
          "type",
          "line"
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "line-color": "rgba(164, 129, 136, 1)"
      }
    },
    {
      "id": "barriers-dotted",
      "type": "line",
      "source": "osm",
      "source-layer": "other_lines",
      "filter": [
        "all",
        [
          "==",
          "type",
          "bollard"
        ]
      ],
      "paint": {
        "line-color": "rgba(217, 217, 217, 1)",
        "line-width": 3,
        "line-dasharray": [
          1,
          1
        ]
      }
    },
    {
      "id": "barriers",
      "type": "line",
      "source": "osm",
      "source-layer": "other_lines",
      "filter": [
        "all"
      ],
      "paint": {
        "line-color": {
          "property": "type",
          "type": "categorical",
          "default": "transparent",
          "stops": [
            [
              {
                "zoom": 0,
                "value": "wall"
              },
              "rgba(223, 223, 223, 1)"
            ],
            [
              {
                "zoom": 0,
                "value": "fence"
              },
              "rgba(233, 228, 216, 1)"
            ],
            [
              {
                "zoom": 0,
                "value": "wood_fence"
              },
              "rgba(241, 224, 200, 1)"
            ],
            [
              {
                "zoom": 0,
                "value": "hedge"
              },
              "rgba(204, 218, 190, 1)"
            ],
            [
              {
                "zoom": 0,
                "value": "hedge_bank"
              },
              "rgba(204, 218, 190, 1)"
            ],
            [
              {
                "zoom": 0,
                "value": "retaining_wall"
              },
              "rgba(223, 223, 223, 1)"
            ],
            [
              {
                "zoom": 0,
                "value": "city_wall"
              },
              "rgba(223, 223, 223, 1)"
            ]
          ]
        },
        "line-width": 2
      }
    },
    {
      "id": "points_of_interest_place_areas",
      "type": "symbol",
      "source": "osm",
      "source-layer": "place_areas",
      "minzoom": 16,
      "filter": [
        "all"
      ],
      "layout": {
        "visibility": "visible",
        "text-field": "{name}",
        "text-size": 9,
        "text-anchor": "center",
        "text-offset": [
          0,
          0
        ],
        "text-font": [
          "OpenHistorical"
        ]
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
      "filter": [
        "all"
      ],
      "layout": {
        "icon-image": "{tourism}-18",
        "visibility": "visible",
        "text-field": "{name}",
        "text-size": 9,
        "text-anchor": "center",
        "text-offset": [
          0,
          0
        ],
        "text-font": [
          "OpenHistorical"
        ]
      },
      "paint": {
        "text-color": "rgba(108, 132, 137, 1)",
        "text-halo-color": "rgba(255, 255, 255, 1)",
        "text-halo-width": 0.5,
        "text-halo-blur": 1
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
        "all",
        [
          "in",
          "type",
          "fire_station",
          "bank",
          "border_control",
          "embassy",
          "government",
          "hospital",
          "police",
          "school",
          "taxi",
          "townhall",
          "university"
        ]
      ],
      "layout": {
        "icon-image": "{type}-12",
        "visibility": "visible",
        "text-field": "{name}",
        "text-size": 8,
        "text-anchor": "top",
        "text-offset": [
          0,
          1
        ],
        "text-font": [
          "OpenHistorical"
        ]
      },
      "paint": {
        "text-color": "rgba(108, 132, 137, 1)",
        "text-halo-color": "rgba(255, 255, 255, 1)",
        "text-halo-width": 0.5,
        "text-halo-blur": 1
      }
    },
    {
      "id": "points_of_interest_fromareas",
      "type": "symbol",
      "source": "osm",
      "source-layer": "amenity_areas",
      "minzoom": 16,
      "maxzoom": 24,
      "filter": [
        "all"
      ],
      "layout": {
        "icon-image": "{type}-18",
        "visibility": "visible",
        "text-field": "{name}",
        "text-size": 8,
        "text-anchor": "top",
        "text-offset": [
          0,
          1
        ],
        "text-font": [
          "OpenHistorical"
        ]
      },
      "paint": {
        "text-color": "rgba(108, 132, 137, 1)",
        "text-halo-color": "rgba(255, 255, 255, 1)",
        "text-halo-width": 0.5,
        "text-halo-blur": 1
      }
    },
    {
      "id": "points_of_interest_amenity_14",
      "type": "symbol",
      "source": "osm",
      "source-layer": "amenity_points",
      "minzoom": 14,
      "maxzoom": 16,
      "filter": [
        "all"
      ],
      "layout": {
        "icon-image": "{type}-12",
        "visibility": "visible",
        "text-field": "{name}",
        "text-size": 8,
        "text-anchor": "top",
        "text-offset": [
          0,
          1
        ],
        "text-font": [
          "OpenHistorical"
        ]
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
      "minzoom": 16,
      "maxzoom": 24,
      "filter": [
        "all"
      ],
      "layout": {
        "icon-image": "{type}-18",
        "visibility": "visible",
        "text-field": "{name}",
        "text-size": 8,
        "text-anchor": "top",
        "text-offset": [
          0,
          1
        ],
        "text-font": [
          "OpenHistorical"
        ]
      },
      "paint": {
        "text-color": "rgba(80, 80, 80, 1)",
        "text-halo-color": "rgba(255, 255, 255, 1)",
        "text-halo-width": 0.5,
        "text-halo-blur": 1
      }
    },
    {
      "id": "points_of_interest_other",
      "type": "symbol",
      "source": "osm",
      "source-layer": "other_points",
      "minzoom": 14,
      "maxzoom": 24,
      "filter": [
        "all",
        [
          "!in",
          "type",
          "artwork"
        ]
      ],
      "layout": {
        "icon-image": "{type}-18",
        "visibility": "visible",
        "text-field": "{name}",
        "text-size": 8,
        "text-anchor": "top",
        "text-offset": [
          0,
          1
        ],
        "text-font": [
          "OpenHistorical"
        ]
      },
      "paint": {
        "text-color": "#505050",
        "text-halo-color": "rgba(255, 255, 255, 1)",
        "text-halo-width": 0.5,
        "text-halo-blur": 1
      }
    },
    {
      "id": "points_of_interest_other_archaeology",
      "type": "symbol",
      "source": "osm",
      "source-layer": "other_points",
      "minzoom": 14,
      "maxzoom": 24,
      "filter": [
        "all",
        [
          "==",
          "type",
          "archaeological_site"
        ]
      ],
      "layout": {
        "icon-image": "{site_type}-18",
        "visibility": "visible",
        "text-field": "{name}",
        "text-size": 8,
        "text-anchor": "top",
        "text-offset": [
          0,
          1
        ],
        "text-font": [
          "OpenHistorical"
        ]
      },
      "paint": {
        "text-color": "#505050",
        "text-halo-color": "rgba(255, 255, 255, 1)",
        "text-halo-width": 0.5,
        "text-halo-blur": 1
      }
    },
    {
      "id": "points_of_interest_other_artwork",
      "type": "symbol",
      "source": "osm",
      "source-layer": "other_points",
      "minzoom": 14,
      "maxzoom": 24,
      "filter": [
        "all",
        [
          "==",
          "type",
          "artwork"
        ]
      ],
      "layout": {
        "icon-image": "{artwork_type}-18",
        "visibility": "visible",
        "text-field": "{name}",
        "text-size": 8,
        "text-anchor": "top",
        "text-offset": [
          0,
          1
        ],
        "text-font": [
          "OpenHistorical"
        ]
      },
      "paint": {
        "text-color": "#505050",
        "text-halo-color": "rgba(255, 255, 255, 1)",
        "text-halo-width": 0.5,
        "text-halo-blur": 1
      }
    },
    {
      "id": "points_powertower",
      "type": "symbol",
      "source": "osm",
      "source-layer": "other_points",
      "minzoom": 15,
      "maxzoom": 24,
      "filter": [
        "all",
        [
          "==",
          "type",
          "tower"
        ]
      ],
      "layout": {
        "icon-image": "power_tower-12",
        "visibility": "visible",
        "text-font": [
          "OpenHistorical"
        ]
      }
    },
    {
      "id": "points_airport",
      "type": "symbol",
      "source": "osm",
      "source-layer": "transport_areas",
      "minzoom": 10,
      "maxzoom": 14,
      "filter": [
        "all",
        [
          "==",
          "type",
          "aerodrome"
        ]
      ],
      "layout": {
        "icon-image": "airport-18",
        "text-font": [
          "OpenHistorical"
        ]
      }
    },
    {
      "id": "transport_points",
      "type": "symbol",
      "source": "osm",
      "source-layer": "transport_points",
      "minzoom": 16,
      "maxzoom": 24,
      "filter": [
        "all"
      ],
      "layout": {
        "icon-image": "{type}-18",
        "visibility": "visible",
        "text-field": "{name}",
        "text-size": 8,
        "text-anchor": "top",
        "text-offset": [
          0,
          1
        ],
        "text-font": [
          "OpenHistorical"
        ]
      },
      "paint": {
        "icon-color": "#000000",
        "text-color": "rgba(80, 80, 80, 1)",
        "text-halo-color": "rgba(255, 255, 255, 1)",
        "text-halo-width": 0.5,
        "text-halo-blur": 1
      }
    },
    {
      "id": "points_placeofworshipother",
      "type": "symbol",
      "source": "osm",
      "source-layer": "buildings",
      "filter": [
        "all",
        [
          "==",
          "type",
          "place_of_worship"
        ],
        [
          "!in",
          "religion",
          "christian",
          "muslim",
          "jewish"
        ]
      ],
      "layout": {
        "icon-image": "place_of_worship-18",
        "text-font": [
          "OpenHistorical"
        ]
      }
    },
    {
      "id": "points_religion",
      "type": "symbol",
      "source": "osm",
      "source-layer": "buildings",
      "filter": [
        "all"
      ],
      "layout": {
        "icon-image": "{religion}-18",
        "text-font": [
          "OpenHistorical"
        ]
      }
    },
    {
      "id": "points_fromlanduse-z14",
      "type": "symbol",
      "source": "osm",
      "source-layer": "landuse_points",
      "minzoom": 14,
      "filter": [
        "all",
        [
          "in",
          "type",
          "peak"
        ]
      ],
      "layout": {
        "icon-image": "{type}-12",
        "text-font": [
          "OpenHistorical"
        ],
        "text-field": "{name}",
        "text-size": 8,
        "text-anchor": "top",
        "text-offset": [
          0,
          0.8
        ]
      },
      "paint": {
        "text-color": "rgba(80, 80, 80, 1)",
        "text-halo-color": "rgba(255, 255, 255, 1)",
        "text-halo-width": 0.5
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
        "text-font": [
          "OpenHistorical"
        ],
        "text-field": "{name}",
        "text-size": 8,
        "text-anchor": "top",
        "text-offset": [
          0,
          1
        ],
        "visibility": "visible"
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
        "all",
        [
          "!in",
          "type",
          "peak",
          "wetland",
          "garden"
        ]
      ],
      "layout": {
        "icon-image": "{type}-18",
        "text-font": [
          "OpenHistorical"
        ]
      }
    },
    {
      "id": "points_acra",
      "type": "symbol",
      "source": "osm",
      "source-layer": "buildings",
      "filter": [
        "all",
        [
          "in",
          "name",
          "ACRA",
          "Acra"
        ]
      ],
      "layout": {
        "icon-image": "acra-18",
        "text-font": [
          "OpenHistorical"
        ]
      }
    },
    {
      "id": "points_oxfam",
      "type": "symbol",
      "source": "osm",
      "source-layer": "buildings",
      "filter": [
        "all",
        [
          "in",
          "name",
          "Oxfam Books & Music",
          "Oxfam",
          "Oxfam Boutique",
          "Oxfam Shop",
          "oxfam",
          "Oxfam Bookshop",
          "Oxfam Wereldwinkel",
          "Oxfam Books",
          "OXFAM",
          "Oxfam GB",
          "Oxfam Solidarité",
          "OXFAM Water point",
          "Oxfam Magasins du monde",
          "Magasin du monde-Oxfam",
          "OXFAM Latrines",
          "Oxfam Charity Shop",
          "Oxfam Ireland",
          "Oxfam Buchshop",
          "Intermon Oxfam",
          "Centro di accoglienza Oxfam Italia",
          "Oxfam wereldwinkel",
          "Oxfam Book Shop",
          "Oxfam Music",
          "Oxfam Novib",
          "OXFAM Water Tank",
          "Oxfam books"
        ]
      ],
      "layout": {
        "icon-image": "oxfam-18",
        "text-font": [
          "OpenHistorical"
        ]
      }
    },
    {
      "id": "points_of_interest_shop",
      "type": "symbol",
      "source": "osm",
      "source-layer": "buildings",
      "minzoom": 16,
      "maxzoom": 24,
      "filter": [
        "all",
        [
          "has",
          "shop"
        ]
      ],
      "layout": {
        "icon-image": "{shop}-18",
        "visibility": "visible",
        "text-field": "{name}",
        "text-size": 8,
        "text-anchor": "top",
        "text-offset": [
          0,
          1
        ],
        "text-font": [
          "OpenHistorical"
        ]
      },
      "paint": {
        "text-color": "rgba(108, 132, 137, 1)",
        "text-halo-color": "rgba(255, 255, 255, 1)",
        "text-halo-width": 0.5,
        "text-halo-blur": 1
      }
    }
  ],
  "id": "io6r61fxt"
};
