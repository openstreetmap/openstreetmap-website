//= require owl/geojson-layer
//= require templates/change
//= require templates/history

var owlGeoJsonLayer;
var initialized = false;

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
  initialized = true;
  owlGeoJsonLayer = new L.OWL.GeoJSON();

  owlGeoJsonLayer.on('loaded', function (geojson) {
    var changesets = changesetsFromGeoJSON(geojson);
    $("#sidebar_content").html(JST["templates/history"]({
      changesets: sortChangesets(changesets)
    }));
    $('#history_sidebar_more').click(function (e) {
        currentOffset += pageSize;
        _refresh();
        return false;
    });
    $('.changeset-item').hover(
      function (e) {
        var changeset_id = parseInt($(e.target).data('changeset-id'));
        owlGeoJsonLayer.highlightChangesetFeatures(changeset_id);
      },
      function (e) {
        var changeset_id = parseInt($(e.target).data('changeset-id'));
        owlGeoJsonLayer.unhighlightChangesetFeatures(changeset_id);
      }
    );
  });

  map.addLayer(owlGeoJsonLayer);
}

function destroyOwlLayer() {
  map.removeLayer(owlGeoJsonLayer);
  owlGeoJsonLayer = null;
  initialized = false;
}

function sortChangesets(changesets) {
  changesets.sort(function (a, b) {
    return a.created_at > b.created_at ? -1 : 1;
  });
  return changesets;
}

function highlightChangesetItem(changeset_id) {
  $('li[data-changeset-id=' + changeset_id + ']').addClass('changeset-item-highlight');
}

function unhighlightChangesetItem(changeset_id) {
  $('li[data-changeset-id=' + changeset_id + ']').removeClass('changeset-item-highlight');
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
