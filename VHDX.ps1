# Parameters

param
(
    [Parameter(ValueFromRemainingArguments=$true)]
    $vhdFiles = $null,
    $operation = $null
)
$vhdSingleFile = $null;

# ============================================

# Run as administrator

if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    $addParameter1 = "";
    $addParameter2 = "";
    if ($vhdFiles -ne $null)
    {
        $addParameter1 += " @(""";
        for ($v = 0; $v -lt @($vhdFiles).Count; $v++)
        {
            $addParameter1 += $vhdFiles[$v];
            if ($v -ne (@($vhdFiles).Count - 1)) {$addParameter1 += """, """;}
        }
        $addParameter1 += """)";
    }
    if ($operation -ne $null) {$addParameter2 = " -operation """ + $operation + """";}
    $arguments = "& """ + $myinvocation.mycommand.definition + """" + $addParameter1 + $addParameter2;
    Start-Process PowerShell -Verb runAs -ArgumentList $arguments;
    Break;
}

# ============================================

# The script itself

Clear-Host;

    # You can customize this parameter
    $defaultLocation = "e";

function Clear-Variables
{
    $script:vhdFiles = $null,
    $script:operation = $null;
    $script:vhdSingleFile = $null;
}

function Get-Input
{
    if ($script:vhdFiles -eq $null)
    {
        $tempFile = $null;
        $tempSource = $null;
        $tempFullPath = $null;

        Write-Host "Hit Enter if you need to mount drive.";
        Write-Host "Type 'c' to create new VHDX.";
        Write-Host "Type 'o' to optimize already created VHDX quickly.";
        Write-Host "Type 'of' for full optimization of already created VHDX (slow).";
        if (!($script:operation = Read-Host -Prompt " `r`n >> Your choice"))
        {
            $script:operation = "";
        }
        switch ($script:operation)
        {
            "c" {Write-Host " >> Create"; Break;}
            "o" {Write-Host " >> Optimize (Quick)"; Break;}
            "of" {Write-Host " >> Optimize (Full)"; Break;}
            "" {Write-Host " >> Mount"; Break;}
        }
        Write-Host "";

        if (!($tempSource = Read-Host -Prompt "Disk or path to the directory"))
        {
            $tempSource = $script:defaultLocation;
        }

        switch ($tempSource)
        {
            "desktop" { $tempSource = "${HOME}\Desktop"; }
            "dt" { $tempSource = "${HOME}\Desktop"; }
        }
        if ($tempSource.Length -eq 1)
        {
            $tempSource = $tempSource.ToUpper() + ":";
        }
        Write-Host " `r`n >> $tempSource `r`n";

        $tempFile = Read-Host -Prompt "VHDX name";
        $tempFullPath = "${tempSource}\${tempFile}.vhdx";
        Write-Host " `r`n >> $tempFullPath `r`n";

        $script:vhdSingleFile = $tempFullPath;
    }
    else
    {
        Write-Host " >> ${script:vhdSingleFile}";
    }
}

function Continuation
{
    Write-Host " `r`nDo you want to continue?";
    Write-Host "y - yes, continue";
    Write-Host "Enter or other symbols - no, close";
    switch (Read-Host -Prompt " `r`n >> Your choice")
    {
        "y" {
            Clear-Variables;
            Write-Host " >> Continue `r`n";
            Time-to-Execute;
            Break;
        }
        default
        {
            Write-Host " >> Close `r`n";
            Start-Sleep -Seconds 1;
            Exit;
        }
    }
}

function Message-Success {Write-Host " `r`nDone! `r`n";}

function Time-to-Execute
{
    Get-Input;

    $vhdFilePath = $script:vhdSingleFile;
    $newvhdSize = $script:newvhdSize;

    # Operation

    switch ($script:operation)
    {
        "c"
        {
            if ($newvhdSize -eq $null)
            {
                $newvhdSize = Read-Host -Prompt "Size (GBs)";
                if ($newvhdSize -eq "") {$newvhdSize = 2048;}
                Write-Host " `r`n >> $newvhdSize GB `r`n";
            }

            New-VHD -Path $vhdFilePath -Dynamic -SizeBytes (($newvhdSize -as [double]) * 1GB) | Mount-VHD -Passthru |Initialize-Disk -Passthru |New-Partition -AssignDriveLetter -UseMaximumSize |Format-Volume -FileSystem NTFS -Confirm:$false -Force;
            Message-Success;
            Break;
        }
        "o"
        {
            Optimize-VHD -Path $vhdFilePath -Mode Quick;
            Message-Success;
            Break;
        }
        "of"
        {
            Optimize-VHD -Path $vhdFilePath -Mode Full;
            Message-Success;
            Break;
        }
        ""
        {
            Mount-VHD -Path $vhdFilePath;
            Message-Success;
            Break;
        }
    }
}

# ============================================

# Execution

if ($vhdFiles -eq $null)
{
    Time-to-Execute;
    Continuation;
}
else
{
    Write-Host " >> ${vhdFiles}";
    Write-Host " `r`n `r`n `r`n `r`n `r`n `r`n";
    foreach ($currentFile in $vhdFiles)
    {
        $vhdSingleFile = $currentFile;
        Time-to-Execute;
    }
    Continuation;
}

if ($error.Count -gt '0')
{
    Start-Sleep -Seconds '60';
}