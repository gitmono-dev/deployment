variable "namespace" {
  type        = string
  description = "Kubernetes namespace for Orion Worker"
  default     = "orion-worker"
}

variable "service_account_name" {
  type        = string
  description = "Kubernetes service account name"
  default     = "orion-worker-sa"
}

variable "image" {
  type        = string
  description = "Orion Worker container image"
  default     = "public.ecr.aws/m8q5m4u3/mega:orion-client-0.1.0-pre-release-amd64"
}

variable "server_ws" {
  type        = string
  description = "Orion server WebSocket URL"
  default     = "wss://orion.gitmono.com/ws"
}

variable "scorpio_base_url" {
  type        = string
  description = "Scorpio base URL"
  default     = "https://git.gitmono.com"
}

variable "scorpio_lfs_url" {
  type        = string
  description = "Scorpio LFS URL"
  default     = "https://git.gitmono.com"
}

variable "rust_log" {
  type        = string
  description = "Rust log level"
  default     = "info"
}

variable "secret_data" {
  type        = map(string)
  description = "Optional secret data for orion-worker-secret (plain values, will be base64-encoded by provider)."
  default     = {}
  sensitive   = true
}

variable "worker_env" {
  type        = map(string)
  description = "Extra environment variables for Orion Worker container"
  default     = {}
}

variable "tolerations" {
  type = list(object({
    key      = string
    operator = string
    value    = string
    effect   = string
  }))
  description = "Tolerations for worker pods"
  default = [
    {
      key      = "dedicated"
      operator = "Equal"
      value    = "orion-build"
      effect   = "NoSchedule"
    }
  ]
}

variable "node_selector" {
  type        = map(string)
  description = "Node selector for worker pods"
  default = {
    nodepool = "build-default"
  }
}

variable "node_affinity_required" {
  type = object({
    key      = string
    operator = string
    values   = list(string)
  })
  description = "Optional requiredDuringScheduling node affinity. If null, affinity is not set."
  default     = null
}

variable "orion_worker_start_scorpio" {
  type        = bool
  description = "Whether to start scorpio sidecar process before orion"
  default     = true
}

variable "scorpio_store_path" {
  type        = string
  description = "Scorpio store path"
  default     = "/data/scorpio/store"
}

variable "scorpio_workspace" {
  type        = string
  description = "Scorpio workspace path"
  default     = "/workspace/mount"
}

variable "buck_project_root" {
  type        = string
  description = "Buck project root"
  default     = "/workspace"
}

variable "build_tmp" {
  type        = string
  description = "Build temp directory"
  default     = "/tmp/orion-builds"
}

variable "scorpio_git_author" {
  type        = string
  description = "Scorpio git author"
  default     = "orion"
}

variable "scorpio_git_email" {
  type        = string
  description = "Scorpio git email"
  default     = "orion@local"
}

variable "scorpio_dicfuse_readable" {
  type        = string
  description = "Scorpio dicfuse readable"
  default     = "true"
}

variable "scorpio_load_dir_depth" {
  type        = string
  description = "Scorpio load dir depth"
  default     = "2"
}

variable "scorpio_fetch_file_thread" {
  type        = string
  description = "Scorpio fetch file thread"
  default     = "8"
}

variable "scorpio_dicfuse_import_concurrency" {
  type        = string
  description = "Scorpio dicfuse import concurrency"
  default     = "8"
}

variable "scorpio_dicfuse_dir_sync_ttl_secs" {
  type        = string
  description = "Scorpio dicfuse dir sync ttl secs"
  default     = "60"
}

variable "scorpio_dicfuse_stat_mode" {
  type        = string
  description = "Scorpio dicfuse stat mode"
  default     = "fast"
}

variable "scorpio_dicfuse_open_buff_max_bytes" {
  type        = string
  description = "Scorpio dicfuse open buff max bytes"
  default     = "134217728"
}

variable "scorpio_dicfuse_open_buff_max_files" {
  type        = string
  description = "Scorpio dicfuse open buff max files"
  default     = "2048"
}

variable "antares_load_dir_depth" {
  type        = string
  description = "Antares load dir depth"
  default     = "2"
}

variable "antares_dicfuse_stat_mode" {
  type        = string
  description = "Antares dicfuse stat mode"
  default     = "fast"
}

variable "antares_dicfuse_open_buff_max_bytes" {
  type        = string
  description = "Antares dicfuse open buff max bytes"
  default     = "134217728"
}

variable "antares_dicfuse_open_buff_max_files" {
  type        = string
  description = "Antares dicfuse open buff max files"
  default     = "2048"
}

variable "antares_dicfuse_dir_sync_ttl_secs" {
  type        = string
  description = "Antares dicfuse dir sync ttl secs"
  default     = "60"
}

variable "antares_upper_root" {
  type        = string
  description = "Antares upper root"
  default     = "/data/scorpio/antares/upper"
}

variable "antares_cl_root" {
  type        = string
  description = "Antares cl root"
  default     = "/data/scorpio/antares/cl"
}

variable "antares_mount_root" {
  type        = string
  description = "Antares mount root"
  default     = "/workspace/mount"
}

variable "antares_state_file" {
  type        = string
  description = "Antares state file"
  default     = "/data/scorpio/antares/state.json"
}

variable "privileged" {
  type        = bool
  description = "Run worker container in privileged mode"
  default     = true
}

variable "host_path_data" {
  type        = string
  description = "HostPath for /data cache"
  default     = "/var/lib/orion/data"
}

variable "host_path_workspace" {
  type        = string
  description = "HostPath for /workspace cache"
  default     = "/var/lib/orion/workspace"
}

variable "cpu_request" {
  type        = string
  description = "CPU request for worker container"
  default     = "6"
}

variable "memory_request" {
  type        = string
  description = "Memory request for worker container"
  default     = "24Gi"
}

variable "cpu_limit" {
  type        = string
  description = "CPU limit for worker container"
  default     = "8"
}

variable "memory_limit" {
  type        = string
  description = "Memory limit for worker container"
  default     = "30Gi"
}

variable "termination_grace_period_seconds" {
  type        = number
  description = "Termination grace period seconds"
  default     = 300
}
