(function () {
  var num = Math.floor(Math.random() * 6);

  // Background image
  if (window.location.hash) {
    var h = window.location.hash.match(/#(.*)/);
    if (!isNaN(parseInt(h[1], 10))) num = h[1];
  }

  // $(document).ready(function () {
  //   $('#content').attr('class', 'photo-' + num);
  // });

  $(document).on('click', '#next-photo', function () {
    num = (num + 1) % 6;
    $('#content').attr('class', 'photo-' + num);
    window.location.hash = num;
    return false;
  });
})();
