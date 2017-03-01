function Enable-ReplicationForVMsOnHost
{
    <#
        .Synopsis
            Enables replication for all VMs that are not replicated on a host to another host.
        .EXAMPLE
            Enable-ReplicationForVMsOnHost -sourceHost 'hyperv-one' -desinationhost 'hyper-two'
        .NOTES
            Written by Ben Taylor
            Version 1.1, 01.03.2017
    #>
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
    [OutputType()]
    Param
    (
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateNotNullOrEmpty()]
        [string]
        $sourceHost,
        [Parameter(Mandatory=$true, Position=1)]
        [ValidateNotNullOrEmpty()]
        [string]
        $destinationHost,
        [Parameter(Mandatory = $false, Position = 2)]
        [ValidateNotNullOrEmpty()]
        [int]
        $timeOut = 7200
    )

    # Prefer here as error message more informative than validateScript
    if($sourceHost -eq $destinationHost) {
        Throw "Source and Destination Host The Same"
    }

    $vms = Get-VM -ComputerName $sourceHost | Where-Object ReplicationState -EQ Disabled

    foreach ($vm in $vms)
    {
        if ($pscmdlet.ShouldProcess($vm.name, 'Replicate'))
        {
            try
            {
                Write-Verbose "Enabling Replication on: $($vm.name)"
                Enable-VMReplication -ComputerName $sourceHost $vm.name $destinationHost 80 Kerberos

                Write-Verbose "Starting Initial Replication On vm: $($vm.name)"
                Start-VMInitialReplication -ComputerName $sourceHost –VMName $vm.name

                Start-Sleep 5

                $timer = [Diagnostics.Stopwatch]::StartNew()

                while ($vm.replicationstate -ne "Replicating" )
                {
                    if($timer.Elapsed.TotalSeconds -ge $timeOut)
                    {
                        Write-Error "$($vm.name) - Hit Timeout Limit, cancelling intial replication"

                        Stop-VMInitialReplication -ComputerName $sourceHost -VMName $vm.name

                        break
                    }

                    Start-Sleep 20
                }

            }
            catch
            {
                Write-Error $_
            }
            finally
            {
                $timer.Stop()
            }
        }
    }
}
