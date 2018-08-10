# Exit if any command fails
$ErrorActionPreference = "Stop"
# Do not ask for confirmation
$ConfirmPreference = "None"
# Fail if any unset variable is used
Set-StrictMode -Version Latest
# Allow running scripts coming from the Internet
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force

# Checkout with the correct line endings on plain text files, depending on the host OS
git config --global core.autocrlf true >$null 2>$null

# $name cannot be empty or Test-Path will go nuts
function ValidateVariable([string]$Name) {
	$value = $null
	if (Test-Path env:$Name -ErrorAction SilentlyContinue) {
		$value = Get-Item Env:$Name
	} elseif (Get-Variable $Name -ErrorAction SilentlyContinue) {
		$value = Get-Variable $Name
	}

	if ($null -eq $value) {
		throw "'$Name' was not set"
	}
}

function UpdateLocalGitRepository([string]$Directory, [string]$Repository) {
	if ((Get-Item $Directory -ErrorAction SilentlyContinue) -is [System.IO.DirectoryInfo]) {
		git -C "$Directory" rev-parse --is-inside-work-tree >$null 2>$null
	} else {
		$LastExitCode = 128
	}

	if ($LastExitCode -ne 0) {
		Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $Directory
		git clone --recursive "$Repository" "$Directory" >$null 2>$null
	} else {
		Push-Location $Directory

		$local = git rev-parse "@"
		$remote = git rev-parse "@{u}"
		$base = git merge-base "@" "@{u}"

		if ($local -eq $base) {
			git pull >$null 2>$null
			git submodule update --init --recursive >$null 2>$null
		} elseif ($local -ne $remote) {
			git reset --hard origin/master >$null 2>$null
			git clean -df >$null 2>$null
			git pull >$null 2>$null
		}

		Pop-Location
	}
}

ValidateVariable "GARRYSMOD_COMMON_REPOSITORY"
ValidateVariable "GARRYSMOD_COMMON"

UpdateLocalGitRepository $env:GARRYSMOD_COMMON -Repository $env:GARRYSMOD_COMMON_REPOSITORY
