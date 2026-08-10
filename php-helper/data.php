<?php
error_reporting(E_ALL & ~E_DEPRECATED);
session_start();

require_once __DIR__ . '/vendor/autoload.php';

if (!isset($_SESSION['access_token'])) {
    header("Location: index.php");
    exit;
}

$client = new Google_Client();
$client->setAccessToken($_SESSION['access_token']);

// Ignore SSL for local development
$client->setHttpClient(
    new GuzzleHttp\Client([
        'verify' => false
    ])
);

// Auto-redirect if token expired
if ($client->isAccessTokenExpired()) {
    unset($_SESSION['access_token']);
    header("Location: index.php");
    exit;
}

$http = $client->authorize();

// Format to clean RFC3339 with standard explicit 'Z' UTC trailing designation
$start = (new DateTime("-30 days", new DateTimeZone('UTC')))->format("Y-m-d\TH:i:s\Z");
$end   = (new DateTime("now", new DateTimeZone('UTC')))->format("Y-m-d\TH:i:s\Z");

$dataTypes = [
    "steps",
    "floors", 
    "heart-rate",
    "oxygen-saturation",
    "active-zone-minutes",
    "weight"
];

echo "<h1>Google Health API Dashboard</h1>";

foreach ($dataTypes as $type) {

    $filterType = str_replace('-', '_', $type);
    
    // Enable rollup mode for daily rollup data structures
    $isRollupOnly = ($type === "floors");

    try {
        if ($isRollupOnly) {

    $url = "https://health.googleapis.com/v4/users/me/dataTypes/"
        . $type
        . "/dataPoints:dailyRollUp";

    $startDate = new DateTime(
        "-30 days",
        new DateTimeZone("UTC")
    );

    $endDate = new DateTime(
        "now",
        new DateTimeZone("UTC")
    );

    $postBody = [
        "range" => [
            "start" => [
                "date" => [
                    "year" => (int)$startDate->format("Y"),
                    "month" => (int)$startDate->format("m"),
                    "day" => (int)$startDate->format("d")
                ],
                "time" => [
                    "hours" => 0,
                    "minutes" => 0,
                    "seconds" => 0,
                    "nanos" => 0
                ]
            ],
            "end" => [
                "date" => [
                    "year" => (int)$endDate->format("Y"),
                    "month" => (int)$endDate->format("m"),
                    "day" => (int)$endDate->format("d")
                ],
                "time" => [
                    "hours" => 0,
                    "minutes" => 0,
                    "seconds" => 0,
                    "nanos" => 0
                ]
            ]
        ],
        "windowSizeDays" => 1
    ];

    $response = $http->post($url, [
        'json' => $postBody,
        'verify' => false
    ]);
}else {
            switch ($type) {
                case "steps":
                case "active-zone-minutes":
                    $filter = $filterType . '.interval.start_time >= "' . $start . '" AND ' . $filterType . '.interval.start_time < "' . $end . '"';
                    break;
                default:
                    $filter = $filterType . '.sample_time.physical_time >= "' . $start . '" AND ' . $filterType . '.sample_time.physical_time < "' . $end . '"';
                    break;
            }

            $url = "https://health.googleapis.com/v4/users/me/dataTypes/" . $type . "/dataPoints?filter=" . urlencode($filter);
            
            // Ignore SSL during Guzzle GET request
            $response = $http->get($url, [
                'verify' => false
            ]);
        }

        $body = json_decode($response->getBody(), true);

        echo "<hr>";
        echo "<h2>" . strtoupper(str_replace('-', ' ', $type)) . "</h2>";

        if (isset($body['rollupDataPoints']) || (isset($body['dataPoints']) && !empty($body['dataPoints']))) {

            // 1. STAIRS / FLOORS (ROLLUP LAYER)
            if ($type == "floors") {
                echo "<table border='1' cellpadding='8' style='border-collapse: collapse; width: 100%; text-align: left;'>";
                echo "<tr style='background-color: #f9f0ff;'><th>Day</th><th>Floors Climbed (Sum)</th></tr>";
                foreach ($body['rollupDataPoints'] as $row) {
                    $dateArray = $row['civilStartTime']['date'] ?? ($row['range']['startTime']['date'] ?? []);
                    $dateStr   = !empty($dateArray) ? "{$dateArray['year']}-{$dateArray['month']}-{$dateArray['day']}" : 'N/A';
                    $floorsSum = $row['floors']['count_sum'] ?? ($row['floors']['countSum'] ?? '0');

                    echo "<tr>";
                    echo "<td>" . htmlspecialchars($dateStr) . "</td>";
                    echo "<td>" . htmlspecialchars($floorsSum) . " floors</td>";
                    echo "</tr>";
                }
                echo "</table>";
            }
            
            // 2. STEPS
            elseif ($type == "steps") {
                echo "<table border='1' cellpadding='8' style='border-collapse: collapse; width: 100%; text-align: left;'>";
                echo "<tr style='background-color: #f2f2f2;'><th>Time</th><th>Steps</th><th>Device</th><th>Platform</th></tr>";
                foreach ($body['dataPoints'] as $row) {
                    $startTime = $row['steps']['interval']['start_time'] ?? ($row['steps']['interval']['startTime'] ?? 'N/A');
                    $count     = $row['steps']['count'] ?? '0';
                    $device    = $row['dataSource']['device']['displayName'] ?? 'Unknown Device';
                    $platform  = $row['dataSource']['platform'] ?? 'Unknown Platform';

                    echo "<tr><td>" . htmlspecialchars($startTime) . "</td><td>" . htmlspecialchars($count) . "</td><td>" . htmlspecialchars($device) . "</td><td>" . htmlspecialchars($platform) . "</td></tr>";
                }
                echo "</table>";
            } 

        elseif ($type == "heart-rate") {

    echo "<table border='1' cellpadding='8' style='border-collapse: collapse; width: 100%; text-align: left;'>";
    echo "<tr style='background-color: #fff1f0;'>";
    echo "<th>Time</th>";
    echo "<th>Heart Rate (BPM)</th>";
    echo "<th>Device</th>";
    echo "<th>Platform</th>";
    echo "</tr>";

    foreach ($body['dataPoints'] ?? [] as $row) {

        $heartRate = $row['heartRate'] ?? [];

        $time = $heartRate['sampleTime']['physicalTime'] ?? 'N/A';

        $bpm = $heartRate['beatsPerMinute'] ?? 'N/A';

        $device = $row['dataSource']['device']['displayName']
            ?? 'Unknown Device';

        $platform = $row['dataSource']['platform']
            ?? 'Unknown Platform';

        echo "<tr>";

        echo "<td>" . htmlspecialchars($time) . "</td>";

        echo "<td><strong>"
            . htmlspecialchars((string)$bpm)
            . " BPM</strong></td>";

        echo "<td>"
            . htmlspecialchars($device)
            . "</td>";

        echo "<td>"
            . htmlspecialchars($platform)
            . "</td>";

        echo "</tr>";
    }

    echo "</table>";
}

            // 4. OXYGEN SATURATION (SpO2)
            elseif ($type == "oxygen-saturation") {
                echo "<table border='1' cellpadding='8' style='border-collapse: collapse; width: 100%; text-align: left;'>";
                echo "<tr style='background-color: #e6fffb;'><th>Time</th><th>SpO2 Percentage</th><th>Device</th></tr>";
                foreach ($body['dataPoints'] as $row) {
                    $time       = $row['oxygenSaturation']['sampleTime']['physicalTime'] ?? ($row['oxygenSaturation']['sample_time']['physical_time'] ?? 'N/A');
                    $percentage = $row['oxygenSaturation']['percentage'] ?? 'N/A';
                    $device     = $row['dataSource']['device']['displayName'] ?? 'Unknown Device';

                    echo "<tr><td>" . htmlspecialchars($time) . "</td><td>" . htmlspecialchars($percentage) . "%</td><td>" . htmlspecialchars($device) . "</td></tr>";
                }
                echo "</table>";
            }
            
            // 5. ACTIVE ZONE MINUTES
            elseif ($type == "active-zone-minutes") {
                echo "<table border='1' cellpadding='8' style='border-collapse: collapse; width: 100%; text-align: left;'>";
                echo "<tr style='background-color: #e6f7ff;'><th>Start Time (UTC)</th><th>Zone Minutes</th><th>Heart Rate Zone</th><th>Device</th></tr>";
                foreach ($body['dataPoints'] as $row) {
                    $azmBlock  = $row['activeZoneMinutes'] ?? [];
                    $startTime = $azmBlock['interval']['startTime'] ?? ($azmBlock['interval']['start_time'] ?? 'N/A');
                    $minutes   = $azmBlock['activeZoneMinutes'] ?? '0';
                    $zone      = $azmBlock['heartRateZone'] ?? 'N/A';
                    $device    = $row['dataSource']['device']['displayName'] ?? 'Unknown Device';

                    echo "<tr><td>" . htmlspecialchars($startTime) . "</td><td>" . htmlspecialchars($minutes) . " mins</td><td><strong>" . htmlspecialchars(str_replace('_', ' ', $zone)) . "</strong></td><td>" . htmlspecialchars($device) . "</td></tr>";
                }
                echo "</table>";
            }
            
            // 6. WEIGHT
            elseif ($type == "weight") {
                echo "<table border='1' cellpadding='8' style='border-collapse: collapse; width: 100%; text-align: left;'>";
                echo "<tr style='background-color: #fff0f6;'><th>Time</th><th>Weight</th><th>Device</th></tr>";
                foreach ($body['dataPoints'] as $row) {
                    $time   = $row['weight']['sampleTime']['physicalTime'] ?? ($row['weight']['sample_time']['physical_time'] ?? 'N/A');
                    $weight = $row['weight']['weightKg'] ?? ($row['weight']['weight_kg'] ?? 'N/A');
                    $device = $row['dataSource']['device']['displayName'] ?? 'Manual / Unknown';

                    echo "<tr><td>" . htmlspecialchars($time) . "</td><td>" . htmlspecialchars($weight) . " kg</td><td>" . htmlspecialchars($device) . "</td></tr>";
                }
                echo "</table>";
            }

        } else {
            echo "<p style='color: #666;'>No data available for this range.</p>";
        }

    } catch (Exception $e) {
        echo "<h3>API Error on " . htmlspecialchars($type) . "</h3>";
        echo "<pre style='color: red;'>";
        echo htmlspecialchars($e->getMessage());
        echo "</pre>";
    }
}