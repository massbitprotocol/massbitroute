define(["views/api/config"], function ($api_config) {
  var type = "api";
  var _blockchain_option = $api_config.blockchains;
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
          {
            view: "fieldset",
            label: "Your API provider",
            body: {
              rows: [
                {
                  view: "text",
                  name: "gateway_http",
                  label: "HTTP Provider",
                  readonly: true,
                },
                {
                  view: "text",
                  label: "WSS Provider",
                  name: "gateway_wss",
                  readonly: true,
                },
              ],
            },
          },
          //          {},
        ],
      },
      {
        view: "text",
        placeholder: type + " name",
        name: "name",
        label: "Name",
      },
      {
        view: "checkbox",
        name: "status",
        label: "Status",
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

            var _ui = $$(type + "network");
            if (_item.network && _ui) {
              _ui.define("options", _item.network);
              _ui.refresh();
            }
            var _ui = $$(type + "api_interface");
            if (_item.api_interface && _ui) {
              _ui.define("options", _item.api_interface);
              _ui.refresh();
            }
          },
        },
      },
      {
        view: "segmented",
        label: "API Interface",
        name: "api_interface",
        id: type + "api_interface",
        options: [
          { id: "jsonrpc", value: "JSON-RPC" },
          { id: "ws", value: "WS" },
        ],
      },
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

      {},
    ],
  };

  return {
    $ui: form,
  };
});
