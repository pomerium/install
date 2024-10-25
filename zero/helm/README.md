# Pomerium Zero Helm Chart

This Helm chart deploys Pomerium Zero, an identity-aware access proxy, on a Kubernetes cluster.

## Prerequisites

- Kubernetes 1.16+
- Helm 3.0+
- A valid Pomerium Zero token

## Installing the Chart

1. Add the Pomerium Helm repository:

`helm repo add pomerium https://helm.pomerium.io`
`helm repo update`

2. Install the chart with a release name (e.g., `my-release`):

`helm install my-release pomerium/pomerium-zero --set pomeriumZeroToken=your-pomerium-zero-token`

**Note:** Replace `your-pomerium-zero-token` with your actual Pomerium Zero token.

## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:

`helm uninstall my-release`

## Configuration

The following table lists the configurable parameters of the Pomerium Zero chart and their default values.

| Parameter | Description | Default |
|-----------|-------------|---------|
| `pomeriumZeroToken` | Pomerium Zero token (required) | `""` |
| `image.repository` | Image repository | `pomerium/pomerium` |
| `image.tag` | Image tag | `v0.27.2` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `replicaCount` | Number of replicas | `1` |
| `resources` | CPU/Memory resource requests/limits | `{}` |
| `service.type` | Service type | `ClusterIP` |
| `service.port` | Service port | `443` |

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example:

`helm install my-release pomerium/pomerium-zero --set pomeriumZeroToken=your-pomerium-zero-token,replicaCount=2`

Alternatively, a YAML file that specifies the values for the parameters can be provided while installing the chart. For example:

`helm install my-release pomerium/pomerium-zero -f values.yaml`

## Upgrading the Chart

To upgrade the `my-release` deployment:

`helm upgrade my-release pomerium/pomerium-zero --set pomeriumZeroToken=your-pomerium-zero-token`

## Accessing Pomerium Zero

After deploying the chart, you can access Pomerium Zero by port-forwarding the service:

`kubectl port-forward svc/my-release-pomerium-zero 8443:443`

Then, access Pomerium Zero at: https://localhost:8443

## Support

For support, please refer to the [Pomerium documentation](https://www.pomerium.com/docs/) or open an issue on the [Pomerium GitHub repository](https://github.com/pomerium/pomerium).

## License

This Helm chart is available under the [Apache 2.0 License](https://www.apache.org/licenses/LICENSE-2.0).

## Testing

This chart includes a test to verify that the Pomerium Zero service is running and healthy. To run the test after installation, use the following command:

```bash
helm test <release-name>
```

This will create a test pod that attempts to access the `/healthz` endpoint of the Pomerium Zero service. If the test is successful, it indicates that the service is up and responding to health checks.
