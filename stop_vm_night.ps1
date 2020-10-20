################################
#### STOP VM Night  ######
################################
# create by Florian_B  - 9 / 10 / 2019

################################
######### Functions ############
################################
# View readme for information
$AWS_PROFILE="DEV"
$START_HOUR=8
$STOP_HOUR=19

#LOG location
cd "C:\Log\"
$time=Get-Date
$logs=$null

$logs+=Write-Output "STOP VM : : $time `n"


function Get_VMs 
{
    $commande=aws ec2 describe-instances --profile $AWS_PROFILE 
    $obj_describe_instance = $commande | ConvertFrom-Json
    $VMs=$obj_describe_instance[0].Reservations.Instances

    return $VMs    
}
function Get_VM_State {
    param (
        $VM 
    )
    return $VM.State.Name
}


function Get_VMs_up
{
    #Get and create VMs obj
    $commande=aws ec2 describe-instances --profile $AWS_PROFILE 
    $obj_describe_instance = $commande | ConvertFrom-Json
    $VMs=$obj_describe_instance[0].Reservations.Instances


    # If VM is up add in tab_running_VMs
    $tab_running_VMs=@()
    ForEach( $VM in $VMs)
    {
        $state=Get_VM_State($VM)
        if( $state -eq "running")
        {
            $tab_running_VMs+=($VM)
        }
    }


    return $tab_running_VMs
}


function TimeToStop {
   $datetime= Get-Date
   if ( $datetime.Hour -lt $START_HOUR -or $datetime.Hour -gt $STOP_HOUR -or ($datetime.DayOfWeek -eq "Saturday") -or ($datetime.DayOfWeek -eq "Sunday" ) )
   {
       #"stop"
       $TimeToStop=$true

   }
   else 
   {
       #"start"
       $TimeToStop=$false
   }
   #Check exception avec tag
   $auto_stop=Get_VM_AutoStop($VM)
   if ($auto_stop -eq "no")
   {
       $TimeToStop=$false
   }


    return $TimeToStop
}

function TimeToStart {
    $datetime= Get-Date
    if ( $datetime.Hour -ge $START_HOUR -or $datetime.Hour -lt $STOP_HOUR -and  ($datetime.DayOfWeek -ne "Saturday" -or $datetime.DayOfWeek -ne "Sunday") )
    {
        $TimeToStart=$true
    }
    else 
    {
        $TimeToStart=$false
    }

    #Check exception avec tag
    $auto_start=Get_VM_AutoStart($VM)
    if ($auto_start -eq "no")
    {
        $TimeToStart=$false
    }

     return  $TimeToStart
 }
 

 function start_vm ($VM) 
 {
    $commande=aws ec2 start-instances --instance-ids $VM.InstanceId --profile $AWS_PROFILE
    $obj_describe = $commande | ConvertFrom-Json
    $obj_return=$obj_describe.StartingInstances
    
    Write-Output "start :  $(Get_VM_TagName($VM))"

    return $obj_return
 }

 function stop_vm ($VM) 
 {
    $commande=aws ec2 stop-instances --instance-ids $VM.InstanceId --profile $AWS_PROFILE
    $obj_describe = $commande | ConvertFrom-Json
    $obj_return=$obj_describe.StoppingInstances
    
    Write-Output "stop :  $(Get_VM_TagName($VM))"

    return $obj_return
 }



function Get_VM_TagName {
    param (
        $VM 
    )
    return ($VM.Tags | Where-Object { $_.Key -eq 'Name'}).Value
}

function Get_VM_TagENV {
    param (
        $VM 
    )
    return ($VM.Tags | Where-Object { $_.Key -eq 'ENV'}).Value
}

function Get_VM_AutoStop {
    param (
        $VM 
    )
    return ($VM.Tags | Where-Object { $_.Key -eq 'AutoStop'}).Value
}


function Get_VM_AutoStart {
    param (
        $VM 
    )
    return ($VM.Tags | Where-Object { $_.Key -eq 'AutoStart'}).Value
}

############################
$VMs= Get_VMs
$tab_vm_dans_perimetre=@()
# Create array with VM in no Prod env
foreach ($VM in $VMs)
{
    $vm_env=Get_VM_TagENV($VM)
    if ( $vm_env -ne "PROD")
    {
        $vm_name=Get_VM_TagName($VM)
        $auto_stop=Get_VM_AutoStop($VM)
        $VM | Add-Member -NotePropertyName AutoStop -NotePropertyValue $auto_stop
        $VM | Add-Member -NotePropertyName Name -NotePropertyValue $vm_name
        $tab_vm_dans_perimetre+= $VM
    }   
}

foreach ($VM in $tab_vm_dans_perimetre)
{
    
    $state=Get_VM_State($VM)
    if ($state -eq "stopped")
    {

        if(TimeToStart($VM))
        {
            start_vm($VM)
            $logs+=Write-Output "START VM | $($vm.Name) | $time `n"

        }
    }

    if ($state -eq "running")
    {

        if(TimeToStop($VM))
        {
            stop_vm($VM)
            $logs+=Write-Output "STOP VM | $($vm.Name) | $time `n"
        }
    }

}

Write-Output " **************** DONE ! ******************** "

$logs > log_vm.txt