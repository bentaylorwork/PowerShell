Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010 -ErrorAction SilentlyContinue

$expectedConfig = @{
    mailBoxServers = @{
        servers = @('MBX-01', 'MBX-03')
        replayQueueThreshold = 10
        copyQueueThreshold = 10
    }
    clientAccessServers = @{
        servers = @('CAS-1', 'CAS-2')
    }
    hubTransportServers = @{
        servers = @('HUB-1', 'HUB-2')
        queueThreshold = 50
    }
}

$currentConfig = @{
    mailBoxServers = @{
        servers = Get-MailboxServer
        databases = Get-MailboxDatabase
    }
    clientAccessServers = @{
        servers = Get-ClientAccessServer
    }
    hubTransportServers = @{
        servers = Get-TransportServer
    }
}

Describe "Exchange 2010 - Operational Validation" {
    Context "MailBox Servers" {
        it "Mail Box Servers - Count Should Be - $($expectedConfig.mailBoxServers.servers.Count)" {
            $currentConfig.mailBoxServers.servers.count | Should be $expectedConfig.mailBoxServers.servers.Count
        }
        foreach($mailBoxServer in $currentConfig.mailBoxServers.servers) {
            it "Mail Box Server $mailBoxServer should exists" {
                $expectedConfig.mailBoxServers.servers.contains($mailBoxServer.name) | Should be $true
            }
        }

        foreach($mailBoxServer in $expectedConfig.mailBoxServers.servers) {
            it "Mail Box Server $mailBoxServer should exists" {
                $currentConfig.mailBoxServers.servers.name.contains($mailBoxServer) | Should be $true
            }
        }
        foreach($mailBoxServer in $currentConfig.mailBoxServers.servers) {
            it "Mail Box Server $mailBoxServer services are running" {
                Test-ServiceHealth -Server $mailBoxServer | Should be $true
            }
        }  
        Get-DatabaseAvailabilityGroup | Select -ExpandProperty:Servers | Test-ReplicationHealth | ForEach-Object {
            it "DAG Member $($_.server.toString()) - $($_.check.toString())" {
                $_.result | Should be "Passed"
            }
        }
        $currentConfig.mailBoxServers.databases | ForEach-Object {
            it "Database $_ - Is Mounted On Preference Server" {
                $_.Server.Name | Should be ($_.ActivationPreference | Where-Object {$_.Value -eq 1}).Key
            }
        }
        $currentConfig.mailBoxServers.servers | ForEach-Object {
            it "Mail flow test - $($_.name)" {
                ($_ | Test-Mailflow).TestMailFlowResult | Should be 'Success'  
            }
        }
        $currentConfig.mailBoxServers.servers | Test-MapiConnectivity | ForEach-Object {
            it "MAPI Connectivity - $($_.Database)" {
                $_.result | Should be 'Success'  
            }
        }
        $currentConfig.mailBoxServers.databases | Get-MailboxDatabaseCopyStatus | ForEach-Object {
            it "Copy Queue Length - $($_.name)" {
                $queue = $false
                if ($_.CopyQueueLength -le $expectedConfig.mailBoxServers.copyQueueThreshold) { $queue = $true }
                $queue | Should Be $true
            }
        }
        $currentConfig.mailBoxServers.databases | Get-MailboxDatabaseCopyStatus | ForEach-Object {
            it "Replay Queue Length - $($_.name)" {
                $queue = $false
                if ($_.ReplayQueueLength -le $expectedConfig.mailBoxServers.replayQueueThreshold) { $queue = $true }
                $queue | Should Be $true
            }
        }
    }
    Context "Client Access Servers" {
        it "Client Access Servers - Count Should Be - $($expectedConfig.clientAccessServers.servers.Count)" {
            $currentConfig.clientAccessServers.servers.Count | Should be $expectedConfig.clientAccessServers.servers.count
        }
        foreach($casServer in ($currentConfig.clientAccessServers.servers)) {
            it "Client Access Server $casServer should exists" {
                $expectedConfig.clientAccessServers.servers.contains($casServer.name) | Should be $true
            }
        }
        foreach($casServer in ($expectedConfig.clientAccessServers.servers)) {
            it "Client Access Server $casServer should exists" {
                $currentConfig.clientAccessServers.servers.name.contains($casServer) | Should be $true
            }
        }
        foreach($casServer in $currentConfig.clientAccessServers.servers) {
            it "Client Access Server $casServer services are running" {
                Test-ServiceHealth -Server $casServer | Should be $true
            }
        }  
    }
    Context "Hub Transport Servers" {
        it "Hub Transport Servers - Count Should Be - $($expectedConfig.hubTransportServers.servers.Count)" {
            $currentConfig.hubTransportServers.servers.Count | Should be $expectedConfig.hubTransportServers.servers.count
        }
        foreach($hubServer in ($currentConfig.hubTransportServers.servers)) {
            it "Hub Transport Server $hubServer should exists" {
                $expectedConfig.hubTransportServers.servers.contains($hubServer.name) | Should be $true
            }
        }
        foreach($hubServer in ($expectedConfig.hubTransportServers.servers)) {
            it "Hub Transport Server $hubServer should exists" {
                $currentConfig.hubTransportServers.servers.name.contains($hubServer) | Should be $true
            }
        }
        foreach($hubServer in $expectedConfig.hubTransportServers.servers) {
            it "Hub Transport Server $hubServer services are running" {
                Test-ServiceHealth -Server $hubServer | Should be $true
            }
        }
        $currentConfig.hubTransportServers.servers | Get-Queue | ForEach-Object {
            it "Hub Transport Server $($_.identity) queue being tested" {
                $queue = $false
                if ($_.MessageCount -le $expectedConfig.hubTransportServers.queueThreshold) { $queue = $true }
                $queue | Should be $true
            }
        }
    }
}
