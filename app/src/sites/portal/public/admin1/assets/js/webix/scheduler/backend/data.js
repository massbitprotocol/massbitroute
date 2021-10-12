const Datastore = require("nedb");

const db = new Datastore();
db.insert(require("./data/records.json"));

// client side expects obj.id while DB provides obj._id
function fixID(a){
    a.id = a._id;
    delete a._id;
    return a;
}

module.exports = function(app, root){
    app.get(root + "/data", (req, res, next)=>{
        db.find({}).sort({ order: 1 }).exec((err, data) => {
            if (err)
                next(err);
            else
                res.send(data.map(fixID));
        });
    });

    app.put(root + "/data/:id", (req, res, next)=>{
        db.update({ _id: req.body.id }, req.body, {}, (err, data) => {
            if (err)
                next(err);
            else
                res.send({});
        });
    });

    app.delete(root + "/data/:id", (req, res, next)=>{
        db.remove({ _id: req.body.id }, (err, data) => {
            if (err)
                next(err);
            else
                res.send({});
        });
    });

    app.post(root + "/data", (req, res, next)=>{
        db.insert(req.body, (err, data) => {
            if (err) 
                next(err);
            else
                res.send({id:fixID(data).id});
        });
    });
};