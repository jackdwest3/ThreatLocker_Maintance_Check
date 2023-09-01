# Set paths and registry entry
$servicePath = "C:\Program Files\ThreatLocker\threatlockerservice.exe"
$registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{B1CA8CFF-3D98-4766-9EF4-0B031E0E3677}"

# Import the Syncro PowerShell module
Import-Module $env:SyncroModule

# Create a Syncro ticket for ThreatLocker installation
$ticketResult = Create-Syncro-Ticket -Subject "ThreatLocker Installation - $DeviceName" -IssueType "Security" -Status "New"
#Add initial comment to ticket
Create-Syncro-Ticket-Comment -TicketIdOrNumber $ticketResult.ticket.id -Subject "Initial Issue" -Body "ThreatLocker not found on system." -Hidden "false" -DoNotEmail "true"
Create-Syncro-Ticket-Comment -TicketIdOrNumber $ticketResult.ticket.id -Subject "Diagnosis" -Body "ThreatLocker service not running on expected device. Need to verify installation." -Hidden "true" -DoNotEmail "true"


# Check if ThreatLocker service file exists
if (Test-Path -Path $servicePath -PathType Leaf) {
    Write-Host "ThreatLocker service file found."
    Create-Syncro-Ticket-Comment -TicketIdOrNumber $ticketResult.ticket.id -Subject "Update" -Body "ThreatLocker service file found." -Hidden "true" -DoNotEmail "true"
}
else {
    # ThreatLocker service file not found. Downloading and installing...
    
    [Net.ServicePointManager]::SecurityProtocol = "Tls12"
    
    # Create directory for support files if it doesn't exist
    if (!(Test-Path "C:\Support")) {
        mkdir "C:\Support"
            Create-Syncro-Ticket-Comment -TicketIdOrNumber $ticketResult.ticket.id -Subject "Update" -Body "Support folder created. Location: C:\Support" -Hidden "true" -DoNotEmail "true"
    }
    
    try {
        # Determine download URL based on OS architecture
        if ([Environment]::Is64BitOperatingSystem) {
            $downloadURL = "https://api.threatlocker.com/updates/installers/threatlockerstubx64.exe"
        }
        else {
            $downloadURL = "https://api.threatlocker.com/updates/installers/threatlockerstubx86.exe"
        }

        $localInstaller = "C:\Support\ThreatLockerStub.exe"
        Create-Syncro-Ticket-Comment -TicketIdOrNumber $ticketResult.ticket.id -Subject "Update" -Body "ThreatLocker installer downloading to file: C:\Support\ThreatLockerStub.exe" -Hidden "true" -DoNotEmail "true"


        # Download installer
        Invoke-WebRequest -Uri $downloadURL -OutFile $localInstaller

        # Run installer with appropriate parameters
        try {
           & C:\Support\ThreatLockerStub.exe Key=$ClientKey Company=$organizationName;
        }
        catch {
            Write-Output "Installation Failed";
            Create-Syncro-Ticket-Comment -TicketIdOrNumber $ticketResult.ticket.id -Subject "Update" -Body "ThreatLocker installation failed." -Hidden "true" -DoNotEmail "true"
            Exit 1;
        }
        
        # Check if ThreatLocker service is running
        $service = Get-Service -Name ThreatLockerService -ErrorAction SilentlyContinue

        if ($service.Name -eq "ThreatLockerService" -and $service.Status -eq "Running") {
            Write-Output "Installation successful"
            $verifyNotes = "ThreatLocker installation verified"
            $ticketStatus = "Resolved"
            Create-Syncro-Ticket-Comment -TicketIdOrNumber $ticketResult.ticket.id -Subject "Completed" -Body "ThreatLocker installation completed and verified." -Hidden "true" -DoNotEmail "true"

            # Check if registry entry exists then # Check if ThreatLocker service file exists
            if (Test-Path -Path $servicePath -PathType Leaf) {
            Write-Host "ThreatLocker service file found. Checking uninstall string."
            
            if (-not (Test-Path -Path $registryPath)) {
                # Registry entry doesn't exist. Creating...
                Create-Syncro-Ticket-Comment -TicketIdOrNumber $ticketResult.ticket.id -Subject "Update" -Body "ThreatLocker uninstall registry key missing. Adding key." -Hidden "true" -DoNotEmail "true"
                
                $propertyValues = @{
                    "AuthorizedCDFPrefix" = ""
                    "Comments" = ""
                    "Contact" = ""
                    "DisplayVersion" = "5.30.1.0"
                    "HelpLink" = [byte[]]@(0x68,0x00,0x74,0x00,0x74,0x00,0x70,0x00,0x73,0x00,0x3a,0x00,0x2f,0x00,0x2f,0x00,0x77,0x00,0x77,0x00,0x77,0x00,0x2e,0x00,0x74,0x00,0x68,0x00,0x72,0x00,0x65,0x00,0x61,0x00,0x74,0x00,0x6c,0x00,0x6f,0x00,0x63,0x00,0x6b,0x00,0x65,0x00,0x72,0x00,0x2e,0x00,0x63,0x00,0x6f,0x00,0x6d,0x00,0x2f,0x00,0x73,0x00,0x75,0x00,0x70,0x00,0x70,0x00,0x6f,0x00,0x72,0x00,0x74,0x00,0x00,0x00)
                    "HelpTelephone" = ""
                    "InstallDate" = "20221122"
                    "InstallLocation" = ""
                    "InstallSource" = "C:\Users\JackWest\Downloads\"
                    "NoModify" = 1
                    "NoRemove" = 1
                    "NoRepair" = 1
                    "Publisher" = "ThreatLocker, Inc"
                    "Readme" = ""
                    "Size" = ""
                    "EstimatedSize" = 2477
                    "SystemComponent" = 1
                    "URLInfoAbout" = "https://www.threatlocker.com"
                    "URLUpdateInfo" = ""
                    "VersionMajor" = 5
                    "VersionMinor" = 30
                    "WindowsInstaller" = 1
                    "Version" = 33226753
                    "Language" = 1033
                    "DisplayName" = "ThreatLocker"
                }
                
            New-Item -Path $registryPath -Force
            $propertyValues.GetEnumerator() | ForEach-Object {
                Set-ItemProperty -Path $registryPath -Name $_.Key -Value $_.Value
            }
            #Add comment to ticket and write status to console.
            Create-Syncro-Ticket-Comment -TicketIdOrNumber $ticketResult.ticket.id -Subject "Completed" -Body "ThreatLocker uninstall registry key created." -Hidden "true" -DoNotEmail "true"
            Write-Host "Registry entry created."
            # Log activity on the asset
            Log-Activity -Message "Checked, installed, and verified ThreatLocker installation [script]" -EventName "ThreatLocker Installation" -TicketIdOrNumber $ticketResult.ticket.id
        }
    else {
        Write-Host "Registry entry already exists."
        Create-Syncro-Ticket-Comment -TicketIdOrNumber $ticketResult.ticket.id -Subject "Completed" -Body "ThreatLocker installation complete and verified." -Hidden "true" -DoNotEmail "true"
        # Log activity on the asset
        Log-Activity -Message "Checked, installed, and verified ThreatLocker installation [script]" -EventName "ThreatLocker Installation" -TicketIdOrNumber $ticketResult.ticket.id
    }
        }
        else {
            Write-Output "Installation Failed"
            $verifyNotes = "ThreatLocker installation verification failed"
            $ticketStatus = "Customer Reply"
            Create-Syncro-Ticket-Comment -TicketIdOrNumber $ticketResult.ticket.id -Subject "Update" -Body "ThreatLocker installation failed verification." -Hidden "true" -DoNotEmail "true"
        }
    }
    catch {
        Write-Output "Installation Failed"
        $verifyNotes = "ThreatLocker installation verification failed"
        $ticketStatus = "Customer Reply"
        Create-Syncro-Ticket-Comment -TicketIdOrNumber $ticketResult.ticket.id -Subject "Update" -Body "ThreatLocker installation failed verification." -Hidden "true" -DoNotEmail "true"
    }
    
    # Add time entry with all notes for the entire process
    Create-Syncro-Ticket-TimerEntry -TicketIdOrNumber $ticketResult.ticket.id -StartTime (Get-Date).ToString("o") -DurationMinutes 10 -Notes "Checked, installed, and verified ThreatLocker installation`nInstalled ThreatLocker: $($localInstaller)`nVerification Status: $verifyNotes" -UserIdOrEmail "jack@westcomputers.com" -ChargeTime "true"

    # Update ticket status
    Update-Syncro-Ticket -TicketIdOrNumber $ticketResult.ticket.id -Status $ticketStatus
}
