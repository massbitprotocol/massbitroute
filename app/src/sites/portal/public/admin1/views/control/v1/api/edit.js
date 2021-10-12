define([app_view + "/util"], function ($util) {
  var scope;
  var type = "api";
  function _update_form_by_id(id) {
    webix
      .ajax()
      .get(
        api_version + "?action=" + type + ".get&id=" + id,
        function (text, raw) {
          var _res = raw.json();
          console.log(_res);
          if (_res && _res.result && _res.data) {
            $$(type + "_form").parse(_res.data);
          }
        }
      );

    webix
      .ajax()
      .get(api_version + "?action=package.get", function (_text, _raw) {
        var _res = _raw.json();
        console.log(_res);
        if (_res.result) {
          var _ui = $$(type + "package_id");
          _ui.define("options", _res.data);
          _ui.refresh();
        }
      });
    webix
      .ajax()
      .get(api_version + "?action=customer.get", function (_text, _raw) {
        var _res = _raw.json();
        console.log(_res);
        if (_res.result) {
          var _ui = $$(type + "customer_id");
          _ui.define("options", _res.data);
          _ui.refresh();
        }
      });
  }
  var _blockchain_option = [
    {
      id: "eth",
      value: "Ethereum",
      api_interface: [
        { id: "jsonrpc", value: "JSON-RPC" },
        { id: "ws", value: "WS" },
      ],
      network: [
        { id: "mainnet", value: "Mainnet" },
        { id: "testnet", value: "Testnet" },
      ],
    },
    {
      id: "btc",
      value: "Bitcoin",
      api_interface: [
        { id: "jsonrpc", value: "JSON-RPC" },
        { id: "rest", value: "Rest" },
      ],
      network: [
        { id: "mainnet", value: "Mainnet" },
        { id: "testnet", value: "Testnet" },
      ],
    },
    {
      id: "bsc",
      value: "Binance Smart Chain",
      api_interface: [
        { id: "jsonrpc", value: "JSON-RPC" },
        { id: "ws", value: "WS" },
      ],
      network: [
        { id: "mainnet", value: "Mainnet" },
        { id: "testnet", value: "Testnet" },
      ],
    },
    {
      id: "bch",
      value: "Bitcoin Cash",
      api_interface: [
        { id: "jsonrpc", value: "JSON-RPC" },
        { id: "ws", value: "WS" },
      ],
      network: [{ id: "mainnet", value: "Mainnet" }],
    },
    {
      id: "xrp",
      value: "XRP",
      api_interface: [{ id: "jsonrpc", value: "JSON-RPC" }],
      network: [{ id: "mainnet", value: "Mainnet" }],
    },
    {
      id: "dot",
      value: "Palkadot",
      api_interface: [{ id: "jsonrpc", value: "JSON-RPC" }],
      network: [
        { id: "mainnet", value: "Mainnet" },
        { id: "testnet", value: "Testnet" },
      ],
    },
    {
      id: "zen",
      value: "Horizen",
      api_interface: [{ id: "jsonrpc", value: "JSON-RPC" }],
      network: [{ id: "mainnet", value: "Mainnet" }],
    },
    { id: "bsv", value: "Bitcoin-SV" },
    { id: "eos", value: "EOS" },
    { id: "ltc", value: "Litecoin" },
    { id: "stake", value: "xDai" },
    { id: "ada", value: "Cardano" },
    { id: "xmr", value: "Monero" },
    { id: "matic", value: "Polygon" },
    { id: "ksm", value: "Kusama" },
    { id: "nem", value: "NEM" },
    { id: "neo", value: "NEO" },
    { id: "trx", value: "Tron" },
    { id: "xlm", value: "Stellar" },
    { id: "xtz", value: "Tezos" },
    { id: "atom", value: "Cosmos" },
    { id: "iota", value: "Miota" },
    { id: "dash", value: "DASH" },
    { id: "zcash", value: "ZEC" },
    { id: "theta", value: "THETA" },
    { id: "etc", value: "Ethereum Classic" },
    { id: "doge", value: "Dogecoin" },
    { id: "waves", value: "Waves" },
    { id: "dgb", value: "DigiByte" },
    { id: "icx", value: "ICON" },
    { id: "zil", value: "Zilliqa" },
    { id: "band", value: "Band Protocol" },
    { id: "dcr", value: "Decred" },
    { id: "btg", value: "Bitcoin Gold" },
    { id: "lsk", value: "Lisk" },
    { id: "xvg", value: "Verge" },
    { id: "steem", value: "Steem" },
    { id: "waxp", value: "Wax" },
    { id: "hive", value: "Hive" },
    { id: "rdd", value: "Reddcoin" },
    { id: "ccxx", value: "Counos X" },
    { id: "bcn", value: "Bytecoin" },
    { id: "grs", value: "Groestlcoin" },
    { id: "fct", value: "Factom" },
    { id: "rsk", value: "Rsk" },
    { id: "fuse", value: "Fuse.io" },
  ];
  var _form = {
    view: "form",
    id: type + "_form",
    elementsConfig: {
      labelPosition: "left",
      labelWidth: 100,
    },
    elements: [
      { view: "text", id: type + "_form_id", label: "ID", name: "id" },
      {
        cols: [
          {},
          {
            view: "button",
            label: "Get",
            autowidth: true,
            click: function () {
              var _id = $$(type + "_form_id").getValue();
              _id && _update_form_by_id(_id);
            },
          },
        ],
      },

      { view: "text", label: "Name", name: "name" },
      { view: "text", label: "API ID", name: "api_id" },
      { view: "text", label: "API key", name: "api_key" },

      {
        view: "select",
        id: type + "customer_id",
        label: "Customer ID",
        name: "customer_id",
        options: [],
      },
      {
        view: "select",
        id: type + "package_id",
        label: "Package ID",
        name: "package_id",
        options: [],
      },
      {
        view: "select",
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
        view: "select",
        label: "Network",
        name: "network",
        id: type + "network",
        options: [],
      },
    ],
  };
  var _control = {
    cols: [
      {},
      {
        view: "button",
        label: "Remove",
        autowidth: true,
        click: function () {
          var _id = $$(type + "_form_id").getValue();
          _id &&
            webix
              .ajax()
              .post(
                api_version + "?action=" + type + ".delete",
                { id: _id },
                function (text, raw) {
                  var _res = raw.json();
                  console.log(_res);
                }
              );
        },
      },
      {
        view: "button",
        label: "Save",
        autowidth: true,
        click: function () {
          console.log("save");
          var _values = $$(type + "_form").getValues();

          webix
            .ajax()
            .post(
              api_version + "?action=" + type + ".update",
              _values,
              function (text, raw) {
                var _res = raw.json();
                console.log(_res);
              }
            );
        },
      },
      {
        view: "button",
        label: "Entrypoints",
        autowidth: true,
        click: function () {
          var _params = $util.params();
          console.log(_params);
          var _api_id = _params["api.edit"].id;
          scope.show("entrypoint.list:api_id=" + _api_id);
        },
      },
    ],
  };
  var _back = {
    cols: [
      {
        view: "button",
        label: "Back",
        autowidth: true,
        click: function () {
          scope.show(type + ".list");
        },
      },
      {},
    ],
  };
  var _layout = {
    cols: [{ rows: [_back, _form, _control, {}] }, {}],
  };
  return {
    $ui: _layout,
    $oninit: function (_view, _scope) {
      scope = _scope;
      var _params = $util.params();
      console.log(_params);
      var type1 = type + ".edit";
      if (_params[type1] && _params[type1].id) {
        _update_form_by_id(_params[type1].id);
      }
    },
  };
});
