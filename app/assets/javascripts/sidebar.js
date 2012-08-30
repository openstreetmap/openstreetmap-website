var openSidebar;

(function () {
  var onclose;

  openSidebar = function(options) {
    options = options || {};

    if (onclose) {
      onclose();
      onclose = null;
    }

    if (options.title) { $("#sidebar_title").html(options.title); }

    if (options.width) { $("#sidebar").width(options.width); }
    else { $("#sidebar").width("30%"); }

    $("#sidebar").css("display", "block");

    $("#sidebar").trigger("opened");

    onclose = options.onclose;
  };

  $(document).ready(function () {
    $(".sidebar_close").click(function (e) {
      $("#sidebar").css("display", "none");

      $("#sidebar").trigger("closed");

      if (onclose) {
        onclose();
        onclose = null;
      }

      e.preventDefault();
    });
  });
})();
