<?php
require 'config.php';

$result = $pdo->query("SELECT COUNT(*) as total FROM players")->fetch();

if ($result['total'] >= 40) {
    echo "OK";
} else {
    http_response_code(500);
    echo "FAIL";
}
?>