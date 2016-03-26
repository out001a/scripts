#!/usr/bin/env bash

ALERT_PROGRAM=./alert/alarm_caller
ALERT_INTERVAL=3600     #报警的时间间隔（秒）

#THIS_IP=192.168.1.147   #本机IP
THIS_IP=($(/sbin/ifconfig  | grep 'inet addr:' | grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}'))

#cd /usr/local/bas/monitor
cd "$(dirname "$0")"

#export `cat ./conf/process | awk '/^\s*[^;]/{print $1"="$2}'`
export `cat ./conf/process | awk 'BEGIN{m_names="";m_detail=""}/^\s*[^;]/{print "m_"$1"="$2;m_names=m_names":"$1;m_detail=m_detail":"$3}END{print "m_names="substr(m_names,2);print "m_detail="substr(m_detail,2)}'`

IFS=:
m_detail=($m_detail)

i=0
for pname in $m_names
do
    now=`date +%s`  #当前时间的时间戳

    pfile=./point/$pname
    eval interval=\$m_$pname

    first_time=0    #该进程是否被第一次监控
    if [ ! -e $pfile ]
    then
        first_time=1
        echo "$now:0:0" > $pfile  #第一次时先更新检查点
    fi

    a_ps=(`cat $pfile`)
    point=${a_ps[0]}    #最新的检查点
    state=${a_ps[1]}    #上次的进程状态（0表示上次检查时没有发现该进程）
    atime=${a_ps[2]}    #上次报警的时间

    detail=${m_detail[$i]}
    if [ "$detail" == "" ]
    then
        detail=$pname
    fi

    #pid=(`ps axo pid,cmd | grep $detail | grep -v grep | awk '{print $1}' | xargs`)
    #echo "ps axo pid,cmd | grep $detail | grep -v grep | wc -l"
    num=`ps axo pid,cmd | grep $detail | grep -v grep | wc -l`

    alert_msg=""
    if [ $num -ge 1 ]
    then
        if [ $state -lt 1 ] && [ $first_time -eq 0 ]
        then
            alert_msg="[server报警！]$THIS_IP上$pname进程已恢复，报警取消。"
        fi
        echo "$now:$num:0" > $pfile  #进程存在时更新检查点
    else
        need_alert=0
        if [ $interval -gt 0 ]
        then
            if [ `echo $now-$point|bc` -ge $interval ]
            then
                need_alert=1
            fi
        else
            need_alert=1
        fi

        if [ $need_alert -eq 1 ] && [ `echo $now-$atime|bc` -ge $ALERT_INTERVAL ]
        then
            alert_msg="[server报警！]$THIS_IP上$pname进程没有找到，请速检查！"
            echo "$point:0:$now" > $pfile  #更新报警时间
        fi
    fi

    if [ "$alert_msg" != "" ]
    then
        #执行报警操作
        echo "$(date +"%Y-%m-%d %H:%M:%S") $alert_msg"   
        alert_msg=`echo -e "$alert_msg\n$(date +"%Y-%m-%d %H:%M:%S")"`
        $ALERT_PROGRAM "$alert_msg" "process"
    fi

    #记日志
    echo "$(date +"%H:%M:%S") $first_time $pname $num $alert_msg" >> ./log/$(date +"%Y%m%d").log

    i=$i+1
done
IFS=" "

exit 0
