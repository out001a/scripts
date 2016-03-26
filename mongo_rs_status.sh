#############################################
# @author shanhuanming <out001a@gmail.com>
#############################################

ALERT_PROGRAM=your/alarm_program/path

status=$(mongo 127.0.0.1:27017/admin --eval "
    print('---');
    db.auth('admin', 'admin');
    var s = [];
    var members = rs.status().members;
    for (i in members) {
        var m = members[i];
        s[i] = 'name=' + m.name + '|statusStr=\"' + m.stateStr + '\"|uptime=' + m.uptime  + '|health=' + m.health;
    }
    print(s);
")
status=$(echo $status | awk -F'---' '{print $2}')
status=$(echo $status) # 去掉首尾空格

status=(${status// /_})
status=(${status//,/ })

for s in ${status[@]}; do
    m=(${s//|/ })
    for v in ${m[@]}; do
        health=""
        export $v
        if [[ "$health" -ne "" ]] && [[ "$health" -ne "1" ]]; then
        #if [[ "$health" -ne "" ]]; then
            alert_msg="$name, $statusStr, $(date +"%Y-%m-%d %H:%M:%S")"
            $ALERT_PROGRAM "$alert_msg" "mongo异常"
            echo $alert_msg
        fi
    done
done