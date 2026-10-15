<#
.SYNOPSIS
    Forwarding script to root run.ps1
#>
[CmdletBinding()]
param (
    [switch]$SkipBuild,
    [switch]$EnableDebug
)

# Forward arguments to main pipeline runner
$ForwardArgs = @()
if ($SkipBuild)   { $ForwardArgs += "-SkipBuild" }
if ($EnableDebug) { $ForwardArgs += "-EnableDebug" }

& "$PSScriptRoot\..\run.ps1" @ForwardArgs