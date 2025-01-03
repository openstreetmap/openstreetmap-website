//= require leaflet.locatecontrol/dist/L.Control.Locate.umd

(function () {
  $(document).on("change", "#user_all", function () {
    $("#user_list input[type=checkbox]").prop("checked", $("#user_all").prop("checked"));
  });
}());

$(document).ready(function () {
  var defaultHomeZoom = 12;
  var map, marker, deleted_lat, deleted_lon, savedLat, savedLon, locationInput;

  if ($("#map").length) {
    savedLat = $("#home_lat").val();
    savedLon = $("#home_lon").val();
    locationInput = {
      dirty: false,
      request: null,
      countryName: $("#location_name").val().trim(),
      deletedText: null,
      checkLocation: savedLat && savedLon && $("#location_name").val().trim()
    };

    map = L.map("map", {
      attributionControl: false,
      zoomControl: false
    }).addLayer(new L.OSM.Mapnik());

    var position = $("html").attr("dir") === "rtl" ? "topleft" : "topright";

    L.OSM.zoom({ position: position })
      .addTo(map);

    var locate = L.control.locate({
      position: position,
      icon: "icon geolocate",
      iconLoading: "icon geolocate",
      strings: {
        title: I18n.t("javascripts.map.locate.title"),
        popup: function (options) {
          return I18n.t("javascripts.map.locate." + options.unit + "Popup", { count: options.distance });
        }
      }
    }).addTo(map);

    var locateContainer = locate.getContainer();

    $(locateContainer)
      .removeClass("leaflet-control-locate leaflet-bar")
      .addClass("control-locate")
      .children("a")
      .attr("href", "#")
      .removeClass("leaflet-bar-part leaflet-bar-part-single")
      .addClass("control-button");

    if (OSM.home) {
      map.setView([OSM.home.lat, OSM.home.lon], defaultHomeZoom);
    } else {
      map.setView([0, 0], 0);
    }

    if ($("#map").hasClass("set_location")) {
      marker = L.marker([0, 0], {
        icon: OSM.getUserIcon(),
        keyboard: false,
        interactive: false
      });

      if (OSM.home) {
        marker.setLatLng([OSM.home.lat, OSM.home.lon]);
        marker.addTo(map);
      }

      map.on("click", function (e) {
        if (!$("#updatehome").is(":checked")) return;

        var zoom = map.getZoom(),
            precision = OSM.zoomPrecision(zoom),
            location = e.latlng.wrap();

        $("#home_lat").val(location.lat.toFixed(precision));
        $("#home_lon").val(location.lng.toFixed(precision));

        clearDeletedText();
        respondToHomeUpdate();
      }).on("moveend", function () {
        var lat = $("#home_lat").val().trim(),
            lon = $("#home_lon").val().trim(),
            location;

        try {
          if (lat && lon) {
            location = L.latLng(lat, lon);
          }
        } catch (error) {
          // keep location undefined
        }

        $("#home_show").prop("disabled", !location || isCloseEnoughToMapCenter(location));
      });

      $("#home_lat, #home_lon").on("input", function () {
        clearDeletedText();
        respondToHomeUpdate();
      });

      $("#location_name").on("input", function () {
        locationInput.dirty = true;
        clearDeletedText();

        respondToHomeUpdate(false);
      });

      $("#home_show").click(function () {
        var lat = $("#home_lat").val(),
            lon = $("#home_lon").val();

        map.setView([lat, lon], defaultHomeZoom);
      });

      $("#home_delete").click(function () {
        const lat = $("#home_lat").val(),
              lon = $("#home_lon").val(),
              locationName = $("#location_name").val();

        $("#home_lat, #home_lon, #location_name").val("");
        deleted_lat = lat;
        deleted_lon = lon;
        locationInput.deletedText = locationName;

        respondToHomeUpdate(false);
        $("#home_undelete").trigger("focus");
      });

      $("#home_undelete").click(function () {
        $("#home_lat").val(deleted_lat);
        $("#home_lon").val(deleted_lon);
        $("#location_name").val(locationInput.deletedText);
        clearDeletedText();

        respondToHomeUpdate(false);
        $("#home_delete").trigger("focus");
      });
    } else {
      $("[data-user]").each(function () {
        var user = $(this).data("user");
        if (user.lon && user.lat) {
          L.marker([user.lat, user.lon], { icon: OSM.getUserIcon(user.icon) }).addTo(map)
            .bindPopup(user.description, { minWidth: 200 });
        }
      });
    }
  }

  function respondToHomeUpdate(updateLocationName = true) {
    let lat = $("#home_lat").val().trim(),
        lon = $("#home_lon").val().trim(),
        locationName = $("#location_name").val().trim(),
        location;

    try {
      if (lat && lon) {
        location = L.latLng(lat, lon);
        if (updateLocationName) {
          if (locationInput.checkLocation) {
            updateHomeLocation(false, savedLat, savedLon, updateHomeLocation);
          } else {
            updateHomeLocation();
          }
        }
      }
      $("#home_lat, #home_lon").removeClass("is-invalid");
    } catch (error) {
      if (lat && isNaN(lat)) $("#home_lat").addClass("is-invalid");
      if (lon && isNaN(lon)) $("#home_lon").addClass("is-invalid");
    }

    $("#home_message").toggleClass("invisible", Boolean(location));
    $("#home_show").prop("hidden", !location);
    $("#home_delete").prop("hidden", !location && !locationName);
    $("#home_undelete").prop("hidden", !(
      (!location || !locationName) &&
      ((deleted_lat && deleted_lon) || locationInput.deletedText)
    ));
    if (location) {
      marker.setLatLng([lat, lon]);
      marker.addTo(map);
      map.panTo([lat, lon]);
    } else {
      marker.removeFrom(map);
    }
  }

  function isCloseEnoughToMapCenter(location) {
    var inputPt = map.latLngToContainerPoint(location),
        centerPt = map.latLngToContainerPoint(map.getCenter());

    return centerPt.distanceTo(inputPt) < 10;
  }

  function updateAuthUID() {
    var provider = $("select#user_auth_provider").val();

    if (provider === "openid") {
      $("input#user_auth_uid").show().prop("disabled", false);
    } else {
      $("input#user_auth_uid").hide().prop("disabled", true);
    }
  }

  function updateHomeLocation(updateInput = true, lat = $("#home_lat").val().trim(), lon = $("#home_lon").val().trim(), successFn) {
    if (!lat || !lon || locationInput.dirty) {
      return;
    }

    const geocodeUrl = "/geocoder/search_osm_nominatim_reverse";
    const params = {
      format: "json",
      lat,
      lon,
      zoom: 3
    };

    if (locationInput.request) {
      locationInput.request.abort();
    }

    locationInput.request = $.ajax({
      url: geocodeUrl,
      method: "POST",
      data: params,
      success: function (country) {
        if (updateInput) {
          locationInput.request = null;
          $("#location_name").val(country);
        } else {
          locationInput.checkLocation = false;
          if (locationInput.countryName !== country) {
            locationInput.dirty = true;
          }
        }
        locationInput.countryName = country;

        if (successFn) {
          successFn();
        }
      }
    });
  }

  function clearDeletedText() {
    deleted_lat = null;
    deleted_lon = null;
    locationInput.deletedText = null;
  }

  updateAuthUID();

  $("select#user_auth_provider").on("change", updateAuthUID);

  $("input#user_avatar").on("change", function () {
    $("#user_avatar_action_new").prop("checked", true);
  });

  function enableAuth() {
    $("#auth_prompt").hide();
    $("#auth_field").show();
    $("#user_auth_uid").prop("disabled", false);
  }

  function disableAuth() {
    $("#auth_prompt").show();
    $("#auth_field").hide();
    $("#user_auth_uid").prop("disabled", true);
  }

  $("#auth_enable").click(enableAuth);

  if ($("select#user_auth_provider").val() === "") {
    disableAuth();
  } else {
    enableAuth();
  }

  $("#content.user_confirm").each(function () {
    $(this).hide();
    $(this).find("#confirm").submit();
  });

  $("input[name=legale]").change(function () {
    var url = $(this).data("url");

    $("#contributorTerms").html("<div class='spinner-border' role='status'><span class='visually-hidden'>" + I18n.t("browse.start_rjs.loading") + "</span></div>");
    $("#contributorTerms").load(url);
  });

  $("#read_ct").on("click", function () {
    $("#continue").prop("disabled", !($(this).prop("checked") && $("#read_tou").prop("checked")));
  });

  $("#read_tou").on("click", function () {
    $("#continue").prop("disabled", !($(this).prop("checked") && $("#read_ct").prop("checked")));
  });
});
