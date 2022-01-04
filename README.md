## Description

Its a shell script which can be used to monitor CPU , Memory , Disk Space of an Linux Server based on the threshold we pass and send email alerts when the usage is above the given threshold . This script also generates list of top  processes which takes high cpu and high memory.

Monitoring servers resources is an integral part of every organization . For this we can use Monitoring tools like nagios , zabbix etc .. but here i made use of shell script as a part of learning shell script and can be set as a cronjob so it will periodically check the usage of server resources. This script can be helpful for system engineers/devops engineers for monitoring their server resources.

----

## Feature

- The script will monitor filesystem (disk usage) , memory utilization and CPU utilization of Linux Server
- We can set threshold limit (critical & warning limits)
- If the usage goes above mentioned threshold , it will automatically send an email to administrator saying the resource usage is in CRITICAL or WARNING state.
- For CPU and Memory It gives top processes which takes more CPU and memory and send that along with mail.
  
## Pre-Requisite

---

- If you want to send mail when usage becomes high a mail agent should be installed on the server.Here we can use sendmail.

  
##  STEPS TO CONFIGURE GMAIL SETUP ON UBUNTU SERVER
---


```sh

 step1: Get Gmail Id and Password

 Step2: login into ubuntu and switch to root using: sudo su -

 Step3:  Run below commands:
 	    apt-get update -y
        apt-get install sendmail mailutils -y
 Step4: Create authentication file
       cd /etc/mail
	   mkdir -m 700 authinfo
       cd authinfo/
       vi gmail
    
    add the below conntent 

	AuthInfo: "U:root" "I:your-mail@gmail.com" "P:your-password"

        Now edit your mail id and password


Step5: create hash map of the file:

	makemap hash gmail < gmail

Step6: Got to /etc/mail and open sendmail.mc

 then Add the following lines to sendmail.mc file right above 
 
 MAILER_DEFINITIONS:
	#GMail settings:
	define(`SMART_HOST',`[smtp.gmail.com]')dnl
	define(`RELAY_MAILER_ARGS', `TCP $h 587')dnl
	define(`ESMTP_MAILER_ARGS', `TCP $h 587')dnl
	define(`confAUTH_OPTIONS', `A p')dnl
	TRUST_AUTH_MECH(`EXTERNAL DIGEST-MD5 CRAM-MD5 LOGIN PLAIN')dnl
	define(`confAUTH_MECHANISMS', `EXTERNAL GSSAPI DIGEST-MD5 CRAM-MD5 LOGIN PLAIN')dnl
	FEATURE(`authinfo',`hash -o /etc/mail/authinfo/gmail.db')dnl

```
```sh
Step7: Now run below two command from /etc/mail
	make
	/etc/init.d/sendmail reload
Step8: Now open https://www.google.com/settings/security/lesssecureapps
       and Allow less secure apps: ON
Step9: Verify the test mail using
	echo "Demo" | mail -s "Status of Httpd" dowithscripting@gmail.com
 
echo "Demo" | mail -s "Status of Httpd" dowithscripting@gmail.com -A demo.txt

```


---

## How to use this script

```sh

- git clone https://github.com/NITHIN-JOHN-GEORGE/disk_cpu_mem_monitor.git

- cd disk_cpu_mem_monitor
- chmod +x resources_cpu_disk_mem.sh

- OPEN THE SCRIPT AND CHANGE THE THRESHOLD VALUES ACCORDING TO OUR ORGANIZATION

DISK_THRESHOLD=<>
CPU_THRESHOLD_WARN=<>
CPU_THRESHOD_CRITICAL=<>
MEM_CRITICAL=<>
MEM_WARNING=<>

-Add a cronjob so it can monitor every 10 mins

# crontab -e

*/10 * * * * <complete path to this script>

```
## Script Running

![CAPTURE-1](https://user-images.githubusercontent.com/96073033/148065467-50c724d0-62ba-4202-b4ba-b60404fede08.JPG)
![CAPTURE-5](https://user-images.githubusercontent.com/96073033/148065762-b6298bb2-3aa5-48ac-ac8a-13d8eaf9903e.JPG)
![CAPTURE-3](https://user-images.githubusercontent.com/96073033/148065475-a67c9f25-98d7-4bf4-a652-1e49afa68945.JPG)
![CAPTURE-4](https://user-images.githubusercontent.com/96073033/148065478-d8163a33-3112-4340-bea1-ec7ecf7a2ab5.JPG)

