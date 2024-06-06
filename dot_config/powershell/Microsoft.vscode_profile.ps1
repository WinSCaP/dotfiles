# Determine user profile parent directory.
$ProfilePath = Split-Path -parent $profile

if (Test-Path $ProfilePath/profile.ps1) {
	. $ProfilePath/profile.ps1
}
