define(["models/api"], function ($domain) {
  var type = "api";
  return {
    $ui: {
      view: "window",
      modal: true,
      id: "auth-win",
      position: "center",
      head: "Infura Authen",
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
                  $domain.create(_values);
                  webix.$$("auth-win").close();
                  $domain.list({}, function (_values) {
                    console.log(_values);
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
                  webix.$$("auth-win").close();
                },
              },
            ],
          },
        ],
      },
    },
  };
});
