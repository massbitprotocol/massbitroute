define(["models/auth"], function ($auth) {
  var layout = {
    type: "clean",
    gravity: 3,
    rows: [
      { height: 200 },
      {
        template: "Login",
        type: "header",
        css: "sub_title22",
        borderless: true,
        height: 50,
      },
      {
        template: "Welcome Back",
        type: "header",
        css: "sub_title22",
        borderless: true,
        height: 50,
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
            placeholder: "Your Username",
            label: "Username",
            name: "username",
          },
          {
            view: "text",
            placeholder: "Your Password",
            label: "Password",
            type: "password",
            name: "password",
          },
          {
            cols: [
              { view: "checkbox", inputAlign: "left", label: "Remember me" },
              {},
              { template: "<a>Forget my password</a>", borderless: true },
            ],
          },
          {
            view: "button",
            // autowidth: true,
            css: "button_primary button_raised",
            label: "Login",
            type: "form",
            align: "right",
            click: $auth.login,
          },
          // {
          //   margin: 10,
          //   paddingX: 2,
          //   borderless: true,
          //   cols: [
          //     // {
          //     //   view: "button",
          //     //   css: "button_danger",
          //     //   label: "Delete",
          //     //   type: "form",
          //     //   align: "left",
          //     // },
          //     {},
          //     // { view: "button", css: "", label: "Reset", align: "right" },
          //     {
          //       view: "button",
          //       // autowidth: true,
          //       css: "button_primary button_raised",
          //       label: "Login",
          //       type: "form",
          //       align: "right",
          //       click: $auth.login,
          //     },
          //   ],
          // },
        ],
      },
    ],
  };

  return {
    $ui: {
      cols: [
        { css: "login-image" },
        { cols: [{ gravity: 1 }, layout, { gravity: 1 }] },
      ],
    },
  };
});
