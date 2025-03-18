//= require leaflet.locatecontrol/dist/L.Control.Locate.umd

(function () {
  $(document).on("change", "#user_all", function () {
    $("#user_list input[type=checkbox]").prop("checked", $("#user_all").prop("checked"));
  });
}());

$(function () {
  const defaultHomeZoom = 12;
  let map, marker, deleted_lat, deleted_lon;

  if ($("#map").length) {
    map = L.map("map", {
      attributionControl: false,
      zoomControl: false
    }).addLayer(new L.OSM.Mapnik());

    const position = $("html").attr("dir") === "rtl" ? "topleft" : "topright";

    L.OSM.zoom({ position: position })
      .addTo(map);

    const locate = L.control.locate({
      position: position,
      icon: "icon geolocate",
      iconLoading: "icon geolocate",
      strings: {
        title: OSM.i18n.t("javascripts.map.locate.title"),
        popup: function (options) {
          return OSM.i18n.t("javascripts.map.locate." + options.unit + "Popup", { count: options.distance });
        }
      }
    }).addTo(map);

    const locateContainer = locate.getContainer();

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

        const [lat, lon] = OSM.cropLocation(e.latlng, map.getZoom());

        $("#home_lat").val(lat);
        $("#home_lon").val(lon);

        deleted_lat = null;
        deleted_lon = null;
        respondToHomeUpdate();
      }).on("moveend", function () {
        const lat = $("#home_lat").val().trim(),
              lon = $("#home_lon").val().trim();
        let location;

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
        deleted_lat = null;
        deleted_lon = null;
        respondToHomeUpdate();
      });

      $("#home_show").click(function () {
        const lat = $("#home_lat").val(),
              lon = $("#home_lon").val();

        map.setView([lat, lon], defaultHomeZoom);
      });

      $("#home_delete").click(function () {
        const lat = $("#home_lat").val(),
              lon = $("#home_lon").val();

        $("#home_lat, #home_lon").val("");
        deleted_lat = lat;
        deleted_lon = lon;
        respondToHomeUpdate();
        $("#home_undelete").trigger("focus");
      });

      $("#home_undelete").click(function () {
        $("#home_lat").val(deleted_lat);
        $("#home_lon").val(deleted_lon);
        deleted_lat = null;
        deleted_lon = null;
        respondToHomeUpdate();
        $("#home_delete").trigger("focus");
      });
    } else {
      $("[data-user]").each(function () {
        const user = $(this).data("user");
        if (user.lon && user.lat) {
          L.marker([user.lat, user.lon], { icon: OSM.getUserIcon(user.icon) }).addTo(map)
            .bindPopup(user.description, { minWidth: 200 });
        }
      });
    }
  }

  function respondToHomeUpdate() {
    const lat = $("#home_lat").val().trim(),
          lon = $("#home_lon").val().trim();
    let location;

    try {
      if (lat && lon) {
        location = L.latLng(lat, lon);
      }
      $("#home_lat, #home_lon").removeClass("is-invalid");
    } catch (error) {
      if (lat && isNaN(lat)) $("#home_lat").addClass("is-invalid");
      if (lon && isNaN(lon)) $("#home_lon").addClass("is-invalid");
    }

    $("#home_message").toggleClass("invisible", Boolean(location));
    $("#home_show").prop("hidden", !location);
    $("#home_delete").prop("hidden", !location);
    $("#home_undelete").prop("hidden", !(!location && deleted_lat && deleted_lon));
    if (location) {
      marker.setLatLng([lat, lon]);
      marker.addTo(map);
      map.panTo([lat, lon]);
    } else {
      marker.removeFrom(map);
    }
  }

  function isCloseEnoughToMapCenter(location) {
    const inputPt = map.latLngToContainerPoint(location),
          centerPt = map.latLngToContainerPoint(map.getCenter());

    return centerPt.distanceTo(inputPt) < 10;
  }

  function updateAuthUID() {
    const provider = $("select#user_auth_provider").val();

    if (provider === "openid") {
      $("input#user_auth_uid").show().prop("disabled", false);
    } else {
      $("input#user_auth_uid").hide().prop("disabled", true);
    }
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
    $("#contributorTerms").html("<div class='spinner-border' role='status'><span class='visually-hidden'>" + OSM.i18n.t("browse.start_rjs.loading") + "</span></div>");
    fetch($(this).data("url"))
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
