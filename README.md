# aws_stop_vm_night

################################## What this script do ##############################

This script shutdown EC2 VM the night and the weekend for DEV env for save money

################################## prerequisite ##############################
This Powershell script need aws cli install on your system.
And configure with aws configure commande
give the name of your AWS profile in the script in the var $AWS_PROFILE

################################## Context ##############################
On my aws network i use TAG for EC2 : ( ENV=PROD or ENV=DEV pr ENV=POC ) 
I use this script for save money. So i stop the VMs the night and weekend.
I use this in a cron and i start this script every hour.
The script will start or stop the VMs. except some vm with the good tag

You can add more tag for better controle on your EC2 like (autostop=no) or (autostart=no)
Don't shutdown VM with tag autostop=no
Don't stat VM with tag autostart=no ( for VM use 1 per month for exemple )
This script don't stop VM with tag ENV=PROD 

