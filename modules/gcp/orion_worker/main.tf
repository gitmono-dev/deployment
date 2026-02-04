locals {
  namespace = var.namespace

  container_env = merge(
    {
      ORION_WORKER_START_SCORPIO = var.orion_worker_start_scorpio ? "true" : "false"
      SCORPIO_STORE_PATH         = var.scorpio_store_path
      SCORPIO_WORKSPACE          = var.scorpio_workspace
      BUCK_PROJECT_ROOT          = var.buck_project_root
      BUILD_TMP                  = var.build_tmp

      SCORPIO_GIT_AUTHOR         = var.scorpio_git_author
      SCORPIO_GIT_EMAIL          = var.scorpio_git_email

      SCORPIO_DICFUSE_READABLE            = var.scorpio_dicfuse_readable
      SCORPIO_LOAD_DIR_DEPTH              = var.scorpio_load_dir_depth
      SCORPIO_FETCH_FILE_THREAD           = var.scorpio_fetch_file_thread
      SCORPIO_DICFUSE_IMPORT_CONCURRENCY  = var.scorpio_dicfuse_import_concurrency
      SCORPIO_DICFUSE_DIR_SYNC_TTL_SECS   = var.scorpio_dicfuse_dir_sync_ttl_secs
      SCORPIO_DICFUSE_STAT_MODE           = var.scorpio_dicfuse_stat_mode
      SCORPIO_DICFUSE_OPEN_BUFF_MAX_BYTES = var.scorpio_dicfuse_open_buff_max_bytes
      SCORPIO_DICFUSE_OPEN_BUFF_MAX_FILES = var.scorpio_dicfuse_open_buff_max_files

      ANTARES_LOAD_DIR_DEPTH              = var.antares_load_dir_depth
      ANTARES_DICFUSE_STAT_MODE           = var.antares_dicfuse_stat_mode
      ANTARES_DICFUSE_OPEN_BUFF_MAX_BYTES = var.antares_dicfuse_open_buff_max_bytes
      ANTARES_DICFUSE_OPEN_BUFF_MAX_FILES = var.antares_dicfuse_open_buff_max_files
      ANTARES_DICFUSE_DIR_SYNC_TTL_SECS   = var.antares_dicfuse_dir_sync_ttl_secs
      ANTARES_UPPER_ROOT                  = var.antares_upper_root
      ANTARES_CL_ROOT                     = var.antares_cl_root
      ANTARES_MOUNT_ROOT                  = var.antares_mount_root
      ANTARES_STATE_FILE                  = var.antares_state_file
    },
    var.worker_env
  )
}

resource "kubernetes_namespace_v1" "this" {
  metadata {
    name = local.namespace
  }
}

resource "kubernetes_service_account_v1" "this" {
  metadata {
    name      = var.service_account_name
    namespace = kubernetes_namespace_v1.this.metadata[0].name
  }
}

resource "kubernetes_config_map_v1" "this" {
  metadata {
    name      = "orion-worker-config"
    namespace = kubernetes_namespace_v1.this.metadata[0].name
  }

  data = {
    SERVER_WS        = var.server_ws
    SCORPIO_BASE_URL = var.scorpio_base_url
    SCORPIO_LFS_URL  = var.scorpio_lfs_url
    RUST_LOG         = var.rust_log
  }
}

resource "kubernetes_secret_v1" "this" {
  metadata {
    name      = "orion-worker-secret"
    namespace = kubernetes_namespace_v1.this.metadata[0].name
  }

  type = "Opaque"
  data = var.secret_data
}

resource "kubernetes_config_map_v1" "scorpio" {
  metadata {
    name      = "scorpio-config"
    namespace = kubernetes_namespace_v1.this.metadata[0].name
  }

  data = {
    "scorpio.toml.template" = <<-EOT
      # =============================================================================
      # Scorpio Configuration Template
      # =============================================================================
      # This template uses simple environment variable placeholders like `$${VAR_NAME}`.
      # The entrypoint script sets defaults and then substitutes the variables via `envsubst`.
      # =============================================================================

      # Mega/Mono service URLs
      base_url = "$${SCORPIO_BASE_URL}"
      lfs_url = "$${SCORPIO_LFS_URL}"

      # Storage paths
      store_path = "$${SCORPIO_STORE_PATH}"
      workspace = "$${SCORPIO_WORKSPACE}"
      config_file = "config.toml"

      # Git author configuration
      git_author = "$${SCORPIO_GIT_AUTHOR}"
      git_email = "$${SCORPIO_GIT_EMAIL}"

      # DicFuse (dictionary-based FUSE) settings
      dicfuse_readable = "$${SCORPIO_DICFUSE_READABLE}"
      load_dir_depth = "$${SCORPIO_LOAD_DIR_DEPTH}"
      fetch_file_thread = "$${SCORPIO_FETCH_FILE_THREAD}"
      dicfuse_import_concurrency = "$${SCORPIO_DICFUSE_IMPORT_CONCURRENCY}"
      dicfuse_dir_sync_ttl_secs = "$${SCORPIO_DICFUSE_DIR_SYNC_TTL_SECS}"
      dicfuse_stat_mode = "$${SCORPIO_DICFUSE_STAT_MODE}"
      dicfuse_open_buff_max_bytes = "$${SCORPIO_DICFUSE_OPEN_BUFF_MAX_BYTES}"
      dicfuse_open_buff_max_files = "$${SCORPIO_DICFUSE_OPEN_BUFF_MAX_FILES}"

      # Antares (overlay filesystem) settings
      antares_load_dir_depth = "$${ANTARES_LOAD_DIR_DEPTH}"
      antares_dicfuse_stat_mode = "$${ANTARES_DICFUSE_STAT_MODE}"
      antares_dicfuse_open_buff_max_bytes = "$${ANTARES_DICFUSE_OPEN_BUFF_MAX_BYTES}"
      antares_dicfuse_open_buff_max_files = "$${ANTARES_DICFUSE_OPEN_BUFF_MAX_FILES}"
      antares_dicfuse_dir_sync_ttl_secs = "$${ANTARES_DICFUSE_DIR_SYNC_TTL_SECS}"
      antares_upper_root = "$${ANTARES_UPPER_ROOT}"
      antares_cl_root = "$${ANTARES_CL_ROOT}"
      antares_mount_root = "$${ANTARES_MOUNT_ROOT}"
      antares_state_file = "$${ANTARES_STATE_FILE}"
    EOT
  }
}

