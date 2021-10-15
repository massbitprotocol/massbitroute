define([], function () {
  var type = "api";
  function _create(args, callback) {
    console.log(args);
    args.action = type + ".create";
    webix.ajax().post("/api/v1", args, function (_text, _json) {
      var _res = _json.json();
      console.log(_res);
      if (_res.result) callback && callback(_res.data);
      else {
        if (_res.err_code == 100) location.hash = "!/auth.login";
      }
    });
  }
  function _delete(args, callback) {
    args.action = type + ".delete";
    console.log(args);
    webix.ajax().post("/api/v1", args, function (_text, _json) {
      var _res = _json.json();
      console.log(_res);
      if (_res.result) callback && callback(_res.data);
      else {
        if (_res.err_code == 100) location.hash = "!/auth.login";
      }
    });
  }
  function _update(args, callback) {
    console.log(args);
    args.action = type + ".update";
    webix.ajax().post("/api/v1", args, function (_text, _json) {
      var _res = _json.json();
      console.log(_res);
      if (_res.result) callback && callback(_res.data);
      else {
        if (_res.err_code == 100) location.hash = "!/auth.login";
      }
    });
  }
  function _list(args, callback) {
    console.log(args);
    args.action = type + ".list";
    webix.ajax().get("/api/v1", args, function (_text, _json) {
      var _res = _json.json();
      console.log(_res);
      if (_res.result) callback && callback(_res.data);
      else {
        if (_res.err_code == 100) location.hash = "!/auth.login";
      }
    });
  }
  return {
    delete: _delete,
    update: _update,
    create: _create,
    list: _list,
  };
});
