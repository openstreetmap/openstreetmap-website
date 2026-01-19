//= require maplibre/map
//= require ./home_location_name-endpoint

$(function () {
  let map, marker, deleted_lat, deleted_lon, deleted_home_name, homeLocationNameGeocoder, savedLat, savedLon;

  if ($("#social_links").length) {
    $("#add-social-link").on("click", function () {
      const newIndex = -Date.now();

      $("#social_links template").contents().clone().appendTo("#social_links")
        .find("input").attr("name", `user[social_links_attributes][${newIndex}][url]`).trigger("focus");

      renumberSocialLinks();
    });

    $("#social_links").on("click", "button", function () {
      const row = $(this).closest(".row");
      const [destroyCheckbox] = row.find(".social_link_destroy input[type='checkbox']");

      if (destroyCheckbox) {
        destroyCheckbox.checked = true;
        row.addClass("d-none");
      } else {
        row.remove();
      }

      renumberSocialLinks();
    });

    $(".social_link_destroy input[type='checkbox']:checked").each(function () {
      $(this).closest(".row").addClass("d-none");
    });

    renumberSocialLinks();
  }

  function renumberSocialLinks() {
    $("#social_links .row:not(.d-none)").each(function (i) {
      const inputLabel = OSM.i18n.t("javascripts.profile.social_link_n", { n: i + 1 });
      const removeButtonLabel = OSM.i18n.t("javascripts.profile.remove_social_link_n", { n: i + 1 });

      $(this).find("input[type='text']")
        .attr("placeholder", inputLabel)
        .attr("aria-label", inputLabel);
      $(this).find("button")
        .attr("title", removeButtonLabel);
    });
  }

  if ($("#map").length) {
    map = new OSM.MapLibre.SecondaryMap();

    savedLat = $("#home_lat").val();
    savedLon = $("#home_lon").val();
    homeLocationNameGeocoder = OSM.HomeLocationNameGeocoder($("#home_lat"), $("#home_lon"), $("#home_location_name"));

    const position = $("html").attr("dir") === "rtl" ? "top-left" : "top-right";
    const navigationControl = new OSM.MapLibre.NavigationControl();
    const geolocateControl = new OSM.MapLibre.GeolocateControl();
    map.addControl(new OSM.MapLibre.CombinedControlGroup([navigationControl, geolocateControl]), position);

    marker = new OSM.MapLibre.Marker();

    if (OSM.home) {
      marker.setLngLat([OSM.home.lon, OSM.home.lat]);
      marker.addTo(map);
    }

    map.on("click", function (e) {
      if (!$("#updatehome").is(":checked")) return;

      const [lat, lon] = OSM.cropLocation(e.lngLat, map.getZoom() + 1);

      $("#home_lat").val(lat);
      $("#home_lon").val(lon);

      clearDeletedText();
      respondToHomeLatLonUpdate();
    });
    map.on("moveend", function () {
      const lat = $("#home_lat").val().trim(),
            lon = $("#home_lon").val().trim();
      let location;

      try {
        if (lat && lon) {
          location = new maplibregl.LngLat(lon, lat);
        }
      } catch (error) {
        // keep location undefined
      }

      $("#home_show").prop("disabled", !location || isCloseEnoughToMapCenter(location));
    });

    $("#home_lat, #home_lon").on("input", function () {
      clearDeletedText();
      respondToHomeLatLonUpdate();
    });

    $("#home_location_name").on("input", function () {
      homeLocationNameGeocoder.autofill = false;
      clearDeletedText();

      respondToHomeLatLonUpdate(false);
    });

    $("#home_show").click(function () {
      const lat = $("#home_lat").val(),
            lon = $("#home_lon").val();

      map.flyTo({ center: [lon, lat], zoom: OSM.MapLibre.defaultHomeZoom });
    });

    $("#home_delete").click(function () {
      const lat = $("#home_lat").val(),
            lon = $("#home_lon").val(),
            locationName = $("#home_location_name").val();

      $("#home_lat, #home_lon, #home_location_name").val("");
      deleted_lat = lat;
      deleted_lon = lon;
      deleted_home_name = locationName;

      respondToHomeLatLonUpdate(false);
      $("#home_undelete").trigger("focus");
    });

    $("#home_undelete").click(function () {
      $("#home_lat").val(deleted_lat);
      $("#home_lon").val(deleted_lon);
      $("#home_location_name").val(deleted_home_name);
      clearDeletedText();

      respondToHomeLatLonUpdate(false);
      $("#home_delete").trigger("focus");
    });
  }

  function respondToHomeLatLonUpdate(updateLocationName = true) {
    const lat = $("#home_lat").val().trim(),
          lon = $("#home_lon").val().trim(),
          locationName = $("#home_location_name").val().trim();
    let location;

    try {
      if (lat && lon) {
        location = new maplibregl.LngLat(lon, lat);
        if (updateLocationName) {
          if (savedLat && savedLon && $("#home_location_name").val().trim()) {
            homeLocationNameGeocoder.updateHomeLocationName(false, savedLat, savedLon, () => {
              savedLat = savedLon = null;
              homeLocationNameGeocoder.updateHomeLocationName();
            });
          } else {
            savedLat = savedLon = null;
            homeLocationNameGeocoder.updateHomeLocationName();
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
      ((deleted_lat && deleted_lon) || deleted_home_name)
    ));
    if (location) {
      marker.setLngLat([lon, lat]);
      marker.addTo(map);
      map.panTo([lon, lat]);
    } else {
      marker.remove();
    }
  }

  function isCloseEnoughToMapCenter(location) {
    const inputPt = map.project(location);
    const centerPt = map.project(map.getCenter());

    return centerPt.dist(inputPt) < 10;
  }

  function clearDeletedText() {
    deleted_lat = null;
    deleted_lon = null;
    deleted_home_name = null;
  }

  $("input#user_avatar").on("change", function () {
    $("#user_avatar_action_new").prop("checked", true);
  });

  $("#content.user_confirm").each(function () {
    $(this).hide();
    $(this).find("#confirm").submit();
  });

  $("input[name=legale]").change(function () {
    $("#contributorTerms").html("<div class='spinner-border' role='status'><span class='visually-hidden'>" + OSM.i18n.t("browse.start_rjs.loading") + "</span></div>");
    fetch(this.dataset.url, { headers: { "x-requested-with": "XMLHttpRequest" } })
      .then(r => r.text())
      .then(html => { $("#contributorTerms").html(html); });
  });

  $("#read_ct").on("click", function () {
    $("#continue").prop("disabled", !($(this).prop("checked") && $("#read_tou").prop("checked")));
  });

  $("#read_tou").on("click", function () {
    $("#continue").prop("disabled", !($(this).prop("checked") && $("#read_ct").prop("checked")));
  });
});
