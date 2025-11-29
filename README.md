# Inception

## Description
`Inception` is a system administration and DevOps project at **42**.  
The goal is to set up a complete **infrastructure of services** using **Docker** and **docker-compose**.  
This project introduces concepts like **containerization**, **service orchestration**, and **network isolation**.

## Features
- Custom **Dockerfiles** for each service  
- Services running in isolated containers:
  - **NGINX** (reverse proxy with TLS)  
  - **WordPress** (PHP application)  
  - **MariaDB** (database)  
- Persistent data storage with Docker **volumes**  
- Container orchestration with **docker-compose**  
- Secure configuration with environment variables  
- Automatic restart policies  

## Tech Stack
- **Containerization:** Docker, docker-compose  
- **Services:** NGINX, WordPress, MariaDB  
- **Operating System:** Debian (VM)

## Learn Outcomes
- Learned to write and configure Dockerfiles for custom services
- Understood how to use docker-compose for multi-container orchestration
- Gained experience in setting up a reverse proxy with TLS
- Practiced managing databases and persistent storage in containers
- Improved skills in automation and reproducible system setups
