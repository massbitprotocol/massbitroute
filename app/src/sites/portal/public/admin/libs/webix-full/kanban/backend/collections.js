const Datastore = require("nedb");

const users = new Datastore();
users.insert(require("./data/users.json"));

const tags = new Datastore();
tags.insert(require("./data/tags.json"));

module.exports = function(app, root){
    // get all users
    app.get(root + "/users",(req, res, next) => {
        users.find({}, (err, docs) => {
            if (err)
                next(err);
            else
                res.send(docs);
        });
    });

    // get all tags
    app.get(root + "/tags",(req, res, next) => {
        tags.find({}, (err, docs) => {
            if (err)
                next(err);
            else
                res.send(docs);
        });
    });


    // show all attachments
    app.get(root + "/attachments/:id",(req, res, next) => {
        res.sendFile(__dirname + "/attachments/"+req.params.id);
    });
}