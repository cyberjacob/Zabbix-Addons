# Powershell used for monitoring the number of open files for each user.
# Windows Only.
# Useful for detecting malware such as cryptolocker that encrypt files, as they do it very quickly.

param (
    [string]$report_user = ""
)

$FILE_SERVER_NAME = "Your.FS.here"

$openFiles = openfiles /query /s $FILE_SERVER_NAME /fo CSV /v | ConvertFrom-Csv

$users = @{}

foreach ($file in $openFiles) {
    $users[$file."Accessed By"] += 1
}

if ($report_user -ne "") {
    Write-host $users[$report_user]
} else {
    Write-host '{"data":['
    foreach ($user in $users.GetEnumerator()) {
        Write-host '{"{#USERNAME}":"'
        Write-host $user.Name
        Write-host '", "{#OPENFILES}":"'
        Write-host $user.Value
        Write-host '"   },'
    }
    Write-host ']}'
}
