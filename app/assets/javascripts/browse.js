$(document).ready(function () {

  var map = L.map("small_map", {
    attributionControl: false,
    zoomControl: false
  }).addLayer(new L.OSM.Mapnik());

  L.OSM.zoom()
    .addTo(map);

  var params = $("#small_map").data();
  var object, bbox;
  if (params.type == "changeset") {
    bbox = L.latLngBounds([params.minlat, params.minlon],
        [params.maxlat, params.maxlon]);

    map.fitBounds(bbox);

    L.rectangle(bbox, {
      weight: 2,
      color: '#e90',
      fillOpacity: 0
    }).addTo(map);

    $("#loading").hide();
    $("#browse_map .secondary-actions").show();

    $("a[data-editor=remote]").click(function () {
      return remoteEditHandler(bbox);
    });

    updatelinks(map.getCenter(), 16, null, [[params.minlat, params.minlon],
        [params.maxlat, params.maxlon]]);
  } else if (params.type == "note") {
    object = {type: params.type, id: params.id};

    map.setView([params.lat, params.lon], 16);

    L.marker([params.lat, params.lon], { icon: getUserIcon() }).addTo(map);

    bbox = map.getBounds();

    $("#loading").hide();
    $("#browse_map .secondary-actions").show();

    $("a[data-editor=remote]").click(function () {
      return remoteEditHandler(bbox);
    });

    updatelinks(params, 16, null, bbox, object);

    function updateNoteCommentButtons() {
      if ($("textarea.comment").val() == "") {
        $("input[name=close]").val(I18n.t("javascripts.notes.show.resolve"));
        $("input[name=reopen]").val(I18n.t("javascripts.notes.show.reactivate"));
        $("input[name=comment]").prop("disabled", true);
      } else {
        $("input[name=close]").val(I18n.t("javascripts.notes.show.comment_and_resolve"));
        $("input[name=reopen]").val(I18n.t("javascripts.notes.show.comment_and_reactivate"));
        $("input[name=comment]").prop("disabled", false);
      }
    }

    $("textarea.comment").on("input", updateNoteCommentButtons);

    $(".buttons input[type=submit]").on("click", function (e) {
      e.preventDefault();
      var data = $(e.target).data();
      
      $(".buttons input[type=submit]").prop("disabled", true);

      $.ajax({
        url: data.url,
        type: data.method,
        oauth: true,
        data: {
          text: $("textarea.comment").val()
        },
        success: function (feature) {
          $(".browse-section").removeClass('hidden');
          var last_comment = feature.properties.comments.pop();
          $("<li>"+last_comment.html+"<small class='deemphasize'>Just now</small></li>").insertBefore($(".browse-section ul li:last-child"));
          $("textarea.comment").val("");
          $(".buttons input[type=submit]").prop("disabled", false);
          updateNoteCommentButtons();
        }
      });
    });

  } else {
    $("#object_larger_map, #object_edit").hide();

    object = {type: params.type, id: params.id};

    if (!params.visible) {
      object.version = params.version - 1;
    }

    map.addObject(object, {
      zoom: true,
      callback: function(extent) {
        $("#loading").hide();
        $("#browse_map .secondary-actions").show();

        if (extent) {
          $("a.bbox[data-editor=remote]").click(function () {
            return remoteEditHandler(extent);
          });

          $("a.object[data-editor=remote]").click(function () {
            return remoteEditHandler(extent, params.type + params.id);
          });

          $("#object_larger_map").show();
          $("#object_edit").show();

          updatelinks(map.getCenter(), 16, null, extent, object);
        } else {
          $("#small_map").hide();
        }
      }
    });
  }
});
