# rsyslog on Linux
Note: this setup only supports one central log server.

How to run:
1. go to ``inventory.ini`` and configure central log server IP and client machine IPs
2. Run ``ansible-playbook -i inventory.ini c_syslog.yml cli_syslog.yml`` in that order.
-- c_syslog.yml configures the main server, which must be up before configuring the clients
3. Logs will be found at ``/var/log/remote/`` under its respective machine name and respective service log file.

Logs are automatically rotated every 1 hour if the log file exceeds 100KB.
Rotated files will be located at the same directory where they are found (turned into a zip file).