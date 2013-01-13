function hasIcon(tags) {
  return iconTags(tags).length > 0;
}

function iconTags(tags) {
  var a = [];
  $.each (OWL.iconTags, function (index, tag) {
    if (tag in tags) {
      a.push(tags[tag]);
      a.push(tag);
    }
  });
  return a;
}

function classForChange(el_type, tags) {
  if (!hasIcon(tags)) { return ""; }
  var cls;
  if (el_type == 'W') {
    cls = 'way ';
  } else if (el_type == 'N') {
    cls = 'node ';
  }
  cls += iconTags(tags).join(' ');
  return cls;
}

function hrefForChange(change) {
  return OSM.OWL_LINKS_BASE_URL
    + 'browse/'
    + (change.el_type == 'N' ? 'node' : 'way')
    + '/'
    + change.el_id;
}

// Tries to find data-changeset-id attribute for given element (searches parents if needed).
function findChangesetId(el) {
  var result = null;
  $.each([$(el), $(el).parent(), $(el).parent().parent()], function (index, e) {
      if (e.data('changeset-id')) {
        result = e.data('changeset-id');
        return false;
      }
  });
  if (result) {
    result = parseInt(result);
  }
  return result;
}
