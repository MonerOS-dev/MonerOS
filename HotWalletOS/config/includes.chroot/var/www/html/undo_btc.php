<?php

$address = $_POST['address'] ?? '';
$safe_addr = basename($address);

if (!empty($safe_addr)) {
    $target_dir = "/mnt/sallyport/watch_bitcoin/{$safe_addr}/";

    $cmd = "sudo /usr/bin/bash /usr/local/bin/os/undo_bitcoin_tx " . escapeshellarg($target_dir);

    shell_exec($cmd);
}

header("Location: " . $safe_addr . ".php");
exit;
?>