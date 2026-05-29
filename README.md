## Welcome to Gh0stn0des easy-n8n repository. 

## General Information

This repo contains a dockerfile which allows you to install N8N on Ubuntu Server. It has been Tested on Ubuntu 26.04 LTS. It also contains a script to set up your .env properly. I have attached an example file. 

## General Installation

* Clone the repo using `git clone [repo address].git`
* Make the script executable using `chmod +x generate-secrets.sh`
* Run the script usng `./generate-secrets.sh`
* The script will generate a .env file, set up a secure password for the postgres database and also generate your encryption key for n8n.
* The script will then ask if you want to enter your host,protocol and webhook url. 
* Keep the generated `.env` file in the repository root so Compose can load it into each service.
* Once the script has finished then type `docker compose up -d` and everything should come up.
* On Ubuntu Server you may have to `sudo` certain commands  

## Troubleshooting

Do not start the docker container until you have run the generate secrets script. What happens is N8N builds its own key and it doesnt match the key in the docker compose / env file and causes the container not to start. 

If you have already made this mistake you can either edit the key on the n8n data volume or remove the volume and run the install again. 
