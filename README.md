# element-docker-demo

WIP of a docker-compose Matrix 2.0 stack to show off EW + EC + EX + Synapse + MAS + livekit.

Not remotely intended for serious production usage, but just to be the simplest possible way to get a
hacker-friendly Matrix 2.0 stack up and running without requiring any k8s.

In future, ESS will support migrating from this (which should be trivial, in terms of copying the env vars and secrets
into their ESS counterparts, and rehoming the postgres).

## To run

```
./setup.sh
docker compose up
```

![Screenshot 2024-11-04 at 03 05 28](https://github.com/user-attachments/assets/c3127f3c-ae0c-43cb-bfe9-88f4be56e0af)

## To admin

```
# To register a user
docker compose exec mas mas-cli -c /data/config.yaml manage register-user
```

```
# if you change the OIDC clients in MAS:
docker compose exec mas mas-cli -c /data/config.yaml config sync --prune
```

## Diagnostics

```
# check that OIDC is working - useful for debugging TLS problems
docker compose exec mas mas-cli -c /data/config.yaml doctor
````

## Todo

 * [x] sort out the networking
 * [x] make nginx do something useful when running on a local workstation
 * [x] hook up letsencrypt to nginx properly
 * [x] hook up livekit properly
 * [x] make it work
 
