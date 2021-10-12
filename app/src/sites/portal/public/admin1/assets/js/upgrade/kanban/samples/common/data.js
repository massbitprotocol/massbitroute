var base_task_set = [
	{ id:1, status:"new", text:"Task 1", tags:"webix,docs", comments:[{text:"Comment 1"}, {text:"Comment 2"}] },
	{ id:2, status:"work", text:"Task 2", color:"#FE0E0E", tags:"webix", votes:1, personId: 4  },
	{ id:3, status:"work", text:"Task 3", tags:"webix,docs", comments:[{text:"Comment 1"}], personId: 6 },
	{ id:4, status:"test", text:"Task 4 pending", tags:"webix 2.5", votes:1, personId: 5  },
	{ id:5, status:"new", text:"Task 5", tags:"webix,docs", votes:3  },
	{ id:6, status:"new", text:"Task 6", tags:"webix,kanban", comments:[{text:"Comment 1"}, {text:"Comment 2"}], personId: 2 },
	{ id:7, status:"work", text:"Task 7", tags:"webix", votes:2, personId: 7, image: "image001.jpg"  },
	{ id:8, status:"work", text:"Task 8", tags:"webix", comments:[{text:"Comment 1"}, {text:"Comment 2"}], votes:5, personId: 4  },
	{ id:9, status:"work", text:"Task 9", tags:"webix", votes:1, personId: 2},
	{ id:10, status:"work", text:"Task 10", tags:"webix", comments:[{text:"Comment 1"}, {text:"Comment 2"}, {text:"Comment 3"}], votes:10, personId:1 },
	{ id:11, status:"work", text:"Task 11", tags:"webix 2.5", votes:3, personId: 8 },
	{ id:12, status:"done", text:"Task 12", votes:2 , personId: 8, image: "image002.jpg"},
	{ id:13, status:"ready", text:"Task 14",  personId: 8}
];


var task_set = [
	{ id:1, status:"new", text:"Task 1", tags:"webix,docs" },
	{ id:2, status:"new", text:"Task 2", tags:"webix" },
	{ id:3, status:"new", text:"Task 3", tags:"webix" },
	{ id:4, status:"new", text:"Task 4", tags:"webix" },
	{ id:5, status:"new", text:"Task 5", tags:"webix,docs" },

	{ id:6, status:"ready", text:"Task 6", tags:"webix,docs" },
	{ id:7, status:"ready", text:"Task 7", tags:"webix" },
	{ id:8, status:"ready", text:"Task 8", tags:"webix" },
	{ id:9, status:"ready", text:"Task 9", tags:"webix" },
	{ id:10, status:"ready", text:"Task 10", tags:"webix,docs" },

	{ id:11, color:"#FE0E0E", status:"work", text:"Task 11", tags:"webix,docs" },
	{ id:12, status:"work", text:"Task 12", tags:"webix" },
	{ id:13, status:"work", text:"Task 13", tags:"webix" },
	{ id:14, color:"#FE0E0E", status:"work", text:"Task 14", tags:"webix" },
	{ id:15, status:"work", text:"Task 15", tags:"webix,docs" },

	{ id:16, status:"test", text:"Task 16", tags:"webix,docs" },
	{ id:17, color:"#FE0E0E", status:"work", text:"Task 17", tags:"webix" },

	{ id:18, status:"done", text:"Task 18", tags:"webix,docs" },
	{ id:19, color:"#FE0E0E", status:"done", text:"Task 19", tags:"webix" },

	{ id:20, status:"complete", text:"Task 20", tags:"webix,docs" },
	{ id:21, color:"#FE0E0E", status:"complete", text:"Task 21", tags:"webix" },


	{ id:22, status:"ready", text:"Task 22", tags:"webix,docs" },
	{ id:23, color:"#FE0E0E", status:"ready", text:"Task 23", tags:"webix" }
];
var staff= [
	{id:1, name:"Rick Lopes"},
	{id:2, name:"Martin Farrell"},
	{id:3, name:"Douglass Moore"},
	{id:4, name:"Eric Doe"},
	{id:5, name:"Sophi Elliman"},
	{id:6, name:"Anna O'Neal"},
	{id:7, name:"Marcus Storm"},
	{id:8, name:"Nick Branson"}
];

var user_task_set =[
	{ id:1, status:"new", text:"Test new authentification service", tags:"webix", comments:[{text:"Comment 1"}, {text:"Comment 2"}] },
	{ id:2, status:"work", user: 1, text:"Performance tests", color:"#FE0E0E", tags:"webix"  },
	{ id:3, status:"work", user: 2, text:"Kanban tutorial", tags:"webix,docs", comments:[{text:"Comment 1"}] },
	{ id:4, status:"work", user: 3, text:"SpreadSheet NodeJS", tags:"webix 3.0"  },
	{ id:5, status:"test", user: 3, text:"Portlets view", tags:"webix 2.5"  }
];
var team_task_set =[
	{ id:1, status:"new", text:"Test new authentification service", user_id: 5, tags:[1], comments:[{text:"Comment 1"}, {text:"Comment 2"}] },
	{ id:2, status:"work", team: 1, text:"Kanban tutorial", user_id: 2, tags:[2] },
	{ id:3, status:"work", team: 2, text:"New skin", user_id: 9, tags:[4,2] },
	{ id:4, status:"work", team: 1, text:"SpreadSheet NodeJS" },
	{ id:5, status:"test", text:"Portlets view", user_id: 7, tags:[4,6] }
];

