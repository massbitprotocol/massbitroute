const Datastore = require("nedb");

const db = new Datastore();
db.insert(require("./data/pages.json"));

module.exports = function(app, root){
    let order = 1;

    app.get(root + "/pages", (req, res, next)=>{
        db.find({}).sort({ order: 1 }).exec((err, docs) => {
            if (err)
                next(err);
            else
                res.send(docs);
        });
    });

    app.put(root + "/pages/:id", (req, res, next)=>{
        const action =  { $set: req.body.name ? { name : req.body.name } : { content : req.body } };
        db.update({ name: req.params.id }, action, {}, (err) => {
            if (err)
                next(err);
            else
                res.send({});
        });
    });

    app.delete(root + "/pages/:id", (req, res, next)=>{
        db.remove({ name: req.params.id }, (err) => {
            if (err)
                next(err);
            else
                res.send({});
        });
    });

    app.post(root + "/pages/:id", (req, res, next)=>{
        db.insert({order: order, name: req.params.id, content: { data: [] }}, (err, newDoc) => {
            if (err) 
                next(err);
            else{
                order++;
                res.send({});
            }
        });
    });
};