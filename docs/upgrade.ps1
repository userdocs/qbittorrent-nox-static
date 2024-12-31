<#
.SYNOPSIS
    Upgrades Astro dependencies using npx.
.DESCRIPTION
    This script runs the Astro upgrade tool to update project dependencies.
.NOTES
    Requires Node.js and NPM to be installed.
#>

# Error handling preference
$ErrorActionPreference = 'Stop'

# Check if npm is installed
if (!(Get-Command npm -ErrorAction SilentlyContinue)) {
    Write-Error "Node.js/NPM is not installed. Please install it first."
    exit 1
}

try {
    npx @astrojs/upgrade
} catch {
    Write-Error "Failed to upgrade Astro: $_"
    exit 1
}
