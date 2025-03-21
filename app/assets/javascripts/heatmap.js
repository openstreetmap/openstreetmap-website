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

  /** @type {{date: string; max_id: number; total_changes: number}[]} */
  const heatmapData = heatmapElement.dataset.heatmap ? JSON.parse(heatmapElement.dataset.heatmap) : [];
  const displayName = heatmapElement.dataset.displayName;
  const colorScheme = document.documentElement.getAttribute("data-bs-theme") ?? "auto";
  const rangeColorsDark = ["#14432a", "#4dd05a"];
  const rangeColorsLight = ["#4dd05a", "#14432a"];
  const startDate = new Date(Date.now() - (365 * 24 * 60 * 60 * 1000));

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
          text: (timestamp) => new Date(timestamp).toLocaleString(OSM.i18n.locale, { timeZone: "UTC", month: "short" }),
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
          type: "sqrt",
          range: currentTheme === "dark" ? rangeColorsDark : rangeColorsLight,
          domain: [0, Math.max(0, ...heatmapData.map(d => d.total_changes))]
        }
      }
    }, [
      [Tooltip, {
        text: (date, value) => getTooltipText(date, value)
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

  function getTooltipText(date, value) {
    const localizedDate = OSM.i18n.l("date.formats.long", date);

    if (value > 0) {
      return OSM.i18n.t("javascripts.heatmap.tooltip.contributions", { count: value, date: localizedDate });
    }

    return OSM.i18n.t("javascripts.heatmap.tooltip.no_contributions", { date: localizedDate });
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


