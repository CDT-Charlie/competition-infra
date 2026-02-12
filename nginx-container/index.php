<?php
# GREYTEAM NOTE: this file should be customized to display a real webpage fitting the competition theme

# database info
$host = "mysql";
$db = "testdb";
$user = "greyteam"; 
$pass = "testpass";

$conn = new mysqli($host, $user, $pass, $db);

if ($conn->connect_error) {
    die("Connection error: " . $conn->connect_error);
}

$result = $conn->query("SELECT message FROM test_table");

while ($row = $result->fetch_assoc()) {
    echo "<p>" . $row['message'] . "</p>"; # display each message in the databse 
}

$result = $conn->query("SELECT name FROM players");
# display a table of players, team, number, position, etc, then customize?
?>