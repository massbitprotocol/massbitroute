define([app_view + "/util"], function ($util) {
  var scope;
  var type = "entrypoint";
  function _update_form_by_id(id) {
    var req = "";
    if (id) req = "&id=" + id;
    webix
      .ajax()
      .get(
        api_version + "?action=" + type + ".get" + req,
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
    view: "list",
    id: type + "_form",
    template: "#id#",
      select: true,
      data: [],
    on: {
      onSelectChange: function () {
        var id = this.getSelectedId();
        console.log(id);
        scope.parent.show("./" + type + ".edit" + ":id=" + id);
      },
    },
  };

  var _control = {
    cols: [
      {},
      {
        view: "button",
        label: "New",
        autowidth: true,
          click: function () {
	        var _params = $util.params();
	      console.log(_params);
	      var _api_id = _params['entrypoint.list'].api_id;
	      var _opt = "";
	      if(_api_id) _opt = ":api_id=" + _api_id;
	      scope.show(type + ".edit" + _opt);
	  },
      },
    ],
  };

  var _layout = {
      rows: [_form, _control, {}],
  };
  return {
    $ui: _layout,
    $oninit: function (_view, _scope) {
      scope = _scope;
      var _params = $util.params();
      console.log(_params);
      _update_form_by_id();
      //      if (_params[type] && _params[type].id) {
      //        _update_form_by_id(_params[type].id);
      //      }
    },
  };
});
