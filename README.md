# Replicated Embedded Cluster AMI

## TL;DR

1. Copy `secrets/REDACTED-params.yaml` to `secrets/params.yaml` and update for
   your AWS account.
2. Log in with the Replicated CLI 
3. Run `make ami:${SLUG}/${CHANNEL}` to build an AMI from the Embedded Cluster
   running your application in airgap mode.
