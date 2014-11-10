if (OSM.PIWIK) {
  $(document).ready(function () {
    var base = document.location.protocol + "//" + OSM.PIWIK.location + "/";
    var piwikTracker;

    var piwikLoader = $.ajax({
      url: base + "piwik.js",
      dataType: "script",
      cache: true,
      success: function () {
        piwikTracker = Piwik.getTracker(base + "piwik.php", OSM.PIWIK.site);
      
        if (OSM.user) {
          piwikTracker.setUserId(OSM.user);
        }

        piwikTracker.trackPageView();
        piwikTracker.enableLinkTracking();
      
        $("meta[name=piwik-goal]").each(function () {
          piwikTracker.trackGoal($(this).attr("content"));
        });
      }
    });

    $("body").on("piwikgoal", function (e, goal) {
      piwikLoader.done(function () {
        piwikTracker.trackGoal(goal);
      });
    });
  });
}
