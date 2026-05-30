<?php
/**
 * HotWalletOS Dashboard - Ultra-Silver Industrial
 * Update: Centered Column Data & Headers
 */
 
// 0. Get Balance
$command = "/usr/local/bin/os/get_monero_balance";
exec("nohup sudo /usr/bin/bash $command > /dev/null 2>&1 &");

// 1. Define configurations
$coinConfigs = [
    //"Bitcoin"   => ["dir" => "/var/www/backend/Bitcoin/",   "api_id" => "bitcoin",     "display" => "Bitcoin (BTC)"],
    //"Litecoin"  => ["dir" => "/var/www/backend/Litecoin/",  "api_id" => "litecoin",    "display" => "Litecoin (LTC)"],
    //"Dogecoin"  => ["dir" => "/var/www/backend/Dogecoin/",  "api_id" => "dogecoin",    "display" => "Dogecoin (DOGE)"],
    "Monero"    => ["dir" => "/var/www/backend/Monero/",    "api_id" => "monero",      "display" => "Monero (XMR)"],
    //"Ethereum"  => ["dir" => "/var/www/backend/Ethereum/",  "api_id" => "ethereum",    "display" => "Ethereum (ETH)"],
    //"Avalanche" => ["dir" => "/var/www/backend/Avalanche/", "api_id" => "avalanche-2", "display" => "Avalanche (AVAX)"]
];

// 2. Fetch Prices
$ids = implode(',', array_map(fn($c) => $c['api_id'], $coinConfigs));
$curl = curl_init("https://api.coingecko.com/api/v3/simple/price?ids=$ids&vs_currencies=usd");
curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, false);
curl_setopt($curl, CURLOPT_USERAGENT, "ColdWalletOS/Admin");
$response = curl_exec($curl);
curl_close($curl);
$priceData = json_decode($response, true);

// 3. Process Data
$rows = [];
$totalPortfolioUsd = 0;

foreach ($coinConfigs as $coinName => $config) {
    $dir = $config["dir"];
    $coinPrice = $priceData[$config["api_id"]]["usd"] ?? 0;
    $wallets = glob($dir . "*_balance.txt");

    if ($wallets) {
        foreach ($wallets as $balanceFile) {
            $address = str_replace("_balance.txt", "", basename($balanceFile));
            $unlockedFile = $dir . $address . "_unlocked.txt";

            $balance = file_exists($balanceFile) ? trim(file_get_contents($balanceFile)) : "0.00";
            $unlocked = file_exists($unlockedFile) ? trim(file_get_contents($unlockedFile)) : "0.00";
            
            $usdValue = (float)$balance * (float)$coinPrice;
            $totalPortfolioUsd += $usdValue;

            $rows[] = [
                "type"     => $config["display"],
                "address"  => $address,
                "balance"  => $balance,
                "unlocked" => $unlocked,
                "usd"      => $usdValue
            ];
        }
    }
}

