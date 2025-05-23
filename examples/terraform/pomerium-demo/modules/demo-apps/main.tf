variable "namespace" {
  type        = string
  description = "Kubernetes namespace for demo apps"
}

variable "domain" {
  type        = string
  description = "Base domain for demo apps"
}

# Hello World Application
resource "kubernetes_deployment" "hello_world" {
  metadata {
    name      = "hello-world"
    namespace = var.namespace
    labels = {
      app = "hello-world"
    }
  }
  
  spec {
    replicas = 2
    
    selector {
      match_labels = {
        app = "hello-world"
      }
    }
    
    template {
      metadata {
        labels = {
          app = "hello-world"
        }
      }
      
      spec {
        container {
          name  = "hello-app"
          image = "gcr.io/google-samples/hello-app:2.0"
          
          port {
            container_port = 8080
          }
          
          env {
            name  = "PORT"
            value = "8080"
          }
          
          resources {
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "100m"
              memory = "128Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "hello_world" {
  metadata {
    name      = "hello-world"
    namespace = var.namespace
  }
  
  spec {
    selector = {
      app = "hello-world"
    }
    
    port {
      port        = 80
      target_port = 8080
    }
    
    type = "ClusterIP"
  }
}

# Grafana for Metrics Demo
resource "kubernetes_deployment" "grafana" {
  metadata {
    name      = "grafana"
    namespace = var.namespace
    labels = {
      app = "grafana"
    }
  }
  
  spec {
    replicas = 1
    
    selector {
      match_labels = {
        app = "grafana"
      }
    }
    
    template {
      metadata {
        labels = {
          app = "grafana"
        }
      }
      
      spec {
        container {
          name  = "grafana"
          image = "grafana/grafana:latest"
          
          port {
            container_port = 3000
          }
          
          env {
            name  = "GF_AUTH_ANONYMOUS_ENABLED"
            value = "true"
          }
          
          env {
            name  = "GF_AUTH_ANONYMOUS_ORG_ROLE"
            value = "Viewer"
          }
          
          env {
            name  = "GF_SECURITY_ADMIN_PASSWORD"
            value = "pomerium-demo"
          }
          
          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }
          
          volume_mount {
            name       = "grafana-storage"
            mount_path = "/var/lib/grafana"
          }
        }
        
        volume {
          name = "grafana-storage"
          empty_dir {}
        }
      }
    }
  }
}

resource "kubernetes_service" "grafana" {
  metadata {
    name      = "grafana"
    namespace = var.namespace
  }
  
  spec {
    selector = {
      app = "grafana"
    }
    
    port {
      port        = 80
      target_port = 3000
    }
    
    type = "ClusterIP"
  }
}

# Protected Admin Panel Demo
resource "kubernetes_deployment" "admin_panel" {
  metadata {
    name      = "admin-panel"
    namespace = var.namespace
    labels = {
      app = "admin-panel"
    }
  }
  
  spec {
    replicas = 1
    
    selector {
      match_labels = {
        app = "admin-panel"
      }
    }
    
    template {
      metadata {
        labels = {
          app = "admin-panel"
        }
      }
      
      spec {
        container {
          name  = "nginx"
          image = "nginx:alpine"
          
          port {
            container_port = 80
          }
          
          volume_mount {
            name       = "html"
            mount_path = "/usr/share/nginx/html"
          }
          
          resources {
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "100m"
              memory = "128Mi"
            }
          }
        }
        
        volume {
          name = "html"
          config_map {
            name = kubernetes_config_map.admin_panel_content.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "admin_panel" {
  metadata {
    name      = "admin-panel"
    namespace = var.namespace
  }
  
  spec {
    selector = {
      app = "admin-panel"
    }
    
    port {
      port        = 80
      target_port = 80
    }
    
    type = "ClusterIP"
  }
}

resource "kubernetes_config_map" "admin_panel_content" {
  metadata {
    name      = "admin-panel-content"
    namespace = var.namespace
  }
  
  data = {
    "index.html" = <<-HTML
      <!DOCTYPE html>
      <html>
      <head>
          <title>Admin Panel - Pomerium Demo</title>
          <style>
              body {
                  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                  margin: 0;
                  padding: 0;
                  background: #f5f5f5;
              }
              .header {
                  background: #1a1a1a;
                  color: white;
                  padding: 20px;
                  text-align: center;
              }
              .container {
                  max-width: 800px;
                  margin: 40px auto;
                  padding: 20px;
                  background: white;
                  border-radius: 8px;
                  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
              }
              .warning {
                  background: #ff5252;
                  color: white;
                  padding: 15px;
                  border-radius: 4px;
                  margin-bottom: 20px;
              }
              .info {
                  background: #e3f2fd;
                  padding: 15px;
                  border-radius: 4px;
                  margin-bottom: 20px;
              }
              code {
                  background: #f5f5f5;
                  padding: 2px 6px;
                  border-radius: 3px;
                  font-family: 'Monaco', 'Menlo', monospace;
              }
          </style>
      </head>
      <body>
          <div class="header">
              <h1>🔒 Protected Admin Panel</h1>
              <p>This page is protected by Pomerium</p>
          </div>
          <div class="container">
              <div class="warning">
                  <strong>⚠️ Restricted Access</strong>
                  <p>This admin panel is only accessible to authorized administrators.</p>
              </div>
              
              <div class="info">
                  <h3>Authentication Info</h3>
                  <p>If you can see this page, you have been successfully authenticated and authorized by Pomerium.</p>
                  <p>Your identity headers are available to the application:</p>
                  <ul>
                      <li><code>X-Pomerium-Claim-Email</code></li>
                      <li><code>X-Pomerium-Claim-Groups</code></li>
                      <li><code>X-Pomerium-Claim-User</code></li>
                      <li><code>X-Pomerium-Jwt-Assertion</code></li>
                  </ul>
              </div>
              
              <h2>Demo Admin Functions</h2>
              <p>This is a demonstration of how Pomerium can protect administrative interfaces.</p>
              
              <h3>Sample Admin Actions:</h3>
              <ul>
                  <li>User Management</li>
                  <li>System Configuration</li>
                  <li>Audit Logs</li>
                  <li>Security Settings</li>
              </ul>
              
              <p><a href="https://www.pomerium.com/docs/">Learn more about Pomerium</a></p>
          </div>
      </body>
      </html>
    HTML
  }
}

# Outputs
output "demo_apps" {
  value = {
    hello_world = {
      service = kubernetes_service.hello_world.metadata[0].name
      port    = kubernetes_service.hello_world.spec[0].port[0].port
    }
    grafana = {
      service = kubernetes_service.grafana.metadata[0].name
      port    = kubernetes_service.grafana.spec[0].port[0].port
    }
    admin_panel = {
      service = kubernetes_service.admin_panel.metadata[0].name
      port    = kubernetes_service.admin_panel.spec[0].port[0].port
    }
  }
}