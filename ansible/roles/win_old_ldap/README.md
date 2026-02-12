Author: Winter Sager
02.04.26

This repository contains two Ansible playbooks:

1. LDAP-Setup.yml
   Installs and configures OpenLDAP, sets up the MDB database, and loads the base directory structure.

2. Features.yml 
   Features implements the following features
   - Create an LDAP group
   - Create a user
   - Add User to Group 
   - Create a file on a server owned by that group. 

## Required Files

The variable files for each one are listed in the vars folder with ldap being for the Setup playbook and ldap_users is for the Features playbook. 

Also needed:
	1. base.ldif to setup the LDAP environment.
    2. inventory.ini for the Linux target, base and admin. 
	3. ansible.cfg for the ansible playbook command.


## Running the Playbooks

Run the setup playbook first:

To run the playbook, use the following command:
	ansible-playbook LDAP-Setup.yml

To access the features run the following command:
	ansible-playbook Features.yml

