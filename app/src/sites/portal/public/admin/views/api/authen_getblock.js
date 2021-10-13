define(["models/api"], function ($api_api) {
  var type = "api";
  return {
    $ui: {
      view: "window",
      modal: true,
      id: "auth-win-getblock",
      position: "center",
      head: "Infura Getblock",
      width: 600,
      body: {
        paddingY: 20,
        paddingX: 30,

        elementsConfig: { labelWidth: 140 },
        view: "form",
        id: type + "getblock-form",
        elements: [
          {
            view: "text",
            label: "API Key",
            placeholder: "Your API Key",
            name: "getblock_api_key",
          },
          {
            margin: 10,
            cols: [
              {},
              {
                view: "button",
                label: "Add",
                type: "form",
                css: "button_primary button_raised",
                align: "center",
                width: 120,
                click: function () {
                  var _values = $$(type + "getblock-form").getValues();
                  //                  $api_api.create(_values);

                  $api_api.list({}, function (_values) {
                    console.log(_values);
                    $$(type + "list").parse(_values);
                  });
                  var _grid = webix.$$(type + "productsData");
                  var id = _grid.getSelectedId();
                  console.log(id);
                  var item = _grid.getItem(id.row);
                  console.log(item);
                  //                    item.authen = _values;
                  Object.assign(item, _values);
                  console.log(item);
                  _grid.updateItem(id.row, item);
                  webix.$$("auth-win-getblock").close();
                },
              },
              {
                view: "button",
                label: "Cancel",
                align: "center",
                width: 120,
                click: function () {
                  webix.$$("auth-win-getblock").close();
                },
              },
            ],
          },
        ],
      },
    },
  };
});