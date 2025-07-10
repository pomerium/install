# Pomerium Zero Helm Chart

This Helm chart deploys Pomerium Zero, an identity-aware access proxy, on a Kubernetes cluster.

## Prerequisites

- Kubernetes 1.28+
- Helm 3.8.0+
- A valid Pomerium Zero token

## Installing the Chart

`helm install my-release oci://docker.io/pomerium/pomerium-zero --set pomeriumZeroToken=your-pomerium-zero-token`

**Note:** Replace `your-pomerium-zero-token` with your actual Pomerium Zero token.

## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:

`helm uninstall my-release`

## Configuration

The following table lists the configurable parameters of the Pomerium Zero chart and their default values.

| Parameter           | Description                         | Default             |
| ------------------- | ----------------------------------- | ------------------- |
| `pomeriumZeroToken` | Pomerium Zero token (required)      | `""`                |
| `image.repository`  | Image repository                    | `pomerium/pomerium` |
| `image.tag`         | Image tag                           | `v0.30.0`           |
| `image.pullPolicy`  | Image pull policy                   | `IfNotPresent`      |
| `replicaCount`      | Number of replicas                  | `1`                 |
| `resources`         | CPU/Memory resource requests/limits | `{}`                |
| `service.type`      | Service type                        | `ClusterIP`         |
| `service.port`      | Service port                        | `443`               |

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example:

`helm install my-release oci://docker.io/pomerium/pomerium-zero --set pomeriumZeroToken=your-pomerium-zero-token,replicaCount=2`

Alternatively, a YAML file that specifies the values for the parameters can be provided while installing the chart. For example:

`helm install my-release oci://docker.io/pomerium/pomerium-zero -f values.yaml`

## Upgrading the Chart

To upgrade the `my-release` deployment:

`helm upgrade my-release oci://docker.io/pomerium/pomerium-zero --set pomeriumZeroToken=your-pomerium-zero-token`

## Exposing Pomerium Zero

This Helm chart deploys Pomerium Zero with a LoadBalancer service type, making it externally accessible. This configuration is suitable for cloud environments that support LoadBalancer services.

### Important Notes:

1. **LoadBalancer IP**: After deployment, it may take a few minutes for the LoadBalancer IP to be assigned. You can check the status using:

   ```
   kubectl get svc -n <namespace> <release-name>
   ```

2. **Firewall Rules**: Depending on your environment, you may need to configure firewall rules or security groups to allow traffic to the LoadBalancer.

3. **Costs**: Be aware that using a LoadBalancer service may incur additional costs in cloud environments.

Remember to properly secure your Pomerium Zero instance to ensure the safety of your applications and data.

## Support

For support, please refer to the [Pomerium documentation](https://www.pomerium.com/docs/) or open an issue on the [Pomerium GitHub repository](https://github.com/pomerium/pomerium).

## License

This Helm chart is available under the [Apache 2.0 License](https://www.apache.org/licenses/LICENSE-2.0).
