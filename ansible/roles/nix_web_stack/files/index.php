<?php
require 'config.php';
$teams = $pdo->query("SELECT * FROM teams")->fetchAll();
?>

<!DOCTYPE html>
<html>
<head>
    <title>1980 Miracle on Ice</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <h1>1980 Miracle on Ice: USA vs Soviet Union</h1>

    <?php foreach ($teams as $team): ?>
        <section>
            <h2><?= htmlspecialchars($team['team_name']) ?></h2>

            <table>
                <tr>
                    <th>No.</th>
                    <th>Pos.</th>
                    <th>Name</th>
                    <th>Age</th>
                    <th>Hometown</th>
                    <th>College / Club</th>
                </tr>

                <?php
                $stmt = $pdo->prepare("SELECT * FROM players WHERE team_id = ? ORDER BY player_number");
                $stmt->execute([$team['id']]);

                foreach ($stmt as $player):
                ?>
                <tr>
                    <td><?= $player['player_number'] ?></td>
                    <td><?= htmlspecialchars($player['position']) ?></td>
                    <td><?= htmlspecialchars($player['player_name']) ?></td>
                    <td><?= $player['age'] ?></td>
                    <td><?= htmlspecialchars($player['hometown']) ?></td>
                    <td><?= htmlspecialchars($player['club_college']) ?></td>
                </tr>
                <?php endforeach; ?>
            </table>
        </section>
    <?php endforeach; ?>
</body>
</html>