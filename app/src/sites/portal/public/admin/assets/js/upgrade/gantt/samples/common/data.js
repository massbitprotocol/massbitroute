const tasks = [];
for (let i = 1; i <= 50; i++) {
	let start_date = 1 + Math.round(i / 3);
	let end_date = start_date + 3 + Math.round(i / 10);
	tasks.push({
		id: i,
		start_date: new Date(2020, 7, start_date, 12, 0),
		end_date: new Date(2020, 7, end_date, 7, 0),
		text: "Task " + i,
		progress: Math.round((100 * i) / 50),
		parent: 0,
	});
}

tasks[3].parent = 3;
tasks[4].parent = 3;
tasks[5].parent = 3;
tasks[6].parent = 6;
tasks[7].parent = 6;
tasks[8].parent = 6;
tasks[9].parent = 9;
tasks[10].parent = 9;
tasks[11].parent = 9;

const links = [
	{ id: 1, source: 3, target: 4, type: 0 },
	{ id: 2, source: 1, target: 2, type: 2 },
	{ id: 3, source: 5, target: 6, type: 3 },
	{ id: 4, source: 8, target: 6, type: 1 },
];

const scales = [
	{ unit: "month", step: 1, format: "%M %y" },
	{ unit: "day", step: 1, format: "%d" },
];

const simpleScales = [{ unit: "day", step: 1, format: "%d" }];

const complexScales = [
	{ unit: "year", step: 1, format: "%Y" },
	{ unit: "month", step: 2, format: "%m %Y" },
	{ unit: "day", step: 1, format: "%d" },
];
