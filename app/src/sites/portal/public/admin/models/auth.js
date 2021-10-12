define([], function () {
  function _ping() {
    webix.ajax().get("/api/v1?action=user.ping", function (_text, _json) {
      var _res = _json.json();
      if (!_res.result) location.hash = "!/auth.login";
    });
  }
  function _register() {
    var _user = $$("userForm").getValues();
    console.log(_user);
    if (_user.password != _user.password1) {
      return webix.message({
        text: "Password not matched",
        type: "error",
        expire: 3000,
      });
    } else {
      delete _user.password1;
    }

    webix
      .ajax()
      .post("/api/v1?action=user.register", _user, function (_text, _json) {
        var _res = _json.json();
        console.log(_res);
        if (_res.result) {
          webix.message({
            text: "Register successful",
            expire: 3000,
          });
          location.hash = "!/auth.login";
        } else {
          webix.message({
            text: "Register failed",
            type: "error",
            expire: 3000,
          });
        }
      });
  }
  function _login() {
    var _user = $$("userForm").getValues();
    console.log(_user);
    webix
      .ajax()
      .post("/api/v1?action=user.login", _user, function (_text, _json) {
        var _res = _json.json();
        console.log(_res);
        if (_res.result) {
          location.hash = "!/app/dashboard";
        } else {
          webix.message({
            text: "Login failed",
            type: "error",
            expire: 3000,
          });
        }
      });
  }
  return {
    ping: _ping,
    login: _login,
    register: _register,
  };
});
