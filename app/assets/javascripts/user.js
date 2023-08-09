//= require leaflet.locatecontrol/src/L.Control.Locate

$(document).ready(function () {
  var map, marker, deleted_lat, deleted_lon;

  if ($("#map").length) {
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
      map.setView([OSM.home.lat, OSM.home.lon], 12);
    } else {
      map.setView([0, 0], 0);
    }

    if ($("#map").hasClass("set_location")) {
      marker = L.marker([0, 0], { icon: OSM.getUserIcon() });

      if (OSM.home) {
        marker.setLatLng([OSM.home.lat, OSM.home.lon]);
        marker.addTo(map);
      }

      map.on("click", function (e) {
        if ($("#updatehome").is(":checked")) {
          var zoom = map.getZoom(),
              precision = OSM.zoomPrecision(zoom),
              location = e.latlng.wrap();

          $("#home_lat").val(location.lat.toFixed(precision));
          $("#home_lon").val(location.lng.toFixed(precision));

          respondToHomeUpdate();
        }
      });

      $("#home_lat, #home_lon").on("input", respondToHomeUpdate);
    } else {
      $("[data-user]").each(function () {
        var user = $(this).data("user");
        if (user.lon && user.lat) {
          L.marker([user.lat, user.lon], { icon: OSM.getUserIcon(user.icon) }).addTo(map)
            .bindPopup(user.description);
        }
      });
    }
  }

  function respondToHomeUpdate() {
    var lat = $("#home_lat").val(),
        lon = $("#home_lon").val(),
        has_home = !!(lat && lon);

    $("#home_message").toggleClass("invisible", has_home);
    $("#home_show").prop("hidden", !has_home);
    $("#home_delete").prop("hidden", !has_home);
    $("#home_undelete").prop("hidden", !(!has_home && deleted_lat && deleted_lon));
    if (has_home) {
      marker.setLatLng([lat, lon]);
      marker.addTo(map);
      map.panTo([lat, lon]);
    } else {
      marker.removeFrom(map);
    }
  }

  function updateAuthUID() {
    var provider = $("select#user_auth_provider").val();

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

  $("#user_all").change(function () {
    $("#user_list input[type=checkbox]").prop("checked", $("#user_all").prop("checked"));
  });

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
