const Datastore = require("nedb");

const db = new Datastore();
db.insert(require("./data/spreadsheets.json"));

module.exports = function(app, root){

    app.get(root + "/sheets/:id", (req, res, next)=>{
        db.findOne({ _id: req.params.id }, (err, data)=>{
            if (err || !data)
                res.send({ data:[] }); // sheet not found, send empty data
            else {
                res.send(data.data);
            }
        });
    });

    app.post(root + "/sheets/:id", (req, res, next)=>{
        db.update({ _id: req.params.id }, {$set: req.body }, { upsert: true }, (err) => {
            if (err)
                next(err);
            else
                res.send({})
        });
    });
};