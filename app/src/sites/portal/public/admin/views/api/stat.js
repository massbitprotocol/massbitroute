define(["views/api/config"], function ($api_config) {
  var type = "api";
  var _blockchain_option = $api_config.blockchains;
  var dataset = [
    { id: 1, sales: 20, year: "02" },
    { id: 2, sales: 55, year: "03" },
    { id: 3, sales: 40, year: "04" },
    { id: 4, sales: 78, year: "05" },
    { id: 5, sales: 61, year: "06" },
    { id: 6, sales: 35, year: "07" },
    { id: 7, sales: 80, year: "08" },
    { id: 8, sales: 50, year: "09" },
    { id: 9, sales: 65, year: "10" },
    { id: 10, sales: 59, year: "11" },
  ];

  var month_dataset = [
    { sales: "20", month: "eth_getBlockByNumber", color: "#ee3639" },
  ];

  var _time = [
    { id: "10m", value: "10 Minutes" },
    { id: "30m", value: "30 Minutes" },
    { id: "1h", value: "1 Hour" },
    { id: "3h", value: "3 Hour" },
    { id: "6h", value: "6 Hour" },
    { id: "12h", value: "12 Hour" },
    { id: "1d", value: "1 Day" },
    { id: "1w", value: "1 Week" },
    { id: "2w", value: "2 Weeks" },
    { id: "1mon", value: "1 Month" },
  ];
  var form = {
    view: "form",
    id: type + "statView",
    elementsConfig: {
      labelWidth: 130,
    },
    scroll: true,
    elements: [
      {
        cols: [
          { template: "Total Number of Method Calls", type: "header" },
          // { view: "select", width: 150, options: _blockchain_option },
          { view: "select", width: 150, options: _time },
        ],
      },
      {
        view: "chart",
        //        width: 600,
        height: 250,
        id: "chart",
        type: "line",
        value: "#sales#",
        preset: "plot", // "diamond", "round", "point", and "simple" style presets are also available
        xAxis: {
          template: "'#year#",
        },
        yAxis: {
          start: 0,
          end: 100,
          step: 10,
          template: function (obj) {
            return obj % 20 ? "" : obj;
          },
        },
        data: dataset,
      },
      {
        cols: [
          { template: "TOP 10 Method Calls", type: "header" },
          // { view: "select", width: 150, options: _blockchain_option },
          { view: "select", width: 150, options: _time },
        ],
      },

      {
        view: "chart",
        type: "pie",
        value: "#sales#",
        color: "#color#",
        legend: "#month#",
        pieInnerText: "#sales#",
        height: 250,
        shadow: 0,
        data: month_dataset,
      },
      {},
    ],
  };

  return {
    $ui: form,
  };
});
