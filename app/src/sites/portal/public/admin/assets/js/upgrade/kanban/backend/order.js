function last(db, item, cb){
    return moveInternal(db, "", item.status, item._id, cb);
}

function move(db, req, res, next){
    const id = req.body.webix_move_id;
    const state = req.body.webix_move_parent;
    const item = req.body.id;

    return moveInternal(db, id, state, item, function(err){
        if (err) return next(err);
        res.send({});
    });
}

function moveInternal(db, id, state, item, cb){
    // drop as last element
    if (!id){
        //select max index
        db.find({ 
            "status" : state
        }, function(err, data){
            if (err) return cb(err);
            const ind = data.length ? 
                Math.max.apply(Math, data.map(a => (a.order || 0)))+1 :
                1;
            move_stage_2(db, item, ind, cb);
        });
    } else {
        // select index of target item
        db.findOne({ "_id" : id }, function(err, data){
            if (err) return cb(err);
            move_stage_1(db, item, data.order, state, cb);
        });
    }
};

function move_stage_1(db, id, ind, state, cb){
    // update all items after moved one
    db.update({ 
        "order" : { $gte: ind },
        "status" : state
    }, { $inc: { order: 1 }}, { multi:true }, function(err, c){
        if (err) return cb(err);
        move_stage_2(db, id, ind, cb);
    });
}
function move_stage_2(db, id, ind, cb){
    // update the moved item
    db.update({ "_id" : id }, { $set: { order: ind }}, cb);
}

module.exports = { move, last };