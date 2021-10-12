define(function () {
     var type = "domain";
  return {
    $ui: {
      view: "form",
      id: type + "metaView",
      elementsConfig: {
        labelWidth: 130,
      },
      elements: [
        {
          view: "text",
          placeholder: "Type here...",
          name: "meta_title",
          label: "Title",
        },
        {
          view: "textarea",
          placeholder: "Type here...",
          label: "Meta Keywords",
          gravity: 1,
          minHeight: 80,
        },
        {
          view: "textarea",
          placeholder: "Type here...",
          label: "Meta Description",
          gravity: 1.5,
          minHeight: 80,
        },
        {},
      ],
    },
  };
});
