define(["views/api/config"], function ($config) {
  var type = "api";
  var _blockchain_option = $config.blockchains;
  var form = {
    view: "form",
    id: type + "mainView",
    elementsConfig: {
      labelWidth: 130,
    },
    scroll: true,
    elements: [
      {
        cols: [
          {},
          {
            view: "toggle",
            autowidth: true,
            name: "status",
            label: "Status",
            offLabel: "Disabled",
            onLabel: "Enabled",
          },
        ],
      },
      {
        view: "text",
        placeholder: type + " name",
        name: "name",
        label: "Name",
      },
      {
        view: "text",
        name: "api_key",
        readonly: true,
        label: "API Key",
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
            if (_item.network) {
              $$(type + "network").define("options", _item.network);
              $$(type + "network").refresh();
            }
            if (_item.api_interface) {
              $$(type + "api_interface").define("options", _item.api_interface);
              $$(type + "api_interface").refresh();
            }
          },
        },
      },
      {
        view: "segmented",
        label: "API Interface",
        name: "api_interface",
        id: type + "api_interface",
        options: [],
      },
      {
        view: "segmented",
        label: "Network",
        name: "network",
        id: type + "network",
        options: [],
      },

      {},
    ],
  };

  return {
    $ui: form,
  };
});
