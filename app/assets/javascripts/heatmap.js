//= require d3/dist/d3
//= require cal-heatmap/dist/cal-heatmap
//= require popper
//= require cal-heatmap/dist/plugins/Tooltip

/* global CalHeatmap, Tooltip */

document.addEventListener("DOMContentLoaded", () => {
  const config = {
    rowsCount: 7,
    allowedDomainType: ["ghDay"],
    cellSize: 11,
    cellGutter: 4,
    // Heuristic: If heatmap starts >15 days into the month, shift month labels for better alignment.
    daysInMonthThreshold: 15,
    monthLabelHeight: 20
  };

  let heatmapStartDate, heatmapEndDate;

  const calculateWeekLabels = (DateHelper, i18nData) => {
    if (!DateHelper || !i18nData?.abbr_day_names || !Array.isArray(i18nData.abbr_day_names) || i18nData.abbr_day_names.length !== 7) {
      return Array(config.rowsCount).fill("");
    }

    const weekStart = DateHelper.date().startOf("week");
    const weekStartsOnMonday = weekStart.day() === 1;
    const { abbr_day_names: abbrDayNames } = i18nData;
    const labels = Array(config.rowsCount).fill("");
    const labeledRowIndices = [1, 3, 5];

    labeledRowIndices.forEach(rowIndex => {
      let dayIndex;

      if (weekStartsOnMonday) {
        dayIndex = (rowIndex + 1) % 7;
      } else {
        dayIndex = rowIndex;
      }

      labels[rowIndex] = abbrDayNames[dayIndex];
    });

    return labels;
  };

  const calculateMonthLabels = (startDate, i18nData) => {
    // Assumes abbr_month_names is 1-indexed [null, Jan, Feb, ... Dec]
    if (!startDate || !i18nData?.abbr_month_names || !Array.isArray(i18nData.abbr_month_names) || i18nData.abbr_month_names.length !== 13) {
      return [];
    }

    const { abbr_month_names: abbrMonthNames } = i18nData;
    const date = new Date(startDate);
    const startMonthIndex = date.getUTCMonth();
    const startDayOfMonth = date.getUTCDate();

    const initialMonthLabels = Array.from({ length: 12 }, (_, i) => {
      const monthIndex = (startMonthIndex + i) % 12;
      return abbrMonthNames[monthIndex + 1];
    });

    // If the start date's day is past the threshold, shift the month label sequence.
    // This aims to align the first visible month label more closely with its corresponding heatmap columns.
    const finalMonthLabels = [...initialMonthLabels]; // Create a copy
    if (startDayOfMonth > config.daysInMonthThreshold) {
      finalMonthLabels.push(finalMonthLabels.shift()); // Re-add the shift
    }

    console.log(finalMonthLabels);
    return finalMonthLabels;
  };

  const calculateMonthPositions = (DateHelper, startDate, endDate) => {
    if (!DateHelper || !startDate || !endDate) {
      return new Map();
    }

    const domainStartDate = DateHelper.date(startDate).startOf("week");
    const domainEndDate = DateHelper.date(endDate);
    // Maps month index (0-11) combined with year to { startX: number, endX: number }
    // e.g., key "2-2023" for March 2023
    const monthYearPositions = new Map();

    // Start column index at 0, will be incremented before first use for 1-based indexing.
    let currentColumnX = 0;
    let currentWeek = null;

    DateHelper.intervals("day", domainStartDate, domainEndDate.add(1, "day")).forEach((ts) => {
      const date = DateHelper.date(ts);
      const week = date.startOf("week").valueOf();

      // Increment column index at the start of each new week
      if (currentWeek !== week) {
        currentColumnX += 1;
        currentWeek = week;
      }

      const month = date.month(); // 0-11
      const year = date.year();
      const key = `${month}-${year}`;

      if (!monthYearPositions.has(key)) {
        // First day encountered for this specific month-year, record its starting column
        monthYearPositions.set(key, { startX: currentColumnX });
      }

      // Always update the end column for this specific month-year
      monthYearPositions.get(key).endX = currentColumnX;
    });

    console.log(monthYearPositions); // You had a console.log here, can be useful for debugging
    return monthYearPositions;
  };

  const LABEL_BASE_CLASS = "heatmap-label";
  const WEEK_LABEL_CLASS = `${LABEL_BASE_CLASS} heatmap-week-label`;
  const MONTH_LABEL_CLASS = `${LABEL_BASE_CLASS} heatmap-month-label`;

  const createLabelElement = (text, className) => {
    const el = document.createElement("div");
    el.className = className;
    el.textContent = text;
    el.style.position = "absolute";
    return el;
  };

  const renderWeekLabels = (container, labels, dimensions) => {
    const { cellSize, cellGutter, rowsCount } = dimensions;
    const cellHeight = cellSize + cellGutter;

    container.innerHTML = "";
    labels.forEach((label, index) => {
      if (!label) return;

      const el = createLabelElement(label, WEEK_LABEL_CLASS);
      // Position vertically centered within the corresponding row
      el.style.top = `${(index * cellHeight) + (cellSize / 2)}px`;
      el.style.transform = "translateY(-50%)";
      container.appendChild(el);
    });

    const totalHeight = rowsCount * cellHeight;
    container.style.height = `${totalHeight}px`;
    container.style.position = "relative";
  };

  const renderMonthLabels = (container, labels, positions, dimensions, i18nData, startDate) => {
    const { cellSize, cellGutter } = dimensions;
    const cellWidth = cellSize + cellGutter;
    const { monthLabelHeight } = config;
    const { abbr_month_names: abbrMonthNames } = i18nData;

    container.innerHTML = "";
    // startDate here is heatmapStartDate, used to determine the year for each label
    const heatMapStartActualDate = new Date(startDate);
    const originalHeatmapStartMonth = heatMapStartActualDate.getUTCMonth();
    const originalHeatmapStartDay = heatMapStartActualDate.getUTCDate();

    labels.forEach((labelName, idx) => {
      const currentLabelDate = new Date(heatMapStartActualDate);
      currentLabelDate.setUTCDate(1); // Normalize day to 1st to avoid month skips with setUTCMonth

      let monthIterationOffset = idx;
      if (originalHeatmapStartDay > config.daysInMonthThreshold) {
        // If the original start day caused a label shift,
        // the idx-th label in the `labels` array corresponds to the (originalStartMonth + idx + 1)-th month.
        monthIterationOffset = idx + 1;
      }
      currentLabelDate.setUTCMonth(originalHeatmapStartMonth + monthIterationOffset);

      const monthIndexForLabel = currentLabelDate.getUTCMonth(); // 0-11
      const yearForLabel = currentLabelDate.getUTCFullYear();

      const positionKey = `${monthIndexForLabel}-${yearForLabel}`;

      // positions is now monthYearPositions from the modified calculateMonthPositions
      if (!positions.has(positionKey)) {
        // This might occur if a month is in domainStartDate-domainEndDate range but not part of the 12 display labels
        console.warn(`No position data for key: ${positionKey} (label: ${labelName})`);
        return; 
      }

      const { startX, endX = startX } = positions.get(positionKey);
      const el = createLabelElement(labelName, MONTH_LABEL_CLASS);

      let midColumn;
      if (idx === 0) { // If this is the first label in the displayed sequence
        // Position this first displayed label towards its own start column.
        midColumn = startX + 2;
      } else {
        // For all subsequent labels, center them in their respective spans.
        midColumn = startX + ((endX - startX) / 2);
      }

      const leftPosition = midColumn * cellWidth;
      el.style.left = `${leftPosition}px`;
      // Adjust horizontal position slightly to center the text element itself
      el.style.transform = "translateX(-50%)";
      container.appendChild(el);
    });

    container.style.position = "relative";
    container.style.height = `${monthLabelHeight}px`;
  };

  const renderDomLabels = (weekLabels, monthLabels, monthPositions, dimensions, i18nData, startDate) => {
    const weekContainer = document.querySelector(".heatmap-week-labels");
    const monthContainer = document.querySelector(".heatmap-month-labels");

    if (!weekContainer || !monthContainer) {
      return;
    }

    if (!dimensions || typeof dimensions.cellSize !== "number" || typeof dimensions.cellGutter !== "number" || typeof dimensions.rowsCount !== "number") {
      return;
    }

    if (!i18nData?.abbr_month_names || !Array.isArray(i18nData.abbr_month_names) || i18nData.abbr_month_names.length !== 13) {
      return;
    }

    renderWeekLabels(weekContainer, weekLabels, dimensions);
    renderMonthLabels(monthContainer, monthLabels, monthPositions, dimensions, i18nData, startDate);
  };

  const yearlyTemplate = (DateHelper) => {
    if (!DateHelper) {
      return null; // Return null or an empty template object if DateHelper is missing
    }

    return {
      name: "yearly",
      allowedDomainType: config.allowedDomainType,
      rowsCount: () => config.rowsCount,
      columnsCount: () => {
        const startDate = DateHelper.date(heatmapStartDate).startOf("week");
        const endDate = DateHelper.date(heatmapEndDate);
        return Math.ceil(endDate.diff(startDate, "weeks", true)) + 1;
      },
      mapping: () => {
        const startDate = DateHelper.date(heatmapStartDate).startOf("week");
        const endDate = DateHelper.date(heatmapEndDate);
        // Determine if the locale considers Monday as the start of the week
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

  function getTooltipText(date, value) {
    const localizedDate = OSM.i18n.l("date.formats.long", date);

    if (value > 0) {
      return OSM.i18n.t("javascripts.heatmap.tooltip.contributions", { count: value, date: localizedDate });
    }

    return OSM.i18n.t("javascripts.heatmap.tooltip.no_contributions", { date: localizedDate });
  }

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
      now.getUTCFullYear(),
      now.getUTCMonth(),
      now.getUTCDate(),
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
        gutter: config.cellGutter,
        label: {
          text: () => ""
        },
        dynamicDimension: true
      },
      subDomain: {
        type: "yearly",
        radius: 2,
        width: config.cellSize,
        height: config.cellSize,
        gutter: config.cellGutter,
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
      }]
    ]).then(() => {
      const DateHelper = cal.dateHelper;
      if (!DateHelper) {
        return;
      }

      const i18nData = {
        abbr_day_names: OSM.i18n.t("date.abbr_day_names"),
        abbr_month_names: OSM.i18n.t("date.abbr_month_names")
      };

      const dimensions = { cellSize: config.cellSize, cellGutter: config.cellGutter, rowsCount: config.rowsCount };

      const weekLabels = calculateWeekLabels(DateHelper, i18nData);
      const monthLabels = calculateMonthLabels(heatmapStartDate, i18nData);
      const monthPositions = calculateMonthPositions(DateHelper, heatmapStartDate, heatmapEndDate);

      renderDomLabels(weekLabels, monthLabels, monthPositions, dimensions, i18nData, heatmapStartDate);
    });

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
