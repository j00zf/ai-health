<?php
error_reporting(E_ALL & ~E_DEPRECATED);
session_start();

require_once __DIR__ . '/vendor/autoload.php';

$client = new Google_Client();

$client->setAuthConfig(__DIR__ . '/client_secret.json');
$client->setRedirectUri('http://localhost:8000/callback.php');

// Ignore SSL for local development
$client->setHttpClient(
    new GuzzleHttp\Client([
        'verify' => false
    ])
);

if (isset($_GET['code'])) {

    $token = $client->fetchAccessTokenWithAuthCode($_GET['code']);

    if (isset($token['error'])) {
        die("Error fetching access token: " . htmlspecialchars($token['error']));
    }

    $_SESSION['access_token'] = $token;

    header("Location: index.php");
    exit;
}

echo "Authorization Failed or missing code.";