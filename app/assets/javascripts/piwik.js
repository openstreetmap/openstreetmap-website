if (OSM.PIWIK_LOCATION && OSM.PIWIK_SITE) {
  $(document).ready(function () {
    var base = document.location.protocol + "//" + OSM.PIWIK_LOCATION + "/";

    $.ajax({
      url: base + "piwik.js",
      dataType: "script",
      cache: true,
      success: function () {
        var piwikTracker = Piwik.getTracker(base + "piwik.php", OSM.PIWIK_SITE);
      
        piwikTracker.trackPageView();
        piwikTracker.enableLinkTracking();
      
        $("meta[name=piwik-goal]").each(function () {
          piwikTracker.trackGoal($(this).attr("content"));
        });
      }
    });
  });
}
