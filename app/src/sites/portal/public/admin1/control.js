define(["assets/js/core"], function($core) {
  if (!webix.env.touch && webix.ui.scrollSize && webix.CustomScroll)
    webix.CustomScroll.init();

  //configuration
  return $core.create({
    id: app_name,
    name: app_name,
    version: app_version,
    viewdir: app_view,
    start: "/app/home"
  });
});
