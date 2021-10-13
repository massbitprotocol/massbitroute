define(function () {
  return {
    $ui: {
      height: 136,
      css: "tiles",
      template: function (data) {
        var t = null;
        var items = data.items;
        var html = "<div class='flex_tmp'>";
        for (var i = 0; i < items.length; i++) {
          t = items[i];
          html += "<div class='item " + t.css + " bg_panel'>";
          html += "<div class='webix_icon icon fa-" + t.icon + "'></div>";
          html +=
            "<div class='details'><div class='value'>" +
            t.value +
            "</div><div class='text'>" +
            t.text +
            "</div></div>";
          html +=
            "<div class='footer'>View more <span class='webix_icon fa-angle-double-right'></span></div>";
          html += "</div>";
        }
        html += "</div>";
        return html;
      },
      data: {
        items: [
          {
            id: 1,
            text: "APIs",
            value: 10,
            icon: "check-square-o",
            css: "orders",
          },
          { id: 2, text: "Providers", value: 20, icon: "user", css: "users" },
          {
            id: 4,
            text: "Entrypoints",
            value: 25,
            icon: "quote-right",
            css: "feedbacks",
          },
          {
            id: 3,
            text: "Requests",
            value: "+25%",
            icon: "line-chart",
            css: "profit",
          },
        ],
      },
    },
  };
});
