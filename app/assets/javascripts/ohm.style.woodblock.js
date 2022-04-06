/* extends ohmVectorStyles defined in ohm.style.js */

ohmVectorStyles.Woodblock = {
  "version": 8,
  "name": "ohm-woodblock-map",
  "metadata": {"maputnik:renderer": "mbgljs"},
  "sources": {
    "osm": {
      "type": "vector",
      "tiles": ohmTileServicesLists[ohmTileServiceName],
    }
  },
  "sprite": "https://openhistoricalmap.github.io/map-styles/woodblock/woodblock_spritesheet",
  "glyphs": "https://openhistoricalmap.github.io/map-styles/fonts/{fontstack}/{range}.pbf",
  "layers": [
    {
      "id": "background-pattern",
      "type": "background",
      "minzoom": 0,
      "maxzoom": 24,
      "filter": ["all"],
      "layout": {"visibility": "visible"},
      "paint": {
        "background-color": "rgba(207, 179, 125, 1)",
        "background-pattern": "woodblock-paper"
      }
    },
    {
      "id": "background",
      "type": "background",
      "minzoom": 0,
      "maxzoom": 24,
      "filter": ["all"],
      "layout": {"visibility": "visible"},
      "paint": {
        "background-color": "rgba(207, 179, 125, 1)",
        "background-opacity": 0.29
      }
    },
    {
      "id": "land-pattern",
      "type": "fill",
      "source": "osm",
      "source-layer": "land",
      "minzoom": 0,
      "maxzoom": 24,
      "layout": {"visibility": "visible"},
      "paint": {
        "fill-color": "rgba(236, 225, 203, 1)",
        "fill-pattern": "woodblock-paper"
      }
    },
    {
      "id": "land",
      "type": "fill",
      "source": "osm",
      "source-layer": "land",
      "minzoom": 0,
      "maxzoom": 24,
      "layout": {"visibility": "visible"},
      "paint": {"fill-color": "rgba(236, 225, 203, 1)", "fill-opacity": 0}
    },
    {
      "id": "water_areas",
      "type": "fill",
      "source": "osm",
      "source-layer": "water_areas",
      "minzoom": 3,
      "maxzoom": 24,
      "layout": {"visibility": "visible"},
      "paint": {"fill-color": "rgba(207, 179, 125, 1)", "fill-opacity": 0.29}
    },
    {
      "id": "water_lines_stream",
      "type": "line",
      "source": "osm",
      "source-layer": "water_lines",
      "minzoom": 13,
      "maxzoom": 24,
      "filter": ["all", ["==", "type", "stream"]],
      "paint": {
        "line-color": "rgba(207, 179, 125, 1)",
        "line-width": {"stops": [[13, 0.5], [15, 0.8], [20, 2]]},
        "line-opacity": 0.29
      }
    },
    {
      "id": "water_lines_ditch",
      "type": "line",
      "source": "osm",
      "source-layer": "water_lines",
      "minzoom": 15,
      "maxzoom": 24,
      "filter": ["all", ["in", "type", "ditch", "drain"]],
      "paint": {
        "line-color": "rgba(207, 179, 125, 1)",
        "line-width": {"stops": [[15, 0.2], [20, 1.5]]},
        "line-opacity": 0.29
      }
    },
    {
      "id": "water_lines_canal",
      "type": "line",
      "source": "osm",
      "source-layer": "water_lines",
      "minzoom": 8,
      "maxzoom": 24,
      "filter": ["all", ["==", "type", "canal"]],
      "paint": {
        "line-color": "rgba(207, 179, 125, 1)",
        "line-width": {"stops": [[8, 0.5], [13, 0.5], [14, 1], [20, 3]]},
        "line-opacity": 0.29
      }
    },
    {
      "id": "water_lines_river",
      "type": "line",
      "source": "osm",
      "source-layer": "water_lines",
      "minzoom": 8,
      "maxzoom": 24,
      "filter": ["all", ["==", "type", "river"]],
      "layout": {"visibility": "visible"},
      "paint": {
        "line-color": "rgba(235, 222, 196, 1)",
        "line-width": {
          "stops": [[8, 1], [12, 1.5], [13, 2], [14, 5], [20, 12]]
        },
        "line-opacity": 1
      }
    },
    {
      "id": "water_lines_dam",
      "type": "line",
      "source": "osm",
      "source-layer": "water_lines",
      "minzoom": 13,
      "maxzoom": 24,
      "filter": ["all", ["==", "type", "dam"]],
      "paint": {
        "line-color": "rgba(207, 179, 125, 1)",
        "line-width": {"stops": [[13, 0.5], [15, 0.8], [20, 2]]},
        "line-opacity": 0.29
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
      "paint": {"fill-color": "rgba(182, 143, 53, 1)", "fill-opacity": 0.1}
    },
    {
      "id": "buildings_flat_ruins",
      "type": "fill",
      "source": "osm",
      "source-layer": "other_areas",
      "minzoom": 14,
      "maxzoom": 24,
      "filter": ["all", ["==", "type", ""]],
      "layout": {"visibility": "none"},
      "paint": {"fill-color": "rgba(182, 143, 53, 1)", "fill-opacity": 0.1}
    },
    {
      "id": "t_outlines",
      "type": "line",
      "source": "osm",
      "source-layer": "other_areas",
      "filter": ["all", ["==", "type", "ruins"]],
      "layout": {"visibility": "none"},
      "paint": {
        "line-color": "rgba(170, 44, 44, 1)",
        "line-opacity": 1,
        "line-width": 6,
        "line-dasharray": []
      }
    },
    {
      "id": "buildings_flat_outlines",
      "type": "line",
      "source": "osm",
      "source-layer": "buildings",
      "minzoom": 14,
      "filter": ["all"],
      "layout": {"visibility": "visible"},
      "paint": {
        "line-color": "rgba(255, 255, 255, 1)",
        "line-opacity": 1,
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          15,
          6,
          18,
          9
        ],
        "line-pattern": "woodblock-splotchBeige"
      }
    },
    {
      "id": "roads_subways",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 14,
      "filter": ["all", ["in", "type", "subway"]],
      "layout": {"visibility": "none"},
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
      "id": "roads_tertiarytunnel_case",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 9,
      "filter": ["all", ["==", "type", "tertiary"], ["==", "tunnel", 1]],
      "layout": {
        "visibility": "none",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "#ffffff",
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
      "filter": ["all", ["==", "type", "secondary"], ["==", "tunnel", 1]],
      "layout": {
        "visibility": "none",
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
      "minzoom": 6,
      "maxzoom": 20,
      "filter": ["all", ["in", "type", "primary"], ["==", "tunnel", 1]],
      "layout": {
        "visibility": "none",
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
      "minzoom": 5,
      "maxzoom": 20,
      "filter": [
        "all",
        ["in", "type", "motorway", "motorway_link", "trunk", "trunk_link"],
        ["==", "tunnel", 1]
      ],
      "layout": {
        "visibility": "none",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "#ffffff",
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
      "filter": ["all", ["==", "type", "tertiary"], ["==", "tunnel", 1]],
      "layout": {
        "visibility": "none",
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
      "filter": ["all", ["==", "type", "secondary"], ["==", "tunnel", 1]],
      "layout": {
        "visibility": "none",
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
      "filter": ["all", ["==", "type", "primary"], ["==", "tunnel", 1]],
      "layout": {"visibility": "none"},
      "paint": {
        "line-color": "#f5f5f5",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          6,
          1,
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
      "minzoom": 11,
      "maxzoom": 20,
      "filter": [
        "all",
        ["in", "type", "motorway", "motorway_link", "trunk", "trunk_link"],
        ["==", "tunnel", 1]
      ],
      "layout": {
        "visibility": "none",
        "line-cap": "butt",
        "line-join": "miter"
      },
      "paint": {
        "line-color": "#f5f5f5",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          11,
          1.5,
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
        ["in", "type", "tram", "funicular", "monorail"],
        ["!in", "service", "yard", "siding"]
      ],
      "layout": {"visibility": "none"},
      "paint": {
        "line-color": "rgba(197, 197, 197, 1)",
        "line-width": {"stops": [[12, 1], [13, 1], [14, 1.25], [20, 2.25]]}
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
        ["in", "type", "miniature", "narrow_gauge"],
        ["!in", "service", "yard", "siding"]
      ],
      "layout": {"visibility": "none"},
      "paint": {
        "line-color": "rgba(179, 179, 179, 1)",
        "line-width": {"stops": [[12, 1], [13, 1], [14, 1.25], [20, 2.25]]}
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
        ["in", "type", "miniature", "narrow_gauge"],
        ["!in", "service", "yard", "siding"]
      ],
      "layout": {"visibility": "none"},
      "paint": {
        "line-color": "rgba(179, 179, 179, 1)",
        "line-width": 4,
        "line-dasharray": [0.2, 2]
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
        ["in", "type", "dismantled", "abandoned", "disused", "razed"],
        ["!in", "service", "yard", "siding"]
      ],
      "layout": {"visibility": "none"},
      "paint": {
        "line-color": "rgba(210, 190, 190, 1)",
        "line-width": {"stops": [[12, 1], [13, 1], [14, 1.25], [20, 2.25]]}
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
        ["in", "type", "dismantled", "abandoned", "disused", "razed"],
        ["!in", "service", "yard", "siding"]
      ],
      "layout": {"visibility": "none"},
      "paint": {
        "line-color": "rgba(210, 190, 190, 1)",
        "line-width": 6,
        "line-dasharray": [0.2, 2]
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
        ["in", "type", "rail", "light_rail", "preserved"],
        ["!in", "service", "yard", "siding"]
      ],
      "layout": {"visibility": "none"},
      "paint": {
        "line-color": "rgba(179, 179, 179, 1)",
        "line-width": {"stops": [[12, 1], [13, 1], [14, 1.25], [20, 2.25]]}
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
        ["in", "type", "rail", "light_rail", "preserved"],
        ["!in", "service", "yard", "siding"]
      ],
      "layout": {"visibility": "none"},
      "paint": {
        "line-color": "rgba(179, 179, 179, 1)",
        "line-width": {"stops": [[6, 2], [7, 3], [8, 4], [9, 5], [10, 6]]},
        "line-dasharray": [0.2, 2]
      }
    },
    {
      "id": "roads_rail_construction",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 9,
      "maxzoom": 24,
      "filter": [
        "all",
        ["in", "type", "construction", "proposed"],
        ["in", "class", "railway"]
      ],
      "layout": {"visibility": "none"},
      "paint": {
        "line-color": "rgba(215, 215, 215, 1)",
        "line-width": {"stops": [[12, 1], [13, 1], [14, 1.25], [20, 2.25]]}
      }
    },
    {
      "id": "roads_rail_construction_cross",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 9,
      "maxzoom": 24,
      "filter": [
        "all",
        ["in", "type", "construction", "proposed"],
        ["in", "class", "railway"]
      ],
      "layout": {"visibility": "none"},
      "paint": {
        "line-color": "rgba(215, 215, 215, 1)",
        "line-width": 6,
        "line-dasharray": [0.2, 2]
      }
    },
    {
      "id": "roads_raceways",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 12,
      "maxzoom": 24,
      "filter": ["in", "type", "raceway"],
      "layout": {"visibility": "none"},
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
      "filter": ["all", ["==", "type", "track"]],
      "layout": {"visibility": "none"},
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
      "filter": ["all", ["==", "type", "track"]],
      "layout": {"visibility": "none"},
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
      "filter": ["all", ["==", "type", "track"]],
      "layout": {"visibility": "none"},
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
      "id": "roads_pedestrian_street",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 14,
      "maxzoom": 24,
      "filter": ["all", ["in", "type", "pedestrian"]],
      "layout": {"visibility": "none"},
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
      "id": "roads_footway",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 14,
      "maxzoom": 24,
      "filter": ["all", ["in", "type", "footway", "cycleway", "path"]],
      "layout": {"visibility": "none"},
      "paint": {
        "line-color": "#b3b3b3",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          11,
          0.2,
          18,
          6
        ],
        "line-dasharray": [1, 0.5]
      }
    },
    {
      "id": "roads_pier",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 14,
      "maxzoom": 24,
      "filter": ["all", ["==", "type", "pier"]],
      "layout": {"visibility": "none"},
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
      "filter": ["all", ["in", "type", "steps"]],
      "layout": {"visibility": "none"},
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
      "id": "roads_other",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 14,
      "maxzoom": 24,
      "filter": [
        "all",
        ["in", "type", "unclassified", "living_street", "raceway"]
      ],
      "layout": {"visibility": "none"},
      "paint": {
        "line-color": "rgba(255, 207, 0, 1)",
        "line-width": {"stops": [[14, 4], [18, 16]]}
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
        ["in", "type", "residential", "service", "unclassified"],
        ["==", "bridge", 0]
      ],
      "layout": {
        "visibility": "none",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "#b3b3b3",
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
      "id": "roads_tertiary-case",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 10.01,
      "maxzoom": 24,
      "filter": ["all", ["==", "type", "tertiary"], ["!=", "tunnel", 1]],
      "layout": {
        "visibility": "none",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "#b3b3b3",
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
      "id": "roads_secondary-case",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 10.01,
      "filter": ["all", ["==", "type", "secondary"], ["!=", "tunnel", 1]],
      "layout": {
        "visibility": "none",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "#b3b3b3",
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
      "id": "roads_primarylink-case",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 10.01,
      "filter": ["all", ["in", "type", "primary_link"], ["!=", "tunnel", 1]],
      "layout": {
        "visibility": "none",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "#b3b3b3",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          10,
          2.6,
          18,
          36
        ]
      }
    },
    {
      "id": "roads_primary-case",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 10.01,
      "filter": [
        "all",
        ["in", "type", "primary"],
        ["!=", "tunnel", 1],
        ["!=", "ford", "yes"]
      ],
      "layout": {
        "visibility": "none",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": {"stops": [[10, "#d5d5d5"], [11, "#b3b3b3"]]},
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          10,
          2.6,
          18,
          36
        ]
      }
    },
    {
      "id": "roads_motorwaylink-case",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 10.01,
      "maxzoom": 20,
      "filter": [
        "all",
        ["in", "type", "motorway_link", "trunk_link"],
        ["!=", "tunnel", 1]
      ],
      "layout": {
        "visibility": "none",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": {
          "stops": [[9, "rgba(255, 255, 255, 1)"], [14, "#b3b3b3"]]
        },
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          10,
          3,
          18,
          40
        ]
      }
    },
    {
      "id": "roads_motorway-case",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 10.01,
      "maxzoom": 20,
      "filter": [
        "all",
        ["in", "type", "motorway", "trunk"],
        ["!=", "tunnel", 1]
      ],
      "layout": {
        "visibility": "none",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": {"stops": [[10, "#d5d5d5"], [11, "#b3b3b3"]]},
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          10,
          3,
          18,
          40
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
        ["in", "type", "residential", "service", "unclassified"],
        ["==", "bridge", 1]
      ],
      "layout": {
        "visibility": "none",
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
      "filter": ["all", ["==", "type", "tertiary"], ["==", "bridge", 1]],
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
          8,
          0,
          12,
          2,
          14,
          4,
          17,
          10,
          18,
          13
        ],
        "line-pattern": "woodblock-roadTest1c"
      }
    },
    {
      "id": "roads_secondarybridge",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 8,
      "filter": ["all", ["==", "type", "secondary"], ["==", "bridge", 1]],
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
          8,
          0,
          12,
          2,
          14,
          4,
          17,
          10,
          18,
          13
        ],
        "line-pattern": "woodblock-roadTest1c"
      }
    },
    {
      "id": "roads_primarybridge",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 6,
      "maxzoom": 20,
      "filter": [
        "all",
        ["in", "type", "primary", "primary_link"],
        ["==", "bridge", 1]
      ],
      "layout": {
        "line-cap": "round",
        "visibility": "visible",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(210, 210, 210, 1)",
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          8,
          2,
          12,
          3,
          14,
          8,
          17,
          13,
          18,
          16
        ],
        "line-pattern": "woodblock-roadTest1c"
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
        ["in", "type", "motorway", "motorway_link", "trunk", "trunk_link"],
        ["==", "bridge", 1]
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
          8,
          2,
          12,
          3,
          14,
          8,
          17,
          13,
          18,
          16
        ],
        "line-pattern": "woodblock-roadTest1c"
      }
    },
    {
      "id": "roads_secondarylink",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 8,
      "filter": ["all", ["==", "type", "secondary_link"], ["!=", "tunnel", 1]],
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
          0,
          12,
          2,
          14,
          4,
          17,
          10,
          18,
          13
        ],
        "line-pattern": "woodblock-roadTest1c"
      }
    },
    {
      "id": "roads_primarylink",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 6,
      "filter": ["all", ["in", "type", "primary_link"], ["!=", "tunnel", 1]],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": {"stops": [[10, "#D5D5D5"], [11, "#ffffff"]]},
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          8,
          2,
          12,
          3,
          14,
          8,
          17,
          13,
          18,
          16
        ],
        "line-pattern": "woodblock-roadTest1c"
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
        ["in", "type", "motorway_link", "trunk_link"],
        ["!=", "tunnel", 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": {
          "stops": [[10, "rgba(204, 204, 204, 1)"], [11, "#ffffff"]]
        },
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          8,
          2,
          12,
          3,
          14,
          8,
          17,
          13,
          18,
          16
        ],
        "line-pattern": "woodblock-roadTest1c"
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
        ["in", "type", "residential", "service", "unclassified"]
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
          0,
          12,
          2,
          14,
          3,
          17,
          8,
          18,
          10
        ],
        "line-pattern": "woodblock-roadTest1c"
      }
    },
    {
      "id": "roads_tertiary",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 9,
      "maxzoom": 24,
      "filter": ["all", ["==", "type", "tertiary"], ["!=", "tunnel", 1]],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": {
          "stops": [[10, "rgba(217, 217, 217, 1)"], [11, "#ffffff"]]
        },
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          8,
          0,
          12,
          2,
          14,
          4,
          17,
          10,
          18,
          13
        ],
        "line-pattern": "woodblock-roadTest1c"
      }
    },
    {
      "id": "roads_secondary",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 8,
      "filter": ["all", ["==", "type", "secondary"], ["!=", "tunnel", 1]],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": {
          "stops": [[10, "rgba(217, 217, 217, 1)"], [11, "#ffffff"]]
        },
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          8,
          0,
          12,
          2,
          14,
          4,
          17,
          10,
          18,
          13
        ],
        "line-pattern": "woodblock-roadTest1c"
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
        ["in", "type", "primary"],
        ["!=", "tunnel", 1],
        ["!=", "ford", "yes"]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": {
          "stops": [[10, "rgba(217, 217, 217, 1)"], [11, "#ffffff"]]
        },
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          8,
          2,
          12,
          3,
          14,
          8,
          17,
          13,
          18,
          16
        ],
        "line-pattern": "woodblock-roadTest1c"
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
        ["in", "type", "motorway", "trunk"],
        ["!=", "tunnel", 1]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": {
          "stops": [[10, "rgba(204, 204, 204, 1)"], [11, "#ffffff"]]
        },
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          8,
          2,
          12,
          3,
          14,
          8,
          17,
          13,
          18,
          16
        ],
        "line-pattern": "woodblock-roadTest1c"
      }
    },
    {
      "id": "roads_ford",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 9,
      "filter": ["all", ["==", "ford", "yes"]],
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
      "id": "roads_residential_bridgetop_z13",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 12,
      "maxzoom": 24,
      "filter": [
        "all",
        ["in", "type", "residential", "service", "unclassified"],
        ["==", "bridge", 1]
      ],
      "layout": {"visibility": "none"},
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
      "minzoom": 9,
      "maxzoom": 24,
      "filter": ["all", ["==", "type", "tertiary"], ["==", "bridge", 1]],
      "layout": {"visibility": "none"},
      "paint": {
        "line-color": {
          "stops": [[10, "rgba(217, 217, 217, 1)"], [11, "#ffffff"]]
        },
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
      "filter": ["all", ["==", "type", "secondary"], ["==", "bridge", 1]],
      "layout": {"visibility": "none"},
      "paint": {
        "line-color": {
          "stops": [[10, "rgba(217, 217, 217, 1)"], [11, "#ffffff"]]
        },
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
      "filter": ["all", ["in", "type", "primary"], ["==", "bridge", 1]],
      "layout": {"visibility": "none"},
      "paint": {
        "line-color": {
          "stops": [[10, "rgba(217, 217, 217, 1)"], [11, "#ffffff"]]
        },
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
      "minzoom": 5,
      "maxzoom": 20,
      "filter": [
        "all",
        ["in", "type", "motorway", "motorway_link", "trunk", "trunk_link"],
        ["==", "bridge", 1]
      ],
      "layout": {
        "visibility": "none",
        "line-cap": "butt",
        "line-join": "miter"
      },
      "paint": {
        "line-color": {
          "stops": [[10, "rgba(204, 204, 204, 1)"], [11, "#ffffff"]]
        },
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
      "id": "roads_secondary_z8",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 8,
      "maxzoom": 9,
      "filter": ["all", ["in", "type", "secondary"]],
      "layout": {"visibility": "visible"},
      "paint": {
        "line-color": {
          "stops": [[7, "#b3b3b3"], [8, "rgba(210, 210, 210, 1)"]]
        },
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
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
      "filter": ["all", ["in", "type", "trunk", "primary"]],
      "layout": {"visibility": "none"},
      "paint": {
        "line-color": {"stops": [[7, "#b3b3b3"], [9, "#EAEAEA"]]},
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
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
      "filter": ["all", ["==", "type", "motorway"]],
      "layout": {"visibility": "visible"},
      "paint": {
        "line-color": {"stops": [[6, "#b3b3b3"], [9, "#EAEAEA"]]},
        "line-width": [
          "interpolate",
          ["exponential", 1.5],
          ["zoom"],
          6,
          0.5,
          9,
          1.5
        ],
        "line-pattern": "woodblock-roadTest1c"
      }
    },
    {
      "id": "admin_countrylines_z10",
      "type": "line",
      "source": "osm",
      "source-layer": "land_ohm",
      "minzoom": 0,
      "maxzoom": 20,
      "filter": ["all", ["in", "admin_level", 1, 2]],
      "layout": {"visibility": "visible"},
      "paint": {
        "line-color": "rgba(157, 169, 174, 1)",
        "line-width": ["interpolate", ["linear"], ["zoom"], 0, 4, 8, 6],
        "line-pattern": "woodblock-splotching-light",
        "line-opacity": 1
      }
    },
    {
      "id": "man_made_bridge_area",
      "type": "fill",
      "source": "osm",
      "source-layer": "other_areas",
      "filter": ["all", ["==", "class", "man_made"], ["==", "type", "bridge"]],
      "layout": {"visibility": "none"},
      "paint": {"fill-color": "rgba(255, 255, 255, 1)"}
    },
    {
      "id": "man_made_bridge_line",
      "type": "line",
      "source": "osm",
      "source-layer": "other_lines",
      "filter": ["all", ["==", "class", "man_made"], ["==", "type", "bridge"]],
      "layout": {"visibility": "none"},
      "paint": {"line-color": "rgba(255, 255, 255, 1)", "line-width": 3}
    },
    {
      "id": "landuse_areaslabels_park",
      "type": "symbol",
      "source": "osm",
      "source-layer": "landuse_areas",
      "minzoom": 12,
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
        [">", "area", 12000]
      ],
      "layout": {
        "text-field": "",
        "text-size": {"stops": [[14, 11], [20, 14]]},
        "visibility": "visible",
        "icon-text-fit": "none",
        "text-allow-overlap": false,
        "text-ignore-placement": false,
        "text-font": ["Open Sans Regular"],
        "icon-image": "woodblock-forestSmlst"
      },
      "paint": {
        "text-color": "rgba(122, 143, 61, 1)",
        "text-halo-color": "rgba(228, 235, 209, 1)",
        "text-halo-width": 1,
        "icon-translate-anchor": "map"
      }
    },
    {
      "id": "landuse_areaslabels_forest",
      "type": "symbol",
      "source": "osm",
      "source-layer": "landuse_areas",
      "minzoom": 7,
      "maxzoom": 24,
      "filter": ["all", ["in", "type", "forest", "wood", "nature_reserve"]],
      "layout": {
        "text-field": "",
        "text-size": 11,
        "visibility": "visible",
        "text-font": ["Open Sans Regular"],
        "icon-image": "woodblock-forestSmlst"
      },
      "paint": {
        "text-color": "rgba(95, 107, 71, 1)",
        "text-halo-color": "rgba(201, 213, 190, 1)",
        "text-halo-width": 1
      }
    },
    {
      "id": "city_labels_z6",
      "type": "symbol",
      "source": "osm",
      "source-layer": "place_points",
      "minzoom": 6,
      "maxzoom": 15,
      "filter": ["all", ["==", "type", "city"], ["!=", "capital", "yes"]],
      "layout": {
        "text-field": "{name}",
        "text-font": ["Eadui"],
        "text-size": {"stops": [[6, 13], [10, 15]]},
        "visibility": "visible",
        "icon-image": "woodblock-3-tiered-house-small-2",
        "icon-offset": {"stops": [[6, [0, -12]], [10, [0, -15]]]},
        "icon-size": 1,
        "icon-anchor": "bottom",
        "text-letter-spacing": 0.1,
        "text-max-width": 10
      },
      "paint": {
        "text-color": "rgba(19, 19, 16, 1)",
        "text-halo-color": "rgba(241, 233, 218, 1)",
        "text-halo-blur": 2,
        "text-halo-width": 12
      }
    },
    {
      "id": "city_capital_labels",
      "type": "symbol",
      "source": "osm",
      "source-layer": "place_points",
      "minzoom": 4,
      "maxzoom": 15,
      "filter": ["all", ["==", "type", "city"], ["==", "capital", "yes"]],
      "layout": {
        "text-field": "{name}",
        "text-font": ["Eadui"],
        "text-size": {"stops": [[6, 16], [10, 20]]},
        "visibility": "visible",
        "icon-image": "woodblock-3-tiered-house-small",
        "icon-offset": {"stops": [[6, [0, -16]], [10, [0, -16]]]},
        "icon-size": 1,
        "icon-anchor": "bottom",
        "text-letter-spacing": 0.1,
        "text-max-width": 10
      },
      "paint": {
        "text-color": "rgba(19, 19, 16, 1)",
        "text-halo-color": "rgba(241, 233, 218, 1)",
        "text-halo-blur": 2,
        "text-halo-width": 12
      }
    },
    {
      "id": "state_labels",
      "type": "symbol",
      "source": "osm",
      "source-layer": "state_label_points",
      "minzoom": 5,
      "maxzoom": 10,
      "filter": ["all", ["==", "scalerank", 2]],
      "layout": {
        "text-field": "{name}",
        "text-font": ["Open Sans Regular"],
        "text-size": {"stops": [[4, 7], [10, 16]]},
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
      "minzoom": 4,
      "maxzoom": 20,
      "filter": ["all", ["in", "type", "state", "territory"]],
      "layout": {
        "visibility": "visible",
        "text-field": "{name}",
        "text-font": ["Eadui"],
        "text-size": {"stops": [[6, 15], [10, 18]]},
        "text-line-height": 1,
        "text-transform": "none",
        "symbol-spacing": 25,
        "symbol-avoid-edges": true,
        "symbol-placement": "point",
        "text-letter-spacing": 0.1
      },
      "paint": {
        "text-color": "rgba(146, 143, 129, 1)",
        "text-halo-width": 12,
        "text-halo-blur": 2,
        "text-halo-color": "rgba(241, 233, 218, 1)"
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
        ["==", "admin_level", 4],
        ["==", "type", "administrative"]
      ],
      "layout": {
        "visibility": "none",
        "text-field": "{name}",
        "text-font": ["Open Sans Regular"],
        "text-size": {"stops": [[6, 10], [10, 14]]},
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
      "filter": ["all", ["==", "featurecla", "Admin-1 capital"]],
      "layout": {
        "text-field": "{name}",
        "text-font": ["Open Sans Bold"],
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
      "filter": ["all", ["==", "featurecla", "Admin-1 capital"]],
      "layout": {
        "text-field": "{name}",
        "text-font": ["Open Sans Bold"],
        "text-size": {"stops": [[4, 7], [10, 10]]},
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
      "id": "admin_countryl_labels",
      "type": "symbol",
      "source": "osm",
      "source-layer": "land_ohm",
      "minzoom": 0,
      "maxzoom": 14,
      "filter": ["all", ["==", "admin_level", 2]],
      "layout": {
        "visibility": "none",
        "text-field": "{name}",
        "text-size": {"stops": [[4, 10], [6, 12], [8, 14]]},
        "text-font": ["Open Sans Bold"],
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
      "id": "country_labels",
      "type": "symbol",
      "source": "osm",
      "source-layer": "country_label_points",
      "minzoom": 3,
      "maxzoom": 7,
      "filter": ["all", ["==", "scalerank", 0]],
      "layout": {
        "text-field": "{sr_subunit}",
        "text-font": [],
        "text-size": {"stops": [[3, 11], [7, 13]]},
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
      "filter": ["all", ["==", "type", "country"]],
      "layout": {
        "visibility": "visible",
        "text-field": "{name}",
        "text-size": {"stops": [[2, 11], [4, 15], [6, 14], [8, 16]]},
        "text-font": ["Eadui"],
        "symbol-placement": "point",
        "text-justify": "center",
        "symbol-avoid-edges": false,
        "text-transform": "uppercase",
        "text-letter-spacing": 0.05
      },
      "paint": {
        "text-color": "rgba(113, 110, 99, 1)",
        "text-halo-width": 13,
        "text-halo-color": "rgba(241, 233, 218, 1)",
        "text-halo-blur": 2,
        "text-opacity": 1,
        "text-translate-anchor": "map"
      }
    },
    {
      "id": "map dragon",
      "type": "symbol",
      "source": "osm",
      "source-layer": "place_points",
      "filter": ["all", ["==", "name", "Pacific Ocean"]],
      "layout": {
        "icon-image": "woodblock-waterdragon2",
        "icon-size": [
          "interpolate",
          ["linear"],
          ["zoom"],
          1,
          0.2,
          2.9,
          0.5,
          5,
          0.9
        ]
      },
      "paint": {"text-opacity": 1}
    },
    {
      "id": "mermonster",
      "type": "symbol",
      "source": "osm",
      "source-layer": "place_points",
      "filter": ["all", ["==", "name", "Atlantic Ocean"]],
      "layout": {
        "icon-image": "woodblock-mapmonster-smaller",
        "icon-size": [
          "interpolate",
          ["linear"],
          ["zoom"],
          1,
          0.4,
          2.9,
          0.6,
          5,
          1
        ]
      },
      "paint": {"text-opacity": 1}
    }
  ],
  "id": "io6r61fxt"
};
