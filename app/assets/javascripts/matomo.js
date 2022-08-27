if (OSM.MATOMO) {
  $(document).ready(function () {
    var base = document.location.protocol + "//" + OSM.MATOMO.location + "/";
    var matomoTracker;

    var matomoLoader = $.ajax({
      url: base + "matomo.js",
      dataType: "script",
      cache: true,
      success: function () {
        matomoTracker = Matomo.getTracker(base + "matomo.php", OSM.MATOMO.site);

        if (OSM.user) {
          matomoTracker.setUserId(OSM.user.toString());
        }

        matomoTracker.trackPageView();
        matomoTracker.enableLinkTracking();

        $("meta[name=matomo-goal]").each(function () {
          matomoTracker.trackGoal($(this).attr("content"));
        });
      }
    });

    $("body").on("matomogoal", function (e, goal) {
      matomoLoader.done(function () {
        matomoTracker.trackGoal(goal);
      });
    });
  });
}
