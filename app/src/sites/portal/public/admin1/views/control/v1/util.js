define([app_name], function($app) {
  function _params() {
    var _params = $app._params().reduce(function(_acc, _obj) {
      _acc[_obj.page] = _obj.params;
      return _acc;
    }, {});
    return _params;
  }
  function init_page(config) {
    if (config && config.menu_data) {
      var _sidebar = $$("main_sidebar");

      _sidebar.clearAll();
      _sidebar.define("data", config.menu_data);
      _sidebar.refresh();
    }
  }
  function flattenObject(ob) {
    var toReturn = {};

    for (var i in ob) {
      if (!ob.hasOwnProperty(i)) continue;

      if (typeof ob[i] == "object" && ob[i] !== null) {
        var flatObject = flattenObject(ob[i]);
        for (var x in flatObject) {
          if (!flatObject.hasOwnProperty(x)) continue;

          toReturn[i + "." + x] = flatObject[x];
        }
      } else {
        toReturn[i] = ob[i];
      }
    }
    return toReturn;
  }
  return {
    flattenObject: flattenObject,
    init_page: init_page,
    params: _params
  };
});
