define(["models/api"], function ($api_api) {
  var type = "api";
  return {
    $ui: {
      view: "window",
      modal: true,
      id: "order-win",
      position: "center",
      head: "Add new " + type,
      width: 600,
      body: {
        paddingY: 20,
        paddingX: 30,
        elementsConfig: { labelWidth: 140 },
        view: "form",
        id: type + "order-form",
        elements: [
          {
            view: "text",
            label: "Name",
            placeholder: "Your " + type + " name",
            name: "name",
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
                  var _values = $$(type + "order-form").getValues();
                  $api_api.create(_values);
                  webix.$$("order-win").close();
                  $api_api.list({}, function (_values) {
                    console.log(_values);
                    $$(type + "list").clearAll();
                    $$(type + "list").parse(_values);
                  });
                },
              },
              {
                view: "button",
                label: "Cancel",
                align: "center",
                width: 120,
                click: function () {
                  webix.$$("order-win").close();
                },
              },
            ],
          },
        ],
      },
    },
  };
});
