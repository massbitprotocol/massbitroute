define([app_view + "/util"], function ($util) {
  var scope;
  var type = "package";
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
      { view: "counter", label: "Price ($)", name: "price" },
      {
        cols: [
          { view: "counter", label: "Requests", name: "requests" },

          {
            view: "select",
            label: "Unit",
            name: "unit",
              options: [
		  { id: "month", value: "Month" },
              { id: "hour", value: "Hour" },
              { id: "day", value: "Day" },
              { id: "week", value: "Week" },

            ],
          },
          {},
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
    rows: [_back, _form, {}, _control],
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
