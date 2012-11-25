//= require owl/data-tiles
//= require templates/history

var owlLayer;
var owlRectangles = [];

// Gather (distinct) changesets from all tiles.
function extractChangesets(data) {
  var result = {};
  for (var i = 0; i < data.length; i++) {
    for (var j = 0; j < data[i].length; j++) {
      result[data[i][j].id] = data[i][j];
    }
  }
  return result;
}

function initOwlLayer() {
  owlLayer = new L.TileLayer.Data('http://owl.osm.org/api/changesets/{z}/{x}/{y}.json?limit=5');

  owlLayer.on('load', function(e) {
    if (!owlLayer) { return; }
    removeRectangles();
    var changesets = extractChangesets(owlLayer.data());
    $.each(changesets, function (index, value) {
      if (!value.tile_bbox) {
        return;
      }
      var bounds = [[value.tile_bbox[1], value.tile_bbox[0]], [value.tile_bbox[3], [value.tile_bbox[2]]]];
      owlRectangles.push(L.rectangle(bounds, {
          changeset_id: value.id,
          color: 'black',
          opacity: 1,
          weight: 1,
          fillColor: 'red',
          fillOpacity: 0.25}).addTo(map));
    });
    $("#sidebar_content").html(JST["templates/history"]({
      changesets: changesets
    }));
  });

  owlLayer.addTo(map);
}

function destroyOwlLayer() {
  removeRectangles();
  map.removeLayer(owlLayer);
  owlLayer = null;
}

function removeRectangles() {
  $.each(owlRectangles, function (index, rect) {
    map.removeLayer(rect);
  });
  owlRectangles = [];
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

  return 'http://owl.osm.org/api/changesets/'
      + map.getZoom() + '/'
      + nwTilePoint.x + '/' + nwTilePoint.y + '/'
      + seTilePoint.x + '/' + seTilePoint.y + '.atom';
}
