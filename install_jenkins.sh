#!/bin/bash

# Nettoyage des ressources existantes
echo "Nettoyage des ressources Docker existantes..."
docker stop jenkins jenkins-docker || true
docker rm jenkins jenkins-docker || true
docker network rm jenkins || true

# Création du réseau Jenkins
echo "Création du réseau jenkins..."
docker network create jenkins

# Création des volumes pour stocker les données de Jenkins
echo "Création des volumes..."
docker volume create jenkins-data

# Exécution du conteneur Jenkins avec BlueOcean (inclut Docker et les plugins nécessaires)
echo "Démarrage du conteneur Jenkins avec BlueOcean..."
# Notez le changement de port ici (8080 -> 8081)
docker run --name jenkins --detach \
  --network jenkins \
  --volume jenkins-data:/var/jenkins_home \
  --volume /var/run/docker.sock:/var/run/docker.sock \
  --publish 8081:8080 --publish 50000:50000 \
  jenkinsci/blueocean

# Récupération du mot de passe administrateur initial
echo "Attente du démarrage de Jenkins..."
sleep 60
echo "Le mot de passe administrateur initial de Jenkins est:"
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
echo "Jenkins est accessible à l'adresse: http://localhost:8081"
echo "Utilisez le mot de passe ci-dessus pour la configuration initiale."
