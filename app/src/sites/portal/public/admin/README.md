Example of Webix MVC Admin App
===============================

Live demos
----------

In Flat skin - http://webix.com/demos/admin-app/

In [Material 5.4](https://github.com/webix-hub/material-design-skin) skin - http://webix.com/demos/material/admin-app/


Technical details
------------------

### Run

- clone repo from git
- fix path to webix.js and webix.css in the index.html
- open index.html in the browser 

### Deploy

- install nodejs
- run `npm install`
- run `npm install -g gulp`
- run `gulp build`
- copy files from "deploy" folder to the server

### Other gulp commands

- `gulp clean` - remove all temporary files
- `gulp lint` - will validate all js code in the project
- `gulp source` - package sources


License
---------

All code except of dhtmlxScheduler files is available under MIT License

[dhtmlxScheduler](http://dhtmlx.com/docs/products/dhtmlxScheduler/) is available under GPL license
