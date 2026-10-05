# ollama

CPU-only Ollama LLM inference server. Foundation for the idea-loop project.

## In-cluster URL

```
http://ollama.llm.svc.cluster.local:11434
```

OpenAI-compatible chat endpoint:

```
http://ollama.llm.svc.cluster.local:11434/v1/chat/completions
```

## Default model

`llama3.2:3b-instruct-q4_K_M` — Meta Llama 3.2 3B, 4-bit k-quant, ~2 GB on disk.
Pulled automatically on first pod start via the `postStart` lifecycle hook.
Subsequent restarts skip the pull if the model is already present in the PVC.

## Swapping or adding models

Edit `values.yaml` and change (or add) the model name, then let ArgoCD sync.
The postStart hook calls `ollama pull <model>` on every pod start; it is a no-op
if the model is already cached in `/root/.ollama` on the PVC.

To add a second model without changing the default, exec into the running pod:

```bash
kubectl exec -n llm deploy/ollama -- ollama pull <model-name>
```

The PVC is 5 Gi; a second 3–4 B Q4 model (~2 GB) fits comfortably.

## Observed performance (servy, 24-core CPU, no GPU)

| Model                        | Prompt tokens | Completion tokens | tokens/sec | time-to-first-token |
|------------------------------|---------------|-------------------|------------|---------------------|
| llama3.2:3b-instruct-q4_K_M  | 34            | 417               | 3.2        | 0.28 s              |

Measured 2026-10-05 via `/api/generate` from a pod in the `default` namespace.
At 3.2 t/s a 100-token idea-loop completion takes ~30 s — well within the
"call every few minutes" budget.

## Resource sizing

| Parameter      | Value  | Rationale                                      |
|----------------|--------|------------------------------------------------|
| CPU request    | 2000m  | Baseline; inference bursts use more            |
| CPU limit      | 8000m  | ~8 cores — fast inference without starving cluster |
| Memory request | 4 Gi   | 2 GB model + 2 GB Ollama overhead              |
| Memory limit   | 6 Gi   | Headroom for larger contexts                   |
| PVC            | 5 Gi   | local-path; room for one extra model           |

## Upgrading Ollama

Change `image.tag` in `values.yaml`. The `Recreate` strategy ensures the old pod
releases the ReadWriteOnce PVC before the new one starts.
