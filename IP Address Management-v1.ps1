Add-Type -AssemblyName System.Windows.Forms

# Function to show an Open File Dialog and return the selected file path
function Get-FilePathUsingDialog {
    param (
        [string]$title # Dialog title
    )

    $fileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $fileDialog.InitialDirectory = [Environment]::GetFolderPath("Desktop")
    $fileDialog.Filter = "Text files (*.txt)|*.txt|All files (*.*)|*.*"
    $fileDialog.Title = $title
    $fileDialog.ShowDialog() | Out-Null

    if ($fileDialog.FileName -and (Test-Path -Path $fileDialog.FileName)) {
        return $fileDialog.FileName
    } else {
        return $null
    }
}

# Function to read IPs from a file and filter out invalid entries
function Get-ValidIPs {
    param (
        [string]$filePath # Path to the file containing IPs
    )
    
    $fileContent = Get-Content -Path $filePath -ErrorAction Stop

    $ipPattern = '^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.'
    $ipPattern += '(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.'
    $ipPattern += '(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.'
    $ipPattern += '(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'

    $fileContent | Where-Object { $_ -match $ipPattern }
}

# Function to check if an IP address is valid
function Is-ValidIPAddress {
    param (
        [string]$ipAddress
    )

    $ipPattern = '^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.'
    $ipPattern += '(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.'
    $ipPattern += '(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.'
    $ipPattern += '(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'

    return $ipAddress -match $ipPattern
}

# Function to add addresses to the main file with a common header
function Add-AddressesToMainFile {
    param (
        [string]$mainListPath,  # Path to the main list file
        [string[]]$addresses,   # Array of addresses to add
        [string]$addedBy        # Name of the person adding the addresses
    )

    if (Test-Path -Path $mainListPath) {
        $mainListIPs = Get-ValidIPs -filePath $mainListPath
        $addedIPs = @()

        $currentDateTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $header = "#> Batch Added Date: $currentDateTime, Added by: $addedBy"
        $newAddresses = @()

        foreach ($ip in $addresses) {
            if ($ip -notin $mainListIPs -and (Is-ValidIPAddress $ip)) {
                $newAddresses += $ip
                $addedIPs += $ip
            } elseif ($ip -in $mainListIPs) {
                Write-Host "Duplicate IP: $ip"
            } else {
                Write-Host "Invalid IP format: $ip"
            }
        }

        if ($newAddresses.Count -gt 0) {
            Add-Content -Path $mainListPath -Value $header
            $newAddresses | ForEach-Object { Add-Content -Path $mainListPath -Value $_ }
        }

        return $addedIPs
    } else {
        Write-Host "Main list file not found at path: $mainListPath"
        return @()
    }
}

# Main script logic
$exitLoop = $false
$mainListPath = $null

while (-not $exitLoop) {
    try {
        Write-Host "Menu:"
        Write-Host "1 - Add addresses to the main file"
        Write-Host "2 - Add addresses from a file"
        Write-Host "3 - Manually enter an IP address"
        Write-Host "4 - Display the main list with new addresses and current main file"
        Write-Host "5 - Exit"

        $choice = Read-Host "Enter your choice (1/2/3/4/5):"

        switch ($choice) {
            1 {
                if (-not $mainListPath) {
                    $mainListPath = Get-FilePathUsingDialog -title "Select the Main IP List File"
                }
                if ($mainListPath) {
                    $secondFilePath = Get-FilePathUsingDialog -title "Select the Second File with Addresses to Add"
                    if ($secondFilePath) {
                        $addressesToCopy = Get-Content -Path $secondFilePath
                        $addedIPs = Add-AddressesToMainFile -mainListPath $mainListPath -addresses $addressesToCopy -addedBy "User"
                        if ($addedIPs.Count -gt 0) {
                            $addedIPs | ForEach-Object { Write-Host "Added new IP: $_" }
                        } else {
                            Write-Host "No new addresses added."
                        }
                    }
                }
            }
            2 {
                if ($mainListPath) {
                    $fileToAdd = Get-FilePathUsingDialog -title "Select the File with Addresses to Add"
                    if ($fileToAdd) {
                        $addresses = Get-Content -Path $fileToAdd
                        $addedIPs = Add-AddressesToMainFile -mainListPath $mainListPath -addresses $addresses -addedBy "User"
                        if ($addedIPs.Count -gt 0) {
                            $addedIPs | ForEach-Object { Write-Host "Added new IP: $_" }
                        } else {
                            Write-Host "No new addresses added."
                        }
                    }
                }
            }
            3 {
                if (-not $mainListPath) {
                    $mainListPath = Get-FilePathUsingDialog -title "Select the Main IP List File"
                }
                if ($mainListPath) {
                    $ipAddress = Read-Host "Enter the IP address in the format [].[].[].[ ]"
                    if (Is-ValidIPAddress $ipAddress) {
                        $addedIPs = Add-AddressesToMainFile -mainListPath $mainListPath -addresses @($ipAddress) -addedBy "User"
                        if ($addedIPs.Count -gt 0) {
                            Write-Host "IP address added successfully: $ipAddress"
                        } else {
                            Write-Host "No new IP address added."
                        }
                    } else {
                        Write-Host "Invalid IP format: $ipAddress"
                    }
                }
            }
            4 {
                if ($mainListPath) {
                    Write-Host "Current Main List File: $mainListPath"
                    $mainListContent = Get-Content -Path $mainListPath
                    $mainListContent | ForEach-Object { Write-Host $_ }
                }
            }
            5 {
                $exitLoop = $true
                Write-Host "Exiting."
            }
            default {
                Write-Host "Invalid choice. Please enter 1, 2, 3, 4, or 5."
            }
        }
    } catch {
        Write-Error "An error occurred: $_"
    }
}
