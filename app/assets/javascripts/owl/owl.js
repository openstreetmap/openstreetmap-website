//= require owl/data-tiles
//= require templates/change
//= require templates/history

var owlLayer;
var owlObjectLayers = {};
var initialized = false;
var pageSize = 15;
var currentOffset = 0;
var changes = {};
var geoJSONLayerGroup;

var geoJSONStyle_active = {
  "color": "green",
  "fillColor": "green",
  "weight": 5,
  "opacity": 0.5,
  "fillOpacity": 0.5
};

// Inactive means deleted or previous geometry.
var geoJSONStyle_inactive = {
  "color": "red",
  "fillColor": "red",
  "weight": 5,
  "opacity": 0.5,
  "fillOpacity": 0.5
};

var geoJSONStyle_hover = {
  "opacity": 0.25,
  "fillOpacity": 0.25
};

var ICON_TAGS = [
  "aeroway", "amenity", "barrier", "building", "highway", "historic", "landuse",
  "leisure", "man_made", "natural", "railway", "shop", "tourism", "waterway"
];

function iconTags(tags) {
  var a = [];
  $.each (ICON_TAGS, function (index, tag) {
    if (tag in tags) {
      a.push(tags[tag]);
      a.push(tag);
    }
  });
  return a;
}

function classForChange(el_type, tags) {
  var cls;
  if (el_type == 'W') {
    cls = 'way ';
  } else if (el_type == 'N') {
    cls = 'node ';
  }
  cls += iconTags(tags).join(' ');
  return cls;
}

function initOwlLayer() {
  if (initialized) {
    console.log('already');
    return;
  }
  currentOffset = 0;
  initialized = true;
  removeObjectLayers();
  changes = {};
  map.on('moveend', handleMapChange);

  geoJSONLayerGroup = L.layerGroup();
  map.addLayer(geoJSONLayerGroup);
}

function destroyOwlLayer() {
  map.off('moveend', handleMapChange);
  removeObjectLayers();
  //map.removeLayer(geoJSONLayer);
  geoJSONLayer = null;
  owlLayer = null;
  initialized = false;
  currentOffset = 0;
  changes = {};
}

function handleMapChange(e) {
  currentOffset = 0;
  refreshHistoryData();
}

function sortChangesets(changesets) {
  changesets.sort(function (a, b) {
    return a.created_at > b.created_at ? -1 : 1;
  });
  return changesets;
}

function highlightChangesetFeatures(changeset_id) {
  if (changeset_id in owlObjectLayers) {
    $.each(owlObjectLayers[changeset_id], function(index, obj) {
      if ('setStyle' in obj) {
        obj.setStyle(geoJSONStyle_hover);
      }
    });
  }
}

function unhighlightChangesetFeatures(changeset_id) {
  if (changeset_id in owlObjectLayers) {
    $.each(owlObjectLayers[changeset_id], function(index, obj) {
      if ('resetStyle' in obj) {
        obj.setStyle(obj.options.style);
      }
    });
  }
}

function highlightChangesetItem(changeset_id) {
  $('li[data-changeset-id=' + changeset_id + ']').addClass('changeset-item-highlight');
}

function unhighlightChangesetItem(changeset_id) {
  $('li[data-changeset-id=' + changeset_id + ']').removeClass('changeset-item-highlight');
}

function refreshHistoryData() {
  console.log('refresh');
  $.ajax({
    url: getUrlForTilerange(),
    dataType: 'jsonp',
    success: function(geojson) {
      console.log('success');
      var changesets = changesetsFromGeoJSON(geojson);
      removeObjectLayers();
      addGeoJSON(geojson);
      $("#sidebar_content").html(JST["templates/history"]({
        changesets: sortChangesets(changesets)
      }));
      $('#history_sidebar_more').click(function (e) {
          currentOffset += pageSize;
          refreshHistoryData();
          return false;
      });
      $('.changeset-item').hover(
        function (e) {
          var changeset_id = parseInt($(e.target).data('changeset-id'));
          highlightChangesetFeatures(changeset_id);
        },
        function (e) {
          var changeset_id = parseInt($(e.target).data('changeset-id'));
          unhighlightChangesetFeatures(changeset_id);
        }
      );
    },
    error: function() {
    }
  });
}

function removeObjectLayers() {
  $.each(owlObjectLayers, function (changeset_id) {
    $.each(owlObjectLayers[changeset_id], function (index, layer) {
      map.removeLayer(layer);
    });
  });
  owlObjectLayers = {};
}

