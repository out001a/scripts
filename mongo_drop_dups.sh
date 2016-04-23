mongo 127.0.0.1/u_history --eval '
    db.auth("u_history_rw", "xxxxxx")

    var cur = db.history.aggregate(
        // pipline
        [
            {
                $group: {
                    _id: {user_id: "$user_id", album_id: "$album_id"}, // duplicate key
                    count: {$sum:1}
                }
            },
            {
                $match: {
                    count : {$gt: 1}
                }
            }
        ],
        // options
        {
            allowDiskUse: true
        }
    )

    var i = 0
    while (cur.hasNext()) {
        var doc = cur.next()
        db.history.remove(doc._id, {justOne: true})
        print(++i)
    }

    print("done")
'
