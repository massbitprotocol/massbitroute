const fs = require("fs");
const path = require("path");
const Datastore = require("nedb");
const Busboy = require('busboy');

const order = require("./order");

const db = new Datastore();
db.insert(require("./data/tasks-attachments.json"));




module.exports = function(app, root){

    app.get(root + "/tasks/attachments",(req,res, next)=>{
        db.find({}).sort({ order: 1 }).exec((err, docs) => {
            if (err)
                next(err);
            else
                res.send(docs.map(a => {
                    // client side expects "id"
                    a.id = a._id;
                    delete a._id;
                    delete a.order;
                    return a;
                }));
        });
    });

    app.put(root + "/tasks/attachments/:id",(req, res, next) => {
        if (req.body.webix_move_parent){
            return order.move(db, req, res, next);
        }

        db.update({ _id:req.params.id }, { $set:  req.body }, function(err, c){
            if (err)
                next(err);
            else
                res.send({});
        });
    });

    // upload new file
    app.post(root + "/attachments",(req, res, next) => {
        var busboy = new Busboy({ headers: req.headers });
        var saveTo = "";
        busboy.on("file", (field, file, name) => {
            saveTo = path.join(__dirname, "attachments", path.basename(name));
            file.pipe(fs.createWriteStream(saveTo));
        });
        busboy.on("finish", function() {
            if (saveTo){
                const fileName = path.basename(saveTo);
                fs.stat(saveTo, function(err, stat){
                    res.send({
                        link:"/kanban/samples/server/attachments/" + fileName,
                        size: stat.size
                    });
                });
            }
        });

        return req.pipe(busboy);
    });
};