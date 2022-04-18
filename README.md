# my-eks-cluster

## EKS Cluster with Managed node group
terraform/initial-working-cluster

terraforn version 1.1.x

`init/plan/appy`


```
aws eks update-kubeconfig --region us-east-1 --name k8s-eks-lab-tf --profile Foghorn
kubectl get nodes
```

## Flux
https://fluxcd.io/docs/get-started/

### Bootstrap Flux and Deploy

Install CLI

```
brew install fluxcd/tap/flux
```
Install on cluster (once per cluster)

```
export GITHUB_TOKEN=<your-token>
export GITHUB_USER=<your-username
```

```
flux check --pre
```

```
flux bootstrap github \
  --owner=$GITHUB_USER \
  --repository=my-eks-cluster \
  --branch=master \
  --path=./clusters/my-cluster \
  --personal
```

Create source (once per repo)

```
flux create source git my-eks-cluster \
  --url=https://github.com/dnlloyd/my-eks-cluster \
  --branch=master \
  --interval=30s \
  --export > ./clusters/my-cluster/my-eks-cluster-source.yaml
```

```
git add -A && git commit -m 'flux src'
git push origin master
```

Deploy project (once per repo)

```
flux create kustomization my-web \
  --target-namespace=web \
  --source=my-eks-cluster \
  --path="./apps/web" \
  --prune=true \
  --interval=5m \
  --export > ./clusters/my-cluster/my-web/web-kustomization.yaml

```

```
git add -A && git commit -m 'flux kust'
git push origin master

```

```
flux get kustomizations --watch
```

### Flux Image Automation

This appears to do the following:

- Scan image repo for latest image (based on policy)
- Update the deployment config file with image and commit it to github

I don't believe this can work with the current config

Re-bootstrap w/ extra components

```
export GITHUB_TOKEN=<your-token>
export GITHUB_USER=<your-username
```

```
flux bootstrap github \
  --components-extra=image-reflector-controller,image-automation-controller \
  --owner=$GITHUB_USER \
  --repository=my-eks-cluster \
  --branch=master \
  --path=./clusters/my-cluster \
  --personal
```

```
flux create image repository basic-web-lighttpd \
--image=docker.io/dnlloyd/basic-web-lighttpd \
--interval=1m \
--export > ./clusters/my-cluster/basic-web-lighttpd-registry.yaml

```

```
flux get image repository basic-web-lighttpd
```

```
flux create image policy basic-web-lighttpd \
--image-ref=basic-web-lighttpd \
--select-semver=0.1.x \
--export > ./clusters/my-cluster/basic-web-lighttpd-policy.yaml
```

```
git add -A && git commit -m 'flux kust'
git push origin master
```

```
flux reconcile kustomization flux-system --with-source

flux get image policy basic-web-lighttpd
```


This portion appears to be where we break - nothing ever gets written to github
flux create image update flux-system \

```
--git-repo-ref=my-eks-cluster \
--git-repo-path="./clusters/my-cluster" \
--checkout-branch=master \
--push-branch=master \
--author-name=fluxcdbot \
--author-email=fluxcdbot@users.noreply.github.com \
--commit-template="{{range .Updated.Images}}{{println .}}{{end}}" \
--export > ./clusters/my-cluster/flux-system-automation.yaml
```

```
git add -A && git commit -m 'Flux: image update'
git push origin master
```

```
flux reconcile kustomization flux-system --with-source
```

Example app
https://github.com/stefanprodan/podinfo/tree/master/kustomize
