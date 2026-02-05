# Milestone D: E2E Validation (GKE / Orion Worker)

This directory provides E2E validation jobs that run inside the cluster.

Prerequisites:
- Orion Worker is deployed.
  - Recommended: deploy via Terraform with `enable_orion_worker = true` in `deployment/envs/gcp/<env>`.
- Worker configuration uses:
  - `SERVER_WS=wss://orion.gitmono.com/ws`
  - `SCORPIO_BASE_URL=https://git.gitmono.com`
  - `SCORPIO_LFS_URL=https://git.gitmono.com`
- Cluster nodes have outbound internet access (NAT) and DNS works.

## 0. Quick check: Orion Worker DaemonSet

```bash
kubectl -n orion-worker get ds/orion-worker
kubectl -n orion-worker get pods -l app=orion-worker -o wide
```

Successful criteria:
- DaemonSet `DESIRED` equals `READY`.
- Pods are scheduled onto the expected build nodepool nodes.

## 1. Connectivity validation (DNS / HTTPS / WS / Mono)

File: `connectivity-check-job.yaml`

Run:
```bash
kubectl apply -f deployment/gcp/e2e/connectivity-check-job.yaml
kubectl -n orion-worker wait --for=condition=complete job/orion-worker-connectivity-check --timeout=120s
kubectl -n orion-worker logs job/orion-worker-connectivity-check
```

Successful criteria:
- Logs contain `ALL_CHECKS_PASSED`.

Failure criteria (common):
- DNS failure: `getent hosts` has no output / non-zero exit
- HTTPS failure: `curl` timeout or cert errors
- WS failure: TLS handshake failure / `/ws` endpoint unreachable

## 2. Task execution validation (submit task -> worker executes -> status readback)

File: `task-e2e-trigger-job.yaml`

Notes:
- This job creates a task via Orion-server HTTP API `POST /task`.
- Then it polls task status via `GET /tasks/{cl}` until it returns `"status":"Completed"`.
- The repo/target values are environment-specific. You MUST update envs before applying:
  - `ORION_API_BASE`: Orion-server base URL (default `https://orion.gitmono.com`)
  - `ORION_TASK_CL`: CL number for query
  - `ORION_TASK_CL_LINK`: any traceable link
  - `ORION_REPO`: repo name as understood by the server
  - `ORION_TARGET`: a small, known-existing target
  - `ORION_POLL_SECONDS`: timeout seconds (default 300s)

Run:
```bash
kubectl apply -f deployment/gcp/e2e/task-e2e-trigger-job.yaml
kubectl -n orion-worker logs -f job/orion-task-e2e-trigger
```

Successful criteria:
- Job logs contain `TASK_E2E_PASSED`.
- Worker logs show:
  - connected to `/ws`
  - received tasks
  - build finished successfully

Failure criteria:
- `TASK_E2E_FAILED`: build status becomes Failed/Interrupted
- timeout: worker did not pick up the task

## 3. Suggested troubleshooting commands

```bash
kubectl -n orion-worker get pods -o wide
kubectl -n orion-worker logs -l app=orion-worker --tail=200
kubectl -n orion-worker describe ds/orion-worker
```

If Orion-server `/task` requires authentication (Authorization header), update `task-e2e-trigger-job.yaml` accordingly.
