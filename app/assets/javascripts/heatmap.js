/* global CalHeatmap, CalendarLabel, Tooltip */

document.addEventListener("DOMContentLoaded", () => {
  const heatmapElement = document.querySelector("#cal-heatmap");

  // Ensure the heatmap element exists in the DOM
  if (!heatmapElement) {
    console.warn("Heatmap element not found in the DOM.");
    return;
  }

  // Retrieve heatmap data and site color scheme
  const heatmapData = heatmapElement.dataset.heatmap ? JSON.parse(heatmapElement.dataset.heatmap) : [];
  const colorScheme = heatmapElement.dataset.siteColorScheme || "auto"; // Default to "auto" if not defined

  const locale = $("head").data().locale;
  const weekdays = getLocalizedWeekdays(locale);
  const rangeColors = ["#14432a", "#166b34", "#37a446", "#4dd05a"];
  const startDate = new Date(Date.now() - (365 * 24 * 60 * 60 * 1000));

  // Determine theme based on color scheme
  const theme = getThemeFromColorScheme(colorScheme);

  // Render the heatmap
  const cal = new CalHeatmap();
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
}, { once: true });

function getThemeFromColorScheme(colorScheme) {
  if (colorScheme === "auto") {
    return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
  }
  return colorScheme; // Return "light" or "dark" directly if specified
}

function getLocalizedWeekdays(locale) {
  const translations = I18n.translations[locale] || I18n.translations.en;
  const date = translations && translations.date;
  const abbrDayNames = date && date.abbr_day_names;

  return (abbrDayNames || []).map((day, index) =>
    index % 2 === 0 ? "" : day
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
  const dateTranslations = translations && translations.date;
  const monthNames = dateTranslations && dateTranslations.month_names;

  const months = monthNames || [];
  const monthName = months[jsDate.getMonth() + 1] || `${jsDate.getMonth + 1}.`;
  const day = jsDate.getDate();
  const year = jsDate.getFullYear();

  const localizedDate = `${day}. ${monthName} ${year}.`;
  return value > 0 ?
    I18n.t("javascripts.heatmap.tooltip.contributions", { count: value, date: localizedDate }) :
    I18n.t("javascripts.heatmap.tooltip.no_contributions", { date: localizedDate });
}
