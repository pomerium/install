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
| `pomeriumZeroToken` | Pomerium Zero token (required) | `""` |
| `createNamespace` | Create the target namespace | `true` |
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
