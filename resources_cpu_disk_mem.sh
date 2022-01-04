#! /usr/bin/env bash


DISK_THRESHOLD=30
CPU_THRESHOLD_WARN=20
CPU_THRESHOD_CRITICAL=40
MEM_CRITICAL=40
MEM_WARNING=20
HOST=$(hostname)
NOW=$(date +"%m-%d-%Y %H:%M:%S")
MAIL_ID=njdevops321@gmail.com

# DISK MONITOR
# ============

# If there are lot of filesystems in our Linux server and if anyone of the filesystem usages reaches an threshold lets say 50% we want to send automatic email alerts.

rm disk_monitor.txt 1>/dev/null 2>/dev/null
touch disk_monitor.txt


df -Ph | grep -vE 'tmpfs|Filesystem|devtmps|loop*' | while read line
do
        partition=$(echo $line | awk '{print $1}')
        usage=$(echo $line | awk '{print $5}' | sed 's/%//g' )
        mount=$(echo $line | grep -vE 'tmpfs|Filesystem|devtmps|loop*' |  awk '{print $6}')
        inode=$(df -i | grep -vE 'tmpfs|Filesystem|devtmps|loop*' | grep $partition |  awk '{print $5}' | tr -d "%")

        if [[ $usage -gt $DISK_THRESHOLD ]]
        then
           echo -e "DISK SPACE LIMIT EXCEEDED THRESHOLD LIMIT!!!!" >> disk_monitor.txt
           echo -e "********************************************* ">> disk_monitor.txt
           echo -e "\n" >> disk_monitor.txt
           echo -e "==========================================================================================================" >> disk_monitor.txt
           echo -e "==========================================================================================================" >> disk_monitor.txt
           echo -e "\n" >> disk_monitor.txt
           echo -e "The partition "$partition" with Mount Point $mount  on "$HOST" has utilized "$usage%" on "$NOW" " >> disk_monitor.txt
           echo -e "\n" >> disk_monitor.txt
           echo -e "=======================TROUBLESHOOTING TIPS============================" >> disk_monitor.txt
           echo -e "\n" >> disk_monitor.txt
           echo -e "1.PLEASE LOGIN TO SERVER AND TORUBLESHOOT WHICH DIRECORY IS OCCUPYING MORE SPACE BY USING du -sch * | sort -nr | head" >>  disk_monitor.txt
           echo -e "2.CHECK INODE USAGE : df -i" >> disk_monitor.txt
           echo -e "3. Under certain circumstances, the system does not report space used by deleted files as free. To Check : lsof | grep -E '^COM|deleted' " >> disk_monitor.txt
           echo -e "4.If logs files occupy more space then , compress old logs" >> disk_monitor.txt
           echo -e "\n" >> disk_monitor.txt
           echo -e "==========================================================================================================" >> disk_monitor.txt
           echo -e "==========================================================================================================" >> disk_monitor.txt

         fi

        content=$(cat disk_monitor.txt | wc -l)

        if [[ $content -gt 0 ]]
        then
                cat disk_monitor.txt | mail -s "DISK UTILIZATION ($partition) HIGH ON $HOST !!! USAGE : $usage % " -A  disk_monitor.txt  $MAIL_ID &> /dev/null
        fi

done


# CPU UTILIZATION
# ===============

check_files()
{
if [ -e high_cpu.txt ]
  then
    rm -rf high_cpu.txt &> /dev/null
    touch high_cpu.txt &> /dev/null
  else
    touch high_cpu.txt &> /dev/null
fi
if [ -e long-running-processes.txt ]
  then
     rm -rf long-running-processes.txt &> /dev/null
     touch long-running-processes.txt &> /dev/null
  else
     touch long-running-processes.txt &> /dev/null
fi
}

high_cpu()
{
check_files
echo "+----------------------------------------------------------------------------------------------------+" >> high_cpu.txt
echo "                        Top 10 Processes which consuming high CPU                                      " >> high_cpu.txt
echo "+----------------------------------------------------------------------------------------------------+" >> high_cpu.txt
ps -eo pid,user,ppid,%mem,%cpu,command --sort=-%cpu | head >> high_cpu.txt
}

long_running_procs()
{
check_files
echo -e "\n" >> high_cpu.txt
echo "+--------------------------------------------------+" >> high_cpu.txt
echo "              LONG RUNNING PROCESSES                " >> high_cpu.txt
echo "+---------------------------------------------------+" >> high_cpu.txt
echo "--------------------------------------------------" >> high_cpu.txt
echo "USER  PID  CMD   %CPU     Process_Running_Time" >> high_cpu.txt
echo "--------------------------------------------------" >> high_cpu.txt
ps -eo pid,user,ppid,%mem,%cpu,cmd --sort=-%cpu | head | sed '1d' | awk '{print $1}' > long-running-processes.txt
for userid in $(cat long-running-processes.txt)
do
    username=$(ps -u -p $userid | tail -1 | awk '{print $1}')
    pruntime=$(ps -p $userid -o etime | tail -1 | sort | sed -e 's/^[ \t]*//')
    ocmd=$(ps -p $userid | tail -1 | awk '{print $4}')
        pcpu=$(top -b -n 2 -d 0.2 -p $userid | tail -1 | awk '{print $9}')
    echo "$username $userid $ocmd $pruntime $pcpu " >> high_cpu.txt
done | column -t
}

