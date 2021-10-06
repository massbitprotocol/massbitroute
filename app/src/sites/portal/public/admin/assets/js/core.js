"use strict";

define([], function() {
  var viewdir = "views";
  function show(path, config) {
    if (config == -1) return render_sub_stack(this, path);
    if (this._subs[path]) return render_sub_stack(this._subs[path], config);

    var scope = get_app_scope(this);
    var index = this.index;

    if (typeof path == "string") {
      //child page
      if (path.indexOf("./") === 0) {
        index++;
        path = path.substr(2);
      }

      //route to page
      var parsed = parse_parts(path);
      scope.path = scope.path.slice(0, index).concat(parsed);
    } else {
      //set parameters
      webix.extend(scope.path[index].params, path, true);
    }

    var _path = url_string(scope.path);
    scope.show(_path, -1);
  }

  function get_app_scope(scope) {
    while (scope) {
      if (scope.app) return scope;
      scope = scope.parent;
    }
    return app;
  }

  function url_string(stack) {
    var url = [];
    var start = app.config.layout ? 1 : 0;

    for (; start < stack.length; start++) {
      url.push("/" + stack[start].page);
      var params = params_string(stack[start].params);
      if (params) url.push(":" + params);
    }

    return url.join("");
  }
  function params_string(obj) {
    var str = [];
    for (var key in obj) {
      if (str.length) str.push(":");
      str.push(key + "=" + obj[key]);
    }

    return str.join("");
  }

  function subui(ui, name, stack) {
    // console.log("subui");
    // console.log(ui);
    //		console.log(name);
    //		if (run_plugins(url_plugins, ui, name, stack, this) === false) return;

    if (name.page != this.name) {
      this.name = name.page;
      this.ui = create_temp_ui;
      this.on = create_temp_event;
      this.show = show;
      this.module = ui;

      destroy.call(this);

      //collect init and destory handlers
      //set subview container
      this._init = [];
      this._destroy = [];
      this._windows = [];
      this._events = [];
      this._subs = {};
      this.$layout = false;

      var subview = copy(ui, null, this);
      //	console.log(subview);
      subview.$scope = this;

      create.call(this, subview);

      //prepare layout for view loading
      if (this.$layout) {
        this.$layout = {
          root: (this._ui.$$ || webix.$$)(this.name + ":subview"),
          sub: subui,
          parent: this,
          index: this.index + 1
        };
      }
    }

    //	console.log(this.$layout);
    //run_plugins(ui_plugins, ui, name, stack, this);
    //if (!ui.$onurlchange || ui.$onurlchange.call(ui, name.params, stack, this) !== false)
    return this.$layout;
  }

  function parse_parts(url) {
    //split url by "/"
    var chunks = url.split("/");

    //use optional default layout page
    if (!chunks[0]) {
      if (app.config.layout) chunks[0] = app.config.layout;
      else chunks.shift();
    }

    //for each page in url
    for (var i = 0; i < chunks.length; i++) {
      var test = chunks[i];
      var result = {};

      //detect params
      var pos = test.indexOf(":");
      if (pos !== -1) {
        var params = test.substr(pos + 1).split(":");
        //detect named params
        var objmode = params[0].indexOf("=") !== -1;

        //create hash of named params
        if (objmode) {
          result = {};
          for (var j = 0; j < params.length; j++) {
            var dchunk = params[j].split("=");
            result[dchunk[0]] = dchunk[1];
          }
        } else {
          result = params;
        }
      }

      //store parsed values
      chunks[i] = {
        page: pos > -1 ? test.substr(0, pos) : test,
        params: result
      };
    }

    //return array of page objects
    return chunks;
  }

  function copy(obj, target, config) {
    if (obj.$oninit) config._init.push(obj.$oninit);
    if (obj.$ondestroy) config._destroy.push(obj.$ondestroy);
    if (obj.$onevent) {
      for (var key in obj.$onevent) config._events.push(key, obj.$onevent[key]);
    }
    if (obj.$windows) config._windows.push.apply(config._windows, obj.$windows);

    if (obj.$subview) {
      if (typeof obj.$subview == "string") {
        var tname = config.name + ":subview:" + obj.$subview;
        var tobj = (config._subs[obj.$subview] = {
          parent: this,
          root: tname,
          sub: subui,
          index: 0,
          app: true
        });

        obj.id = tname;
      } else {
        obj = { id: config.name + ":subview" };
        config.$layout = true;
      }
    }
    if (obj.$ui) obj = obj.$ui;
    if (obj.$init) {
      return obj;
    }

    target = target || (webix.isArray(obj) ? [] : {});
    for (var method in obj) {
      if (
        obj[method] &&
        typeof obj[method] == "object" &&
        !webix.isDate(obj[method])
      ) {
        target[method] = copy(
          obj[method],
          webix.isArray(obj[method]) ? [] : {},
          config
        );
      } else {
        target[method] = obj[method];
      }
    }

    return target;
  }

  function render_sub_stack(scope, path) {
    if (scope.root) scope.root = webix.$$(scope.root);

    var parts = parse_parts(path);
    render_stack(scope, [].concat(parts));
  }

  function render_stack(layout, stack, prev_url) {
    //        var stack = [].concat(stack1);

    var line = stack[0];
    if (line) {
      layout.path = line;
      var url = line.page;
      //      console.log("+ render -> " + url);
      var issubpage = url.indexOf(".") === 0;

      if (issubpage) url = (layout.fullname || "") + url;

      url = url.replace(/\./g, "/");
      url = url.replace(/[\/]+/g, "/");
      url = url.replace(/\/[^\/]+\/\$/g, "/");

      if (url[0] == "$") url = prev_url + "/" + url.substring(1);
      //			if (run_plugins(require_plugins, url, line, stack, layout) === false) return;

      var next_step = function(ui) {
        if (typeof ui === "function") ui = ui();
        //	    console.log(ui);
        stack.shift();
        //	    console.log(stack);
        var next = layout.sub(ui, line, stack);
        //	  console.log(next);
        if (next) {
          next.fullname = (issubpage ? layout.fullname || "" : "") + line.page;
          render_stack(next, stack, url);
        } else {
          webix.ui.$freeze = false;
          webix.ui.resize();
        }
      };
      var _url = (viewdir || "views") + "/" + url;
      //	console.log(_url);
      require([_url], function(ui) {
        if (ui.then) ui.then(next_step);
        else next_step(ui);
      });
    } else {
      webix.ui.$freeze = false;
      webix.ui.resize();
    }
  }

  var ui_plugins = [];
  var url_plugins = [];
  var require_plugins = [];
  function run_plugins(plugins, ui, name, stack, scope) {
    for (var i = 0; i < plugins.length; i++)
      if (plugins[i](ui, name, stack, scope) === false) return false;
    return true;
  }

  function _createStore(initState, reducer) {
    var _debug = app.debug;
    var $state = initState || {};
    if (initState._name) app.states[initState._name] = $state;
    var _reducer = reducer || {};
    var _event = PubSub;

    function _getState() {
      return $state;
    }

    function _dispatch(action, callback, notPublish) {
      var _action_type = action.type;
      //	  console.log(_action_type);
      var _action_type_internal = _action_type
        .split(":")
        .slice(0, 2)
        .join(":");
      //	  console.log(_action_type_internal);
      var reducer = _reducer[_action_type_internal];
      if (reducer) {
        reducer($state, action, _event, function(_state, res) {
          if (_state) $state = _state;
          if (!notPublish) _event.publish(action.type, _state);
          if (callback) callback(_state, res);
        });
      }
    }
    function _registerReducer(type, handler) {
      _reducer[type] = handler;
    }
    function _initState(_initState) {
      $state = _initState;
    }
    function _updateState(_state, callback) {
      Object.assign($state, _state);
      callback && callback($state);
    }

    return {
      getState: _getState,
      initState: _initState,
      updateState: _updateState,
      registerReducer: _registerReducer,
      subscribe: _event.subscribe,
      unsubscribe: _event.unsubscribe,
      publish: _event.publish,
      dispatch: _dispatch
    };
  }
  var _noop = function() {};
  var app = {
    states: {},
    createStore: _createStore,
    create: function(config) {
      //init config
      app.config = webix.extend(
        {
          name: "App",
          version: "1.0",
          container: document.body,
          start: "/"
        },
        config,
        true
      );
      if (config.debug) app.log = console.log;
      else app.log = _noop;
      //init self
      app.debug = config.debug;
      app.$layout = {
        sub: subui,
        root: app.config.container,
        index: 0,
        add: true
      };
      viewdir = app.config.viewdir || "views";
      webix.extend(app, webix.EventSystem);
      webix.attachEvent("onClick", function(e) {
        if (e) {
          var target = e.target || e.srcElement;
          if (target && target.getAttribute) {
            var trigger = target.getAttribute("trigger");
            if (trigger) app.trigger(trigger);
          }
        }
      });

      //show start page
      setTimeout(function() {
        app.start();
      }, 1);

      var title = document.getElementsByTagName("title")[0];
      if (title) title.innerHTML = app.config.name;

      return app;
    },

    ui: create_temp_ui,
    _params: function() {
      var _arr = parse_parts(location.hash);
      _arr.splice(0, 1);
      return _arr;
    },
    params: function() {
      var _arr = parse_parts(location.hash);
      _arr.splice(0, 1);
      return _arr.reduce(function(_o, _i) {
        _o[_i.page] = _i.params;
        return _o;
      }, {});
    },

    //navigation
    router: function(name) {
      var parts = parse_parts(name);

      //app.path = [].concat(parts);
      app.path = [].concat(parts);
      webix.ui.$freeze = true;
      //	console.log([].concat(parts));
      render_stack(app.$layout, [].concat(parts));
    },
    show: function(name, options) {
      // if (window.location.hash != "#!" + name)
      routie.navigate("!" + name, options);
      // 	  else
      //	      app.router(name);
    },
    start: function(name) {
      //init routing
      routie("!*", app.router);

      if (!window.location.hash) app.show(app.config.start);
      else {
        webix.ui.$freeze = false;
        webix.ui.resize();
      }
    },

    //plugins
    use: function(handler, config) {
      if (handler.$oninit) handler.$oninit(this, config || {});

      if (handler.$onurlchange) url_plugins.push(handler.$onurlchange);
      if (handler.$onurl) require_plugins.push(handler.$onurl);
      if (handler.$onui) ui_plugins.push(handler.$onui);
    },

    //event helpers
    trigger: function(name) {
      app.apply(name, [].splice.call(arguments, 1));
    },
    apply: function(name, data) {
      app.callEvent(name, data);
    },
    action: function(name) {
      return function() {
        app.apply(name, arguments);
      };
    },
    on: function(name, handler) {
      this.attachEvent(name, handler);
    },

    _uis: [],
    _handlers: []
  };

  function create_temp_event(obj, name, code) {
    var id = obj.attachEvent(name, code);
    this._handlers.push({ obj: obj, id: id });
    return id;
  }

  function run_handlers(arr, view, scope) {
    if (arr) for (var i = 0; i < arr.length; i++) arr[i](view, scope);
  }

  function destroy() {
    if (!this._ui) return;

    if (this.$layout) destroy.call(this.$layout);

    var handlers = this._handlers;
    for (var i = handlers.length - 1; i >= 0; i--)
      handlers[i].obj.detachEvent(handlers[i].id);
    this._handlers = [];

    var uis = this._uis;
    for (var i = uis.length - 1; i >= 0; i--)
      if (uis[i] && uis[i].destructor) uis[i].destructor();
    this._uis = [];

    run_handlers(this._destroy, this._ui, this);

    if (!this.parent && this._ui) this._ui.destructor();
  }

  function delete_ids(view) {
    delete webix.ui.views[view.config.id];
    view.config.id = "";
    var childs = view.getChildViews();
    for (var i = childs.length - 1; i >= 0; i--) delete_ids(childs[i]);
  }

  function create_temp_ui(module, container) {
    var view;
    var temp = { _init: [], _destroy: [], _windows: [], _events: [] };
    var ui = copy(module, null, temp);
    ui.$scope = this;

    if (ui.id) view = $$(ui.id);

    if (!view) {
      //create linked windows
      for (var i = 0; i < temp._windows.length; i++) this.ui(temp._windows[i]);

      view = webix.ui(ui, container);
      this._uis.push(view);

      for (var i = 0; i < temp._events.length; i += 2)
        this.on(app, temp._events[i], temp._events[i + 1]);

      run_handlers(temp._init, view, this);
    }

    return view;
  }

  function create(subview) {
    this._uis = [];
    this._handlers = [];

    //naive solution for id dupplication
    if (this.root && this.root.config) delete_ids(this.root);

    //create linked windows
    for (var i = 0; i < this._windows.length; i++) this.ui(this._windows[i]);

    if (this.root && subview) {
      this._ui = webix.ui(subview, this.root);
      if (this.parent) this.root = this._ui;
    }
    for (var i = 0; i < this._events.length; i += 2)
      this.on(app, this._events[i], this._events[i + 1]);

    run_handlers(this._init, this._ui, this);
  }

  function invalid_url(err) {
    if (!err.requireModules) throw err;
    if (app.debug)
      webix.message({
        type: "error",
        expire: 5000,
        text: "Can't load " + err.requireModules.join(", ")
      });
    app.show(app.config.start);
  }

  //  requirejs.onError = invalid_url;
  return app;
});
