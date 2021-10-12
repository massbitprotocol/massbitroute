const Datastore = require("nedb");
const order = require("./order");

const db = new Datastore();
db.insert(require("./data/tasks-common.json"));


module.exports = function(app, root){

    app.get(root + "/tasks/common",(req,res, next)=>{
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

    app.put(root + "/tasks/common/:id",(req, res, next)=>{
        if (req.body.webix_move_parent){
            return order.move(db, req, res, next);
        }

        db.update({ _id: req.params.id }, { $set : req.body }, (err) => {
            if (err)
                next(err);
            else
                res.send({})
        });
    });

    app.post(root + "/tasks/common",(req, res, next)=>{
        db.insert(req.body, (err, newDoc) => {
            if (err) return next(err);
            // move to end of list
            order.last(db, newDoc, function(err){
                if (err) return next(err);
                res.send({ id:newDoc._id })
            });                
        });
    });

    app.delete(root + "/tasks/common/:id", (req, res, next)=>{
        db.remove({ _id: req.params.id }, (err) => {
            if (err)
                next(err);
            else
                res.send({});
        });
    });

};