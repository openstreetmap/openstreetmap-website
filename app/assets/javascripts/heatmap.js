//= require d3/dist/d3
//= require cal-heatmap/dist/cal-heatmap
//= require popper
//= require cal-heatmap/dist/plugins/Tooltip

/* global CalHeatmap, Tooltip */
document.addEventListener("DOMContentLoaded", () => {
  const heatmapElement = document.querySelector("#cal-heatmap");

  if (!heatmapElement) {
    return;
  }

  const heatmapData = heatmapElement.dataset.heatmap ? JSON.parse(heatmapElement.dataset.heatmap) : [];
  const displayName = heatmapElement.dataset.displayName;
  const colorScheme = document.documentElement.getAttribute("data-bs-theme") ?? "auto";
  const rangeColors = ["#14432a", "#166b34", "#37a446", "#4dd05a"];
  const startDate = new Date(Date.now() - (365 * 24 * 60 * 60 * 1000));
  const monthNames = I18n.t("date.abbr_month_names");

  const mediaQuery = window.matchMedia("(prefers-color-scheme: dark)");

  let cal = new CalHeatmap();
  let currentTheme = getTheme();

  function renderHeatmap() {
    cal.destroy();
    cal = new CalHeatmap();

    cal.paint({
      itemSelector: "#cal-heatmap",
      theme: currentTheme,
      domain: {
        type: "month",
        gutter: 4,
        label: {
          text: (timestamp) => monthNames[new Date(timestamp).getMonth() + 1],
          position: "top",
          textAlign: "middle"
        },
        dynamicDimension: true
      },
      subDomain: {
        type: "ghDay",
        radius: 2,
        width: 11,
        height: 11,
        gutter: 4
      },
      date: {
        start: startDate
      },
      range: 13,
      data: {
        source: heatmapData,
        type: "json",
        x: "date",
        y: "total_changes"
      },
      scale: {
        color: {
          type: "threshold",
          range: currentTheme === "dark" ? rangeColors : Array.from(rangeColors).reverse(),
          domain: [10, 20, 30, 40]
        }
      }
    }, [
      [Tooltip, {
        text: (date, value) => getTooltipText(date, value)
      }]
    ]);

    cal.on("click", (_event, timestamp) => {
      if (!displayName) return;
      for (const { date, max_id } of heatmapData) {
        if (!max_id) continue;
        if (timestamp !== Date.parse(date)) continue;
        const params = new URLSearchParams([["max_id", max_id]]);
        location = `/user/${encodeURIComponent(displayName)}/history?${params}`;
      }
    });
  }

  function getTooltipText(date, value) {
    const localizedDate = I18n.l("date.formats.long", date);

    if (value > 0) {
      return I18n.t("javascripts.heatmap.tooltip.contributions", { count: value, date: localizedDate });
    }

    return I18n.t("javascripts.heatmap.tooltip.no_contributions", { date: localizedDate });
  }

  function getTheme() {
    if (colorScheme === "auto") {
      return mediaQuery.matches ? "dark" : "light";
    }

    return colorScheme;
  }

  if (colorScheme === "auto") {
    mediaQuery.addEventListener("change", (e) => {
      currentTheme = e.matches ? "dark" : "light";
      renderHeatmap();
    });
  }

  renderHeatmap();
});


