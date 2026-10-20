// Balão com o nome ao passar o mouse nos ícones do menu lateral, cards e títulos de região
apex.jQuery(function ($) {
  var $tip = $('<div id="nav-tip"></div>')
    .css({
      position: "fixed",
      display: "none",
      background: "#2B2B2B",
      color: "#FFFFFF",
      padding: "6px 12px",
      borderRadius: "4px",
      fontSize: "13px",
      whiteSpace: "nowrap",
      zIndex: 100000,
      pointerEvents: "none"
    })
    .appendTo("body");

  $(document)
    .on("mouseenter", ".t-Body-nav .a-TreeView-node", function () {
      var rect = this.getBoundingClientRect();
      var texto = $.trim($(this).find(".a-TreeView-label").first().text());
      if (!texto || rect.width > 120) {
        return;
      }
      $tip.text(texto).css({
        left: rect.right + 8,
        top: rect.top + rect.height / 2,
        transform: "translateY(-50%)",
        display: "block"
      });
    })
    .on("mouseleave", ".t-Body-nav .a-TreeView-node", function () {
      $tip.hide();
    });

  function addTitles() {
    $(".a-CardView-icon, .a-CardView-initials, .t-Cards-icon").each(function () {
      var $i = $(this);
      var t = $.trim($i.closest("li").find(".a-CardView-title, .t-Cards-title").first().text());
      if (t && !$i.attr("title")) {
        $i.attr("title", t);
      }
    });

    $(".t-Region-title").each(function () {
      var $h = $(this);
      var t = $.trim($h.text());
      if (t) {
        $h.find("span.fa, span.t-Icon").attr("title", t);
      }
    });
  }
  addTitles();
  setTimeout(addTitles, 800);
});
