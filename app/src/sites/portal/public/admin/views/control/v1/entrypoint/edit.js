define([app_view + "/util"], function ($util) {
  var scope;
  var type = "entrypoint";
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
  }
  function _init(_params) {
    webix.ajax().get(api_version + "?action=api.get", function (_text, _raw) {
      var _res = _raw.json();
      console.log(_res);
      if (_res.result) {
        var _ui = $$(type + "api_id");
        _ui.define("options", _res.data);
        _ui.refresh();
      }
    });
  }
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
      {
        view: "select",
        id: type + "api_id",
        label: "API ID",
        name: "api_id",
        options: [],
      },
		{ view: "counter", label: "Weight", name: "weight", value: 5 },
	{ view: "checkbox", label: "Is Backup", name: "is_backup", value: 0 },
      {
        view: "select",
        label: "Provider",
        name: "provider",
        options: [
          { id: "getblock", value: "GetBlock" },
          { id: "infura", value: "Infura" },
        ],
        on: {
          onChange: function (_v) {
            console.log(_v);
            ["getblock", "infura"].forEach(function (_v1) {
              var _ui = $$(type + "provider_option_" + _v1);
              if (_v == _v1) _ui.show();
              else _ui.hide();
            });
          },
        },
      },
      {
        rows: [
          {
            id: type + "provider_option_getblock",
            // hidden: true,
            rows: [
              {
                view: "text",
                name: "getblock_api_key",
                label: "API Key",
                labelWidth: 100,
              },
            ],
          },
          {
            id: type + "provider_option_infura",
            hidden: true,
            rows: [
              {
                view: "text",
                name: "infura_project_id",
                label: "Project ID",
                labelWidth: 100,
              },
              {
                view: "text",
                name: "infura_project_secret",
                label: "Project Secret",
                labelWidth: 100,
              },
            ],
          },
        ],
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
      _init(_params);
      var type1 = type + ".edit";
      if (_params[type1] && _params[type1].id) {
        _update_form_by_id(_params[type1].id);
      }
    },
  };
});
