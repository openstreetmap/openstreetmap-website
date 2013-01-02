var OWL = {

  geoJsonStyles: {
    'node_create': {
      fill: true,
      stroke: false,
      fillColor: "indigo",
      fillOpacity: 0.85,
      radius: 8
    },
    'node_modify': {
      fill: true,
      stroke: false,
      fillColor: "blue",
      fillOpacity: 0.85,
      radius: 8
    },
    'node_delete': {
      fill: true,
      stroke: false,
      fillColor: "red",
      fillOpacity: 0.85,
      radius: 8
    },
    'way_create': {
      color: "indigo",
      fillColor: "indigo",
      weight: 5,
      opacity: 0.85,
      fillOpacity: 0.85
    },
    'way_modify': {
      color: "blue",
      fillColor: "blue",
      weight: 5,
      opacity: 0.85,
      fillOpacity: 0.85
    },
    'way_delete': {
      color: "red",
      fillColor: "red",
      weight: 5,
      opacity: 0.85,
      fillOpacity: 0.85
    },
    'way_affect': {
      color: "blue",
      fillColor: "lightblue",
      weight: 5,
      opacity: 0.85,
      fillOpacity: 0.85
    },
    'hover': {
      opacity: 0.25,
      fillOpacity: 0.25
    }
  },

  iconTags: [
    "aeroway", "amenity", "barrier", "building", "highway", "historic", "landuse",
    "leisure", "man_made", "natural", "railway", "shop", "tourism"//, "waterway"
  ]
};
