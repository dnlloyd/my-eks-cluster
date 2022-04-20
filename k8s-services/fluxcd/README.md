# FluxCD - Continous Delivery for kubernetes

_NOTE:_ this is a manually deployed service.

## Versions
- [v1.18.0](./base/v0.18.0)
- [v0.19.0](./base/v0.19.0)
- [v0.20.1](./base/v0.20.1)
- [v0.20.2](./base/v0.20.2) - current

## secrets
the secrets are encrypted with sops.

- [botkube-communication-secret](/k8s-services/fluxcd/overlays/common/secrets_flux-git-deploy.enc.yaml) - this is the ssh key for github auth

an example unencrypted version of the secret is below.

```
apiVersion: v1
data:
  identity: {{ base64 of the below file text }}
kind: Secret
metadata:
  labels:
    app.kubernetes.io/instance: flux
    app.kubernetes.io/managed-by: Kustomize
    app.kubernetes.io/name: flux
  name: flux-git-deploy
  namespace: flux
type: Opaque
```

### installation

as this is a manually deployed service the following commands will be useful.

in the root of this repo run the following commands.
```
kubectl create ns flux ;
kubectl apply -k ./k8s-services/fluxcd/overlays/common ;
```

## configuration

all the important configuration options can be found in [overlays/dev/patches/deployment-args.yaml](overlays/dev/patches/deployment-args.yaml)

with the largest change variance being `--git-path` which should contain a comma separated list of the folders to handle deployment for.
