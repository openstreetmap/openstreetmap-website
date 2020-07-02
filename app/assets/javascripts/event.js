/*global showMap,formMapInput*/

$(document).ready(function () {
  function init_event_form() {
    formMapInput("event_map_form", "event");
  }

  function init_event_show() {
    showMap("event_map_show");
  }

  if ($("#event_map_form").length) {
    init_event_form();
  } else if ($("#event_map_show").length) {
    init_event_show();
  }
});
