define(["models/api"], function ($api_api) {
  var type = "api";
  return {
    $ui: {
      view: "window",
      modal: true,
      id: "auth-win-infura",
      position: "center",
      head: "Infura Authen",
      width: 600,
      body: {
        paddingY: 20,
        paddingX: 30,

        elementsConfig: { labelWidth: 140 },
        view: "form",
        id: type + "infura-form",
        elements: [
          {
            view: "text",
            label: "Project ID",
            placeholder: "Your Project ID",
            name: "infura_project_id",
          },
          {
            view: "text",
            label: "Project Secret",
            placeholder: "Your Project Secret",
            name: "infura_project_secret",
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
                  var _values = $$(type + "infura-form").getValues();
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
                  // item.authen = _values;
                  Object.assign(item, _values);
                  console.log(item);
                  _grid.updateItem(id.row, item);
                  webix.$$("auth-win-infura").close();
                },
              },
              {
                view: "button",
                label: "Cancel",
                align: "center",
                width: 120,
                click: function () {
                  webix.$$("auth-win-infura").close();
                },
              },
            ],
          },
        ],
      },
    },
  };
});
