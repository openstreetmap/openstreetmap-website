/* global CalHeatmap, CalendarLabel, Tooltip */
document.addEventListener("DOMContentLoaded", () => {
  const heatmapElement = document.querySelector("#cal-heatmap");

  // Don't render heatmap if there is no heatmap element in the DOM
  if (!heatmapElement) {
    console.warn("Heatmap element not found in the DOM.");
    return;
  }

  const { heatmapData, locale, weekdays, rangeColors, startDate } = initializeHeatmapConfig(heatmapElement);

  let cal = new CalHeatmap();

  // Initialize/repaint the heatmap
  function renderHeatmap(theme) {
    cal.destroy(); // Ensure no duplication when repainting
    cal = new CalHeatmap();
    cal.paint({
      itemSelector: "#cal-heatmap",
      theme: theme,
      domain: {
        type: "month",
        gutter: 4,
        label: {
          text: (timestamp) => getMonthNameFromTranslations(locale, new Date(timestamp).getMonth()),
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
          range: theme === "dark" ? rangeColors : rangeColors.reverse(),
          domain: [10, 20, 30, 40]
        }
      }
    }, [
      [CalendarLabel, {
        position: "left",
        key: "left",
        text: () => weekdays,
        textAlign: "end",
        width: 30,
        padding: [23, 10, 0, 0]
      }],
      [Tooltip, {
        text: (date, value) => getTooltipText(date, value, locale)
      }]
    ]);
  }

  // Initialize the heatmap with the current theme
  let currentTheme = getTheme();
  renderHeatmap(currentTheme);

  // Listen for theme changes
  const mediaQuery = window.matchMedia("(prefers-color-scheme: dark)");
  mediaQuery.addEventListener("change", (e) => {
    const newTheme = e.matches ? "dark" : "light";
    if (newTheme !== currentTheme) {
      currentTheme = newTheme;
      renderHeatmap(currentTheme);
    }
  });
}, { once: true });

function initializeHeatmapConfig(heatmapElement) {
  const heatmapData = heatmapElement.dataset.heatmap ? JSON.parse(heatmapElement.dataset.heatmap) : [];
  const applicationData = $("head").data();
  const locale = applicationData.locale;
  const weekdays = getLocalizedWeekdays(locale);
  const rangeColors = ["#14432a", "#166b34", "#37a446", "#4dd05a"];
  const startDate = new Date(Date.now() - (365 * 24 * 60 * 60 * 1000));

  return { heatmapData, locale, weekdays, rangeColors, startDate };
}

function getTheme() {
  return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
}

function getLocalizedWeekdays(locale) {
  const translations = I18n.translations[locale] || I18n.translations.en;
  const date = translations && translations.date;
  const abbrDayNames = date && date.abbr_day_names;

  return (abbrDayNames || []).map((day, index) =>
    index % 2 === 0 ? day : ""
  );
}

function getMonthNameFromTranslations(locale, monthIndex) {
  const translations = I18n.translations[locale] || I18n.translations.en;
  const date = translations && translations.date;
  const abbrMonthNames = date && date.abbr_month_names;

  const months = abbrMonthNames || [];
  return months[monthIndex + 1] || "";
}

function getTooltipText(date, value, locale) {
  const jsDate = new Date(date);
  const translations = I18n.translations[locale] || I18n.translations.en;
  const dateObj = translations && translations.date;
  const monthNames = dateObj && dateObj.month_names;

  const months = monthNames || [];
  const monthName = months[jsDate.getMonth() + 1] || "";
  const day = jsDate.getDate();
  const year = jsDate.getFullYear();

  const localizedDate = `${monthName} ${day}. ${year}.`;
  return value > 0 ?
    I18n.t("javascripts.heatmap.tooltip.contributions", { count: value, date: localizedDate }) :
    I18n.t("javascripts.heatmap.tooltip.no_contributions", { date: localizedDate });
}
