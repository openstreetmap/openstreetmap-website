/*global showMap,formMapInput*/

$(document).ready(function () {
  if ($("#event_map_form").length) {
    formMapInput("event_map_form", "event");
  } else if ($("#event_map_show").length) {
    showMap("event_map_show");
  }
});
