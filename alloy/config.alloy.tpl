# Minimal Alloy config template
# Replace placeholders or use simple envsubst before copying.

loki.write "local" {
  endpoint {
    url = "${LOKI_URL:-http://log.ediacarian.home:3100/loki/api/v1/push}"
    # If using TLS with a custom CA, set ca_file path below and ensure alloy can read it
    # ca_file = "${LOKI_CA:-/etc/ssl/certs/ca.crt}"
  }
}

prometheus.remote_write "remote" {
  endpoint {
    url = "${PROM_REMOTE_WRITE:-http://mimir.example:8428/api/v1/push}"
  }
}

# Node exporter style collection (unix socket / proc)
prometheus.exporter.unix "node" {
}

# Read system journal and forward to loki
loki.source.journal "read" {
  forward_to = [
    loki.write.local.receiver,
  ]
  labels = {
    job = "proxmox-host-journal",
  }
}

# Add additional scrape or pipeline blocks below as needed
