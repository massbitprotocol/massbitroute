define(["models/auth"], function ($auth) {
  var layout = {
    type: "clean",
    rows: [
      {
        view: "toolbar",
        css: "highlighted_header header1",
        paddingX: 5,
        paddingY: 5,
        height: 40,
        cols: [
          {
            template: "<span class='webix_icon fa-male'></span>Register",
            css: "sub_title2",
            borderless: true,
          },
          // {
          //   view: "button",
          //   css: "button_transparent",
          //   label: "Close",
          //   width: 80,
          // },
        ],
      },
      {
        view: "form",
        id: "userForm",
        elementsConfig: {
          labelWidth: 120,
        },
        elements: [
          {
            view: "text",
            placeholder: "Your username",
            label: "Name",
            name: "username",
          },
          {
            view: "text",
            placeholder: "Your email",
            label: "Email",
            name: "email",
          },
          {
            view: "text",
            placeholder: "Your password",
            label: "Password",
            name: "password",
            type: "password",
          },
          {
            view: "text",
            placeholder: "Your password confirm",
            label: "Password Confirm",
            name: "password1",
            type: "password",
          },
          {
            margin: 10,
            paddingX: 2,
            borderless: true,
            cols: [
              // {
              //   view: "button",
              //   css: "button_danger",
              //   label: "Delete",
              //   type: "form",
              //   align: "left",
              // },
              {},
              // { view: "button", css: "", label: "Reset", align: "right" },
              {
                view: "button",
                autowidth: true,
                css: "button_primary button_raised",
                label: "Register",
                type: "form",
                align: "right",
                click: $auth.register,
              },
            ],
          },
        ],
      },
    ],
  };

  return {
    $ui: {
      cols: [{}, layout, {}],
    },
  };
});
