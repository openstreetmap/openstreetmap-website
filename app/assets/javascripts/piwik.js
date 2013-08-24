if (OSM.PIWIK) {
  $(document).ready(function () {
    var base = document.location.protocol + "//" + OSM.PIWIK.location + "/";

    $.ajax({
      url: base + "piwik.js",
      dataType: "script",
      cache: true,
      success: function () {
        var piwikTracker = Piwik.getTracker(base + "piwik.php", OSM.PIWIK.site);
      
        piwikTracker.trackPageView();
        piwikTracker.enableLinkTracking();
      
        $("meta[name=piwik-goal]").each(function () {
          piwikTracker.trackGoal($(this).attr("content"));
        });
      }
    });
  });
}
