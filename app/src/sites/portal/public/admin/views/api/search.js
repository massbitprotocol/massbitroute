define(["models/api"], function ($api_api) {
  var type = "api";
  return {
    $oninit: function (_view, _scope) {
      $api_api.list({}, function (_values) {
        console.log(_values);
        $$(type + "list").parse(_values);
      });
    },
    $ui: {
      rows: [
        {
          view: "form",

          paddingX: 5,
          paddingY: 5,
          margin: 2,
          rows: [
            { view: "label", label: "Find API:" },
            { view: "search", placeholder: "Type here..." },
          ],
        },
        {
          view: "list",
          id: type + "list",
          select: true,
          template: "<div class='marker status#status#'></div>#name#",
        },
      ],
    },
  };
});
