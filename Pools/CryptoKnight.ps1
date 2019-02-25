﻿using module ..\Include.psm1

param(
    [PSCustomObject]$Wallets,
    [PSCustomObject]$Params,
    [alias("WorkerName")]
    [String]$Worker,
    [TimeSpan]$StatSpan,
    [String]$DataWindow = "estimate_current",
    [Bool]$InfoOnly = $false,
    [Bool]$AllowZero = $false,
    [String]$StatAverage = "Minute_10"
)

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Pool_Region_Default = "eu"

try {
    $Pool_Ngix = Invoke-RestMethodAsync "https://cryptoknight.cc/nginx.conf" -tag $Name -cycletime (4*3600)
} catch {
    if ($Error.Count){$Error.RemoveAt(0)}
    Write-Log -Level Warn "Pool API ($Name) has failed. "
    return
}

if (-not $Pool_Ngix) {
    Write-Log -Level Warn "Pool API ($Name) returned nothing. "
    return
}

$Pool_Algorithms = ([regex]"\/rpc\/([a-z]+)\/").Matches($Pool_Ngix) | Foreach-Object {$_.Groups[1]} | Select-Object -ExpandProperty Value -Unique

$Pools_Data = @(
    [PSCustomObject]@{coin = "Aeon";        symbol = "AEON"; algo = "CnLiteV7";    port = 5541;  fee = 0.0; rpc = "aeon"}
    [PSCustomObject]@{coin = "Alloy";       symbol = "XAO";  algo = "CnAlloy";     port = 5661;  fee = 0.0; rpc = "alloy"}
    [PSCustomObject]@{coin = "Arqma";       symbol = "ARQ";  algo = "CnLiteV7";    port = 3731;  fee = 0.0; rpc = "arq"}
    [PSCustomObject]@{coin = "Arto";        symbol = "RTO";  algo = "CnArto";      port = 51201; fee = 0.0; rpc = "arto"}
    [PSCustomObject]@{coin = "BBS";         symbol = "BBS";  algo = "CnLiteV7";    port = 19931; fee = 0.0; rpc = "bbs"}
    [PSCustomObject]@{coin = "BitcoinNote"; symbol = "BTCN"; algo = "CnLiteV7";    port = 4461;  fee = 0.0; rpc = "btcn"}
    [PSCustomObject]@{coin = "Bittorium";   symbol = "BTOR"; algo = "CnLiteV7";    port = 10401; fee = 0.0; rpc = "bittorium"}
    [PSCustomObject]@{coin = "BitTube";     symbol = "TUBE"; algo = "CnSaber";     port = 4461;  fee = 0.0; rpc = "ipbc"; host = "tube"}
    [PSCustomObject]@{coin = "Caliber";     symbol = "CAL";  algo = "CnV8";        port = 14101; fee = 0.0; rpc = "caliber"}
    [PSCustomObject]@{coin = "CitiCash";    symbol = "CCH";  algo = "CnHeavy";     port = 4461;  fee = 0.0; rpc = "citi"}
    [PSCustomObject]@{coin = "Elya";        symbol = "ELYA"; algo = "CnV7";        port = 50201; fee = 0.0; rpc = "elya"}
    [PSCustomObject]@{coin = "Graft";       symbol = "GRFT"; algo = "CnV8";        port = 9111;  fee = 0.0; rpc = "graft"}
    [PSCustomObject]@{coin = "Haven";       symbol = "XHV";  algo = "CnHaven";     port = 5531;  fee = 0.0; rpc = "haven"}
    [PSCustomObject]@{coin = "IPBC";        symbol = "IPBC"; algo = "CnSaber";     port = 4461;  fee = 0.0; rpc = "ipbc"; host = "ipbcrocks"}
    [PSCustomObject]@{coin = "Iridium";     symbol = "IRD";  algo = "CnLiteV7";    port = 50501; fee = 0.0; rpc = "iridium"}
    [PSCustomObject]@{coin = "Italo";       symbol = "ITA";  algo = "CnHaven";     port = 50701; fee = 0.0; rpc = "italo"}
    [PSCustomObject]@{coin = "Lethean";     symbol = "LTHN"; algo = "CnV8";        port = 8881;  fee = 0.0; rpc = "lethean"}
    #[PSCustomObject]@{coin = "Lines";       symbol = "LNS";  algo = "CnV7";        port = 50401; fee = 0.0; rpc = "lines"}
    [PSCustomObject]@{coin = "Loki";        symbol = "LOKI"; algo = "CnHeavy";     port = 7731;  fee = 0.0; rpc = "loki"}
    [PSCustomObject]@{coin = "Masari";      symbol = "MSR";  algo = "CnHalf";      port = 3333;  fee = 0.0; rpc = "msr"; host = "masari"}
    [PSCustomObject]@{coin = "Monero";      symbol = "XMR";  algo = "CnV8";        port = 4441;  fee = 0.0; rpc = "monero"}
    [PSCustomObject]@{coin = "MoneroV";     symbol = "XMV";  algo = "CnV7";        port = 9221;  fee = 0.0; rpc = "monerov"}
    [PSCustomObject]@{coin = "Niobio";      symbol = "NBR";  algo = "CnHeavy";     port = 50101; fee = 0.0; rpc = "niobio"}
    [PSCustomObject]@{coin = "Ombre";       symbol = "OMB";  algo = "CnHeavy";     port = 5571;  fee = 0.0; rpc = "ombre"}
    #[PSCustomObject]@{coin = "Qwerty";      symbol = "QWC";  algo = "CnHeavy";     port = 8261;  fee = 0.0; rpc = "qwerty"}
    [PSCustomObject]@{coin = "Ryo";         symbol = "RYO";  algo = "CnGpu";       port = 52901; fee = 0.0; rpc = "ryo"}
    [PSCustomObject]@{coin = "SafeX";       symbol = "SAFE"; algo = "CnV7";        port = 13701; fee = 0.0; rpc = "safex"}
    [PSCustomObject]@{coin = "Saronite";    symbol = "XRN";  algo = "CnHeavyXhv";  port = 5531;  fee = 0.0; rpc = "saronite"}
    [PSCustomObject]@{coin = "Solace";      symbol = "SOL";  algo = "CnHeavy";     port = 5001;  fee = 0.0; rpc = "solace"}
    [PSCustomObject]@{coin = "Stellite";    symbol = "XTL";  algo = "CnHalf";      port = 16221; fee = 0.0; rpc = "stellite"}
    [PSCustomObject]@{coin = "Swap";        symbol = "XWP";  algo = "Cuckaroo29s"; port = 7731;  fee = 0.0; rpc = "swap"; divisor = 32; regions = @("eu","asia")}
    [PSCustomObject]@{coin = "Triton";      symbol = "TRIT"; algo = "CnLiteV7";    port = 6631;  fee = 0.0; rpc = "triton"}
    [PSCustomObject]@{coin = "WowNero";     symbol = "WOW";  algo = "CnWow";       port = 50901; fee = 0.0; rpc = "wownero"}
)

