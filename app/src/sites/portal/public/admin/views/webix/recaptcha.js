webix.protoUI(
  {
    name: "recapcha",
    $init: function() {
      this.$ready.push(function() {
        var key = this.config.sitekey;
        window.grecaptcha.render(this.$view, {
          sitekey: key
        });
      });
    },
    getValue: function() {
      return this.$view.querySelector("textarea").value;
    },
    setValue: function() {
      /*do nothing*/
    },
    focus: function() {
      /*do nothing*/
    },
    defaults: {
      name: "g-recaptcha-response",
      borderless: true,
      height: 85
    }
  },
  webix.ui.view
);
