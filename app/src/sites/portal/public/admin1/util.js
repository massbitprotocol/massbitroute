/// @namespace Util
/// Helpers for various tasks

define(["app"], function ($app) {
  function _getParam(_props) {
    var _params = $app._params();

    if (_props) {
      var _item = _params.filter(function (_obj) {
        return _obj.page == _props.page;
      });
      return _item[0];
    } else
      return _params.reduce(function (_acc, _obj) {
        _acc[_obj.page] = _obj.params;
        return _acc;
      }, {});
  }
  function _updateParam(_page, _props) {
    var _params = $app._params();
    var _hash = _params
      .map(function (_obj) {
        if (_obj.page == _page) Object.assign(_obj.params, _props);
        //        var _param = "";
        var _params = _obj.params;
        var _keys = Object.keys(_params);
        var _param = _keys
          .map(function (_k) {
            var _v = _params[_k];
            return _k + "=" + _v;
          })
          .join(":");
        return _obj.page + (_param ? ":" + _param : "");
      })
      .join("/");
    return "!/" + _hash;
  }
  function _registerActions($store, _actions) {
    Object.keys(_actions).forEach(function (type) {
      $store.subscribe(type, _actions[type]);
    });
  }

  function _updateStateFromParams(_store, tabs) {
    var _config = _store._config;
    var $ptype = _config.ptype;
    var $type = _config.type;

    var _params = _getParam();

    // var _dns_id = _params.dns && _params.dns.id;
    // var _record_id = _params.record && _params.record.id;

    var _vid = _params.app && _params.app.vid;

    var _stack_id = _params.stack && _params.stack.id;
    var _id = _params[$type] && _params[$type].id;
    var _pid = _params[$ptype] && _params[$ptype].id;
    var _version_id = _params[$type] && _params[$type].version_id;
    var _state = {
      // _type: $type,
      // _ptype: $ptype
      //	  dns_id: _dns_id,
      //      stack_id: _stack_id,
      //      record_id: _record_id,
      // version_id: _version_id,
      // id: _id
    };

    if (_vid) _state.vid = _vid;
    if (_id) _state.id = _id;
    if (_id) _state[$type + "_id"] = _id;
    if (_pid) _state[$ptype + "_id"] = _pid;
    if (_stack_id) _state.stack_id = _stack_id;
    if (_version_id) _state.version_id = _version_id;

    //    if (!tabs) return _state;
    var _tabbar = $$($type + "tabbar");
    _tabbar && webix.extend(_tabbar, webix.ProgressBar);

    if (_params && _params["$list"]) {
      var _tab = _params["$list"].tab || $type + "mainViewTab";
      _tabbar && _tabbar.setValue(_tab);
      location.hash = _updateParam("$list", { tab: _tab });
    }

    if (_params && _params["$list"]) {
      //	_store.updateState({ page_type: "list" });
      _state.page_type = "list";

      tabs &&
        tabs.forEach(function (_tab) {
          _tabbar.showOption(_tab["$ui"].id);
        });
    } else {
      _state.page_type = "single";
      tabs &&
        tabs.forEach(function (_tab) {
          _tabbar.hideOption(_tab["$ui"].id);
        });
    }

    if (_state.page_type === "list") _store.publish($type + ":list:update");

    _store.updateState(_state);

    return _state;
  }

  function _removePrivateProp(_values) {
    Object.keys(_values).forEach(function (_k) {
      if (/^_/.test(_k)) delete _values[_k];
    });
  }

  function _traverseAndFlatten(currentNode, target, flattenedKey) {
    for (var key in currentNode) {
      if (currentNode.hasOwnProperty(key)) {
        var newKey;
        if (flattenedKey === undefined) {
          newKey = key;
        } else {
          newKey = flattenedKey + "." + key;
        }

        var value = currentNode[key];
        if (typeof value === "object") {
          _traverseAndFlatten(value, target, newKey);
        } else {
          target[newKey] = value;
        }
      }
    }
  }

  function _flatten(obj) {
    var flattenedObject = {};
    _traverseAndFlatten(obj, flattenedObject);
    return flattenedObject;
  }
  function startCompare(value, filter) {
    value = value.toString().trim().toLowerCase();
    filter = filter.toString().trim().toLowerCase();
    return value.indexOf(filter) === 0;
  }
  var _format_number = webix.Number.numToStr({
    groupDelimiter: ",",
    groupSize: 3,
    decimalDelimiter: ".",
    decimalSize: 0,
  });
  function nFormatter(num1) {
    var num = Math.floor(num1);
    var _val;
    if (num >= 1000000000) {
      _val = (num / 1000000000).toFixed(1).replace(/\.0$/, "");
      return _format_number(_val) + "B";
    }
    if (num >= 1000000) {
      _val = (num / 1000000).toFixed(1).replace(/\.0$/, "");
      return _format_number(_val) + "M";
    }
    if (num >= 1000) {
      _val = (num / 1000).toFixed(1).replace(/\.0$/, "");
      return _format_number(_val) + "K";
    }
    return num;
  }

  function _objectValues(_values) {
    _values = Object.keys(_values).reduce(function (_o, _k) {
      if (/\./.test(_k)) {
        objectPath.set(_o, _k, _values[_k]);
        delete _values[_k];
      } else _o[_k] = _values[_k];
      return _o;
    }, {});
    return _values;
  }
  return {

  };
});
