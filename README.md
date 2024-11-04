# element-quick-start

WIP of a docker-copmose Matrix 2.0 stack to show off EW + EC + EX + Synapse + MAS + livekit.

Not remotely intended for serious production usage, but just to be the simplest possible way to get a
hacker-friendly Matrix 2.0 stack up and running without requiring any k8s.

In future, ESS will support migrating from this (which should be trivial, in terms of copying the env vars and secrets
into their ESS counterparts, and rehoming the postgres).

## To run

```
cp .env-sample .env
# edit the .env to configure your environment
docker compose up
```

## Todo

 * [ ] sort out the networking
 * [ ] make nginx do something useful when running on a local workstation
 * [ ] hook up letsencrypt to nginx properly
 * [ ] hook up livekit properly
 * [ ] make it work
