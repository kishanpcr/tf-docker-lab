# -------------------------------------------------
# 1. Private network per workspace
# -------------------------------------------------
resource "docker_network" "app_net" {
  name = "net-${terraform.workspace}"
}

# -------------------------------------------------
# 2. Custom Nginx image with status page
# -------------------------------------------------
resource "docker_image" "status_nginx" {
  name = "status-nginx:${terraform.workspace}"

  build {
    context    = "."
    dockerfile = "Dockerfile.nginx"
  }

  triggers = {
    script_hash = filesha256("files/generate_status.sh")
  }
}

# -------------------------------------------------
# 3. Web container with health check
# -------------------------------------------------
resource "docker_container" "web" {
  name  = "web-${terraform.workspace}"
  image = docker_image.status_nginx.name

  ports {
    internal = 80
    external = terraform.workspace == "prod" ? 8080 : 8081
  }

  networks_advanced {
    name = docker_network.app_net.name
  }

  env = [
    "DB_HOST=db-${terraform.workspace}",
    "DB_PORT=5432",
    "ENVIRONMENT=${terraform.workspace}"
  ]

  # Health check: curl status page every 10s
  healthcheck {
    test     = ["CMD", "curl", "-f", "http://localhost"]
    interval = "10s"
    timeout  = "5s"
    retries  = 3
    start_period = "30s"
  }
}

# -------------------------------------------------
# 4. PostgreSQL container with health check
# -------------------------------------------------
resource "docker_container" "db" {
  name  = "db-${terraform.workspace}"
  image = "postgres:15-alpine"

  env = [
    "POSTGRES_DB=app_${terraform.workspace}",
    "POSTGRES_USER=admin",
    "POSTGRES_PASSWORD=secret123"
  ]

  ports {
    internal = 5432
    external = terraform.workspace == "prod" ? 5433 : 5434
  }

  volumes {
    container_path = "/var/lib/postgresql/data"
    host_path      = "/home/kitta/tf-lab/data/${terraform.workspace}"
  }

  networks_advanced {
    name = docker_network.app_net.name
  }

  # Health check: pg_isready
  healthcheck {
    test     = ["CMD", "pg_isready", "-U", "admin"]
    interval = "10s"
    timeout  = "5s"
    retries  = 5
    start_period = "30s"
  }
}  # Test change
