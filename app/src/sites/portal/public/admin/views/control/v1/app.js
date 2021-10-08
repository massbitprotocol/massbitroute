define([], function () {
  var scope;
  var menu_data = [
    {
      id: "packge_group",
      value: "Package",
      data: [
        { id: "package.edit", value: "New Package" },
        { id: "package.list", value: "List Package" },
      ],
    },
    // {
    //   id: "billing_group",
    //   value: "Billing",
    //   data: [
    //     { id: "billing.edit", value: "New Billing" },
    //     { id: "billing.list", value: "List Billing" },
    //   ],
    // },
    {
      id: "customer_group",
      value: "Customer",
      data: [
        { id: "customer.edit", value: "New Customer" },
        { id: "customer.list", value: "List Customer" },
      ],
    },
    {
      id: "api_group",
      value: "Api",
      data: [
        { id: "api.edit", value: "New Api" },
        { id: "api.list", value: "List Api" },
      ],
    },
    {
      id: "entrypoint_group",
      value: "Entrypoint",
      data: [
        { id: "entrypoint.edit", value: "New Entrypoint" },
        { id: "entrypoint.list", value: "List Entrypoint" },
      ],
    },

    // {
    //   id: "stack_group",
    //   value: "Stack",
    //   data: [
    //     { id: "stack.edit", value: "New Stack" },
    //     { id: "stack.list", value: "List Stack" },
    //     {
    //       id: "dns_group",
    //       value: "Dns",
    //       data: [
    //         { id: "dns.edit", value: "New Dns" },
    //         { id: "dns.list", value: "List Dns" },
    //         {
    //           id: "record_group",
    //           value: "Record",
    //           data: [
    //             { id: "record.edit", value: "New Record" },
    //             { id: "record.list", value: "List Record" },
    //           ],
    //         },
    //         {
    //           id: "datacenter_group",
    //           value: "Datacenter",
    //           data: [
    //             { id: "datacenter.edit", value: "New Datacenter" },
    //             { id: "datacenter.list", value: "List Datacenter" },
    //           ],
    //         },
    //         {
    //           id: "map_group",
    //           value: "Map",
    //           data: [
    //             { id: "map.edit", value: "New Map" },
    //             { id: "map.list", value: "List Map" },
    //           ],
    //         },
    //         {
    //           id: "monitor_group",
    //           value: "Monitor",
    //           data: [
    //             { id: "monitor.edit", value: "New Monitor" },
    //             { id: "monitor.list", value: "List Monitor" },
    //           ],
    //         },
    //       ],
    //     },

    //     {
    //       id: "site_group",
    //       value: "Site",
    //       data: [
    //         { id: "site.edit", value: "New Site" },
    //         { id: "site.list", value: "List Site" },
    //       ],
    //     },
    //   ],
    // },
  ];
  var _layout = {
    rows: [
      {
        view: "toolbar",
        padding: 3,
        elements: [
          {
            view: "icon",
            icon: "mdi mdi-menu",
            click: function () {
              $$("main_sidebar").toggle();
            },
          },
          { view: "label", label: "My App" },
          {},
          // { view: "icon", icon: "mdi mdi-comment", badge: 4 },
          // { view: "icon", icon: "mdi mdi-bell", badge: 10 }
        ],
      },
      {
        cols: [
          {
            view: "sidebar",
            id: "main_sidebar",
            scroll: "y",
            data: menu_data,
            on: {
              onAfterSelect: function (id) {
                scope.show("./" + id);
                //webix.message("Selected: " + this.getItem(id).value);
              },
            },
          },
          { $subview: true },
        ],
      },
    ],
  };

  return {
    $ui: _layout,
    $oninit: function (_view, _scope) {
      scope = _scope;
    },
  };
});