cpu_util()
{
CPU_IDLE=$(top -b -n 2 -d1 | grep "Cpu(s)" | tail -n 1 |  awk -F , '{print $4}' | tr -d '%id,' | awk -F. '{print $1}')
CPU_USE=$((100-$CPU_IDLE))

#CPU=$(top -b -n 2 -d 0.5 |  grep -i '^%Cpu' | tail -n 1 | awk '{print $2+$4+$6}' | awk -F. '{print $1}')

if [[ $CPU_USE -gt $CPU_THRESHOLD_WARN ]] && [[ $CPU_USE -lt $CPU_THRESHOD_CRITICAL ]]
then
    check_files
        echo -e "WARNING: CPU load is $CPU_USE % on $(hostname) at $NOW" >> high_cpu.txt
    cat high_cpu.txt | mail -s "WARNING : CPU LOAD HIGH ON $HOST !!! USAGE : $CPU_USE % " -A  high_cpu.txt  $MAIL_ID &> /dev/null

elif [[ $CPU_USE -gt $CPU_THRESHOD_CRITICAL ]]
then
    check_files
        echo -e "CRITICAL: CPU load is $CPU_USE % on $(hostname) at $NOW" >> high_cpu.txt
        high_cpu
        long_running_procs
        cat high_cpu.txt | mail -s "CRITICAL : CPU LOAD HIGH ON $HOST !!! USAGE : $CPU_USE % " -A  high_cpu.txt  $MAIL_ID &> /dev/null

else
        echo -e "NORMAL: CPU load is $CPU_USE % on $(hostname) at $NOW !!! USAGE : $CPU_USE % " >> cpu_normal.txt
fi

}

cpu_util

# MEMORY MONITOR


rm mem_monitor.txt 1>/dev/null 2>/dev/null
touch mem_monitor.txt 1>/dev/null 2>/dev/null

MEM_TOTAL=$(free -mth | grep "Total:" | awk '{print $2}' | tr -d '[Mi]')
MEM_USED=$(free -mth | grep "Total:" | awk '{print $3}' | tr -d '[Mi]')
MEM_PERCENTAGE=$(free -mth | grep "Total:" | awk '{print $3/$2*100}' | awk -F . '{print $1}')
MEM_FREE=$(free -mth | grep "Total:" | awk '{print $4}' | tr -d '[Mi]')


if [[ $MEM_PERCENTAGE -gt $MEM_WARNING ]] && [[ $MEM_PERCENTAGE -lt $MEM_CRITICAL]]
then
echo -e "WARNING: Memory Utilization is High on $HOST at $NOW \n\n Free Memory : $MEM_PERCENTAGE% \n" >> mem_monitor.txt
echo -e "TOTAL : $MEM_TOTAL mb    FREE : $MEM_FREE mb    USED : $MEM_USED mb  " >> mem_monitor.txt
echo -e "-----------------------------------------------------------------------------------------------------" >> mem_monitor.txt
echo -e  "##########################Top processes consuming system memory : ##############################  " >> mem_monitor.txt
echo -e "-----------------------------------------------------------------------------------------------------" >> mem_monitor.txt
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head  >> mem_monitor.txt
cat mem_monitor.txt | mail -s "WARNING : Memory Utilization High on $HOST !!! USAGE : $MEM_PERCENTAGE % " -A  mem_monitor.txt  $MAIL_ID &> /dev/null

elif [[ $MEM_PERCENTAGE -gt $MEM_CRITICAL ]]
then
echo -e "CRITICAL: Memory Utilization is High on $HOST at $NOW \n\n Free Memory : $MEM_PERCENTAGE% \n" >> mem_monitor.txt
echo -e "TOTAL : $MEM_TOTAL mb   FREE : $MEM_FREE mb   USED : $MEM_USED mb " >> mem_monitor.txt
echo -e "-----------------------------------------------------------------------------------------------------" >> mem_monitor.txt
echo -e  "##########################Top processes consuming system memory : ##############################  " >> mem_monitor.txt
echo -e "-----------------------------------------------------------------------------------------------------" >> mem_monitor.txt
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head >> mem_monitor.txt >> mem_monitor.txt
cat mem_monitor.txt | mail -s "CRITICAL : Memory Utilization High on $HOST !!! USAGE : $MEM_PERCENTAGE % " -A  mem_monitor.txt  $MAIL_ID &> /dev/null

else
        echo -e "NORMAL: Memory Utilization is  $MEM_PERCENTAGE%  on $HOST at $NOW !!! FREE : $MEM_FREE mb % " >> cpu_normal.txt
fi