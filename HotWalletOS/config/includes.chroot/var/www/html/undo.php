<?php
// undo.php - Triggers the bash undo script

$address = $_POST['address'] ?? '';
$safe_addr = basename($address);

if (!empty($safe_addr)) {
    $target_dir = "/mnt/sallyport/watch_monero/{$safe_addr}/";
    
    // Construct the command calling the new bash script with sudo
    $cmd = "sudo /usr/bin/bash /usr/local/bin/os/undo_monero_tx " . escapeshellarg($target_dir);
    
    // Execute it
    shell_exec($cmd);
}

// Redirect back to the wallet page
header("Location: " . $safe_addr . ".php");
exit;
?>