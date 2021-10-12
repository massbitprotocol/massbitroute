const Datastore = require("nedb");

const db = new Datastore();
db.insert(require("./data/records.json"));

module.exports = function(app, root){
    app.get(root + "/data/dyn", (req, res, next)=>{
        db.find({
            start_date:{$lt:req.query.to+" 24:00"},
            end_date:{$gte:req.query.from}
        }).sort({ order: 1 }).exec((err, data) => {
            if (err)
                next(err);
            else
                res.send(data);
        });
    });
};