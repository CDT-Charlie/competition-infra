CREATE DATABASE IF NOT EXISTS miracle_ice; 
USE miracle_ice;

CREATE TABLE IF NOT EXISTS teams (
    id INT AUTO_INCREMENT PRIMARY KEY,
    team_name VARCHAR(255) NOT NULL
);

INSERT IGNORE INTO teams (team_name) VALUES ('United States'), ('Soviet Union');

CREATE TABLE IF NOT EXISTS players (
    id INT AUTO_INCREMENT PRIMARY KEY, 
    team_id INT NOT NULL,
    player_num INT NOT NULL,
    position VARCHAR(20) NOT NULL, 
    player_name VARCHAR(255) NOT NULL,
    age INT NOT NULL,
    hometown VARCHAR(255) NOT NULL,
    club_college VARCHAR(255) NOT NULL,
    FOREIGN KEY (team_id) REFERENCES teams(id)
); 

-- United States Players
INSERT IGNORE INTO players (team_id, player_num, position, player_name, age, hometown, club_college) VALUES
(1,30,'G','Jim Craig',22,'North Easton, MA','Boston U.'),
(1,3,'D','Ken Morrow',23,'Flint, MI','Bowling Green'),
(1,5,'D','Mike Ramsey',19,'Minneapolis, MN','Minnesota'),
(1,10,'C','Mark Johnson',22,'Madison, WI','Wisconsin'),
(1,24,'LW','Rob McClanahan',22,'Saint Paul, MN','Minnesota'),
(1,8,'RW','Dave Silk',21,'Scituate, MA','Boston U.'),
(1,6,'D','Bill Baker (A)',22,'Grand Rapids, MN','Minnesota'),
(1,9,'C','Neal Broten',20,'Roseau, MN','Minnesota'),
(1,23,'RW','Dave Christian',20,'Warroad, MN','North Dakota'),
(1,11,'RW','Steve Christoff',21,'Richfield, MN','Minnesota'),
(1,21,'LW','Mike Eruzione (C)',25,'Winthrop, MA','Boston U.'),
(1,28,'RW','John Harrington',22,'Virginia, MN','Minnesota-Duluth'),
(1,1,'G','Steve Janaszak',22,'Saint Paul, MN','Minnesota'),
(1,17,'D','Jack O''Callahan',22,'Charlestown, MA','Boston U.'),
(1,16,'C','Mark Pavelich',21,'Eveleth, MN','Minnesota-Duluth'),
(1,25,'LW','Buzz Schneider',25,'Grand Rapids, MN','Minnesota'),
(1,19,'RW','Eric Strobel',21,'Rochester, MN','Minnesota'),
(1,20,'D','Bob Suter',22,'Madison, WI','Wisconsin'),
(1,27,'LW','Phil Verchota',22,'Duluth, MN','Minnesota'),
(1,15,'C','Mark Wells',21,'St. Clair Shores, MI','Bowling Green') ON CONFLICT DO NOTHING;

-- Soviet Union Players
INSERT IGNORE INTO players (team_id, player_num, position, player_name, age, hometown, club_college) VALUES
(2,20,'G','Vladislav Tretiak',27,'Orudyevo','CSKA Moscow'),
(2,2,'D','Viacheslav Fetisov',21,'Moscow','CSKA Moscow'),
(2,7,'D','Alexei Kasatonov',20,'Leningrad','CSKA Moscow'),
(2,16,'C','Vladimir Petrov',32,'Krasnogorsk','CSKA Moscow'),
(2,17,'LW','Valeri Kharlamov',32,'Moscow','CSKA Moscow'),
(2,13,'RW','Boris Mikhailov (C)',35,'Moscow','CSKA Moscow'),
(2,19,'RW','Helmuts Balderis',27,'Riga','CSKA Moscow'),
(2,14,'D','Zinetula Bilyaletdinov',24,'Moscow','Dynamo Moscow'),
(2,23,'RW','Aleksandr Golikov',27,'Penza','Dynamo Moscow'),
(2,25,'C','Vladimir Golikov',25,'Penza','Dynamo Moscow'),
(2,9,'LW','Vladimir Krutov',19,'Moscow','CSKA Moscow'),
(2,11,'RW','Yuri Lebedev',28,'Moscow','Krylya Sovetov Moscow'),
(2,24,'RW','Sergei Makarov',21,'Chelyabinsk','CSKA Moscow'),
(2,10,'C/RW','Aleksandr Maltsev',30,'Kirovo-Chepetsk','Dynamo Moscow'),
(2,1,'G','Vladimir Myshkin',24,'Kirovo-Chepetsk','Dynamo Moscow'),
(2,5,'D','Vasili Pervukhin',24,'Penza','Dynamo Moscow'),
(2,26,'LW','Aleksandr Skvortsov',25,'Gorky','Torpedo Gorky'),
(2,12,'D','Sergei Starikov',21,'Chelyabinsk','CSKA Moscow'),
(2,6,'D','Valeri Vasiliev (A)',30,'Gorky','Dynamo Moscow'),
(2,22,'C','Viktor Zhluktov',26,'Inta','CSKA Moscow') ON CONFLICT DO NOTHING;