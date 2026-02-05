# Orion Worker (GCP) – End-to-End 验收流程

> 适用目录：`deployment/k8s/gcp/*`  
> 目标：验证 GKE 上的 Orion Worker 已正确接入现有 AWS Orion-server/Mono(`gitmono.com`) 并能成功执行一次构建任务。

---

## Phase 0：前提检查

1. `kubectl config current-context` 指向目标 GKE 集群。
2. 已创建 NodePool `build-default`，节点具备出网能力（Cloud NAT 或 Public IP）。
3. 如需私有镜像仓库，请先确保节点可拉取 `public.ecr.aws/.../mega:*` 镜像。

---

## Phase 1：连通性快速自检

```bash
# 1) 创建 namespace（如未创建）
kubectl apply -f deployment/k8s/gcp/orion-worker-namespace.yaml

# 2) 运行连通性检查 Job
kubectl apply -f deployment/k8s/gcp/e2e/connectivity-check-job.yaml

# 3) 查看日志
kubectl logs -n orion-worker job/orion-worker-connectivity-check --tail=200 | cat
```

**期望输出**
- `getent hosts orion.gitmono.com` / `git.gitmono.com` 均返回解析结果。
- `curl -I https://git.gitmono.com` / `https://orion.gitmono.com` 返回 2xx/3xx/4xx 均视为“可达”。
- TLS handshake 与 `/ws` HTTP Upgrade 没有超时/证书错误。

---

## Phase 2：部署 Orion Worker DaemonSet

```bash
kubectl apply -f deployment/k8s/gcp/orion-worker-serviceaccount.yaml
kubectl apply -f deployment/k8s/gcp/orion-worker-configmap.yaml
kubectl apply -f deployment/k8s/gcp/orion-worker-secret.yaml   # 如有敏感信息可跳过
kubectl apply -f deployment/k8s/gcp/orion-worker-daemonset.yaml

# 查看 DaemonSet / Pod 状态
kubectl get ds -n orion-worker -o wide
kubectl get pods -n orion-worker -o wide
```

**期望**
- `DESIRED/CURRENT/READY` 数量与构建节点数一致。
- Pod 状态为 `Running`。若 `Pending/CrashLoopBackOff`，请 `kubectl describe pod` 调试。

### 2.1 关键依赖验收

```bash
POD=$(kubectl get pods -n orion-worker -o jsonpath='{.items[0].metadata.name}')

# WebSocket 连接是否成功
a.kubectl logs -n orion-worker $POD --tail=200 | cat

# FUSE 设备是否存在
kubectl exec -n orion-worker $POD -- ls -l /dev/fuse
```

日志应出现 `connected to wss://orion.gitmono.com/ws` 及心跳/idle 信息。

---

## Phase 3：触发一次 E2E 构建任务

仓库已提供触发 Job，并默认指向 `orion.gitmono.com`。

```bash
kubectl apply -f deployment/k8s/gcp/e2e/task-e2e-trigger-job.yaml
kubectl logs -n orion-worker job/task-e2e-trigger --tail=200 | cat
```

随后在 Worker Pod 内实时查看：

```bash
kubectl logs -n orion-worker $POD -f | cat
```

**期望**
- Worker 收到任务（`starting job …`）。
- `scorpio mount` 成功，`buck2` 执行无错误。
- 任务结果 `success` / exit 0，Orion-server 侧状态变更为 `success`。

---

## Phase 4：收集验收证据

```bash
kubectl get nodes
kubectl get ds/pods -n orion-worker -o wide
kubectl logs -n orion-worker job/orion-worker-connectivity-check | tail -20
kubectl logs -n orion-worker $POD --since=30m | grep -E "connected|success"
```

将以上输出保存，作为本次 GCP Worker 部署 E2E 成功的佐证。
