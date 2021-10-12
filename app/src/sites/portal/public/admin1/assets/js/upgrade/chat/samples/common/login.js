function login(url) {
	return new Promise(function(res) {
		var token = sessionStorage.getItem("login-token");
		if (token) {
			res(token);
			return;
		}

		function doLogin() {
			webix.ajax(url + "login?id=" + this.config.user).then(raw => {
				win.close();

				var token = raw.text();
				sessionStorage.setItem("login-token", token);
				res(token);
			});
		}

		var win = webix.ui({
			modal: true,
			view: "window",
			position: "center",
			head: "Select user",
			body: {
				view: "form",
				rows: [
					{ view: "button", value: "Alex Brown", user: 1, click: doLogin },
					{ view: "button", value: "Sinister Alpha", user: 2, click: doLogin },
					{ view: "button", value: "Alan Raichu", user: 3, click: doLogin },
				],
			},
		});
		win.show();
	});
}
