function hrefForChange(change) {
  return OSM.OWL_LINKS_BASE_URL
    + 'browse/'
    + (change.el_type == 'N' ? 'node' : 'way')
    + '/'
    + change.el_id;
}

// Calculates symbols for changes, aggregates tag symbols on changeset level.
function prepareChangesetInfo(changeset) {
  var data = {symbols: {}};
  $.each(changeset.changes, function (index, change) {
      var symbolKey = symbolForChange(change);
      if (symbolKey) {
        change.symbolKey = symbolKey;
        if (!(symbolKey in data.symbols)) {
          data.symbols[symbolKey] = 1;
        } else {
          data.symbols[symbolKey]++;
        }
      }
  });
  changeset.info = data;
}

// Calculates what symbol should be used for given change. Returns symbol key.
function symbolForChange(change) {
  var result = null;
  $.each ($.extend(change.tags, change.prev_tags), function (key, value) {
    var symbolKey = key + '=' + value;
    if (symbolKey in OWL.tagSymbols) {
      result = symbolKey;
      return false;
    }
  });
  return result;
}

function cssClassForChange(change) {
  var result = (change.el_type == 'N' ? 'node' : 'way');
  if (change.symbolKey) {
    result += ' ' + change.symbolKey.split('=').join(' ');
  }
  return result;
}

function nameForChange(change) {
  var friendlyTagInfo = null, name = null;
  if (change.prev_tags) {
    friendlyTagInfo = findTagWithFriendlyName(change.prev_tags);
    name = findName(change.prev_tags);
  }
  if (change.tags) {
    if (friendlyTagInfo == null) {
      friendlyTagInfo = findTagWithFriendlyName(change.tags);
    }
    if (name == null) {
      name = findName(change.tags);
    }
  }
  if (!name) {
    name = change.el_id;
  }
  var result = '';
  if (friendlyTagInfo) {
    result = friendlyTagInfo.toLowerCase();
    if (name) {
      result += ' (' + name + ')';
    }
  } else {
    result = name;
  }
  return result;
}

// Searches for a tag that has a translation and returns the translation or null if no such tags found.
function findTagWithFriendlyName(tags) {
  var result = null;
  $.each(tags, function (k, v) {
    if (I18n.lookup('geocoder.search_osm_nominatim.prefix.' + k + '.' + v)) {
      result = I18n.t('geocoder.search_osm_nominatim.prefix.' + k + '.' + v);
      return false;
    }
  });
  return result;
}

function findName(tags) {
  var result = null;
  if ('name' in tags) {
    result = tags['name'];
  }
  return result;
}


function findChangesetId(el) {
  return findDataValue(el, 'changeset-id');
}

function findChangeId(el) {
  return findDataValue(el, 'change-id');
}

// Tries to find data with given key attribute for given element (searches parents if needed).
function findDataValue(el, key) {
  var result = null;
  $.each([$(el), $(el).parent(), $(el).parent().parent(), $(el).parent().parent().parent(),
    $(el).parent().parent().parent().parent()], function (index, e) {
      if (e.data(key)) {
        result = e.data(key);
        return false;
      }
  });
  if (result) {
    result = parseInt(result);
  }
  return result;
}

// Determines if the "Load more" element is in view - means that we need to load another page of results!
function isLoadMoreInView() {
  return $('#sidebar_content').height() - $('#sidebar').scrollTop() < $('#sidebar').height();
}
