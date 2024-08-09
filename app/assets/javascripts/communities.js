/*global showMap,formMapInit*/


$(document).ready(function () {
  if ($("#community_form").length) {
    formMapInit("community_form");
  } else if ($("#community_map").length) {
    showMap("community_map");
  }
});