resource "kubernetes_daemon_set_v1" "this" {
  metadata {
    name      = "orion-worker"
    namespace = kubernetes_namespace_v1.this.metadata[0].name
    labels = {
      app = "orion-worker"
    }
  }

  spec {
    selector {
      match_labels = {
        app = "orion-worker"
      }
    }

    template {
      metadata {
        labels = {
          app = "orion-worker"
        }
      }

      spec {
        service_account_name             = var.service_account_name
        termination_grace_period_seconds = var.termination_grace_period_seconds

        dynamic "toleration" {
          for_each = var.tolerations
          content {
            key      = toleration.value.key
            operator = toleration.value.operator
            value    = toleration.value.value
            effect   = toleration.value.effect
          }
        }

        node_selector = var.node_selector

        dynamic "affinity" {
          for_each = var.node_affinity_required != null ? [1] : []
          content {
            node_affinity {
              required_during_scheduling_ignored_during_execution {
                node_selector_term {
                  match_expressions {
                    key      = var.node_affinity_required.key
                    operator = var.node_affinity_required.operator
                    values   = var.node_affinity_required.values
                  }
                }
              }
            }
          }
        }

        container {
          name  = "orion-worker"
          image = var.image

          command = ["/bin/sh", "-c"]
          args = [
            <<-EOT
              set -e
              # Force localhost to resolve to IPv4 to avoid IPv6 connection issues
              echo "127.0.0.1 localhost" >> /etc/hosts

              echo "Generating scorpio config via envsubst..."
              envsubst < /etc/scorpio/scorpio.toml.template > /tmp/scorpio.toml

              echo "Attempting to start scorpio in background..."
              # Run scorpio with config, listening on default 0.0.0.0:2725
              /app/bin/scorpio --config-path /tmp/scorpio.toml > /tmp/scorpio.log 2>&1 &
              sleep 2
              echo "--- Scorpio Log Start ---"
              cat /tmp/scorpio.log || true
              echo "--- Scorpio Log End ---"
              exec orion
            EOT
          ]

          env_from {
            config_map_ref {
              name = kubernetes_config_map_v1.this.metadata[0].name
            }
          }

          env_from {
            secret_ref {
              name     = kubernetes_secret_v1.this.metadata[0].name
              optional = true
            }
          }

          dynamic "env" {
            for_each = local.container_env
            content {
              name  = env.key
              value = env.value
            }
          }

          security_context {
            privileged = var.privileged
          }

          resources {
            requests = {
              cpu    = var.cpu_request
              memory = var.memory_request
            }
            limits = {
              cpu    = var.cpu_limit
              memory = var.memory_limit
            }
          }

          lifecycle {
            pre_stop {
              exec {
                command = ["/bin/sh", "-lc", "sleep 10"]
              }
            }
          }

          volume_mount {
            name       = "orion-data-cache"
            mount_path = "/data"
          }

          volume_mount {
            name       = "orion-workspace-cache"
            mount_path = "/workspace"
          }

          volume_mount {
            name       = "scorpio-config"
            mount_path = "/etc/scorpio/scorpio.toml.template"
            sub_path   = "scorpio.toml.template"
          }
        }

        volume {
          name = "orion-data-cache"
          host_path {
            path = var.host_path_data
            type = "DirectoryOrCreate"
          }
        }

        volume {
          name = "orion-workspace-cache"
          host_path {
            path = var.host_path_workspace
            type = "DirectoryOrCreate"
          }
        }

        volume {
          name = "scorpio-config"
          config_map {
            name = kubernetes_config_map_v1.scorpio.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_namespace_v1.this,
    kubernetes_service_account_v1.this,
    kubernetes_config_map_v1.this,
    kubernetes_secret_v1.this,
    kubernetes_config_map_v1.scorpio
  ]
}
