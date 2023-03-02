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

        if (OSM.user && OSM.MATOMO.set_user) {
          matomoTracker.setUserId(OSM.user.toString());
        }

        if (OSM.MATOMO.visitor_cookie_timeout) {
          matomoTracker.setVisitorCookieTimeout(OSM.MATOMO.visitor_cookie_timeout);
        }

        if (OSM.MATOMO.referral_cookie_timeout) {
          matomoTracker.setReferralCookieTimeout(OSM.MATOMO.referral_cookie_timeout);
        }

        if (OSM.MATOMO.session_cookie_timeout) {
          matomoTracker.setSessionCookieTimeout(OSM.MATOMO.session_cookie_timeout);
        }

        matomoTracker.setSecureCookie(true);
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