$Pools_Data | Where-Object {$Pool_Algorithms -icontains $_.rpc} | Where-Object {$Wallets."$($_.symbol)" -or $InfoOnly} | ForEach-Object {
    $Pool_Currency = $_.symbol
    $Pool_RpcPath = $_.rpc.ToLower()
    $Pool_HostPath = if ($_.host) {$_.host} else {$Pool_RpcPath}
    $Pool_Algorithm = $_.algo
    $Pool_Algorithm_Norm = Get-Algorithm $Pool_Algorithm
    $Pool_Divisor = if ($_.divisor) {$_.divisor} else {1}
    $Pool_Regions = if ($_.regions) {$_.regions} else {$Pool_Region}

    $Pool_Port = 0
    $Pool_Fee  = 0.0

    $Pool_Request = [PSCustomObject]@{}
    $Pool_Ports   = [PSCustomObject]@{}

    $ok = $true
    if (-not $InfoOnly) {
        try {
            $Pool_Request = Invoke-RestMethodAsync "https://cryptoknight.cc/rpc/$($Pool_RpcPath)/stats" -tag $Name -timeout 15 -cycletime 120
            $Pool_Port = $Pool_Request.config.ports | Where-Object desc -match '(CPU|GPU)' | Select-Object -First 1 -ExpandProperty port
            @("CPU","GPU","RIG") | Foreach-Object {
                $PortType = $_
                $Pool_Request.config.ports | Where-Object desc -match $PortType | Select-Object -First 1 -ExpandProperty port | Foreach-Object {$Pool_Ports | Add-Member $PortType $_ -Force}
            }
        }
        catch {
            if ($Error.Count){$Error.RemoveAt(0)}
            Write-Log -Level Warn "Pool API ($Name) for $Pool_Currency has failed. "
            $ok = $false
        }
    }

    if ($ok -and $Pool_Port -and -not $InfoOnly) {
        $Pool_Fee = $Pool_Request.config.fee

        $timestamp    = Get-UnixTimestamp
        $timestamp24h = $timestamp - 24*3600

        $diffLive     = $Pool_Request.network.difficulty
        $reward       = $Pool_Request.network.reward
        $profitLive   = 86400/$diffLive*$reward/$Pool_Divisor
        $coinUnits    = $Pool_Request.config.coinUnits
        $amountLive   = $profitLive / $coinUnits

        $lastSatPrice = if ($Pool_Request.charts.price) {[Double]($Pool_Request.charts.price | Select-Object -Last 1)[1]} else {0}
        $satRewardLive = $amountLive * $lastSatPrice

        $amountDay = 0.0
        $satRewardDay = 0.0

        $Divisor = 1e8

        $averageDifficulties = ($Pool_Request.charts.difficulty | Where-Object {$_[0] -gt $timestamp24h} | Foreach-Object {$_[1]} | Measure-Object -Average).Average
        if ($averageDifficulties) {
            $averagePrices = if ($Pool_Request.charts.price) {($Pool_Request.charts.price | Where-Object {$_[0] -gt $timestamp24h} | Foreach-Object {$_[1]} | Measure-Object -Average).Average} else {0}
            if ($averagePrices) {
                $profitDay = 86400/$averageDifficulties*$reward/$Pool_Divisor
                $amountDay = $profitDay/$coinUnits
                $satRewardDay = $amountDay * $averagePrices
            }
        }

        $blocks = $Pool_Request.pool.blocks | Where-Object {$_ -match '^.*?\:(\d+?)\:'} | Foreach-Object {$Matches[1]} | Sort-Object -Descending
        $blocks_measure = $blocks | Where-Object {$_ -gt $timestamp24h} | Measure-Object -Minimum -Maximum
        $Pool_BLK = [int]$(if ($blocks_measure.Maximum - $blocks_measure.Minimum) {24*3600/($blocks_measure.Maximum - $blocks_measure.Minimum)*$blocks_measure.Count})
        $Pool_TSL = if ($blocks.Count) {$timestamp - $blocks[0]}
    
        if (-not (Test-Path "Stats\Pools\$($Name)_$($Pool_Currency)_Profit.txt")) {$Stat = Set-Stat -Name "$($Name)_$($Pool_Currency)_Profit" -Value ($satRewardDay/$Divisor) -Duration (New-TimeSpan -Days 1) -HashRate ($Pool_Request.charts.hashrate | Where-Object {$_[0] -gt $timestamp24h} | Foreach-Object {$_[1]} | Measure-Object -Average).Average -BlockRate $Pool_BLK -Quiet}
        else {$Stat = Set-Stat -Name "$($Name)_$($Pool_Currency)_Profit" -Value ($satRewardLive/$Divisor) -Duration $StatSpan -ChangeDetection $false -HashRate $Pool_Request.pool.hashrate -BlockRate $Pool_BLK -Quiet}
    }
    
    if (($ok -and $Pool_Port -and ($AllowZero -or $Pool_Request.pool.hashrate -gt 0)) -or $InfoOnly) {
        foreach($Pool_Region in $Pool_Regions) {
            [PSCustomObject]@{
                Algorithm     = $Pool_Algorithm_Norm
                CoinName      = $_.coin
                CoinSymbol    = $Pool_Currency
                Currency      = $Pool_Currency
                Price         = $Stat.$StatAverage #instead of .Live
                StablePrice   = $Stat.Week
                MarginOfError = $Stat.Week_Fluctuation
                Protocol      = "stratum+tcp"
                Host          = "$($Pool_HostPath).ingest$(if ($Pool_Region -ne $Pool_Region_Default) {"-$Pool_Region"}).cryptoknight.cc"
                Port          = if (-not $Pool_Port) {$_.port} else {$Pool_Port}
                Ports         = $Pool_Ports
                User          = "$($Wallets.$($_.symbol)){diff:.`$difficulty}"
                Pass          = "{workername:$Worker}"
                Region        = Get-Region $Pool_Region
                SSL           = $False
                Updated       = $Stat.Updated
                PoolFee       = $Pool_Fee
                Workers       = $Pool_Request.pool.miners
                Hashrate      = $Stat.HashRate_Live
                TSL           = $Pool_TSL
                BLK           = $Stat.BlockRate_Average
            }
        }
    }
}
