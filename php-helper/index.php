<?php
error_reporting(E_ALL & ~E_DEPRECATED);
session_start();

require_once __DIR__ . '/vendor/autoload.php';

$client = new Google_Client();

$client->setAuthConfig(__DIR__ . '/client_secret.json');
$client->setRedirectUri('http://localhost:8000/callback.php');

$client->setScopes([
    'https://www.googleapis.com/auth/googlehealth.activity_and_fitness.readonly',
    'https://www.googleapis.com/auth/googlehealth.health_metrics_and_measurements.readonly'
]);

$client->setAccessType('offline');
$client->setPrompt('consent select_account');

// Ignore SSL for local development
$client->setHttpClient(
    new GuzzleHttp\Client([
        'verify' => false
    ])
);

// Check if user is already logged in with a valid token
if (isset($_SESSION['access_token'])) {
    $client->setAccessToken($_SESSION['access_token']);
    if ($client->isAccessTokenExpired()) {
        unset($_SESSION['access_token']);
    }
}

// Redirect to Google Auth if no valid token exists
if (!isset($_SESSION['access_token'])) {
    header("Location: " . $client->createAuthUrl());
    exit;
}
?>
<!DOCTYPE html>
<html>
<head>
    <title>Google Health API Demo</title>
</head>
<body>

<h2>Google Health API</h2>

<p>Authorization Successful.</p>

<p>
    <a href="data.php">Read Health Data</a>
</p>

<p>
    <a href="logout.php">Logout</a>
</p>

</body>
</html>