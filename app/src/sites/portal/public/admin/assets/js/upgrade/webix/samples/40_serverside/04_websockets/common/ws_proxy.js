//all data widgets
webix.proxy.socket = {
	$proxy:true,
	load:function(view) {
		this.socket = new WebSocket("ws:"+this.source);

		this.socket.onerror = (error) => {
			console.log("WebSocket Error", error);
		};

		this.socket.onmessage = (e) => {
			var update = webix.DataDriver.json.toObject(e.data);
			if(update.key != this.key) return;

			if(update.clientId == this.clientId){
				if(update.operation == "insert")
					view.data.changeId(update.id, update.data.id);
			}
			else{
				webix.dp(view).ignore(() => {
					if (update.operation == "delete")
						view.remove(update.data.id);
					else if (update.operation == "insert")
						view.add(update.data);
					else if (update.operation == "update"){
						view.updateItem(update.data.id, update.data);
					}
				});
			}
		};

		view.attachEvent("onDestruct", () => {
			this.socket.close();
		});
	},
	save:function(view, update) {
		update.clientId = this.clientId;
		update.key = this.key;
		this.socket.send(webix.stringify(update));
	}
};

//Comments widget
webix.proxy.comments = {
	init:function(){
		webix.extend(this, webix.proxy.socket);
	},
	load:function(view){
		webix.proxy.socket.load.call(this, view.queryView("list"));
	}
};