var full_task_set = [
	{ id:1, status:"new", text:"Test new authentification service", tags:[1,2,3] },
	{ id:2, status:"work", user_id: 5, text:"Performance tests", tags:[1] },
	{ id:3, status:"work", user_id: 6, text:"Kanban tutorial", tags:[2] },
	{ id:4, status:"work", user_id: 3, text:"SpreadSheet NodeJS", tags:[3] },
	{ id:5, status:"test", user_id: 9, text:"Portlets view", tags:[4,2] },
	{ id:6, status:"new", user_id: 7, text:"Form Builder", tags:[4,6] },
	{ id:7, status:"test", text:"Code Snippet", tags:[1,2,3] },
	{ id:8, status:"work", user_id: 1, text:"Backend integration", tags:[5] },
	{ id:9, status:"work", user_id: 2, text:"Drag-n-drop with shifting cards", tags:[5] },
	{ id:10, status:"work", user_id: 4, text:"Webix Jet 2.0", tags:[4] },
	{ id:11, status:"test", user_id: 9, text:"Chat app interface", tags:[4,2] },
	{ id:12, status:"done", user_id: 8, text:"Material skin", tags:[4,6] }
];

var task_set_with_comments = [
	{ id:1, status:"new", text:"Test new authentification service", tags:[1,2,3],
		comments:[
            {id:1, user_id:1, date:"2018-06-10 18:45", text:"Greetings, fellow colleagues. I would like to share my insights on this task. I reckon we should deal with at least half of the points in the plan without further delays. I suggest proceeding from one point to the next and notifying the rest of us with at least short notices. This way is best to keep track of who is doing what."},
            {id:2, user_id:2, date:"2018-06-12 19:40", text:"Hi, Rick. I am sure that that's exactly what is thought best out there in Dunwall. Let's just do what we are supposed to do to get the result."},
            {id:3, user_id:3, date:"2018-06-12 20:16", text:"Whoa, Martin. Rick is right, though I must admit, he is often way too serious and lacks a good healthy sense of humour.<br><br>I'd also like to add that half of the points in the plan (btw who wrote it? I would like a long thoughtful conversation in person with the guy / lady in question. Maybe over a chessboard as well) Well, most of the points can be omitted if we rationally split the subtasks between all the parties and optimize the whole line of work."}
		]
	},
	{ id:2, status:"work", user_id: 5, text:"Performance tests", tags:[1],
		comments:[
            {id:6, user_id:7, date:"2018-06-14 22:31", text:"One more question, guys. What about the latest specifications?"},
            {id:7, user_id:9, date:"2018-06-14 22:43", text:"They are ready, but not published yet."},
            {id:8, user_id:7, date:"2018-06-14 23:01", text:"Wow great, could you please share them with me?"}
		]
	},
	{ id:3, status:"work", user_id: 6, text:"Kanban tutorial", tags:[2] },
	{ id:4, status:"work", user_id: 3, text:"SpreadSheet NodeJS", tags:[3] },
	{ id:5, status:"test", user_id: 4, text:"Portlets view", tags:[4,2],
		comments:[
			{id:6, user_id:4, date:"2018-06-14 23:01", text:"No worry, I am planning to finish it up in half an hour and make them public for all. Just wait..)"}
		]
	}
];

var tags_set = [
	{id:1, value:"webix"},
	{id:2, value:"jet"},
	{id:3, value:"easy"},
	{id:4, value:"hard"},
	{id:5, value:"kanban"},
	{id:6, value:"docs"},
];

var users_set = [
	{id:1, value:"Rick Lopes", image:"../common/imgs/1.jpg"},
	{id:2, value:"Martin Farrell", image:"../common/imgs/2.jpg"},
	{id:3, value:"Douglass Moore", image:"../common/imgs/3.jpg"},
	{id:4, value:"Eric Doe", image:"../common/imgs/4.jpg"},
	{id:5, value:"Sophi Elliman", image:"../common/imgs/5.jpg"},
	{id:6, value:"Anna O'Neal"},
	{id:7, value:"Marcus Storm", image:"../common/imgs/7.jpg"},
	{id:8, value:"Nick Branson", image:"../common/imgs/8.jpg"},
	{id:9, value:"CC", image:"../common/imgs/9.jpg"}
];

var colors_set = [
    {id:1, value:"Normal", color:"green"},
    {id:2, value:"Low", color:"orange"},
	{id:3, value:"Urgent", color:"red"}
];