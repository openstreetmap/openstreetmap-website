//= require owl/data-tiles
//= require templates/history

var owlLayer;
var owlObjectLayers = [];
var initialized = false;

// Gather (distinct) changesets from all tiles.
function extractChangesets(data) {
  var result = {};
  for (var i = 0; i < data.length; i++) {
    result[data[i].id] = data[i];
  }
  return result;
}

// Add bounding boxes and point markers for changesets.
function addObjectLayers(data) {
  $.each(data, function (index, value) {
    if (!value.tile_bbox) { return; }
    if (value.tile_bbox[1] == value.tile_bbox[3] && value.tile_bbox[0] == value.tile_bbox[2]) {
      owlObjectLayers.push(L.marker([value.tile_bbox[1], value.tile_bbox[0]]).addTo(map));
    } else {
      owlObjectLayers.push(L.rectangle([[value.tile_bbox[1], value.tile_bbox[0]], [value.tile_bbox[3], value.tile_bbox[2]]],
        {
        color: 'black',
        opacity: 1,
        weight: 1,
        fillColor: 'red',
        fillOpacity: 0.25}).addTo(map));
    }
  });
}

function initOwlLayer() {
  if (initialized) {
    console.log('already');
    return;
  }
  initialized = true;
  //owlLayer = new L.TileLayer.Data('http://owl.osm.org/api/changesets/{z}/{x}/{y}.json?limit=5');
  removeObjectLayers();
  //map.on('moveend', refreshHistoryData);
  map.on('moveend', refreshHistoryData);
}

function destroyOwlLayer() {
  //map.off('moveend', refreshHistoryData);
  map.off('moveend', refreshHistoryData);
  removeObjectLayers();
  //map.removeLayer(owlLayer);
  owlLayer = null;
  initialized = false;
}

function refreshHistoryData() {
  console.log('refresh');
  $.ajax({
    url: getUrlForTilerange(),
    dataType: 'jsonp',
    success: function(data) {
      console.log('success');
      removeObjectLayers();
      var changesets = extractChangesets(data);
      addObjectLayers(data);
      $("#sidebar_content").html(JST["templates/history"]({
        changesets: changesets
      }));
    },
    error: function() {
    }
  });
}

function removeObjectLayers() {
  $.each(owlObjectLayers, function (index, layer) {
    map.removeLayer(layer);
  });
  owlObjectLayers = [];
}

function loadHistoryForCurrentViewport() {
  initOwlLayer();
}

function getUrlForTilerange() {
  var bounds = map.getPixelBounds(),
    nwTilePoint = new L.Point(
      Math.floor(bounds.min.x / 256),
      Math.floor(bounds.min.y / 256)),
    seTilePoint = new L.Point(
      Math.floor(bounds.max.x / 256),
      Math.floor(bounds.max.y / 256));

  return OSM.OWL_API_URL + 'changesets/'
      + map.getZoom() + '/'
      + nwTilePoint.x + '/' + nwTilePoint.y + '/'
      + seTilePoint.x + '/' + seTilePoint.y + '.json?limit=20';
}