function loadHistoryForCurrentViewport() {
  initOwlLayer();
}

function getUrlForTilerange() {
  var tileSize;
  if (map.getZoom() > 16) {
    // Modified tile size: ZL17 -> 512, ZL19 -> 1024
    tileSize = Math.pow(2, 8 - (16 - map.getZoom()));
  } else {
    // Regular settings.
    tileSize = 256;
  }
  var bounds = map.getPixelBounds(),
    nwTilePoint = new L.Point(
      Math.floor(bounds.min.x / tileSize),
      Math.floor(bounds.min.y / tileSize)),
    seTilePoint = new L.Point(
      Math.floor(bounds.max.x / tileSize),
      Math.floor(bounds.max.y / tileSize));
  //console.log(bounds);
  //console.log(seTilePoint);
  return OSM.OWL_API_URL + 'changesets/'
      + 16 + '/'
      + nwTilePoint.x + '/' + nwTilePoint.y + '/'
      + seTilePoint.x + '/' + seTilePoint.y + '.geojson?limit=' + pageSize + '&offset=' + currentOffset;
}

// Add bounding boxes and point markers for changesets.
function addObjectLayers(changesets) {
  $.each(changesets, function (index, changeset) {
    if (!changeset.bboxes) { return; }
    $.each(changeset.bboxes, function (index, bbox) {
      if (!(changeset.id in owlObjectLayers)) {
        owlObjectLayers[changeset.id] = [];
      }
      if (bbox[1] == bbox[3] && bbox[0] == bbox[2]) {
        owlObjectLayers[changeset.id].push(L.marker([bbox[1], bbox[0]]).addTo(map));
      } else {
        owlObjectLayers[changeset.id].push(L.rectangle([[bbox[1], bbox[0]], [bbox[3], bbox[2]]], {
          color: 'black',
          opacity: 1,
          weight: 1,
          fillColor: 'red',
          fillOpacity: 0.25}).addTo(map));
      }
    });
  });
}

// Add GeoJSON features.
function addGeoJSON(geojson) {
  geoJSONLayerGroup.clearLayers();
  $.each(geojson['features'], function (index, changeset) {
    owlObjectLayers[changeset.properties.id] = [];
    $.each(changeset.properties.changes, function (index, change) {
      change.diffTags = diffTags(change.tags, change.prev_tags);
      changes[change.id] = change;
    });
    $.each(changeset['features'], function (index, change) {
      addChangeFeatureLayer(change, change.features[0]);
      if (change.features.length > 1) {
        addChangeFeatureLayer(change, change.features[1]);
      }
    });
  });
}

// Prepares a GeoJSON layer for a given change feature and adds it to the map.
function addChangeFeatureLayer(change, geojson) {
  var active = geojson.properties.type == 'current';

  if (!active && changes[change.properties.change_id].el_action != 'DELETE') {
    return;
  }

  var style = active ? geoJSONStyle_active : geoJSONStyle_inactive;
  var layer = new L.GeoJSON(geojson, {style: style});
  layer.on('mouseover', function (e) {
      e.target.setStyle(geoJSONStyle_hover);
      highlightChangesetItem(change.properties.changeset_id);
  });
  layer.on('mouseout', function (e) {
      e.target.setStyle(style);
      unhighlightChangesetItem(change.properties.changeset_id);
  });
  layer.on('click', function (e) {
    L.popup()
      .setLatLng(e.latlng)
      .setContent(JST["templates/change"]({change: changes[change.properties.change_id]}))
      .openOn(map);
  });
  owlObjectLayers[change.properties.changeset_id].push(layer);
  geoJSONLayerGroup.addLayer(layer);
}

function changesetsFromGeoJSON(geojson) {
  var changesets = [];
  $.each(geojson['features'], function (index, changeset) {
    changesets.push(changeset['properties']);
  });
  return changesets;
}

// Calculates a diff between two hashes containing tags.
function diffTags(tags, prev_tags) {
  var result = {added: {}, removed: {}, same: {}, modified: {}};
  $.each(tags, function (k, v) {
    if (prev_tags && k in prev_tags) {
      if (v == prev_tags[k]) {
        result.same[k] = v;
      } else {
        result.modified[k] = [v, prev_tags[k]];
      }
    } else {
      result.added[k] = v;
    }
  });
  if (prev_tags) {
    $.each(prev_tags, function (k, v) {
      if (!(k in tags)) {
        result.removed[k] = v;
      }
    });
  }
  return result;
}
