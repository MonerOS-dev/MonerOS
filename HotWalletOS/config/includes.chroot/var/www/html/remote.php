<?php
/**
 * HotWalletOS - Remote Access View
 */
$onion_file = '/var/www/html/onion_address.txt';
$qr_file = 'onion_address.png';

$onion_addr = file_exists($onion_file) ? trim(file_get_contents($onion_file)) : "ADDRESS NOT FOUND";

// Ensure protocol for clickable link
$href = (stripos($onion_addr, 'http') === 0) ? $onion_addr : "http://" . $onion_addr;
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>HotWalletOS - Remote Access</title>
    <style>
        :root {
            --silver-light: #e0e0e0;
            --silver-mid: #C0C0C0;
            --silver-dark: #8e8e8e;
            --matte-black: #0a0a0a;
            --glow-green: #00ff41;
        }

        body {
            background: radial-gradient(circle at center, #1c1c1c 0%, #000000 100%);
            background-attachment: fixed;
            color: var(--silver-mid);
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
            margin: 0;
            padding: 20px 10px; /* Tightened padding */
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
            margin-bottom: 20px; /* Reduced margin */
            letter-spacing: 2px;
            text-transform: uppercase;
        }

        .container {
            background: linear-gradient(145deg, #1a1a1a, #050505);
            border: 2px solid #444;
            padding: 20px; /* Tightened internal padding */
            border-radius: 4px;
            box-shadow: 0 20px 50px rgba(0,0,0,0.8);
            position: relative;
            overflow: hidden;
            width: 100%;
            max-width: 550px;
            box-sizing: border-box;
            text-align: center;
            margin-bottom: 20px;
        }

        .container::before {
            content: "";
            position: absolute;
            top: 0; left: 0; right: 0;
            height: 2px;
            background: linear-gradient(to right, transparent, var(--silver-mid), transparent);
        }

        .qr-frame {
            background: #FFFFFF; 
            padding: 10px; 
            display: block; 
            /* Centers the frame and keeps the bottom margin */
            margin: 0 auto 20px auto; 
            border-radius: 2px;
            box-shadow: 0 0 15px rgba(255,255,255,0.1);
            box-sizing: border-box; 
            /* Limits growth on desktop, fills width on mobile */
            max-width: 350px; 
            width: 100%;
        }

        .qr-frame img {
            display: block;
            /* Ensures image fills the 350px frame */
            width: 100%; 
            height: auto;
        }

        .address-box {
            width: 100%;
            padding: 12px;
            background: rgba(0, 0, 0, 0.6);
            border: 2px solid #333;
            color: var(--glow-green);
            font-family: 'Roboto Mono', monospace;
            box-sizing: border-box;
            word-break: break-all;
            margin-bottom: 20px;
            font-size: 0.85rem;
            border-radius: 2px;
        }

        .address-box a {
            color: var(--glow-green);
            text-decoration: none;
            opacity: 0.9;
        }

        .address-box a:hover {
            opacity: 1;
            text-decoration: underline;
        }

        .btn-cmd {
            display: block;
            width: 100%;
            padding: 14px;
            background: #000;
            color: var(--silver-light);
            text-decoration: none;
            font-weight: bold;
            letter-spacing: 2px;
            transition: 0.3s;
            text-transform: uppercase;
            border: 2px solid #444;
            text-align: center;
            cursor: pointer;
            box-sizing: border-box;
        }

        .btn-cmd:hover {
            background: var(--silver-light);
            color: #000;
            border-color: var(--silver-light);
        }

        .status-msg {
            color: #ff3333;
            font-size: 0.75rem;
            font-family: 'Roboto Mono', monospace;
            margin-bottom: 15px;
            text-transform: uppercase;
        }
    </style>
</head>
<body>

    <h1>HotWalletOS</h1>
    <div class="update-tag">Tor Browser Remote Access</div>

    <div class="container">
        <?php if (file_exists($qr_file)): ?>
            <div class="qr-frame">
                <img src="<?php echo $qr_file; ?>" alt="Onion QR Code">
            </div>
        <?php else: ?>
            <div class="status-msg">IMAGE FILE NOT FOUND: <?php echo htmlspecialchars($qr_file); ?></div>
        <?php endif; ?>

        <div class="address-box">
            <a href="<?php echo htmlspecialchars($href); ?>" target="_blank">
                <?php echo htmlspecialchars($onion_addr); ?>
            </a>
        </div>

        <a href="index.php" class="btn-cmd">Return to Dashboard</a>
    </div>

</body>
</html>