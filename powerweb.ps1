$hostname=[System.Net.DNS]::GetHostByName('').HostName
$script_path="d:\tools"
$current_path=$script_path
$base_url="http://$hostname/"
$done_cr_dirname="done_cr"
$crs_path="crs"
$resultpath="d:\tools\log"

if(!(Test-Path $script_path"\crs"))
{
    mkdir $script_path"\crs"
}
if(!(Test-Path $script_path"\"$done_cr_dirname))
{
    mkdir $script_path"\"$done_cr_dirname
}
if(!(Test-Path $resultpath))
{
    mkdir $resultpath
}

function get_dirfiles($path){
    $dirfiles = Get-ChildItem $path | ForEach-Object -Process {
        $_.Name
    }
    return $dirfiles
}

function get_dir($path){
    $dirs = Get-ChildItem -Directory $path | ForEach-Object -Process {
        $_.Name
    }
    return $dirs
}

function get_files($path){
    $files = Get-ChildItem $path | ForEach-Object -Process{
        if($_ -is [System.IO.FileInfo])
        {
        $_.Name
        }
    }
    return $files
}

function Start_Server()
{
    Add-Type -AssemblyName System.Web
    $http = [System.Net.HttpListener]::new()
    $http.Prefixes.Add($base_url)
    try{
        $http.Start()
    }
    catch
    {
        Write-Host "Failed to Start WebServer."
    }

    If($http.IsListening){
        Write-Host "HTTP Server Ready!" -f Black -b Green
        Write-Host "now try to going to $($http.Prefixes)" -f Yellow
    }

    while($http.IsListening){
        $context = $http.GetContext()
        $dirs = get_dirs($current_path)
        $files = get_files($current_path)
        
        if($context.Request.HttpMethod -eq 'GET' -and $context.Request.RawUrl -eq '/'){
            Write-Host "$($context.Request.UserHostAddress) => $($context.Request.Url)" -f Magenta
            $temp = get_dirfiles($script_path)
            $content = $temp | ForEach-Object -Process{"<li><a href=$base_url$_>$_</a></li>"}
            $menu = Get-Content $script_path"\menu.html"

            [String]$html = $menu+"<dev class='main'><ul>"+$content + "</ul></div>"
            Write-Host $html

            $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
            $context.Response.ContentLength64 =$buffer.Length
            $context.Response.OutputStream.Write($buffer, 0, $buffer.Length)
            $context.Response.OutputStream.Close()
            $current_path=$script_path
        }

        if($context.Request.HttpMethod -eq 'GET' -and $context.Request.RawUrl -eq '/health'){
            $scriptname = $context.Request.RawUrl
            
            Write-Host $scriptname
            Write-Host "$($context.Request.UserHostAddress) => $($context.Request.Url)" -f Magenta
            
            $json = @"
                    "": true,
                    "": 123
                    "": ""
                    "": ""

"@
            
            [String]$html = $json
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
            $context.Response.ContentLength64 =$buffer.Length
            $context.Response.OutputStream.Write($buffer, 0, $buffer.Length)
            $context.Response.OutputStream.Close()
        }

        if($context.Request.HttpMethod -eq 'GET' -and $context.Request.RawUrl -eq '/'){
            Write-Host "$($context.Request.UserHostAddress) => $($context.Request.Url)" -f Magenta
            $temp = get_dirfiles($script_path)
            $content = $temp | ForEach-Object -Process{"<li><a href=$base_url$_>$_</a></li>"}
            $menu = Get-Content $script_path"\menu.html"

            [String]$html = $menu+"<dev class='main'><ul>"+$content + "</ul></div>"
            Write-Host $html

            $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
            $context.Response.ContentLength64 =$buffer.Length
            $context.Response.OutputStream.Write($buffer, 0, $buffer.Length)
            $context.Response.OutputStream.Close()
            $current_path=$script_path
        }

        if($files -contains $context.Request.RawUrl.Substring(1){
            if($context.Request.HttpMethod -eq 'GET' -and $context.Request.RawUrl -ne '/health'){
               $scriptname = $context.Request.RawUrl
            
                Write-Host $scriptname
                Write-Host "$($context.Request.UserHostAddress) => $($context.Request.Url)" -f Magenta
                        
                [String]$html = Get-Content $current_path$scriptname
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
                $context.Response.ContentLength64 =$buffer.Length
                $context.Response.OutputStream.Write($buffer, 0, $buffer.Length)
                $context.Response.OutputStream.Close()
            }
        }

        if($context.Request.HttpMethod -eq 'GET' -and $context.Request.RawUrl -eq '/get_crs'){
               $files = get_files($script_path+"\"+$crs_path)
               
                Write-Host "$($context.Request.UserHostAddress) => $($context.Request.Url)" -f Magenta
                        
                [String]$html = files
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
                $context.Response.ContentLength64 =$buffer.Length
                $context.Response.OutputStream.Write($buffer, 0, $buffer.Length)
                $context.Response.OutputStream.Close()
            }

            if($context.Request.HttpMethod -eq 'GET' -and $context.Request.RawUrl -ne '/crs/*'){
                $cr = $context.Request.RawUrl
            
                Write-Host "$($context.Request.UserHostAddress) => $($context.Request.Url)" -f Magenta
                        
                [String]$html = Get-Content $current_path$cr
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
                $context.Response.ContentLength64 =$buffer.Length
                $context.Response.OutputStream.Write($buffer, 0, $buffer.Length)
                $context.Response.OutputStream.Close()
            }

            if($context.Request.HttpMethod -eq 'GET' -and $context.Request.RawUrl -ne '/scripts/*'){
                $scriptname = $context.Request.RawUrl
            
                Write-Host "$($context.Request.UserHostAddress) => $($context.Request.Url)" -f Magenta
                        
                $html = [IO.File]::ReadAllText($current_path+$scriptname)
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
                $context.Response.ContentLength64 =$buffer.Length
                $context.Response.OutputStream.Write($buffer, 0, $buffer.Length)
                $context.Response.OutputStream.Close()
            }

          if($dirs -contains $context.Request.RawUrl.Substring(1){
            if($context.Request.HttpMethod -eq 'GET' -and $context.Request.RawUrl -ne '/health'){
               $subpath = $context.Request.RawUrl
                $menu = Get-Content $script_path"\menu.html"
                $temp = get_dirfiles($current_path+$subpath)
                $content = $temp | ForEach-Object -Process{"<li><a href=$base_url$_>$_</a></li>"}
                Write-Host "$($context.Request.UserHostAddress) => $($context.Request.Url)" -f Magenta
                        
                [String]$html = $menu+"<div class='main'><ul>"+$content+"</ul></div>"
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
                $context.Response.ContentLength64 =$buffer.Length
                $context.Response.OutputStream.Write($buffer, 0, $buffer.Length)
                $context.Response.OutputStream.Close()
                $current_path=$current_path+$subpath
            }
        }

        if($context.Request.HttpMethod -eq 'GET' -and $context.Request.RawUrl -eq '/result'){
                $result = [System.IO.StreamReader]::new($context.Request.InputStream).ReadToEnd()
                $crnum = $result
                $srcfile = $script_path+"\crs\"+crnum
                $destdir = $script_path+"\"+$done_cr_dirname+"\"
                mv $srcfile $destdir

                $resultfile = $resultpath+"\"+"test.txt"
                Add-Content $resultfile -Value $result
                
                Write-Host "$($context.Request.UserHostAddress) => $($context.Request.Url)" -f Magenta
                Write-Host $crnum "finished sucessfully!" -f Green
                        
                [String]$html = "OK"
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
                $context.Response.ContentLength64 =$buffer.Length
                $context.Response.OutputStream.Write($buffer, 0, $buffer.Length)
                $context.Response.OutputStream.Close()
               
            }

        if($context.Request.HttpMethod -eq 'GET' -and $context.Request.RawUrl -eq '/submit/cr_submitform'){
                
                               
                Write-Host "$($context.Request.UserHostAddress) => $($context.Request.Url)" -f Magenta
                $content = Get-Content $script_path"cr_submitform.html"
                $menu = Get-Content $script_path"\menu.html"
                        
                [String]$html = $menu+$content
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
                $context.Response.ContentLength64 =$buffer.Length
                $context.Response.OutputStream.Write($buffer, 0, $buffer.Length)
                $context.Response.OutputStream.Close()
               
            }

            if($context.Request.HttpMethod -eq 'POST' -and $context.Request.RawUrl -eq '/submit/cr_submitform'){
                
                               
                Write-Host "$($context.Request.UserHostAddress) => $($context.Request.Url)" -f Magenta
                $FormContent = [System.IO.StreamReader]::New($context.Request.InputStream).ReadToEnd()
                $crnum = $FormContent.Split("&")[0].Split("=")[1]
                $temp = $FormContent.Split("&")[1].Split("=")[1]
                $content = [System.Web.HttpUtility]::UrlDecode($temp)
                $menu = Get-Content $script_path"\menu.html"
                Add-Content $script_path"\crs\"$crnum -Value $content
                        
                [String]$html = $menu+"<div class='main'><h1>CR submit sucessful!</h1></div>"
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
                $context.Response.ContentLength64 =$buffer.Length
                $context.Response.OutputStream.Write($buffer, 0, $buffer.Length)
                $context.Response.OutputStream.Close()
               
            }

            if($context.Request.HttpMethod -eq 'GET' -and $context.Request.RawUrl -eq '/submit/script_submitform'){
                
                               
                Write-Host "$($context.Request.UserHostAddress) => $($context.Request.Url)" -f Magenta
                $content = Get-Content $script_path"script_submitform.html"
                $menu = Get-Content $script_path"\menu.html"
                        
                [String]$html = $menu+$content
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
                $context.Response.ContentLength64 =$buffer.Length
                $context.Response.OutputStream.Write($buffer, 0, $buffer.Length)
                $context.Response.OutputStream.Close()
               
            }

            if($context.Request.HttpMethod -eq 'POST' -and $context.Request.RawUrl -eq '/submit/scrip_submitform'){
                
                               
                Write-Host "$($context.Request.UserHostAddress) => $($context.Request.Url)" -f Magenta
                $FormContent = [System.IO.StreamReader]::New($context.Request.InputStream).ReadToEnd()
                $crnum = $FormContent.Split("&")[0].Split("=")[1]
                $temp = $FormContent.Split("&")[1].Split("=")[1]
                $content = [System.Web.HttpUtility]::UrlDecode($temp)
                $menu = Get-Content $script_path"\menu.html"
                Add-Content $script_path"\scripts\"$crnum -Value $content
                        
                [String]$html = $menu+"<div class='main'><h1>CR submit sucessful!</h1></div>"
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
                $context.Response.ContentLength64 =$buffer.Length
                $context.Response.OutputStream.Write($buffer, 0, $buffer.Length)
                $context.Response.OutputStream.Close()
               
            }
    }
}