usort($rows, function($a, $b) { return $b['usd'] <=> $a['usd']; });
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="refresh" content="300">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>HotWalletOS</title>
    <style>
        :root {
            --silver-light: #e0e0e0;
            --silver-mid: #C0C0C0;
            --silver-dark: #8e8e8e;
            --matte-black: #0a0a0a;
        }

        body {
            background: radial-gradient(circle at center, #1c1c1c 0%, #000000 100%);
            background-attachment: fixed;
            color: var(--silver-mid);
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
            margin: 0;
            padding: 20px 10px;
            display: flex;
            flex-direction: column;
            align-items: center;
            min-height: 100vh;
        }

        h1 {
            font-size: clamp(2.5rem, 10vw, 4rem); 
            margin: 0;
            letter-spacing: 8px;
            color: var(--silver-light);
            text-transform: none;
            font-weight: 250;
            text-shadow: 0 0 20px rgba(192, 192, 192, 0.2);
            text-align: center;
        }

        .update-tag {
            font-size: 0.8rem;
            color: var(--silver-dark);
            margin-bottom: 20px;
            letter-spacing: 2px;
        }

        .total-container {
            background: linear-gradient(145deg, #1a1a1a, #050505);
            border: 2px solid #444;
            padding: 30px;
            border-radius: 4px;
            text-align: center;
            box-shadow: 0 20px 50px rgba(0,0,0,0.8);
            margin-bottom: 20px;
            position: relative;
            overflow: hidden;
            width: 100%;
            max-width: 1000px;
            box-sizing: border-box;
        }

        .total-container::before {
            content: "";
            position: absolute;
            top: 0; left: 0; right: 0;
            height: 2px;
            background: linear-gradient(to right, transparent, var(--silver-mid), transparent);
        }

        .total-label {
            font-size: 0.8rem;
            color: var(--silver-dark);
            text-transform: uppercase;
            letter-spacing: 4px;
            margin-bottom: 15px;
            display: block;
        }

        .total-amount {
            font-size: clamp(2.5rem, 10vw, 4rem);
            color: #FFFFFF;
            font-weight: 700;
            text-shadow: 0 0 30px rgba(255,255,255,0.1);
        }

        .main-table {
            width: 100%;
            max-width: 1000px;
            background: rgba(255, 255, 255, 0.02);
            border: 2px solid #333;
            border-radius: 8px;
            overflow: hidden;
            border-spacing: 0;
        }

        /* Balanced 4-column grid */
        .th-row, .tr-link {
            display: grid;
            grid-template-columns: 1fr 1fr 1fr 1fr; 
            border-bottom: 2px solid #222;
            text-decoration: none;
            color: inherit;
        }

        .th-row {
            background: linear-gradient(to bottom, #333 0%, #111 100%);
            border-bottom: 2px solid #444;
        }

        .th {
            padding: 15px;
            color: var(--silver-light);
            font-size: 0.7rem;
            text-transform: uppercase;
            letter-spacing: 1px;
            text-align: center; /* Center Header Text */
        }

        .tr-link {
            transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        }

        .tr-link:hover {
            background: rgba(255, 255, 255, 0.05);
            box-shadow: inset 0 0 15px rgba(255, 255, 255, 0.03);
        }

        .td {
            padding: 18px 10px;
            display: flex;
            align-items: center;
            justify-content: center; /* Center Column Content */
            color: var(--silver-mid);
            font-size: 0.9rem;
            text-align: center;
        }

        .status-icon {
            font-size: 1rem;
            margin-right: 8px;
            color: #444;
        }

        .val-usd { 
            color: #FFF; 
            font-weight: bold; 
        }

        /* Footer Command Buttons */
        .footer-nav {
            margin-top: 20px;
            display: flex;
            flex-direction: column;
            gap: 10px;
            align-items: center;
        }

        .btn-cmd {
            display: inline-block;
            padding: 12px 35px;
            background: #000;
            text-decoration: none;
            font-weight: bold;
            letter-spacing: 2px;
            transition: 0.3s;
            text-transform: uppercase;
            border: 2px solid #444;
            text-align: center;
            min-width: 320px;
        }

        .btn-remote { color: var(--silver-light); }
        .btn-remote:hover {
            background: var(--silver-light);
            color: #000;
            border-color: var(--silver-light);
        }

        .btn-shutdown { color: #ff3333; }
        .btn-shutdown:hover {
            background: #ff3333;
            color: #fff;
            border-color: #ff3333;
        }

        @media (max-width: 600px) {
            .th, .td { font-size: 0.65rem; padding: 15px 5px; }
        }
    </style>
</head>
<body>

    <h1>HotWalletOS</h1>
    <div class="update-tag">BALANCE UPDATED EVERY 10-20 MINUTES</div>

    <div class="total-container">
        <span class="total-label">Current Net Balance</span>
        <div class="total-amount">$<?php echo number_format($totalPortfolioUsd, 2); ?></div>
    </div>

    <div class="main-table">
        <div class="th-row">
            <div class="th">Asset</div>
            <div class="th">Address</div>
            <div class="th">Balance</div>
            <div class="th">Value</div>
        </div>

        <?php foreach ($rows as $w): ?>
            <?php 
                $addr = $w["address"];
                $link = htmlspecialchars($addr) . ".php";
                $displayAddr = (strlen($addr) > 8) ? substr($addr, 0, 4) . "..." . substr($addr, -4) : $addr;
                
                $isLocked = ((float)$w["balance"] > (float)$w["unlocked"]);
            ?>
            
            <a href="<?php echo $link; ?>" class="tr-link">
                <div class="td">
                    <span style="color: #fff; font-weight: bold;"><?php echo $w["type"]; ?></span>
                </div>

                <div class="td" style="font-family: 'Roboto Mono', monospace;">
                    <?php echo $displayAddr; ?>
                </div>

                <div class="td">
                    <?php if ($isLocked): ?>
                        <span class="status-icon">&#128274;</span>
                    <?php endif; ?>
                    <?php echo number_format((float)$w["balance"], 7, '.', ''); ?>
                </div>

                <div class="td val-usd">
                    $<?php echo number_format($w["usd"], 2); ?>
                </div>
            </a>
        <?php endforeach; ?>
    </div>

    <div class="footer-nav">
        <a href="remote.php" class="btn-cmd btn-remote">Remote viewing link</a>
        <a href="shutdown.php" class="btn-cmd btn-shutdown">Shutdown System</a>
    </div>

</body>
</html>
