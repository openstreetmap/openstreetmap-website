//= require owl/data-tiles
//= require templates/history

var owlLayer;
var owlObjectLayers = {};
var initialized = false;
var pageSize = 20;
var currentOffset = 0;

// Add bounding boxes and point markers for changesets.
function addObjectLayers(changesets) {
  $.each(changesets, function (index, changeset) {
    if (!changeset.tile_bboxes) { return; }
    $.each(changeset.tile_bboxes, function (index, bbox) {
      if (bbox[1] == bbox[3] && bbox[0] == bbox[2]) {
        owlObjectLayers[changeset.id] = L.marker([bbox[1], bbox[0]]).addTo(map);
      } else {
        owlObjectLayers[changeset.id] = L.rectangle([[bbox[1], bbox[0]], [bbox[3], bbox[2]]], {
          color: 'black',
          opacity: 1,
          weight: 1,
          fillColor: 'red',
          fillOpacity: 0.25}).addTo(map);
      }
    });
  });
}

function initOwlLayer() {
  if (initialized) {
    console.log('already');
    return;
  }
  currentOffset = 0;
  initialized = true;
  removeObjectLayers();
  map.on('moveend', handleMapChange);
}

function destroyOwlLayer() {
  map.off('moveend', handleMapChange);
  removeObjectLayers();
  owlLayer = null;
  initialized = false;
  currentOffset = 0;
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

function highlightChangeset(changeset_id) {
  if (owlObjectLayers[changeset_id].setStyle) {
    owlObjectLayers[changeset_id].setStyle({
          color: 'black',
          opacity: 1,
          weight: 1,
          fillColor: 'green',
          fillOpacity: 0.25});
  }
}

function unhighlightChangeset(changeset_id) {
  if (owlObjectLayers[changeset_id].setStyle) {
    owlObjectLayers[changeset_id].setStyle({
          color: 'black',
          opacity: 1,
          weight: 1,
          fillColor: 'red',
          fillOpacity: 0.25});
  }
}

function refreshHistoryData() {
  console.log('refresh');
  $.ajax({
    url: getUrlForTilerange(),
    dataType: 'jsonp',
    success: function(changesets) {
      console.log('success');
      removeObjectLayers();
      addObjectLayers(changesets);
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
          highlightChangeset(changeset_id);
        },
        function (e) {
          var changeset_id = parseInt($(e.target).data('changeset-id'));
          unhighlightChangeset(changeset_id);
        }
      );
    },
    error: function() {
    }
  });
}

function removeObjectLayers() {
  $.each(owlObjectLayers, function (index, layer) {
    map.removeLayer(layer);
  });
  owlObjectLayers = {};
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
      + seTilePoint.x + '/' + seTilePoint.y + '.json?limit=' + pageSize + '&offset=' + currentOffset;
}
