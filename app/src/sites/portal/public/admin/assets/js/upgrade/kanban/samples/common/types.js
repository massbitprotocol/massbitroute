webix.type(webix.ui.kanbanlist,{
	name: "icons",
	icons:[
		{
			id: "votes",
			tooltip: "Vote up",
			icon:"mdi mdi-thumb-up-outline",
			show: function(obj){ return obj.status!=="done" },
			template:function(obj){
				return obj.votes ? obj.votes : "";
			},
			click: function(id){
				webix.message("Vote for '"+this.getItem(id).text+"'");
			}
		},
		{
			id: "votesdown",
			tooltip: "Vote down",
			icon:"mdi mdi-thumb-down-outline",
			show: function(obj){ return obj.status!=="done" },
			template:function(obj){
				return obj.votesdown ? obj.votesdown : "";
			},
			click: function(id){
				webix.message("Vote against'"+this.getItem(id).text+"'");
			}
		}
	]
});
webix.type(webix.ui.kanbanlist,{
	name: "avatars",
	templateAvatar: function(obj){
		if(obj.personId){
			var name = "";
			for(var i=0; i < staff.length && !name;i++){
				if(staff[i].id == obj.personId){
					name = staff[i].name;
				}
			}
			return '<img class="avatar" src="../common/imgs/'+obj.personId+'.jpg" title="'+name+'"/>';
		}
		return "<span class='webix_icon mdi mdi-account'></span>";
	}
});
webix.type(webix.ui.kanbanlist,{
	name: "users",
	icons:[
		{icon: "mdi mdi-comment-outline" , show: function(obj){ return !!obj.comments }, template:"#comments.length#"},
		{icon: "mdi mdi-square-edit-outline"}
	],
	templateAvatar: function(obj){
		if(obj.user){
			return '<img class="avatar" src="../common/photos/'+obj.user+'.png" title="'+name+'"/>';
		}
		return "<span class='webix_icon mdi mdi-account'></span>";
	}
});

webix.type(webix.ui.dataview,{
	name: "avatars",
	width: 80,
	height: 80,
	template: function(obj){
		var name = obj.name.split(" ");
		return '<img class="large_avatar" src="../common/imgs/'+obj.id+'.jpg" title="'+obj.name+'"/><div class="name">'+name[0]+'</div>';
	}
});
