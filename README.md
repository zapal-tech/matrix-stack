# element-docker-demo

element-docker-demo is a minimal example of how to rapidly stand up a Matrix 2.0 stack on macOS or Linux using Docker,
featuring:

 * Element Web
 * Element Call
 * Synapse
 * Matrix Authentication Service
 * LiveKit
 * Postgres
 * nginx + letsencrypt / mkcert for TLS.

This is **not** intended for serious production usage, but instead as a tool for curious sysadmins to easily experiment
with Matrix 2.0 in a simple docker compose environment.  As of Nov 2024, it's considered beta.

In particular, this has:
 * No support, security or maintenance guarantees whatsoever
 * No high availability, horizontal scalability, elastic scaling, clustering, backup etc.
 * No admin interface
 * No UDP traffic or TURN for LiveKit (all traffic is tunnelled over TCP for simplicity)
 * No integration manager, integrations, or identity lookup server

For production-grade Matrix from Element, please see https://element.io/server-suite (ESS).

## To run

Install [Docker Compose](https://docs.docker.com/compose/install/). Then:

```
./setup.sh
docker compose up
```

![docker demo](https://github.com/user-attachments/assets/c17e42f7-3442-478a-9ae4-ad2709885386)

## To configure

Check the .env file, or customise the templates in `/data-templates` and then `docker compose down && docker compose up -d`.

In particular, you may wish to:
 * Point at your own SMTP server rather than mailhog
 * Use your own reverse proxy rather than the provided nginx
 * Use your own database cluster

## To admin

```
# To register a user
docker compose exec mas mas-cli -c /data/config.yaml manage register-user
```

## Diagnostics

```
# check that OIDC is working - useful for debugging TLS problems
docker compose exec mas mas-cli -c /data/config.yaml doctor
````
