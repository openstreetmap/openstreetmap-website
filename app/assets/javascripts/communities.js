/*global showMap,formMapInput*/


$(document).ready(function () {
  if ($("#community_map_form").length) {
    formMapInput("community_map_form", "community");
  } else if ($("#community_map").length) {
    showMap("community_map");
  }
});
