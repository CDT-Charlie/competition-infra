-- Initialize database and create greyteam user
-- GREYTEAM NOTE: this script should be customized to populate database with real themed data for competition

CREATE database IF NOT EXISTS testdb; 

CREATE USER IF NOT EXISTS 'greyteam'@'%' IDENTIFIED BY 'testpass';
GRANT ALL PRIVILEGES ON testdb.* TO 'greyteam'@'%';

-- Create example table for testing
use testdb; 

CREATE TABLE IF NOT EXISTS test_table (
    id INT AUTO_INCREMENT PRIMARY KEY,
    message VARCHAR(255)
);

-- Create example table entries to be displayed on example webpage
INSERT INTO test_table (message) VALUES
('Team Charlie example website connected to MySQL database successfully!'),
('Example message 2'),
('I hope this works...');


CREATE TABLE IF NOT EXISTS players {
    if INT AUTO_INCREMENT PRIMARY KEY, 
    name VARCHAR(50), 
    team VARCHAR(50), 
    player_number INT, 
    position VARCHAR(10), 
}