define(["models/api", "views/api/config"], function ($api_api, $api_config) {
  var type = "api";
  var _blockchain_option = $api_config.blockchains;
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
            view: "combo",
            label: "Blockchain",
            name: "blockchain",
            options: _blockchain_option,
            on: {
              onChange: function (_v) {
                console.log(_v);
                var _item = _blockchain_option.find(function (_i) {
                  return _i.id == _v;
                });
                console.log(_item);
                if (!_item) return;
                var _ui = $$(type + "network");
                if (_ui && _item.network) {
                  _ui.define("options", _item.network);
                  _ui.refresh();
                }
                // if (_item.api_interface) {
                //   $$(type + "api_interface").define(
                //     "options",
                //     _item.api_interface
                //   );
                //   $$(type + "api_interface").refresh();
                // }
              },
            },
          },
          // {
          //   view: "segmented",
          //   label: "API Interface",
          //   name: "api_interface",
          //   id: type + "api_interface",
          //   options: [],
          // },
          {
            view: "segmented",
            label: "Network",
            name: "network",
            id: type + "network",
            options: [
              { id: "mainnet", value: "Mainnet" },
              { id: "testnet", value: "Testnet" },
            ],
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
                  $$(type + "list").add(Object.assign(_values, { status: 1 }));
                  setTimeout(function () {
                    $api_api.list({}, function (_values) {
                      console.log(_values);
                      $$(type + "list").clearAll();
                      $$(type + "list").parse(_values);
                    });
                  }, 1000);
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
