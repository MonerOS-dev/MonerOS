<?php
/**
 * HotWalletOS Dashboard - Ultra-Silver Industrial
 * Update: Centered Column Data & Headers
 */

if (isset($_GET['action']) && $_GET['action'] === 'start_basicswap') {
    // Run as user 'user' instead of default root, preserving DISPLAY=:0 permissions
    shell_exec('sudo -n -u user /usr/bin/bash /usr/local/bin/start-dashboard > /dev/null 2>&1 &');
    header("Location: " . strtok($_SERVER["REQUEST_URI"], '?')); 
    exit;
}
 
// 0. Get Balance
$command = "/usr/local/bin/os/get_crypto_balances";
exec("nohup sudo /usr/bin/bash $command > /dev/null 2>&1 &");

// 1. Define configurations
$coinConfigs = [
    "Bitcoin" => ["dir" => "/var/www/backend/Bitcoin/", "key" => "bitcoin", "display" => "Bitcoin (BTC)"],
    "Monero"  => ["dir" => "/var/www/backend/Monero/",  "key" => "monero",  "display" => "Monero (XMR)"],
];

// 2. Fetch Prices from GitHub raw prices.json
$rawUrl = "https://gist.githubusercontent.com/MonerOS-dev/b715a2d6610d7ffd88a2231ae3576ff1/raw/prices.json";
$curl = curl_init($rawUrl);
curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
curl_setopt($curl, CURLOPT_TIMEOUT, 5);
curl_setopt($curl, CURLOPT_USERAGENT, "HotWalletOS/Admin");
$response = curl_exec($curl);
$httpCode = curl_getinfo($curl, CURLINFO_HTTP_CODE);
curl_close($curl);

$priceData = [];
if ($httpCode === 200 && $response) {
    $parsed = json_decode($response, true);
    if (isset($parsed['prices'])) {
        $priceData = $parsed['prices'];
    }
}

// Fallback to local cache if GitHub fetch drops momentarily
$cacheFile = '/tmp/hotwalletos_prices_cache.json';
if (!empty($priceData)) {
    file_put_contents($cacheFile, json_encode($priceData));
} elseif (file_exists($cacheFile)) {
    $priceData = json_decode(file_get_contents($cacheFile), true) ?? [];
}

// 3. Process Data
$rows = [];
$totalPortfolioUsd = 0;

foreach ($coinConfigs as $coinName => $config) {
    $dir = $config["dir"];
    $coinPrice = (float)($priceData[$config["key"]] ?? 0);
    $wallets = glob($dir . "*_balance.txt");

    if ($wallets) {
        foreach ($wallets as $balanceFile) {
            $address = str_replace("_balance.txt", "", basename($balanceFile));
            $unlockedFile = $dir . $address . "_unlocked.txt";

            $balance = file_exists($balanceFile) ? trim(file_get_contents($balanceFile)) : "0.00";
            $unlocked = file_exists($unlockedFile) ? trim(file_get_contents($unlockedFile)) : "0.00";
            
            $usdValue = (float)$balance * $coinPrice;
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
    <title>MonerOS</title>
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
            padding: 40px 0; /* Changed horizontal padding to 0 since we control width directly */
            display: flex;
            flex-direction: column;
            align-items: center;
            min-height: 100vh;
        }

        h1 {
            /* Slower scaling (4.5vw) so it stays normal on laptops, but reaches 7rem on big screens */
            font-size: clamp(3rem, 4.5vw, 7rem);
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
            border: 3px solid #444;
            padding: 30px;
            border-radius: 4px;
            text-align: center;
            box-shadow: 0 20px 50px rgba(0,0,0,0.8);
            margin-bottom: 20px;
            position: relative;
            overflow: hidden;
            width: 95vw; /* Always 95% of screen width */
            box-sizing: border-box; /* Prevents padding from breaking the 95vw rule */
        }

        .total-container::before {
            content: "";
            position: absolute;
            top: 0; left: 0; right: 0;
            height: 3px;
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
            /* Starts at a normal 2.5rem, scales slowly, but caps at a massive 10rem on TVs */
            font-size: clamp(2.5rem, 5vw, 10rem); 
            color: #FFFFFF;
            font-weight: 700;
            text-shadow: 0 0 30px rgba(255,255,255,0.1);
        }

        .main-table {
            width: 95vw; /* Always 95% of screen width */
            background: rgba(255, 255, 255, 0.02);
            border: 3px solid #333;
            border-radius: 8px;
            overflow: hidden;
            border-spacing: 0;
            box-sizing: border-box;
            position: relative;
        }

        .main-table::before {
            content: "";
            position: absolute;
            top: 0; left: 0; right: 0;
            height: 2px;
            background: linear-gradient(to right, transparent, var(--silver-mid), transparent);
            z-index: 1; /* Ensures the strip stays on top of background layers */
        }

        /* Balanced 4-column grid */
        .th-row, .tr-link {
            display: grid;
            grid-template-columns: 1fr 1fr 1fr 1fr; 
            border-bottom: 3px solid #333;
            text-decoration: none;
            color: inherit;
        }

        .tr-link:last-child {
            border-bottom: none;
        }

        .th-row {
            background: linear-gradient(to bottom, #333 0%, #111 100%);
            border-bottom: 3px solid #444;
        }

        .th {
            padding: 15px;
            color: var(--silver-light);
            /* Keeps headers normal on desktops, scales up to 2.2rem on big screens */
            font-size: clamp(0.65rem, 1.3vw, 2.2rem); 
            text-transform: uppercase;
            letter-spacing: 1px;
            text-align: center;
        }

        .tr-link {
            transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        }

        .tr-link:hover {
            background: rgba(255, 255, 255, 0.05);
            box-shadow: inset 0 0 15px rgba(255, 255, 255, 0.03);
        }

        .td {
            padding: 18px 5px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: var(--silver-mid);
            /* Keeps table text readable on normal screens, scales up to 2.5rem on big screens */
            font-size: clamp(0.75rem, 1.5vw, 2.5rem); 
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
            width: 95vw;
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
            border: 3px solid #444;
            text-align: center;
            width: 100%;
            max-width: 320px; /* Prevents button from stretching entirely across huge TVs */
            box-sizing: border-box;
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
        
        .btn-basicswap { 
            color: #59cbe8; 
        }
        .btn-basicswap:hover {
            background: #59cbe8;
            color: #000;
            border-color: #59cbe8;
        }
        
        .tag-warning {
            font-size: 0.8rem;
            color: black;
            background-color: yellow;
            padding: 8px 12px;
            margin: 0 auto 20px auto;
            letter-spacing: 2px;
            text-transform: uppercase;
            text-align: center;
            width: 95vw;
            max-width: 95vw;
            box-sizing: border-box;
            border-radius: 4px;
        }                

    </style>
</head>
<body>

    <h1>MonerOS</h1>
    <div class="update-tag">BALANCE UPDATED EVERY 10-20 MINUTES</div>
    
    <?php if (file_exists('/var/www/html/monero.down')): ?>
        <div class="tag-warning">Monero node appears to be down - balance may not be accurate</div>
    <?php endif; ?>

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
        <?php if (file_exists('/var/www/backend/bs.en')): ?>
            <a href="?action=start_basicswap" class="btn-cmd btn-basicswap">Open BasicSwap</a>
        <?php endif; ?>
        <a href="remote.php" class="btn-cmd btn-remote">Remote viewing link</a>
        <a href="shutdown.php" class="btn-cmd btn-shutdown">Shutdown System</a>
    </div>

</body>
</html>
