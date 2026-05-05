<?php
/**
 * HotWalletOS - System Shutdown
 */
$message = "";
$shutdown_triggered = false;

if (isset($_GET['action']) && $_GET['action'] === 'shutdown') {
    // Reverted to background execution for reliability
    shell_exec('sudo bash /usr/local/bin/os/safe_shutdown > /dev/null 2>&1 &');
    $message = "SYSTEM IS SHUTTING DOWN...";
    $shutdown_triggered = true;
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <?php if ($shutdown_triggered): ?>
    <meta http-equiv="refresh" content="1;url=index.php">
    <?php endif; ?>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>HotWalletOS - System</title>
    <style>
        :root {
            --silver-light: #e0e0e0;
            --silver-mid: #C0C0C0;
            --silver-dark: #8e8e8e;
            --matte-black: #0a0a0a;
            --glow-green: #00ff41;
            --alert-red: #ff3333;
        }

        body {
            background: radial-gradient(circle at center, #1c1c1c 0%, #000000 100%);
            background-attachment: fixed;
            color: var(--silver-mid);
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
            margin: 0;
            padding: 20px 10px; /* Top-aligned industrial padding */
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
            text-transform: uppercase;
        }

        .container {
            background: linear-gradient(145deg, #1a1a1a, #050505);
            border: 2px solid #444;
            padding: 20px;
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

        .status-msg {
            color: var(--alert-red);
            font-family: 'Roboto Mono', monospace;
            font-size: 1.1rem;
            margin: 20px 0;
            letter-spacing: 1px;
            text-transform: uppercase;
            font-weight: bold;
        }

        .warning-text {
            color: var(--silver-dark);
            font-size: 0.75rem;
            letter-spacing: 1px;
            margin-bottom: 25px;
            line-height: 1.5;
        }

        .btn-cmd {
            display: block;
            width: 100%;
            padding: 14px;
            background: #000;
            text-decoration: none;
            font-weight: bold;
            letter-spacing: 2px;
            transition: 0.3s;
            text-transform: uppercase;
            border: 2px solid #444;
            text-align: center;
            cursor: pointer;
            box-sizing: border-box;
            margin-bottom: 12px;
        }

        .btn-silver { 
            color: var(--silver-light); 
        }
        .btn-silver:hover {
            background: var(--silver-light);
            color: #000;
            border-color: var(--silver-light);
        }

        .btn-red {
            color: var(--alert-red);
            border-color: #500;
        }
        .btn-red:hover {
            background: var(--alert-red);
            color: #fff;
            border-color: var(--alert-red);
        }
    </style>
</head>
<body>

    <h1>HotWalletOS</h1>
    <div class="update-tag">System Control</div>

    <div class="container">
        <?php if ($shutdown_triggered): ?>
            <div class="status-msg"><?php echo $message; ?></div>
            <p class="warning-text">
                Power-off sequence initiated.<br>
                Terminating sessions...
            </p>
        <?php else: ?>
            <p class="warning-text">
                WARNING: THIS WILL TERMINATE ALL ACTIVE SESSIONS AND POWER DOWN THE HARDWARE SAFELY.
            </p>
            
            <a href="?action=shutdown" class="btn-cmd btn-red">Execute Shutdown</a>
            <a href="index.php" class="btn-cmd btn-silver">Cancel</a>
        <?php endif; ?>
    </div>

</body>
</html>