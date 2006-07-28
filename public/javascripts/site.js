function updatelinks(lon,lat,zoom) {
  var links = new Array();
  links['viewanchor'] = '/index.html';
  //links['editanchor'] = 'edit.html';
  links['uploadanchor'] = '/traces';
  links['loginanchor'] = '/login.html';
  links['logoutanchor'] = '/logout.html';
  links['registeranchor'] = '/create-account.html';

  var node;
  var anchor;
  for (anchor in links) {
    node = document.getElementById(anchor);
    if (! node) { continue; }
    node.href = links[anchor] + "?lat=" + lat + "&lon=" + lon + "&zoom=" + zoom;
  }

  node = document.getElementById("editanchor");
  if (node) {
    if ( zoom >= 14) {
      node.href = '/edit.html?lat=' + lat + '&lon=' + lon + "&zoom=" + zoom;
      node.style.fontStyle = 'normal';
    } else {
      node.href = 'javascript:alert("zoom in to edit map");';
      node.style.fontStyle = 'italic';
    }
  }
}
