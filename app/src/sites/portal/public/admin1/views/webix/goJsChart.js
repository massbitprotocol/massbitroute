webix.protoUI(
  {
    name: "goJsChart",
    $init: function(config) {
      this.$view.innerHTML =
        "<div style='position:relative; width:100%; height:100%; overflow:scroll'></div>";
      this._initChart(config);
    },

    _initChart: function(config) {
      var chart = config.chartConfig;
      this.$ = go.GraphObject.make;
      this.myDiagram = this.$(go.Diagram, this.$view.firstChild, {
        initialContentAlignment: go.Spot.Center
      });

      this.myDiagram.nodeTemplate = this.$(
        go.Node,
        "Auto",
        this.$(
          go.Shape,
          "RoundedRectangle",
          { strokeWidth: 0 },
          new go.Binding("fill", "color")
        ),
        this.$(go.TextBlock, { margin: 8 }, new go.Binding("text", "key"))
      );
    },
    model_setter: function(value) {
      this.myDiagram.model = new go.GraphLinksModel(value.data, value.links);
    }
  },
  webix.ui.view
);

// {
//   view: "goJsChart",
//   height: 300,
//   model: { data: data, links: links }
// },
