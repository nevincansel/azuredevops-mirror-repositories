[CmdletBinding()]
param()

Import-VstsLocStrings "$PSScriptRoot\task.json"

$sourceType = Get-VstsInput -Name "sourceType"
$sourceURL = Get-VstsInput -Name "sourceURL"
$sourcePAT = Get-VstsInput -Name "sourcePAT"
$sourceUsername = Get-VstsInput -Name "sourceUsername"
$sourcePass = Get-VstsInput -Name "sourcePass"


if ($sourceType -eq "true"){
    Write-Host "Source is Cloud"
    $sourceURLHelper = "//"+$sourcePAT+"@"
    $sourceURL= $sourceURL -replace "//", $sourceURLHelper
}
else{
    Write-Host "Source is not Cloud"
    $sourceURLHelper = "//"+$sourceUsername+":"+$sourcePass+"@"
    $sourceURL= $sourceURL -replace "//", $sourceURLHelper
}

Write-Host Starting the synchronization process
git clone --mirror $sourceURL

if ($sourceURL -like "*.git*"){
    $destinationPath = $sourceURL.Remove(0, $sourceURL.LastIndexOf('/') + 1)
}
else{
    $destinationPath = $sourceURL.Remove(0, $sourceURL.LastIndexOf('/') + 1) + ".git"
}

Set-Location $destinationPath

$destinationType = Get-VstsInput -Name "destinationType"
$destinationURL = Get-VstsInput -Name "destinationURL"
$destinationPAT = Get-VstsInput -Name "destinationPAT"


try {

if ($destinationType -eq "true"){
    Write-Host "Destination is Cloud"
    $destinationURLHelper = "//"+$destinationPAT+"@"
    $destinationURL= $destinationURL -replace "//", $destinationURLHelper

    Write-Output "*****Git remote set destination URL****"
    git remote set-url origin $destinationURL

    Write-Output "*****Git fetch source repo****"
    git fetch $sourceURL

    Write-Output "*****Git push to destination repo****"
    git push -f

    Set-Location ..
    Remove-Item -Path $destinationPath -Force -Recurse 
}
else{
    Write-Host "Destination is not Cloud"

    $destinationPAT = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($destinationPAT)"))
    Write-Output "*****Git remote set destination URL****"
    git remote set-url origin $destinationURL

    Write-Output "*****Git fetch source repo****"
    git fetch $sourceURL

    Write-Output "*****Git push to destination repo****"
    git -c http.extraheader="AUTHORIZATION: basic $destinationPAT" push -f

    Set-Location ..
    Remove-Item -Path $destinationPath -Force -Recurse 
}
}
catch [Exception] {    
    Write-Error ($_.Exception.Message)
    Throw
}