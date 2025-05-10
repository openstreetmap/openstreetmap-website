$(function () {
  $(".heatmap-wrapper").attr("hidden", false);
  const weekInfo = getWeekInfo();
  const maxPerDay = $(".heatmap").data("max-per-day");
  let week = 0;
  let lastUpdatedMonth = -1;

  for (const day of $(".heatmap [data-weekday]")) {
    const weekday = $(day).data("weekday");
    const weekdayOffset = (weekday - weekInfo.firstDay + 7) % 7;
    if (weekday < weekInfo.firstDay % 7) {
      $(day).insertAfter($(".heatmap [data-weekday]").last());
    }
    if (weekdayOffset % 2 === 0) {
      $(day).addClass("d-none");
    }
    $(day).css({ "grid-column": 1, "grid-row": weekdayOffset + 2 });
  }

  for (const day of $(".heatmap [data-date]")) {
    const data = $(day).data();
    const date = new Date(data.date);
    const isBeginningOfWeek = date.getUTCDay() === weekInfo.firstDay;
    if (isBeginningOfWeek) {
      week++;
      // check (respecting weekInfo.minimalDays) if the new week is a new month
      const nextDate = new Date(date);
      nextDate.setUTCDate(date.getUTCDate() + weekInfo.minimalDays - 1);
      const nextMonth = nextDate.getUTCMonth();
      if (lastUpdatedMonth !== nextMonth) {
        $(`.heatmap [data-month="${lastUpdatedMonth + 1}"]`).css({ "grid-column-end": week + 1 });
        $(`.heatmap [data-month="${nextMonth + 1}"]`).css({ "grid-column-start": week + 1 });
        lastUpdatedMonth = nextMonth;
      }
    }
    const weekday = (date.getUTCDay() - weekInfo.firstDay + 7) % 7;
    if (!week) {
      $(day).addClass("d-none");
      continue;
    }
    const tooltipOptions = {
      placement: "top",
      trigger: "hover",
      delay: { show: 0, hide: 0 }
    };
    const localizedDate = OSM.i18n.l("date.formats.long", date);
    if (data.count > 0) {
      tooltipOptions.title = OSM.i18n.t("javascripts.heatmap.tooltip.contributions", { count: data.count, date: localizedDate });
      $(day).find("div").css("opacity", Math.sqrt(data.count / maxPerDay));
    } else {
      tooltipOptions.title = OSM.i18n.t("javascripts.heatmap.tooltip.no_contributions", { date: localizedDate });
    }
    $(day)
      .css({ "grid-column": week + 1, "grid-row": weekday + 2 })
      .tooltip(tooltipOptions);
  }
  $(".heatmap [data-month]").first().css({ "grid-column-start": 2 });
  $(".heatmap [data-month]").last().css({ "grid-column-end": week + 2 });

  function getWeekInfo() {
    const weekInfo = { firstDay: 1, minimalDays: 4 }; // ISO 8601
    const locale = new Intl.Locale(OSM.i18n.locale);
    return locale.getWeekInfo?.() || locale.weekInfo || weekInfo;
  }
});
