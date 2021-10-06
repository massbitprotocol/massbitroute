const Datastore = require("nedb");
const order = require("./order");

const tasks = new Datastore();
tasks.insert(require("./data/tasks-normalized.json"));

const files = new Datastore();
files.insert(require("./data/files-normalized.json"));

module.exports = function(app, root){

    app.get(root + "/tasks/normalized",(req, res, next)=>{
        tasks.find({}).sort({ order: 1 }).exec((err, docs) => {
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

    app.put(root + "/tasks/normalized/:id",(req, res, next)=>{
        if (req.body.webix_move_parent){
            return order.move(tasks, req, res, next);
        }

        // normalize data before saving
        const attachments = req.body.attachments;
        if (attachments){
            //recreate attachment records
            files.remove({ taskId :req.params.id },  { multi: true }, function(){
                attachments.map(a => {
                    files.insert({ 
                        _id : a.id, taskId : req.params.id,
                        link : a.link, size : a.size });
                });
            });
        }

        // we are storing attachments in the separate collection
        // so we need not info in the tasks collection
        delete req.body.attachments;

        tasks.update({ _id: req.params.id }, { $set : req.body }, (err) => {
            if (err)
                next(err);
            else
                res.send({})
        });
    });


    // show all attachments
    app.get(root + "/tasks/normalized/:id/attachments",(req, res, next) => {
        files.find({ taskId: req.params.id }, (err, docs) => {
            if (err)
                next(err);
            else
                res.send(docs.map(a => {
                    // client side expects "id"
                    a.id = a._id;
                    delete a._id;
                    return a;
                }));
        });
    });
};