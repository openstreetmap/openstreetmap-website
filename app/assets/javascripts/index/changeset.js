OSM.Changeset = function (map) {
  var page = {},
      content = $("#sidebar_content"),
      currentChangesetId;

  page.pushstate = page.popstate = function (path, id) {
    OSM.loadSidebarContent(path, function () {
      page.load(path, id);
    });
  };

  page.load = function(path, id) {
    // the original page.load content is the function below, and is used when one visits this page, be it first load OR later routing change
    // below, we wrap "if map.timeslider" so we only try to add the timeslider if we don't already have it
    function originalLoadFunction () {
    if(id)
      currentChangesetId = id;
    initialize();

    addChangeset(currentChangesetId, true);
    }  // end originalLoadFunction

    // "if map.timeslider" only try to add the timeslider if we don't already have it
    if (map.timeslider) {
      originalLoadFunction();
    }
    else {
      var params = querystring.parse(location.hash ? location.hash.substring(1) : location.search.substring(1));
      addOpenHistoricalMapTimeSlider(map, params, originalLoadFunction);
    }
  };

  function addChangeset(id, center) {
    map.addObject({ type: "changeset", id: parseInt(id, 10) }, function (bounds) {
      if (!window.location.hash && bounds.isValid() &&
          (center || !map.getBounds().contains(bounds))) {
        OSM.router.withoutMoveListener(function () {
          map.fitBounds(bounds);
        });
      }
    });
  }

  function updateChangeset(method, url, include_data) {
    var data;

    content.find("#comment-error").prop("hidden", true);
    content.find("button[data-method][data-url]").prop("disabled", true);

    if (include_data) {
      data = { text: content.find("textarea").val() };
    } else {
      data = {};
    }

    $.ajax({
      url: url,
      type: method,
      oauth: true,
      data: data,
      success: function () {
        OSM.loadSidebarContent(window.location.pathname, page.load);
      },
      error: function (xhr) {
        content.find("button[data-method][data-url]").prop("disabled", false);
        content.find("#comment-error")
          .text(xhr.responseText)
          .prop("hidden", false)
          .get(0).scrollIntoView({ block: "nearest" });
      }
    });
  }

  function initialize() {
    content.find("button[data-method][data-url]").on("click", function (e) {
      e.preventDefault();
      var data = $(e.target).data();
      var include_data = e.target.name === "comment";
      updateChangeset(data.method, data.url, include_data);
    });

    content.find("textarea").on("input", function (e) {
      var form = e.target.form;

      if ($(e.target).val() === "") {
        $(form.comment).prop("disabled", true);
      } else {
        $(form.comment).prop("disabled", false);
      }
    });

    content.find("textarea").val("").trigger("input");
  }

  page.unload = function () {
    map.removeObject();
  };

  return page;
};
