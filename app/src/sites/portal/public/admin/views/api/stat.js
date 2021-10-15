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

  var _refresh_opt = [
    { id: "off", value: "Off" },
    { id: "10s", value: "10s" },
    { id: "30s", value: "30s" },
    { id: "1m", value: "1m" },
    { id: "5m", value: "5m" },
    { id: "15m", value: "15m" },
    { id: "30m", value: "30m" },
    { id: "1h", value: "1h" },
    { id: "2h", value: "2h" },
    { id: "1d", value: "1d" },
  ];
  var _time_opt = [
    { id: "now|now-5m", value: "Last 5 Minutes" },
    { id: "now|now-15m", value: "Last 15 Minutes" },
    { id: "now|now-30m", value: "Last 30 Minutes" },
    { id: "now|now-1h", value: "Last 1 Hour" },
    { id: "now|now-3h", value: "Last 3 Hour" },
    { id: "now|now-6h", value: "Last 6 Hour" },
    { id: "now|now-12h", value: "Last 12 Hour" },
    { id: "now|now-24h", value: "Last 24 Hours" },
    { id: "now|now-2d", value: "Last 2 Days" },
    { id: "now|now-7d", value: "Last 7 Days" },
    { id: "now|now-30d", value: "Last 30 Days" },
    { id: "now|now-90d", value: "Last 90 Days" },
    { id: "now|now-6M", value: "Last 6 Months" },
    { id: "now|now-1y", value: "Last 1 Year" },
    { id: "now|now-2y", value: "Last 2 Year" },
    { id: "now|now-5y", value: "Last 5 Year" },
    { id: "now-1d/d|now-1d/d", value: "Yesterday" },
    { id: "now-2d/d|now-2d/d", value: "Day Before Yesterday" },
    { id: "now-7d/d|now-7d/d", value: "This Day Last Week" },
    { id: "now-1w/w|now-1w/w", value: "Previous Week" },
    { id: "now-1M/M|now-1M/M", value: "Previous Month" },
    { id: "now-1y/y|now-1y/y", value: "Previous Year" },
    { id: "now/d|now/d", value: "Today" },
    { id: "now|now/d", value: "Today so far" },
    { id: "now/w|now/w", value: "This Week" },
    { id: "now|now/w", value: "This Week so far" },
    { id: "now/M|now/M", value: "This Month" },
    { id: "now|now/M", value: "This Month so far" },
    { id: "now/y|now/y", value: "This Year" },
    { id: "now|now/y", value: "This Year so far" },
    { id: "custom", value: "Custom Period" },
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
  var _domain = "vt5hkxebciln.sol-mainnet.massbitroute.com";
  var form = {
    view: "form",
    id: type + "statView",
    elementsConfig: {
      labelWidth: 130,
    },
    scroll: true,
    elements: [
      { cols: [{}, { view: "select", width: 150, options: _time_opt }] },
      {
        view: "iframe",
        id: type + "stat_total_request",
        height: 300,
        src: "https://stats.massbitroute.com/__internal_grafana/d-solo/51eatqDMn/api?orgId=1&var-Instance=All&var-Host=All&panelId=1",
      },
      {
        view: "iframe",
        id: type + "stat_total_bandwidth",
        height: 300,
        src: "https://stats.massbitroute.com/__internal_grafana/d-solo/51eatqDMn/api?orgId=1&var-Instance=All&var-Host=All&panelId=2",
      },
      {
        view: "iframe",
        id: type + "stat_time_response",
        height: 300,
        src: "https://stats.massbitroute.com/__internal_grafana/d-solo/51eatqDMn/api?orgId=1&var-Instance=All&var-Host=All&panelId=8",
      },
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
