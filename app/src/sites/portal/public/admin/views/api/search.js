define(["models/api"], function ($api_api) {
  var type = "api";
  function getLocation(href) {
    var match = href.match(
      /^(https?\:)\/\/(([^:\/?#]*)(?:\:([0-9]+))?)([\/]{0,1}[^?#]*)(\?[^#]*|)(#.*|)$/
    );
    return (
      match && {
        href: href,
        protocol: match[1],
        host: match[2],
        hostname: match[3],
        port: match[4],
        pathname: match[5],
        search: match[6],
        hash: match[7],
      }
    );
  }

  return {
    $oninit: function (_view, _scope) {
      $api_api.list({}, function (_values) {
        _values = _values.map(function (_v) {
          if (_v.entrypoints && typeof _v.entrypoints === "string")
            _v.entrypoints = JSON.parse(_v.entrypoints);
          return _v;
        });
        console.log(_values);
        $$(type + "list").parse(_values);
      });
    },
    $ui: {
      rows: [
        {
          view: "form",

          paddingX: 5,
          paddingY: 5,
          margin: 2,
          rows: [
            { view: "label", label: "Find API:" },
            { view: "search", placeholder: "Type here..." },
          ],
        },
        {
          view: "list",
          id: type + "list",
          select: true,
          template: "<div class='marker status#status#'></div>#name#",
          on: {
            onAfterSelect: function (_id) {
              console.log(_id);
              var _items = this.getSelectedItem(_id);
              console.log(_items);
              var _item = _items[0];

              if (_item.gateway_http) {
                var _loc = getLocation(_item.gateway_http);
                var _chart_url_total_request =
                  "https://stats.massbitroute.com/__internal_grafana/d-solo/51eatqDMn/api?orgId=1&var-Instance=All&var-Host=" +
                  _loc.hostname +
                  "&panelId=1";
                var _chart_url_total_bandwidth =
                  "https://stats.massbitroute.com/__internal_grafana/d-solo/51eatqDMn/api?orgId=1&var-Instance=All&var-Host=" +
                  _loc.hostname +
                  "&panelId=2";
                var _chart_url_time_response =
                  "https://stats.massbitroute.com/__internal_grafana/d-solo/51eatqDMn/api?orgId=1&var-Instance=All&var-Host=" +
                  _loc.hostname +
                  "&panelId=8";

                var _ui = $$(type + "stat_total_request");
                if (_ui) _ui.define("src", _chart_url_total_request);
                var _ui = $$(type + "stat_total_bandwidth");
                if (_ui) _ui.define("src", _chart_url_total_bandwidth);
                var _ui = $$(type + "stat_time_response");
                if (_ui) _ui.define("src", _chart_url_time_response);
              }
              $$(type + "productsData").clearAll();
              if (_item.entrypoints) {
                $$(type + "productsData").parse(_item.entrypoints);
              }
            },
          },
        },
      ],
    },
  };
});
