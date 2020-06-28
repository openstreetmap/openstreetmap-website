/*global showMap,formMapInput*/

function init_event_form() {
  formMapInput("event_map_form", "event");
}

function init_event_show() {
  showMap("event_map_show");
}

$(document).ready(function () {
  if ($("#event_map_form").length) {
    init_event_form();
  } else if ($("#event_map_show").length) {
    init_event_show();
  }
});
