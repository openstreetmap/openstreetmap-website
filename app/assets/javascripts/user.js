//= require leaflet.locate

$(document).ready(function () {
  if ($("#map").length) {
    var map = L.map("map", {
      attributionControl: false,
      zoomControl: false
    }).addLayer(new L.OSM.Mapnik());

    var position = $('html').attr('dir') === 'rtl' ? 'topleft' : 'topright';

    L.OSM.zoom({position: position})
      .addTo(map);

    var locate = L.control.locate({
      position: position,
      icon: 'icon geolocate',
      iconLoading: 'icon geolocate',
      strings: {
        title: I18n.t('javascripts.map.locate.title'),
        popup: I18n.t('javascripts.map.locate.popup')
      }
    }).addTo(map);

    var locateContainer = locate.getContainer();

    $(locateContainer)
      .removeClass('leaflet-control-locate leaflet-bar')
      .addClass('control-locate')
      .children("a")
      .attr('href', '#')
      .removeClass('leaflet-bar-part leaflet-bar-part-single')
      .addClass('control-button');

    if (OSM.home) {
      map.setView([OSM.home.lat, OSM.home.lon], 12);
    } else {
      map.setView([0, 0], 0);
    }

    if ($("#map").hasClass("set_location")) {
      var marker = L.marker([0, 0], {icon: OSM.getUserIcon()});

      if (OSM.home) {
        marker.setLatLng([OSM.home.lat, OSM.home.lon]);
        marker.addTo(map);
      }

      map.on("click", function (e) {
        if ($('#updatehome').is(':checked')) {
          var zoom = map.getZoom(),
              precision = OSM.zoomPrecision(zoom),
              location = e.latlng.wrap();

          $('#homerow').removeClass();
          $('#home_lat').val(location.lat.toFixed(precision));
          $('#home_lon').val(location.lng.toFixed(precision));

          marker.setLatLng(e.latlng);
          marker.addTo(map);
        }
      });
    } else {
      $("[data-user]").each(function () {
        var user = $(this).data('user');
        if (user.lon && user.lat) {
          L.marker([user.lat, user.lon], {icon: OSM.getUserIcon(user.icon)}).addTo(map)
            .bindPopup(user.description);
        }
      });
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

    $("#contributorTerms").html("<img src='" + OSM.SEARCHING + "' />");
    $("#contributorTerms").load(url);
  });
});
