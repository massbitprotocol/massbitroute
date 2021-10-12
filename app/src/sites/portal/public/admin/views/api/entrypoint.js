define([
  "views/api/entrypoint_new",
  "views/api/authen_infura",
  "views/api/authen_getblock",
], function (ui_entrypoint_new, ui_authen_infura, ui_authen_getblock) {
  var type = "api";
  // var products = [
  //   {
  //     id: 1,
  //     type: "INFURA",
  //     priority: 5,
  //     status: 0,
  //   },
  //   {
  //     id: 2,
  //     type: "GETBLOCK",
  //     priority: 3,
  //     status: 1,
  //   },
  // ];

  var grid = {
    id: type + "productsData",
    view: "datatable",
    select: true,
    editable: true,
    editaction: "dblclick",
    columns: [
      { id: "id", header: "#", minWidth: 150 },

      {
        id: "type",
        header: ["Type", { content: "selectFilter" }],
        sort: "string",
        minWidth: 150,
        // fillspace: 2,
        editor: "select",
        options: ["INFURA", "GETBLOCK"],
        template: "<div class='status provider#type#'>#type#</div>",
      },

      {
        id: "priority",
        header: ["Priority"],
        sort: "int",
        minWidth: 50,
        editor: "text",
      },
      {
        id: "status",
        //          header: ["Status"],
        header: ["Status", { content: "selectFilter" }],
        minWidth: 110,
        sort: "string",
        editor: "select",
        options: [
          { id: "1", value: "Enable" },
          { id: "0", value: "Disable" },
        ],
        fillspace: 1,
        template: function (_v) {
          console.log(_v);
          var _statusName = _v.status ? "Enable" : "Disable";
          return (
            "<span class='status status" +
            _v.status +
            "'>" +
            _statusName +
            "</span>"
          );
        },
      },
      {
        id: "auth",
        header: "&nbsp;",
        width: 50,
        template:
          "<span  style='cursor:pointer;' class='webix_icon fa-shield'></span>",
      },
      {
        id: "delete",
        header: "&nbsp;",
        width: 50,
        template:
          "<span  style='cursor:pointer;' class='webix_icon fa-trash-o'></span>",
      },
      // {
      //   id: "add",
      //   header: "&nbsp;",
      //   width: 50,
      //   template:
      //     "<span  style='cursor:pointer;' class='webix_icon fa-plus'></span>",
      // },
    ],
    pager: "pagerA",
    export: true,
    data: [],
    onClick: {
      "fa-shield": function (e, id, node) {
        var item = webix.$$(type + "productsData").getItem(id);
        switch (item.type) {
          case "INFURA":
            this.$scope.ui(ui_authen_infura.$ui).show();
            $$(type + "infura-form").setValues({
              infura_project_id: item.infura_project_id,
              infura_project_secret: item.infura_project_secret,
            });
            break;
          case "GETBLOCK":
            this.$scope.ui(ui_authen_getblock.$ui).show();
            $$(type + "getblock-form").setValues({
              getblock_api_key: item.getblock_api_key,
            });
            break;
        }
        webix.$$(type + "productsData").refresh(id);
      },
      "fa-trash-o": function (e, id, node) {
        webix.confirm({
          text: "The product will be deleted. <br/> Are you sure?",
          ok: "Yes",
          cancel: "Cancel",
          callback: function (res) {
            if (res) {
              webix.$$(type + "productsData").remove(id);
            }
          },
        });
      },
    },
    ready: function () {
      webix.extend(this, webix.ProgressBar);
    },
  };

  var form = {
    view: "form",
    id: type + "entrypointView",
    elementsConfig: {
      labelWidth: 130,
    },
    scroll: true,
    elements: [
      {
        css: "bg_clean",
        height: 40,
        cols: [
          {
            view: "button",
            css: "button_primary button_raised",
            type: "iconButton",
            icon: "file-excel-o",
            width: 190,
            label: "Add Entrypoint",
            click: function () {
              this.$scope.ui(ui_entrypoint_new.$ui).show();
              //              $$(type + "productsData").exportToExcel();
            },
          },
          // {
          //   view: "button",
          //   css: "button_primary button_raised",
          //   type: "iconButton",
          //   icon: "refresh",
          //   width: 130,
          //   label: "Refresh",
          //   click: function () {
          //     var grid = $$(type + "productsData");
          //     grid.clearAll();
          //     grid.showProgress();
          //     webix.delay(
          //       function () {
          //         grid.parse(products.getAll);
          //         grid.hideProgress();
          //       },
          //       null,
          //       null,
          //       300
          //     );
          //   },
          // },
          {},
          // {
          //   view: "richselect",
          //   id: "order_filter",
          //   value: "all",
          //   maxWidth: 300,
          //   minWidth: 250,
          //   vertical: true,
          //   labelWidth: 110,
          //   options: [
          //     { id: "all", value: "All" },
          //     { id: "1", value: "Published" },
          //     { id: "2", value: "Not published" },
          //     { id: "0", value: "Deleted" },
          //   ],
          //   label: "Filter products",
          //   on: {
          //     onChange: function () {
          //       var val = this.getValue();
          //       if (val == "all")
          //         $$(type + "productsData").filter("#status#", "");
          //       else $$(type + "productsData").filter("#status#", val);
          //     },
          //   },
          // },
        ],
      },
      {
        rows: [
          grid,
          {
            view: "toolbar",
            css: "highlighted_header header6",
            paddingX: 5,
            paddingY: 5,
            height: 40,
            cols: [
              {
                view: "pager",
                id: "pagerA",
                template: "{common.pages()}",
                autosize: true,
                height: 35,
                group: 5,
              },
            ],
          },
        ],
      },

      //      {},
    ],
  };

  var layout = form;

  return {
    $ui: layout,
  };
});
