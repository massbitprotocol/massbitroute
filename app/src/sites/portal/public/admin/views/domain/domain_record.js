define([
  //"views/webix/ckeditor"
  //  "models/products",
], function () {
  var type = "domain";
  var products = [
    {
      id: 1,
      name: "www",
      type: "A",
      route: "STATIC",
      priority: 5,
      status: 1,
      value: "1.1.1.1",
    },
    {
      id: 2,
      name: "api",
      type: "A",
      route: "WEIGHTED",
      priority: 5,
      status: 0,
      value: "2.2.2.2",
    },
    {
      id: 3,
      name: "api",
      type: "A",
      route: "WEIGHTED",
      priority: 5,
      status: 0,
      value: "3.3.3.3",
    },
  ];
  var type = "domain";
  var grid = {
    id: type  + "productsData",
    view: "datatable",
    select: true,
    editable: true,
    editaction: "dblclick",
    columns: [
      { id: "id", header: "#", width: 50 },

      {
        id: "name",
        header: ["Name", { content: "textFilter" }],
        sort: "string",
        minWidth: 120,
        // fillspace: 2,
        editor: "text",
      },
      {
        id: "type",
        header: ["Type", { content: "selectFilter" }],
        sort: "string",
        minWidth: 80,
        // fillspace: 2,
        editor: "select",
        options: ["A", "CNAME"],
        // template: "<div class='category#category#'>#categoryName#</div>",
      },
      {
        id: "route",
        header: ["Route", { content: "selectFilter" }],
        sort: "string",
        minWidth: 120,
        // fillspace: 2,
        editor: "select",
        options: ["STATIC", "WEIGHTED"],
        // template: "<div class='category#category#'>#categoryName#</div>",
      },
      // {
      //   id: "price",
      //   header: ["Price"],
      //   sort: "int",
      //   minWidth: 80,
      //   fillspace: 1,
      //   format: webix.i18n.priceFormat,
      // },
      {
        id: "priority",
        header: ["Priority"],
        sort: "int",
        minWidth: 50,
        editor: "text",
        // fillspace: 1,
      },
      // {
      //   id: "statusName",
      //   header: ["Status"],
      //   minWidth: 110,
      //   sort: "string",
      //   fillspace: 1,
      //   template: "<span class='status status#status#'>#statusName#</span>",
      // },
      {
        id: "value",
        header: ["Value"],
        // header: ["Value", { content: "textFilter" }],
        sort: "string",
        minWidth: 120,
        fillspace: 1,
        editor: "text",
      },

      // {
      //   id: "edit",
      //   header: "&nbsp;",
      //   width: 50,
      //   template:
      //     "<span  style=' cursor:pointer;' class='webix_icon fa-pencil'></span>",
      // },
      {
        id: "delete",
        header: "&nbsp;",
        width: 50,
        template:
          "<span  style='cursor:pointer;' class='webix_icon fa-trash-o'></span>",
      },
      {
        id: "add",
        header: "&nbsp;",
        width: 50,
        template:
          "<span  style='cursor:pointer;' class='webix_icon fa-plus'></span>",
      },
    ],
    pager: "pagerA",
    export: true,
    data: products,
    onClick: {
      "fa-trash-o": function (e, id, node) {
        webix.confirm({
          text: "The product will be deleted. <br/> Are you sure?",
          ok: "Yes",
          cancel: "Cancel",
          callback: function (res) {
            if (res) {
              var item = webix.$$("productsData").getItem(id);
              item.status = "0";
              item.statusName = "Deleted";
              webix.$$("productsData").refresh(id);
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
    id: type + "recordView",
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
            label: "Export To Excel",
            click: function () {
              $$("productsData").exportToExcel();
            },
          },
          {
            view: "button",
            css: "button_primary button_raised",
            type: "iconButton",
            icon: "refresh",
            width: 130,
            label: "Refresh",
            click: function () {
              var grid = $$("productsData");
              grid.clearAll();
              grid.showProgress();
              webix.delay(
                function () {
                  grid.parse(products.getAll);
                  grid.hideProgress();
                },
                null,
                null,
                300
              );
            },
          },
          {},
          {
            view: "richselect",
            id: "order_filter",
            value: "all",
            maxWidth: 300,
            minWidth: 250,
            vertical: true,
            labelWidth: 110,
            options: [
              { id: "all", value: "All" },
              { id: "1", value: "Published" },
              { id: "2", value: "Not published" },
              { id: "0", value: "Deleted" },
            ],
            label: "Filter products",
            on: {
              onChange: function () {
                var val = this.getValue();
                if (val == "all") $$("productsData").filter("#status#", "");
                else $$("productsData").filter("#status#", val);
              },
            },
          },
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
