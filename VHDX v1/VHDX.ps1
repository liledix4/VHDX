# Run as administrator

if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    $addParameter1 = "";
    $addParameter2 = "";
    if ($args[0] -ne $null) {$addParameter1 = " '" + $args[0] + "'";}
    if ($args[1] -ne $null) {$addParameter2 = " '" + $args[1] + "'";}
    $arguments = "& '" + $myinvocation.mycommand.definition + "'" + $addParameter1 + $addParameter2;
    Start-Process powershell -Verb runAs -ArgumentList $arguments;
    Break;
}

# ============================================

# The script itself

Clear-Host;

    # You can customize this parameter
    $defaultLocation = "r";
    # $defaultLocation = "x";

$vhdFullPath = $args[0];
$vhdOperation = $args[1];
$newvhdSize = $args[2];

Write-Host $vhdFullPath;

if ($vhdFullPath -eq $null)
{
    Write-Host "Hit Enter if you need to mount drive.";
    Write-Host "Type 'c' to create new VHDX.";
    Write-Host "Type 'o' to optimize already created VHDX quickly.";
    Write-Host "Type 'of' for full optimization of already created VHDX (slow).";
    $vhdOperation = Read-Host -Prompt " `r`n >> Your choice";
    Write-Host ""
}

function Generate-Source
{
    if ($script:vhdFullPath -eq $null)
    {
        $vhdFile = $null;
        $vhdSource = $null;
        $vhdFullPathTemp = $null;

        if (!($vhdSource = Read-Host -Prompt "Disk or path to the directory"))
        { $vhdSource = $defaultLocation; } # Default value

        switch ($vhdSource)
        {
            "c" { $vhdSource = "C:"; }
            "d" { $vhdSource = "D:"; }
            "e" { $vhdSource = "E:"; }
            "r" { $vhdSource = "R:"; }
            "desktop" { $vhdSource = "${HOME}\Desktop"; }
            "dt" { $vhdSource = "${HOME}\Desktop"; }
        }
        Write-Host " `r`n >> $vhdSource `r`n";

        $vhdFile = Read-Host -Prompt "VHDX name";
        $vhdFullPathTemp = "${vhdSource}\${vhdFile}.vhdx";
        Write-Host " `r`n >> $vhdFullPathTemp `r`n";

        $script:vhdFullPath = $vhdFullPathTemp;
    }
}

function Time-to-Execute
{
    Generate-Source;

    $vhdOperation = $script:vhdOperation;
    $vhdFullPath = $script:vhdFullPath;
    $newvhdSize = $script:newvhdSize;

    switch ($vhdOperation)
    {
        "c"
        {
            if ($newvhdSize -eq $null)
            {
                $newvhdSize = Read-Host -Prompt "Size (GBs)";
                if ($newvhdSize -eq "") {$newvhdSize = 2048;}
                Write-Host " `r`n >> $newvhdSize GB `r`n";
            }

            New-VHD -Path $vhdFullPath -Dynamic -SizeBytes (($newvhdSize -as [double]) * 1GB) | Mount-VHD -Passthru |Initialize-Disk -Passthru |New-Partition -AssignDriveLetter -UseMaximumSize |Format-Volume -FileSystem NTFS -Confirm:$false -Force;
            Break;
        }
        "o"
        {
            Optimize-VHD -Path $vhdFullPath -Mode Quick;
            Break;
        }
        "of"
        {
            Optimize-VHD -Path $vhdFullPath -Mode Full;
            Break;
        }
        default
        {
            Mount-VHD -Path $vhdFullPath;
        }
    }
}

Time-to-Execute;

if ($error.Count -gt '0') { Start-Sleep -Seconds '60'; }