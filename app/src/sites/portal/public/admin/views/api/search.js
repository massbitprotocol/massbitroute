define(["models/api"], function ($api_api) {
  var type = "api";
  return {
    $oninit: function (_view, _scope) {
      $api_api.list({}, function (_values) {
        _values = _values.map(function (_v) {
          if (_v.entrypoints && typeof _v.entrypoints === "string")
            _v.entrypoints = JSON.parse(_v.entrypoints);
          return _v;
        });
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
          on: {
            onAfterSelect: function (_id) {
              console.log(_id);
              var _items = this.getSelectedItem(_id);
              console.log(_items);
              var _item = _items[0];
              $$(type + "productsData").clearAll();
              if (_item.entrypoints) {
                $$(type + "productsData").parse(_item.entrypoints);
              }
            },
          },
        },
      ],
    },
  };
});
