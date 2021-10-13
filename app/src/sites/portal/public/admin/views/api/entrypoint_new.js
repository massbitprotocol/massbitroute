define(["views/api/config", "models/api"], function ($api_config, $api_api) {
  var _providers = $api_config.providers;
  var type = "api";
  return {
    $ui: {
      view: "window",
      modal: true,
      id: "auth-win-entrypoint",
      position: "center",
      head: "New Entrypoint",
      width: 600,
      body: {
        paddingY: 20,
        paddingX: 30,

        elementsConfig: { labelWidth: 140 },
        view: "form",
        id: type + "entrypoint-form",
        elements: [
          {
            view: "combo",
            label: "Provider",
            placeholder: "Your Provider",
            name: "type",
            value: "INFURA",
            options: _providers,
            on: {
              onChange: function (_v) {
                _providers.forEach(function (_v1) {
                  var _ui = $$("authen_" + _v1);
                  if (_ui) {
                    if (_v == _v1) _ui.show();
                    else _ui.hide();
                  }
                });
              },
            },
          },
          {
            view: "slider",
            label: "Priority",
            value: "5",
            min: 1,
            max: 10,
            title: webix.template("#value#"),
            name: "priority",
          },
          {
            view: "checkbox",
            name: "status",
            value: 1,
            label: "Status",
          },

          {
            id: "authen_INFURA",
            rows: [
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
            ],
          },
          {
            hidden: true,
            id: "authen_GETBLOCK",
            rows: [
              {
                view: "text",
                label: "API Key",
                placeholder: "Your API Key",
                name: "getblock_api_key",
              },
            ],
          },
          {
            hidden: true,
            id: "authen_QUICKNODE",
            rows: [
              {
                view: "text",
                label: "API Key",
                placeholder: "Your API Key",
                name: "quicknode_api_key",
              },
            ],
          },
          {
            hidden: true,
            id: "authen_CUSTOM",
            rows: [
              {
                view: "text",
                label: "API URI",
                placeholder: "Your API URI",
                name: "custom_api_uri",
              },
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
                  var _values = $$(type + "entrypoint-form").getValues();
                  //                  $api_api.create(_values);

                  // $api_api.list({}, function (_values) {
                  //   console.log(_values);
                  //   $$(type + "list").parse(_values);
                  // });
                  var _grid = webix.$$(type + "productsData");
                  _grid.add(_values);
                  // var id = _grid.getSelectedId();
                  // console.log(id);
                  // var item = _grid.getItem(id.row);
                  // console.log(item);
                  // item.authen = _values;
                  // console.log(item);
                  // _grid.updateItem(id.row, item);
                  webix.$$("auth-win-entrypoint").close();
                },
              },
              {
                view: "button",
                label: "Cancel",
                align: "center",
                width: 120,
                click: function () {
                  webix.$$("auth-win-entrypoint").close();
                },
              },
            ],
          },
        ],
      },
    },
  };
});
