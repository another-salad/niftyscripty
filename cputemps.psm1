function New-CpuTempChart {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)][ValidateScript({$_.PsObject.TypeNames -contains "CpuChartItem"})][pscustomobject]$NewCpuChartItem,
        [int]$Width = 100
    )
    process {
        $min = ($_.data.Temp | Measure-Object -Minimum).Minimum
        $max = ($_.data.Temp | Measure-Object -Maximum).Maximum
        Write-Host $_.Title
        $_.data | ForEach-Object {
            $len = [math]::Round((($_.Temp - $min) / $(if (($max - $min) -eq 0) { 1 } else { $max - $min })) * $Width)
            Write-Host ("{0} {1} {2}" -f ($_.Time.PadRight(8)), ("{0,5:N1}°C" -f $_.Temp), ('#' * $(if ($len -gt 0) { $len } else { 0 })))
        }
        Write-Host ("min {0:N1}°C   max {1:N1}°C" -f $min, $max)
    }
}

function Get-CpuTempData {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)][ValidateScript({ Test-Path $_ })][string]$Path
    )
    process {
        $_ | Import-Csv | ForEach-Object {
            [pscustomobject]@{ 
                Time = $_.Time;
                Temp = (($_.'CPU Temp' -replace '[^\d\.\-]','') -as [double])
            }
        }
    }
}


# > "./yayaya/2026-06-14.csv" | New-CpuChartItem | Set-OrderByTemp -Limit 10 | New-CpuTempChart
# CPU temps for: yayaya - 2026-06-14
# 12:47:01  51.9°C #######
# 12:44:01  52.0°C ########
# 12:43:01  54.1°C ########################
# 12:40:01  54.4°C ##########################
# 12:46:01  55.2°C ################################
# 12:42:01  55.5°C ###################################
# 12:38:01  58.0°C ######################################################
# 12:45:01  58.0°C ######################################################
# 12:39:01  60.9°C ############################################################################
# 12:41:01  63.4°C ###############################################################################################
# min 51.0°C   max 64.0°C

function New-CpuChartItem {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)][ValidateScript({ Test-Path $_ })][string]$Path
    )
    process {
        [pscustomobject]@{
            PsTypeName = 'CpuChartItem'
            Title="CPU temps for: $($_ | Split-Path -Parent | Split-Path -Leaf) - $(($_ | Split-Path -Leaf).TrimEnd('.csv'))"
            Data=($_ | Get-CpuTempData)
        }
    }
    # I had grand plans but the $Input said no. If you have a process and an end, it looks like $input is exhausted within the process block,
    # even if you end up doing nothing (i.e. protecting from processing via parameter sets)
    # end {
    #     if ($PSCmdlet.ParameterSetName -eq 'Data') {
    #         [pscustomobject]@{
    #             PsTypeName = 'CpuChartItem'
    #             Title=$Title
    #             Data=$Input
    #         }
    #     }
    # }
}

# .....Other dead ideas maybe....
# $z.data | Set-OrderByTemp | select -Last 10 | Update-CpuChartItemData -NewCpuChartItem $z
# This might look like a bit of an odd shape but you'll be _processing_ your temp data in the pipe before shoving it into New-CpuTempChart
# Function Update-CpuChartItemData {
#     [cmdletbinding()]
#     param(
#         [Parameter(Mandatory, ValueFromPipeline)][PscustomObject]$Data,
#         [Parameter(Mandatory)][ValidateScript({$_.PsObject.TypeNames -contains "CpuChartItem"})][pscustomobject]$NewCpuChartItem
#     )
#     end {
#         $NewCpuChartItem.data = $input
#         $NewCpuChartItem
#     }

# }

# Filter Set-OrderByTemp {
#     process {
#         $_ | Sort-Object -Property Temp
#     }
# }

Filter Set-OrderByTemp {
    param(
        [int]$Limit
    )
    process {
        $_.data = $_.data | Sort-Object -Property Temp
        if ($Limit) {
            $_.data = $_.data | select -last $limit
        }
        $_
    }
}

Function Get-HostData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)][ValidateScript({ Test-Path $_ })][string]$Path,
        [Parameter()][int]$Last=1  # Per discovered host
    ) 
    # Will recurse down each discovered host directory and fetch the paths for the latest X csv files.
    # Expected dir structure is:
    # Parent/
    #   host1/
    #       date-time.csv,
    #   host2/
    #       date-time.csv,
    process {
        Get-ChildItem -Path $_ | % {$_ | Get-ChildItem | Sort-Object | Select-Object -Last $Last}
    }
}
