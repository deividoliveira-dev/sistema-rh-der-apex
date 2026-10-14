// Tooltip nos itens do menu lateral: usa o próprio nome do item como title
apex.jQuery(function ($) {
  function addNavTitles() {
    $(".t-Body-nav a").each(function () {
      var $a = $(this);
      var t = $.trim($a.text());
      if (t && !$a.attr("title")) {
        $a.attr("title", t);
      }
    });
  }
  addNavTitles();
  setTimeout(addNavTitles, 800);
});
