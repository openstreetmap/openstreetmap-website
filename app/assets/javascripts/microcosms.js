/*global showMap,formMapInput*/


$(document).ready(function () {
  if ($("#microcosm_map_form").length) {
    formMapInput("microcosm_map_form", "microcosm");
  } else if ($("#microcosm_map").length) {
    showMap("microcosm_map");
  }
});
