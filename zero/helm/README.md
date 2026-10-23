# Pomerium Zero Helm Chart

This Helm chart deploys Pomerium Zero, an identity-aware access proxy, on a Kubernetes cluster.

## Prerequisites

- Kubernetes 1.28+
- Helm 3.8.0+
- A valid Pomerium Zero token

## Installing the Chart

### From OCI Registry

```sh
helm install pomerium-zero oci://docker.io/pomerium/pomerium-zero \
  -n pomerium-zero \
  --set pomeriumZeroToken=your-pomerium-zero-token
```

### From Source

```sh
git clone https://github.com/pomerium/install.git
cd install/zero/helm

helm install pomerium-zero . \
  -n pomerium-zero \
  --set pomeriumZeroToken=your-pomerium-zero-token
```

**Note:** Replace `your-pomerium-zero-token` with your actual Pomerium Zero token.

## Uninstalling the Chart

```sh
helm uninstall pomerium-zero -n pomerium-zero
```

## Configuration

| Parameter | Description | Default |
| --- | --- | --- |
| `pomeriumZeroToken` | Pomerium Zero token (required unless existingSecret is set) | `""` |
| `existingSecret.name` | Use a pre-existing secret instead of creating one | `""` |
| `existingSecret.key` | Key in the existing secret | `"pomerium_zero_token"` |
| `createNamespace` | Create the target namespace | `true` |
| `serviceAccount.annotations` | Annotations for the ServiceAccount (e.g. workload identity) | `{}` |
| `image.repository` | Image repository | `pomerium/pomerium` |
| `image.tag` | Image tag (defaults to appVersion) | `""` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `replicaCount` | Number of replicas | `1` |
| `resources` | CPU/Memory resource requests/limits | `{}` |
| `service.type` | Service type | `LoadBalancer` |
| `service.port` | Service port | `443` |
| `service.nodePort` | NodePort (when service.type is NodePort) | |
| `persistence.enabled` | Use StatefulSet with PVC for persistent storage | `true` |
| `persistence.storageClass` | Storage class (empty uses cluster default) | `""` |
| `persistence.size` | PVC size | `1Gi` |
| `persistence.accessModes` | PVC access modes | `[ReadWriteOnce]` |
| `probes.enabled` | Render the default HTTP probes (they fail in Zero mode, see [Health probes](#health-probes)) | `false` |
| `probes.startupProbe` | Startup probe that replaces the default; rendered even when `probes.enabled` is false | `{}` |
| `probes.livenessProbe` | Liveness probe that replaces the default; rendered even when `probes.enabled` is false | `{}` |
| `probes.readinessProbe` | Readiness probe that replaces the default; rendered even when `probes.enabled` is false | `{}` |
| `lifecycle` | Container lifecycle hooks, e.g. a `preStop` sleep | `{}` |
| `terminationGracePeriodSeconds` | Pod termination grace period | Kubernetes default |
| `minReadySeconds` | Seconds a new pod must stay ready before it counts as available | `0` |
| `topologySpreadConstraints` | Pod topology spread constraints | `[]` |

Specify parameters using `--set key=value` or provide a YAML values file:

```sh
helm install pomerium-zero oci://docker.io/pomerium/pomerium-zero \
  -n pomerium-zero -f values.yaml
```

### Persistence

By default, the chart deploys a **StatefulSet** with a PersistentVolumeClaim for databroker state and bootstrap configuration. This means data survives pod restarts without requiring RBAC permissions to write back to Kubernetes Secrets.

To disable persistence and use the legacy **Deployment** mode (bootstrap config stored in a Kubernetes Secret):

```sh
helm install pomerium-zero oci://docker.io/pomerium/pomerium-zero \
  -n pomerium-zero \
  --set pomeriumZeroToken=your-token \
  --set persistence.enabled=false
```

### Health probes

Pomerium serves `/startupz`, `/healthz` and `/readyz` on its health server. In Zero mode that server listens on `127.0.0.1:28080` and the address can't be changed yet, so the kubelet can't reach the default HTTP probes (`probes.enabled`). Until it can, run the probe inside the container with `pomerium health`, which reads `/status` from the local health server:

```yaml
probes:
  readinessProbe:
    exec:
      command:
        - /bin/pomerium
        - health
        - -e
        - zero.bootstrap-config.save
        - -e
        - zero.connect
        - -e
        - zero.telemetry.collect-and-send
        - -e
        - routes.reachable
    initialDelaySeconds: 5
    periodSeconds: 5
    timeoutSeconds: 5
    failureThreshold: 2
```

`pomerium health` fails on any reported check that isn't `RUNNING` or carries an error. The excluded checks are the ones the HTTP probes leave out as well. On clusters that cap service account token lifetime, `zero.bootstrap-config.save` reports an error once the token expires ([pomerium/pomerium#6842](https://github.com/pomerium/pomerium/issues/6842)). Add `-e storage.backend` if a short database outage shouldn't take every replica out of rotation at once.

Behind a load balancer, combine the readiness probe with a `preStop` delay that is longer than the load balancer needs to stop sending new connections to a pod. The image has no `sleep` binary, so use the `sleep` action (Kubernetes 1.30+):

```yaml
lifecycle:
  preStop:
    sleep:
      seconds: 30
terminationGracePeriodSeconds: 60
```

## Upgrading the Chart

```sh
helm upgrade pomerium-zero oci://docker.io/pomerium/pomerium-zero \
  -n pomerium-zero \
  --set pomeriumZeroToken=your-pomerium-zero-token
```

## Exposing Pomerium Zero

This Helm chart deploys Pomerium Zero with a LoadBalancer service type, making it externally accessible. This configuration is suitable for cloud environments that support LoadBalancer services.

### Important Notes

1. **LoadBalancer IP**: After deployment, it may take a few minutes for the LoadBalancer IP to be assigned. You can check the status using:

   ```sh
   kubectl get svc -n pomerium-zero
   ```

2. **Firewall Rules**: Depending on your environment, you may need to configure firewall rules or security groups to allow traffic to the LoadBalancer.

3. **Costs**: Be aware that using a LoadBalancer service may incur additional costs in cloud environments.

## Development

### Prerequisites

- [helm](https://helm.sh/docs/intro/install/)
- [yq](https://github.com/mikefarah/yq)

### Testing

```sh
make test
```

### Makefile Targets

| Target | Description |
| --- | --- |
| `make lint` | Run `helm lint` |
| `make test` | Lint + run unit tests |
| `make template` | Render templates (StatefulSet mode) |
| `make template-deployment` | Render templates (Deployment mode) |
| `make package` | Lint, test, and package chart |

## Support

For support, please refer to the [Pomerium documentation](https://www.pomerium.com/docs/) or open an issue on the [Pomerium GitHub repository](https://github.com/pomerium/pomerium).

## License

This Helm chart is available under the [Apache 2.0 License](https://www.apache.org/licenses/LICENSE-2.0).
