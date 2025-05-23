# Pomerium Demo Environment Setup

This guide provides instructions for deploying the official Pomerium demo environment at demo.pomerium.com.

## Overview

The demo environment showcases Pomerium's key features:
- **Ingress Controller**: Kubernetes-native ingress management
- **Enterprise Console**: Centralized policy management
- **Identity-Aware Proxy**: Secure access to web applications
- **TCP Proxy**: SSH access through Pomerium
- **Multi-App Support**: Various demo applications with different policies

## Prerequisites

1. **GCP Project**: Access to `pomerium-public-demo` project
2. **Terraform**: Version 1.0 or higher
3. **Google Cloud SDK**: Authenticated with appropriate permissions
4. **Pomerium Enterprise License**: Valid license key
5. **Docker Registry Access**: Credentials for docker.cloudsmith.io

## Directory Structure

```
examples/
├── terraform/
│   ├── pomerium-demo/          # Complete demo environment
│   ├── gke-cluster/            # Standalone GKE cluster module
│   └── ingress-controller/     # Basic ingress controller example
├── helm/
│   └── pomerium-zero/          # Helm values examples
└── kustomize/
    └── demo-apps/              # Demo application manifests
```

## Deployment Steps

### 1. Configure Terraform Variables

```bash
cd terraform/pomerium-demo
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your credentials:
```hcl
pomerium_license_key       = "YOUR_LICENSE_KEY"
pomerium_registry_password = "YOUR_REGISTRY_PASSWORD"

# OAuth Provider (Google recommended for demo)
idp_provider      = "google"
idp_client_id     = "YOUR_CLIENT_ID"
idp_client_secret = "YOUR_CLIENT_SECRET"

demo_administrators = [
  "admin@pomerium.com",
  "demo@pomerium.com"
]
```

### 2. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review the deployment plan
terraform plan

# Deploy the infrastructure
terraform apply
```

This creates:
- GKE cluster with Workload Identity
- Cloud SQL for Enterprise storage
- Static IP for load balancer
- SSH demo VM
- All necessary firewall rules

### 3. Configure DNS

After deployment, configure DNS records:

1. Get the LoadBalancer IP:
   ```bash
   kubectl get svc pomerium-proxy -n pomerium-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
   ```

2. Create wildcard DNS record:
   ```
   *.demo.pomerium.com → [LoadBalancer IP]
   ```

### 4. Access Demo Applications

Once DNS propagates, access:

- **Verify Service**: https://verify.demo.pomerium.com
  - Public access with identity headers
  - Shows user information after authentication

- **Hello World**: https://hello.demo.pomerium.com
  - Requires @pomerium.com or @pomerium.io email

- **Admin Panel**: https://admin.demo.pomerium.com
  - Restricted to admin@pomerium.com only

- **Grafana**: https://grafana.demo.pomerium.com
  - Available to pomerium.com domain or engineering group

- **Enterprise Console**: https://console.demo.pomerium.com
  - Administrative interface for policy management

### 5. Test SSH Proxy

Install Pomerium CLI:
```bash
brew install pomerium/tap/pomerium-cli
# or
curl https://scripts.pomerium.com/install.sh | bash
```

Connect via SSH:
```bash
pomerium-cli tcp --listen stdio ssh.demo.pomerium.com:22 \
  | ssh -o "ProxyCommand=/dev/stdin" demo@localhost
```

Default credentials:
- Username: `demo`
- Password: `pomerium-demo`

## Demo Features

### 1. Policy Examples

The demo includes various policy patterns:

**Public with Identity**:
```yaml
allow_public_unauthenticated_access: true
pass_identity_headers: true
```

**Domain-based Access**:
```yaml
- allow:
    or:
      - domain:
          is: pomerium.com
```

**User-specific Access**:
```yaml
- allow:
    and:
      - email:
          is: admin@pomerium.com
```

### 2. TCP Proxy

Demonstrates secure SSH access through Pomerium:
- No direct SSH exposure
- Identity-based access control
- Full audit logging

### 3. Enterprise Features

- Centralized policy management
- Audit logs and compliance
- External data sources
- Device trust (optional)

## Customization

### Adding Applications

1. Deploy your app to the cluster
2. Create an Ingress with Pomerium annotations:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app
  annotations:
    ingress.pomerium.io/policy: |
      - allow:
          or:
            - email:
                ends_with: "@example.com"
spec:
  ingressClassName: pomerium
  rules:
  - host: myapp.demo.pomerium.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-app
            port:
              number: 80
```

### Modifying Policies

Use the Enterprise Console or edit the Pomerium CRD:

```bash
kubectl edit pomerium global -n pomerium-system
```

## Monitoring

### Metrics

Prometheus metrics available at:
```bash
kubectl port-forward -n pomerium-system svc/pomerium-metrics 9090:9090
```

### Logs

View logs:
```bash
# Ingress controller logs
kubectl logs -n pomerium-system -l app.kubernetes.io/name=pomerium-ingress-controller

# Proxy logs
kubectl logs -n pomerium-system -l app.kubernetes.io/name=pomerium-proxy
```

## Troubleshooting

### Common Issues

1. **DNS Not Resolving**
   - Verify wildcard DNS record
   - Check TTL settings

2. **Authentication Errors**
   - Verify OAuth credentials
   - Check callback URLs include https://authenticate.demo.pomerium.com/oauth2/callback

3. **502 Bad Gateway**
   - Check backend service is running
   - Verify service names and ports in Ingress

4. **SSH Connection Failed**
   - Ensure VM is running
   - Check firewall rules
   - Verify internal IP in TCP route configuration

### Debug Commands

```bash
# Check Pomerium pods
kubectl get pods -n pomerium-system

# View Pomerium configuration
kubectl get pomerium -n pomerium-system -o yaml

# Check ingress status
kubectl get ingress -A

# Test backend connectivity
kubectl exec -n pomerium-system deployment/pomerium-ingress-controller -- \
  curl -v http://verify.pomerium-demo-apps.svc.cluster.local
```

## Cleanup

To remove the demo environment:

```bash
cd terraform/pomerium-demo
terraform destroy
```

This removes:
- GKE cluster and all workloads
- Cloud SQL instance
- SSH VM
- All GCP networking resources

## Security Considerations

For production use:
1. Enable private GKE nodes
2. Restrict authorized networks
3. Use Cloud Armor for DDoS protection
4. Enable Binary Authorization
5. Implement proper secret management
6. Regular security scanning

## Support

- Documentation: https://www.pomerium.com/docs/
- Community: https://discuss.pomerium.com/
- Enterprise Support: support@pomerium.com