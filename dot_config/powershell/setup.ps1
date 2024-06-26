# -*-mode:powershell-*- vim:ft=powershell

# ~/.config/powershell/setup.ps1
# =============================================================================
# Idempotent manual setup script to install or update Powershell dependencies.
#
# On Windows, this file will be copied over to these locations after
# running `chezmoi apply` by the script `../../run_powershell.bat.tmpl`:
#     - %USERPROFILE%\Documents\PowerShell
#     - %USERPROFILE%\Documents\WindowsPowerShell
#
# TODO: Convert this to `~/dotfiles.ps1`

# Requires that PowerShell be running with elevated privileges to be able to
# change system properties.
#Disabled Requires -RunAsAdministrator

# Create missing $IsWindows if running Powershell 5 or below.
if (!(Test-Path variable:global:IsWindows)) {
    Set-Variable "IsWindows" -Scope "Global" -Value ([System.Environment]::OSVersion.Platform -eq "Win32NT")
}

if ($null -eq (Get-Variable "ColorInfo" -ErrorAction "Ignore")) {
    Set-Variable -Name ColorInfo -Value "DarkYellow"
}
Set-Variable -Name count -Value 0 -Scope Script

function eos {
    <#
    .SYNOPSIS
        Terminates the script and counts the actions taken.
    .INPUTS
        None
    .OUTPUTS
        None
    #>
    if ($count) {
        Write-Host "Done! $count modification(s) applied." -ForegroundColor $ColorInfo
    }
    else {
        Write-Host "No modifications performed." -ForegroundColor $ColorInfo
    }
    Remove-Variable -Name count -Scope Script
}

# Ask for confirmation.
$hereString = "
    This script will perform the following non-destructive adjustements to the system (if required):
        - Install packages using scoop and WinGet
        - Install/update Powershell modules"
if ($IsWindows) {
    $hereString += "
        - Enable LongPaths support for file paths above 260 characters"
}
$hereString += [Environment]::NewLine
Write-Host $hereString -ForegroundColor $ColorInfo
$confirmation = Read-Host -Prompt "Do you want to proceed? [y/N]"
if ($confirmation -notMatch '^y(es)?$') {
    eos
    exit
}
Remove-Variable -Name ("confirmation", "hereString")


#
# Dependencies
#


# Setup Programs using WinGet
#if ($IsWindows) {
#        # Install any missing app.
#        $appList = Invoke-Command -ScriptBlock { scoop export }
#        $appList = $appList -replace "[\s].+",""
#	  $apps = (
#		"Git.Git",
#		""
#}

# Setup Scoop.
# See https://github.com/lukesampson/scoop
if ($IsWindows) {
    if (!(Get-Command "scoop" -ErrorAction "Ignore")) {
        Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')
    }
    if (Get-Command "scoop" -ErrorAction "Ignore") {
        Write-Host "Verifying the state of Scoop..." -ForegroundColor $ColorInfo
        Get-Command -Name scoop -ErrorAction Stop
        Invoke-Command -ScriptBlock { scoop checkup }

        # Install any missing bucket.
        $buckets = (
            "extras",
            "nerd-fonts",
            "twpayne"
        )
        $buckets | ForEach-Object {
                Invoke-Command -ScriptBlock { scoop bucket add $_ }
        }

        # Install any missing app.
        $appList = Invoke-Command -ScriptBlock { scoop export }
        $appList = $appList -replace "[\s].+",""
        $apps = (
            "chezmoi",
            "FiraCode-NF-Mono",
            "FiraCode-NF-Propo",
            "FiraCode-NF",
            "FiraCode-Script",
            "FiraCode",
            "FiraMono-NF-Mono",
            "FiraMono-NF-Propo",
            "FiraMono-NF",
            "git",
            "heroku-cli",
            "less",
            "micro",
            "nano",
            "neofetch",
            "ntop",
            "ripgrep",
            "sqlite",
            "starship",
            "sudo",
            "vim",
            "wget",
            "winfetch"
        )
        $apps | ForEach-Object {
            if (!$appList.Contains($_)) {
                Invoke-Command -ScriptBlock { scoop install $_ }
                $count++
            }
        }
    }
}


#
# System tweaks
#

# Enable LongPaths support for file paths above 260 characters.
# See https://social.msdn.microsoft.com/Forums/en-US/fc85630e-5684-4df6-ad2f-5a128de3deef
if ($IsWindows) {
    $property = 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem'
    $name = 'LongPathsEnabled'
    if ((Get-ItemPropertyValue $property -Name $name) -ne 0) {
        Write-Host "LongPaths support already enabled, skipping." -ForegroundColor $ColorInfo
    }
    else {
        Write-Host "Enabling LongPaths support for file paths above 260 characters." -ForegroundColor $ColorInfo
        Set-ItemProperty $property -Name $name -Value 1
        $count++
    }
}

# Display termination message.
eos