//= require jquery

(function () {
  var num = Math.floor(Math.random() * 6);

  // Background image
  if (window.location.hash) {
    var h = window.location.hash.match(/#(.*)/);
    if (!isNaN(parseInt(h[1], 10))) num = h[1];
  }

  $(document).ready(function () {
    $('body').attr('class', 'photo-' + num);
  });

  $(document).on('click', '#next-photo', function () {
    num = (num + 1) % 6;
    $('body').attr('class', 'photo-' + num);
    window.location.hash = num;
    return false;
  });

  // Attribution builder
  $(document).on('keyup', '#builder input', function() {
    var name = $('#field-user-name').val(),
      image = $('#field-user-image').val();
    $('#preview .customized .user-name').text(name);
    $('#preview .customized .user-image').css('background-image', image && 'url("' + encodeURIComponent(image) + '")');
    $('#builder').toggleClass('customized', !!(name || image));
    return false;
  });

  $(document).on('click', '#builder .button', function() {
    var query = {};
    if ($('#field-user-name').val())
      query.name = $('#field-user-name').val();
    if ($('#field-user-image').val())
      query.image = $('#field-user-image').val();
    var url = 'http://www.openstreetmap.org/copyright/?' + $.param(query);
    var attr = "<a target='_blank' href='" + url + "' style='background:url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABoAAAAaCAMAAACelLz8AAAB11BMVEXZ2dlkZGT///////////8mJibIyMj5+fm6urr///8sLCywsLBJSUn///9eXl7////////j4+P////////Q0ND////u7u7i4uIfHx/s7OxmZmZzc3P39/fw8PDg4OD5+fmNjY1cXFz5+flQUFBGRkaIiIhtbW3///////9hYWHS0tKlpaWsrKzZ2dmgoKCpqalycnLg4OCCgoJLS0tEREQlJSX9/f3///8/Pz/e3t4jIyP///////////+/v7+Ghobp6enDw8Pl5eVXV1f////////U1NT////////////////l5eW1tbX///+4uLj////////////////////////////w8PDNzc3GxsYuLi7w8PD///////9paWmvr6/c3NwhISHe3t5UVFQfHx/y8vLn5+d3d3eXl5f////09PTs7Oz///8zMzN8fHz///+UlJT////////u7u44ODj////p6en///86Ojqurq5ZWVlfX1////////8hISFBQUGioqIlJSXV1dV6enoqKioxMTH39/eLi4s4ODj///9ra2ubm5v9/f3Nzc28vLz///9LS0v///////////+FhYUdHR3////X19cjIyM2Njaenp7///8AAAAbGxtl93oXAAAAnXRSTlNzcE9udnpweG9Gem50TnI9Z3VgbHEWeHR9dnBvendzfG5ye3N0b3A4I3Fxbm5ybm5wdG5zdXt0NHVze14eMW9udW90cld4cUdSFx11bnJvHG1ANj8VQnlwcHl4H1xwb3N8dHN8eXZvbnV5d0t4byluAyd3dwt2VnZucnEvCn11bnxyb3p4e252BHBufXFvYnRzZQxvfWpyfHdufQB9fOn/1AAAAY5JREFUKM+V0mVvwzAQBuCMmZmZmZmZmZmZGcpMa7ukWXK5H7ukVbOpmqbt/WDZfiRLdz6C+8oqAPh6+8BqnANaOI74RoASydLisnzRdiGt9yQa9pVglC7LYws8advLTxEWoJaGx1x6ksx/LdQetI5R55xIE4O2+yvhwZDgwxUaobDh1kn6F/ud9vSMBu3p5lLgycqGAZosjneCe52zLTyjEB17DRAdERkva0Rk34h3x+gNinmy7FqyKOcWiDcWfw4QgL+TXC2sH8yOJ9V1AXRaUZmdkZqCALX4APDhotKjbcZ8LDkyoiyBp3I0ipRWgVgDORu768mJCFt3uEe4SXPA1wRFqgPatEVBJpyZSDcpFBR2mKzFubgGN5BfpjEb3GTVdJtNRqrq+DE9aQcMJFSKhIyW7UFsri7JUyHJqMhNhqT+UPL/iO+8ix4e5y1P38A6zv+X0Pln89jU7LT9mtU575mLkcmZV47/r/Y9+4temIKhARutVO/3H54Mc87ZuG1rFQfn8uq+r/dc7zp8AmmAXy4xp9xiAAAAAElFTkSuQmCC) no-repeat; background-size:26px 26px;width:24px;height:24px;display:block;z-index:1000;bottom:2px;right:5px;bottom:5px;position:absolute;'></a>";
    $('#builder').attr('class', 'builder widget');
    $('#field-widget').val(attr);
    return false;
  });

  $(document).on('click', '#builder .close', function() {
    $('body').removeClass('builder');
    $('#builder').attr('class', 'builder');
    return false;
  });

  function builder() {
    $('body').addClass('builder');
  }

  $(document).on('click', 'a[href=#builder]', function() {
    builder();
    return false;
  });

  $(document).ready(function () {
    if (window.location.hash === '#builder') builder();
  });
})();
