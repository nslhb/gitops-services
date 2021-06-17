## Services

This directory is used to define the K8S resource definitions for your service.

## Kustomize

In the more recent versions, we have adopted [Kustomize][1] to create K8S resources that reduces the need for writing a lot of boilerplate code.
With a very small effort, one can create a full-fledged microservice deployment.

> kustomize lets you customize raw, template-free YAML files for multiple purposes, leaving the original YAML untouched and usable as is.

## How to use Kustomize

The `/base` directory contains the foundational YAML scripts to set up a service on nslhub's K8S environment. You will notice that this folder contains several files, each corresponding to a K8S resource. Each file is setup with a default configuration.

There is a special file called `kustomization.yaml`. This file is a config file for the `Kustomize` generator.

The files in the `/base` directory can be inherited in your `service` directories, if you want to make any changes to the configurations or add any additional resource or configuration.

To do this, you need to create a different directory, `/gateway` for example. In this directory, create a `kustomization.yaml` file, which looks something like:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namePrefix: gateway
namespace: apps
commonLabels:
  app: gateway
bases:
  - ../base/

images:
  - name: app
    newName: 516580504223.dkr.ecr.ap-south-1.amazonaws.com/gateway
patchesJson6902:
  - target:
      kind: VirtualService
      name: -vs
      group: networking.istio.io
      version: v1alpha3
    path: ingress-patch.json
```

If you notice, the `kustomization.yaml` file includes the `base` directory via the `bases:` directive. This means that
the entire configuration of `/base/kustomization.yaml` is now available for use for `gateway`

In addition to that, `Kustomize` allows you to override specific details in the following two ways:

1. You can use the default directives such as `images`, `namePrefix` etc.
2. You can create patch files that essentially patch a section of the corresponding default file present in `/base`.

Here is a sample patch file:

```yaml
---

- op: replace
  path: /spec/http/0/match/0/uri/prefix
  value: /gw
- op: replace
  path: /spec/http/0/route/0/destination/host
  value: gateway
- op: replace
  path: /spec/http/0/name
  value: gateway-routes

``` 

This patch file is applied on the VirtualService resource as defined by:

```yaml
patchesJson6902:
  - target:
      kind: VirtualService
      name: -vs
      group: networking.istio.io
      version: v1alpha3
    path: ingress-patch.json
```

## Resources
1. https://github.com/kubernetes-sigs/kustomize
2. https://github.com/kubernetes-sigs/kustomize/blob/master/examples/jsonpatch.md
3. https://kustomize.io/tutorial
4. https://www.youtube.com/watch?v=ahMIBxufNR0

[1]: https://github.com/kubernetes-sigs/kustomize