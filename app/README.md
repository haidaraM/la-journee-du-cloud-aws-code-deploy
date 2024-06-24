# App

Ce repertoire contient le code applicatif du projet.

## Lancer en local

1. Copier le fichier `.env.sample` vers `.env`: `cp .env.sample .env`
2. Démarrer l'application avec `docker compose up`.
3. Lancer les migrations et la collecte des fichiers statiques: `docker compose exec app ./collect-and-migrate.sh`
4. Accéder à l'application via le `http://localhost:${APP_PORT}`. Example: http://localhost:8001/
