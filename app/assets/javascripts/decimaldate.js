/*
 * adapted from decimaldate.js https://github.com/OpenHistoricalMap/decimaldate-javascript
 */

const decimaldate = {};

decimaldate.DECIMALPLACES = 6;

decimaldate.RE_YEARMONTHDAY = /^(\-?\+?)(\d+)\-(\d\d)\-(\d\d)$/;

decimaldate.iso2dec = (isodate) => {
    // parse the date into 3 integers and maybe a minus sign
    // validate that it's a valid date
    const datepieces = isodate.match(decimaldate.RE_YEARMONTHDAY);
    if (! datepieces) throw new Error(`iso2dec() malformed date ${isodate}`);

    const [plusminus, yearstring, monthstring, daystring] = datepieces.slice(1);
    const monthint = parseInt(monthstring);
    const dayint = parseInt(daystring);
    let yearint = plusminus == '-' ? -1 * parseInt(yearstring) : parseInt(yearstring);
    if (yearint <= 0) yearint -= 1;  // ISO 8601 shift year<=0 by 1, 0=1BCE, -1=2BCE; we want proper negative integer
    if (! decimaldate.isvalidmonthday(yearint, monthint, dayint))  throw new Error(`iso2dec() invalid date ${isodate}`);

    // number of days passed = decimal portion
    // if BCE <=0 then count backward from the end of the year, instead of forward from January
    const decbit = decimaldate.proportionofdayspassed(yearint, monthint, dayint);

    let decimaloutput;
    if (yearint < 0) {
        // ISO 8601 shift year<=0 by 1, 0=1BCE, -1=2BCE; we want string version
        // so it's 1 to get from the artificially-inflated integer (string 0000 => -1 for math, +1 to get back to 0)
        decimaloutput = 1 + 1 + yearint - (1 - decbit);
    }
    else {
        decimaloutput = yearint + decbit;
    }

    // round to standardized number of decimals
    decimaloutput = parseFloat(decimaloutput.toFixed(decimaldate.DECIMALPLACES));
    return decimaloutput;
};


decimaldate.dec2iso = (decdate) => {
    // remove the artificial +1 that we add to make positive dates look intuitive
    const truedecdate = decdate - 1;
    const ispositive = truedecdate > 0;

    // get the integer year
    if (ispositive) {
        yearint = Math.floor(truedecdate) + 1;
    }
    else {
        yearint = -Math.abs(Math.floor(truedecdate));  // ISO 8601 shift and year<=0 by 1, 0=1BCE, -1=2BCE
    }

    // how many days in year X decimal portion = number of days into the year
    // if it's <0 then we count backward from the end of the year, instead of forward into the year
    const dty = decimaldate.daysinyear(yearint);
    let targetday = dty * (Math.abs(truedecdate) % 1);
    if (ispositive) targetday = Math.ceil(targetday);
    else targetday = dty - Math.floor(targetday);

    // count up days months at a time, until we reach our target month
    // then the remainder (days) is the day of that month
    let monthint;
    let dayspassed = 0;
    for (let m = 1; m <= 12; m++) {
        monthint = m;
        const dtm = decimaldate.daysinmonth(yearint, monthint);
        if (dayspassed + dtm < targetday) {
            dayspassed += dtm;
        }
        else {
            break;
        }
    }
    const dayint = targetday - dayspassed;

    // make string output
    // months and day as 2 digits
    // ISO 8601 shift year<=0 by 1, 0=1BCE, -1=2BCE
    const monthstring = monthint.toString().padStart(2, '0');
    const daystring = dayint.toString().padStart(2, '0');
    let yearstring;
    if (yearint > 0) yearstring = yearint.toString().padStart(4, '0');  // just the year as 4 digits
    else if (yearint == -1) yearstring = (Math.abs(yearint + 1).toString().padStart(4, '0'));  // BCE offset by 1 but do not add a - sign
    else yearstring = '-' + (Math.abs(yearint + 1).toString().padStart(4, '0'));  // BCE offset by 1 and add  - sign

    return `${yearstring}-${monthstring}-${daystring}`;
};


decimaldate.isvalidmonthday = (yearint, monthint, dayint) => {
    if (yearint != parseInt(yearint) || yearint == 0) return false;
    if (monthint != parseInt(monthint)) return false;
    if (dayint != parseInt(dayint)) return false;

    if (monthint < 1 || monthint > 12) return false;
    if (dayint < 1) return false;

    const dtm = decimaldate.daysinmonth(yearint, monthint);
    if (! dtm) return false;
    if (dayint > dtm) return false;

    return true;
};


decimaldate.proportionofdayspassed = (yearint, monthint, dayint) => {
    // count the number of days to get through the prior months
    let dayspassed = 0;
    for (let m = 1; m < monthint; m++) {
        const dtm = decimaldate.daysinmonth(yearint, m);
        dayspassed += dtm;
    }

    // add the leftover days not in a prior month
    // but minus 0.5 to get us to noon of the target day, as opposed to the end of the day
    dayspassed = dayspassed + dayint - 0.5;

    // divide by days in year, to get decimal portion
    // even January 1 is 0.5 days in since we snap to 12 noon
    const dty = decimaldate.daysinyear(yearint);
    return dayspassed / dty;
};


decimaldate.daysinmonth = (yearint, monthint) => {
    const monthdaycounts = {
        1: 31,
        2: 28,  // February
        3: 31,
        4: 30,
        5: 31,
        6: 30,
        7: 31,
        8: 31,
        9: 30,
        10: 31,
        11: 30,
        12: 31,
    };

    if (decimaldate.isleapyear(yearint)) monthdaycounts[2] = 29;

    return monthdaycounts[monthint];
};


decimaldate.daysinyear = (yearint) => {
    return decimaldate.isleapyear(yearint) ? 366 : 365;
};


decimaldate.isleapyear = (yearint) => {
    if (yearint != parseInt(yearint) || yearint == 0) throw new Error(`isleapyear() invalid year ${yearint}`);

    // don't forget BCE; there is no 0 so leap years are -1, -5, -9, ..., -2001, -2005, ...
    // just add 1 to the year to correct for this, for this purpose
    const yearnumber = yearint > 0 ? yearint : yearint + 1;

    const isleap = yearnumber % 4 == 0 && (yearnumber % 100 != 0 || yearnumber % 400 == 0);
    return isleap;
};
