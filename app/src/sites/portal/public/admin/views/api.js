define([
  "models/api",
  "views/api/new",

  "views/api/search",
  "views/api/main",
  "views/api/stat",
  "views/api/entrypoint",
], function ($api_api, ui_new, ui_search, ui_main, ui_stat, ui_entrypoint) {
  var type = "api";

  var mainView = {};

  var controls = [
    {
      view: "button",
      css: "button_primary button_raised",
      type: "iconButton",
      icon: "plus",
      label: "Add API",
      width: 150,
      click: function () {
        this.$scope.ui(ui_new.$ui).show();
      },
    },
    {},
  ];
  var layout1 = {
    cols: [
      ui_search,
      {
        gravity: 2.2,
        type: "line",
        rows: [
          {
            rows: [
              {
                view: "tabbar",
                multiview: true,
                optionWidth: 100,
                options: [
                  { id: type + "mainView", value: "Main" },

                  { id: type + "entrypointView", value: "Entrypoints" },
                  { id: type + "statView", value: "Stat" },
                ],
              },
            ],
          },
          {
            cells: [ui_main, ui_entrypoint, ui_stat],
          },
          {
            view: "form",
            css: "highlighted_header header6",
            paddingX: 5,
            paddingY: 5,
            height: 40,

            cols: [
              {
                view: "button",
                css: "button_primary button_raised",
                type: "form",
                icon: "plus",
                label: "Save",
                width: 90,
                click: function () {
                  var _values = $$(type + "mainView").getValues();
                  var _entrypoints = $$(type + "productsData").serialize();
                  console.log(_entrypoints);
                  _values.entrypoints = _entrypoints;
                  $api_api.update(_values);
                  setTimeout(function () {
                    $api_api.list({}, function (_values) {
                      console.log(_values);
                      $$(type + "list").clearAll();
                      $$(type + "list").parse(_values);
                    });
                  }, 1000);
                },
              },
              // {
              //   view: "button",
              //   css: "button2",
              //   icon: "angle-left",
              //   label: "Reset",
              //   width: 90,
              // },

              {},
              {
                view: "button",
                css: "button_danger button0",
                icon: "times",
                label: "Delete",
                width: 90,
                click: function () {
                  webix.confirm({
                    text: "The API will be deleted. <br/> Are you sure?",
                    ok: "Yes",
                    cancel: "Cancel",
                    callback: function (res) {
                      if (res) {
                        var _values = $$(type + "mainView").getValues();
                        $api_api.delete(_values);
                        $$(type + "list").remove(_values.id);
                        $api_api.list({}, function (_values) {
                          console.log(_values);
                          $$(type + "list").clearAll();
                          $$(type + "list").parse(_values);
                        });
                      }
                    },
                  });
                },
              },
            ],
          },
        ],
      },
    ],
  };

  var layout = {
    type: "material",
    rows: [
      {
        height: 40,
        css: "bg_clean",
        cols: controls,
      },

      layout1,
    ],
  };
  return {
    $ui: layout,
    $oninit: function () {
      $$(type + "mainView").bind($$(type + "list"));
    },
  };
});
