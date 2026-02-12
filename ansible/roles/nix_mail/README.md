# Mail Server Playbook
### Author: Swapnil Acharjee

This deploys both Dovecot and Postfix with SASL and TLS support preconfigured. The current implementation uses self signed SSL and PAM authentication for the mail server. This is subject to change and does need iteration to be fully usable.
## Requirements
### Variables
* `C`: This is the country code required to generate the SSL cert.
* `ST`: This is the state/province name for the SSL cert.
* `L`: This is the Locale to be used for the SSL cert.
* `O`: This is the Organization name to be used for the SSL cert.
* `OU`: This is the Organizational Unit to be used for the SSL cert.
* `CN`: This is a common name for the SSL cert.
* `pf_hostname`: This is the hostname that Postfix will use.
* `pf_domain`: This is the domain that Postfix will use.
* `pf_allowed_networks`: This is a list of subnets that Postfix will allow unauthenticated.
### Files
#### `dovecot.conf`
This is the main configuration file for Dovecot. This creates a basic inbox for whichever users authenticate. As previously said, this uses PAM authentication in order for users to access it. Dovecot is also configured to provide unix sockets for LMTP as well as authentication for Postfix to use.
#### `postfix.conf.j2`
This is the main configuration file for Postfix, saved at `/etc/postfix/main.cf`. This is a fairly basic file that sets up TLS to secure SMTP, while also configuring the domain for Postfix. All mail that is directed to a user is meant to be sent to Dovecot via LMTP for safekeeping. Postfix also piggybacks off Dovecot's authentication scheme to authenticate its users as well, maintaining parity between users
