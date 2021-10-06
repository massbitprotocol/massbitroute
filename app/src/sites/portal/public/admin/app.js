define([
  "assets/js/core",
], function (
  $core,
) {
  // webix.codebase = document.location.href.split("#")[0].replace("index.html","")+"libs/webix/";

  if (!webix.env.touch && webix.ui.scrollSize && webix.CustomScroll)
    webix.CustomScroll.init();
  //configuration
  var _app_opt = {
    id: "admin",
    name: "Massbit Decentralized API",
    version: app_version,
    debug: true,
    viewdir: app_view,
    start: "/app/dashboard",
  };
  var app = $core.create(_app_opt);
  return app;
});
