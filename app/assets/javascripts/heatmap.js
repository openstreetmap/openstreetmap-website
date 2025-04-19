//= require d3/dist/d3
//= require cal-heatmap/dist/cal-heatmap
//= require popper
//= require cal-heatmap/dist/plugins/Tooltip
//= require cal-heatmap/dist/plugins/CalendarLabel

/* global CalHeatmap, Tooltip, CalendarLabel */

document.addEventListener("DOMContentLoaded", () => {
  const ROWS_COUNT = 7;
  const ALLOWED_DOMAIN_TYPE = ["ghDay"];
  const CELL_SIZE = 11;
  const CELL_GUTTER = 4;
  const MONTH_LABEL_WIDTH = 61;
  const DAYS_IN_MONTH_THRESHOLD = 15;

  let heatmapStartDate, heatmapEndDate;

  const yearlyTemplate = (DateHelper) => {
    window.heatmapDateHelper = DateHelper;

    return {
      name: "yearly",
      allowedDomainType: ALLOWED_DOMAIN_TYPE,
      rowsCount: () => ROWS_COUNT,
      columnsCount: () => {
        const startDate = DateHelper.date(heatmapStartDate).startOf("week");
        const endDate = DateHelper.date(heatmapEndDate);
        return Math.ceil(endDate.diff(startDate, "weeks", true)) + 1;
      },
      mapping: () => {
        const startDate = DateHelper.date(heatmapStartDate).startOf("week");
        const endDate = DateHelper.date(heatmapEndDate);
        const weekStart = DateHelper.date().startOf("week");
        const weekStartsOnMonday = weekStart.day() === 1;

        const dateMap = new Map();
        let x = 0;

        let currentWeek = null;
        DateHelper.intervals("day", startDate, endDate.add(1, "day")).forEach((ts) => {
          const date = DateHelper.date(ts);
          const week = date.startOf("week").valueOf();

          if (currentWeek !== week) {
            currentWeek = week;
            x += 1;
          }

          let y;
          if (weekStartsOnMonday) {
            y = date.day() === 0 ? 6 : date.day() - 1;
          } else {
            y = date.day();
          }

          dateMap.set(ts, { x, y });
        });

        return DateHelper.intervals("day", startDate, endDate.add(1, "day")).map((ts) => {
          const coordinates = dateMap.get(ts);
          return {
            t: ts,
            x: coordinates.x,
            y: coordinates.y
          };
        });
      },
      extractUnit: (ts) => DateHelper.date(ts).startOf("day").valueOf()
    };
  };

  const getMonthLabels = () => {
    const abbr_month_names = OSM.i18n.t("date.abbr_month_names");
    const currentDate = new Date(heatmapStartDate);
    const startMonth = currentDate.getUTCMonth() + 1;
    const startDayOfMonth = currentDate.getUTCDate();
    const months = Array.from({ length: 12 }).map((_, i) => {
      const monthIndex = ((startMonth + i - 1) % 12) + 1;
      return abbr_month_names[monthIndex];
    });
    if (startDayOfMonth > DAYS_IN_MONTH_THRESHOLD) {
      months.push(months.shift());
    }
    return months;
  };

  const getWeekLabels = () => {
    const weekStart = window.heatmapDateHelper.date().startOf("week");
    const weekStartsOnMonday = weekStart.day() === 1;
    const dayNames = OSM.i18n.t("date.abbr_day_names");
    const labels = weekStartsOnMonday ? [...dayNames.slice(1), dayNames[0]] : dayNames;
    return labels.map((label, index) => [1, 3, 5].includes(index) ? label : "");
  };

  const getTooltipText = (date, value) => {
    const localizedDate = OSM.i18n.l("date.formats.long", date);
    const key = value > 0 ? "javascripts.heatmap.tooltip.contributions" : "javascripts.heatmap.tooltip.no_contributions";
    return OSM.i18n.t(key, { count: value, date: localizedDate });
  };

  const getTheme = (colorScheme, mediaQuery) => {
    if (colorScheme === "auto") {
      return mediaQuery.matches ? "dark" : "light";
    }
    return colorScheme;
  };

  const setupDateRange = () => {
    const now = new Date();
    heatmapStartDate = new Date(Date.UTC(
      now.getUTCFullYear() - 1,
      now.getUTCMonth(),
      now.getUTCDate(),
      0, 0, 0, 0
    ));
    heatmapEndDate = new Date(Date.UTC(
      heatmapStartDate.getUTCFullYear() + 1,
      heatmapStartDate.getUTCMonth(),
      heatmapStartDate.getUTCDate(),
      23, 59, 59, 999
    ));
  };

  const heatmapElement = document.querySelector("#cal-heatmap");
  if (!heatmapElement) return;

  const heatmapData = heatmapElement.dataset.heatmap ? JSON.parse(heatmapElement.dataset.heatmap) : [];
  const displayName = heatmapElement.dataset.displayName;
  const colorScheme = document.documentElement.getAttribute("data-bs-theme") ?? "auto";
  const rangeColorsDark = ["#14432a", "#4dd05a"];
  const rangeColorsLight = ["#4dd05a", "#14432a"];
  setupDateRange();
  const mediaQuery = window.matchMedia("(prefers-color-scheme: dark)");
  let cal = new CalHeatmap();
  let currentTheme = getTheme(colorScheme, mediaQuery);

  function renderHeatmap() {
    cal.destroy();
    cal = new CalHeatmap();
    cal.addTemplates(yearlyTemplate);

    cal.paint({
      itemSelector: "#cal-heatmap",
      theme: currentTheme,
      date: {
        locale: OSM.i18n.locale,
        start: heatmapStartDate,
        end: heatmapEndDate,
        timezone: "UTC"
      },
      domain: {
        type: "ghDay",
        gutter: CELL_GUTTER,
        label: {
          text: () => ""
        },
        dynamicDimension: true
      },
      subDomain: {
        type: "yearly",
        radius: 2,
        width: CELL_SIZE,
        height: CELL_SIZE,
        gutter: CELL_GUTTER,
        highlightClass: (timestamp) => {
          const date = new Date(timestamp);
          const today = new Date();
          return date.toDateString() === today.toDateString() ? "today" : null;
        }
      },
      range: 1,
      data: {
        source: heatmapData,
        type: "json",
        x: "date",
        y: "total_changes"
      },
      scale: {
        color: {
          type: "sqrt",
          range: currentTheme === "dark" ? rangeColorsDark : rangeColorsLight,
          domain: [0, Math.max(0, ...heatmapData.map(d => d.total_changes))]
        }
      }
    }, [
      [Tooltip, {
        text: (date, value) => getTooltipText(date, value)
      }],
      [CalendarLabel, {
        position: "top",
        key: "month-labels",
        text: getMonthLabels,
        width: MONTH_LABEL_WIDTH,
        textAlign: "middle",
        padding: heatmapStartDate.getUTCDate() > DAYS_IN_MONTH_THRESHOLD ? [0, 0, 10, 5] : [0, 0, 10, 0]
      }],
      [CalendarLabel, {
        position: "left",
        key: "week-labels",
        text: getWeekLabels,
        width: 30,
        textAlign: "right",
        padding: [0, 5, 0, 0]
      }]
    ]);

    cal.on("mouseover", (event, timestamp, value) => {
      if (!displayName || !value) return;
      if (event.target.parentElement.nodeName === "a") return;

      for (const { date, max_id } of heatmapData) {
        if (!max_id) continue;
        if (timestamp !== Date.parse(date)) continue;

        const params = new URLSearchParams({ before: max_id + 1 });
        const a = document.createElementNS("http://www.w3.org/2000/svg", "a");
        a.setAttribute("href", `/user/${encodeURIComponent(displayName)}/history?${params}`);
        $(event.target).wrap(a);
        break;
      }
    });
  }

  if (colorScheme === "auto") {
    mediaQuery.addEventListener("change", (e) => {
      currentTheme = e.matches ? "dark" : "light";
      renderHeatmap();
    });
  }

  renderHeatmap();
});


