$hostname = [System.Net.DNS]::GetHostByName('').HostName
$gsdurl="restAPI url"
$weburl="powerweb url"
$crsurl="powerweb get_crsurl"
$crurl="powerweb crs"
$scripturl="powerweb scripturl"
$cr_completed_file="cr_done.txt"
$script_path="d:\temp"
$log_path="d:\temp"
$cr_completed=Get-Content $cr_completed_file
$oldcrmpath="d:\"
$interval=120
$env="uat"

if(!(Test-Path $script_path))
{
    mkdir $script_path
}
if(!(Test-Path $log_path))
{
    mkdir $log_path
}
function get_crs($gsdurl, $crsurl, $env)
{
    try
    {
        $response = Invoke-WebRequest $crurl | select -ExpandProperty Content
        $crlist = [System.Text.Encoding]::utf8.GetString($response)
        foreach($cr in $crlist.split(" "))
        {
            cr_check -gsdurl $gsdurl -crnum $cr -env $env
            #$job = Start-job -ScriptBlock {cr_check -gsdurl $args[0] -crnum $args[1] -env $args[2]} =ArgumentList $gsdurl, $cr, $env
            Write-Host "crnum:" $cr "job is :" $job.id
        }
    }
    catch
    {
        write-host "Failed to get the CR list."
    }
}

function cr_check($gsdurl, $crnum, $env)
{
    [Net.ServicePointManager]::SecurityProtocol = "tls12,tls11,tls"
    $url = $gsdurl+$crnum
    try
    {
        $response = Invoke-WebRequest $url -TimeoutSec 10 | select -ExpandProperty content
        $json = $response | ConvertTo-Json
        if($json.Approvers[0].Approver[1].ApproverStatus -eq "Approved" -and $json.Approvers[1].Approver[1].ApproverStatus -eq "Approved" -and $json.Approvers[2].Approver[1].ApproverStatus -eq "Approved")
        {
            write-host $crnum "Approved"
            write-host "Starting process the CR...."
            process_cr -weburl $weburl -crurl $crurl -scripturl $scripturl -crnum $crnum -script_path $script_path -logfile $logfile -oldcrmpath $oldcrmpath
        }
        else
        {
            Write-Host $crm "Pending or Waiting for approve"
            return False
        }
    }
    catch
    {
        Write-Host "Failed to get the approved status from GSD API..."
    }

}

function process_cr($weburl, $crsurl, $scripturl,$crnum,$script_path,$logfile,$oldcrmpath)
{
    $Value=""
    $crendpoint=$crurl+$crnum
    $scriptendpioint = $scripturl+$crnum

    $file=$script_path+"\"+$crnum+".ps1"
    $temp=$response.ToString()
    $logfile=$log_path+"\"+$crnum+".log"

    try
    {
        $response = Invoke-WebRequest $crendpoint -TimeoutSec 10
        $computers_apply = [System.Text.Encoding]::UTF8.GetString($response)
        if($computers_apply -contains $hostname)
        {
            $response = Invoke-WebRequest $scriptendpioint -TimeoutSec 10
            if(Test-Path $file)
            {
                del $file
            }

            Add-Content $file -Value $response
            Write-Host "get the patchs from WebServer. the patch file is " $file
            Write-Host "Starting patching......"
            Invoke-Command {powershell $file} | Out-String
            Add-Content $logfile -Value "$crnum finished sucessfully!"
            $resulturl = $weburl+"result"
            $resultjson = @{
                        "crnum"="$crnum"
                        "content"="$response"
            } | ConvertTo-Json

            Write-Host "reply WebServer with the patching result."
            Invoke-WebRequest -Uri $resulturl -Method POST -Body $crnum -TimeoutSec 10


        }
    }
    catch
    {
        Write-Host "Failed to patching . Please check whether the cr/patching is exist and WebServer is ok..."
        Add-Content $logfile -Value "$crnum failed!"
    }

}


while(1)
{
    get_crs -gsdurl $gsdurl -crsurl $crsurl -env "uat"
    Start-Sleep $interval
}