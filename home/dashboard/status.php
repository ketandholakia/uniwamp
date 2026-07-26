<?php
declare(strict_types=1);

$root = dirname(__DIR__, 2);
require __DIR__ . '/shared.php';

$state = dashboardLoadState($root);
dashboardHandleRequest($state);

header('Content-Type: application/json; charset=UTF-8');
header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
header('Pragma: no-cache');

echo json_encode(
    [
        'generatedAtUtc' => gmdate('c'),
        'dashboard' => $state,
    ],
    JSON_UNESCAPED_SLASHES | JSON_PRETTY_PRINT
);
