## Welcome to Gh0stn0des easy-n8n repository. 

## General Information

This repo contains a dockerfile which allows you to install N8N on Ubuntu Server. It has been Tested on Ubuntu 26.04 LTS. It also contains a script to set up your .env properly. I have attached an example file. 

## General Installation

* Clone the repo using "git clone [repo address].git"
* Make the script executable using 'chmod +x generate-secrets.sh'
* Run the script usng './generate-secrets.sh'
* The script will generate a .env file, set up a secure password for the postgres database and also generate your encryption key for n8n.
* The script will then ask if you want to enter your host,protocol and webhook url. 
* Once the script has finished then type 'docker compose up -d' and everything should come up.
* On Ubuntu Server you may have to 'sudo' certain commands  