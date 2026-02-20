$(document).on("turbo:frame-load", function () {
  const heatmap = $(".heatmap").removeClass("d-none").addClass("d-grid");
  const weekInfo = getWeekInfo();
  const maxPerDay = heatmap.data("max-per-day");
  const weekdayLabels = heatmap.find("[data-weekday]");
  const monthLabelStartIndex = Math.min(...heatmap.find("[data-month]").get().map(l => l.dataset.month));
  let weekColumn = 1;
  let previousMonth = null;

  for (const day of weekdayLabels) {
    const $day = $(day);
    const weekday = $day.data("weekday");
    if (weekday < weekInfo.firstDay % 7) {
      $day.insertAfter(weekdayLabels.last());
    }
    const weekdayRow = getWeekdayRow(weekday);
    if (weekdayRow % 2 === 0) $day.remove();
    $day.css("grid-area", weekdayRow + " / 1");
  }

  for (const day of heatmap.find("[data-date]")) {
    const $day = $(day);
    const date = new Date($day.data("date"));
    if (date.getUTCDay() === weekInfo.firstDay % 7) {
      weekColumn++;
      const currentMonth = getMonthOfThisWeek(date);
      if (previousMonth === null) {
        previousMonth = currentMonth + (Math.round((monthLabelStartIndex - currentMonth) / 12) * 12);
        heatmap.find(`[data-month]:has( ~ [data-month="${previousMonth}"])`).remove();
        heatmap.find("[data-month]").first().css("grid-column-start", 2);
      }
      if (previousMonth % 12 !== currentMonth % 12) {
        heatmap.find(`[data-month="${previousMonth}"]`).css("grid-column-end", weekColumn);
        previousMonth++;
        heatmap.find(`[data-month="${previousMonth}"]`).css("grid-column-start", weekColumn);
      }
    }
    if (weekColumn === 1) {
      $day.remove();
      continue;
    }
    const count = $day.data("count") ?? 0;
    const tooltipText = getTooltipText($day.data("date"), count);
    $day
      .css("grid-area", getWeekdayRow(date.getUTCDay()) + " / " + weekColumn)
      .attr("aria-label", tooltipText)
      .tooltip({
        title: tooltipText,
        customClass: "wide",
        delay: { show: 0, hide: 0 }
      })
      .find("span")
      .css("opacity", Math.sqrt(count / maxPerDay));
  }
  heatmap.find(`[data-month="${previousMonth}"] ~ [data-month]`).remove();
  heatmap.find("[data-month]").last().css("grid-column-end", weekColumn + 1);

  function getMonthOfThisWeek(date) {
    const nextDate = new Date(date);
    nextDate.setUTCDate(date.getUTCDate() + weekInfo.minimalDays - 1);
    return nextDate.getUTCMonth() + 1;
  }

  function getWeekdayRow(weekday) {
    return ((weekday - weekInfo.firstDay + 7) % 7) + 2;
  }

  function getTooltipText(date, value) {
    const localizedDate = OSM.i18n.l("date.formats.heatmap", date);

    if (value > 0) {
      return OSM.i18n.t("javascripts.heatmap.tooltip.contributions", { count: value, date: localizedDate });
    }

    return OSM.i18n.t("javascripts.heatmap.tooltip.no_contributions", { date: localizedDate });
  }

  function getWeekInfo() {
    const weekInfo = { firstDay: 1, minimalDays: 4 }; // ISO 8601
    const locale = new Intl.Locale(OSM.i18n.locale);
    return { ...weekInfo, ...locale.weekInfo, ...locale.getWeekInfo?.() };
  }
});
