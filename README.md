# env0 Discovery Destroy Approval Bug — Reproduction Repo

> **Internal Use Only** — env0 Support / QA
>
> Slack Issue: Paramount - Env Discovery Destroy Skips Approval Gate
> Reported: May 6, 2026 | Channel: `#env0-paramount`

---

## 🧠 What This Repo Tests

When an environment is **removed from `env0-discovery.yaml`**, env0 should respect the `requiresApproval: true` setting and pause for a human to approve the destroy.

**The suspected bug:** env0 resets `requiresApproval` back to its platform default (`false`) as part of the discovery reconciliation step — *before* queuing the destroy. The destroy then runs with `requiresApproval: false`, bypassing the approval gate entirely.

This repo uses a **no-op Terraform configuration** (`null_resource`) so nothing real is created or destroyed in any cloud provider. It is safe to run in any env0 org.

---

## 📁 Repo Structure

```
env0-discovery-approval-bug/
├── README.md                        ← You are here
├── CHECKLIST.md                     ← Step-by-step verification checklist
├── env0-discovery.yaml              ← Phase 1: env present (initial state)
├── env0-discovery-removed.yaml      ← Phase 2: env removed (triggers bug)
└── terraform/
    ├── main.tf                      ← null_resource no-op
    ├── variables.tf
    ├── outputs.tf
    └── common.tfvars
```

---

## 🔧 Prerequisites

Before starting:

1. Access to an **env0 organization** where you can create projects and templates
2. A **GitHub (or GitLab/Bitbucket) repo** connected to env0 — fork or mirror this repo
3. An env0 **project** to deploy into (create a throwaway project named `discovery-bug-test`)
4. An env0 **template** pointing to `terraform/` in this repo using the `null` provider
5. env0 org must have **File-Based Environment Discovery** enabled

---

## 🚀 Step-by-Step Reproduction

### Step 0 — Prep: Create Template in env0

1. Go to **Templates** in your env0 org
2. Click **+ New Template**
3. Set the following:
   - **Name:** `noop-discovery-test`
   - **Repository:** *(this repo)*
   - **Terraform working directory:** `terraform/`
   - **Terraform version:** `1.5.x` or later
   - **IaC type:** Terraform
4. Save the template — no variables needed, the `null` provider requires no credentials

---

### Step 1 — Set Up Discovery

1. In `env0-discovery.yaml`, replace the two placeholder values:
   ```yaml
   projectName: <YOUR_PROJECT_NAME>    # the throwaway project you created
   templateName: noop-discovery-test   # the template you just made
   ```
2. Commit and push `env0-discovery.yaml` to your `main` branch
3. In env0, navigate to your project → **Settings** → **Environment Discovery**
4. Enable file-based discovery and point it at this repo / `env0-discovery.yaml`
5. Trigger a discovery scan (or wait for the auto-scan on push)

**Expected:** env0 discovers `noop-approval-test-env` and queues an initial deploy.

---

### Step 2 — Approve & Confirm Initial Deploy

1. Go to the environment page in env0
2. You should see the deployment in **"Waiting for Approval"** status
3. ✅ Approve it
4. Wait for apply to complete — you should see `null_resource.noop` in the plan/state
5. **Confirm on the environment settings page:** `requiresApproval` = **ON**

> 📸 Capture a screenshot of the environment settings showing `requiresApproval: true` — this is your baseline.

---

### Step 3 — API Baseline Check

Before triggering the bug, record the current `requiresApproval` value via the API:

```bash
ENV_ID="<paste-env-id-from-UI-URL>"
ORG_ID="<your-org-id>"
API_KEY="<your-env0-api-key>"

curl -s \
  -H "Authorization: Bearer $API_KEY" \
  "https://api.env0.com/environments/$ENV_ID" \
  | jq '{id: .id, name: .name, requiresApproval: .requiresApproval}'
```

**Expected output:**
```json
{
  "id": "...",
  "name": "noop-approval-test-env",
  "requiresApproval": true
}
```

Record this result in `CHECKLIST.md` (Phase 1, row 1.5).

---

### Step 4 — Trigger the Bug

1. In your repo, **rename** `env0-discovery-removed.yaml` → `env0-discovery.yaml`
   *(replacing the Phase 1 file — the environments block is now empty)*
2. Commit and push to `main`
3. Watch env0 — it should detect that `noop-approval-test-env` is no longer in the file

**What should happen (correct behavior):**
> env0 queues a destroy for `noop-approval-test-env` and shows it in **"Waiting for Approval"**

**What actually happens (bug):**
> env0 queues and **immediately executes** the destroy, skipping the approval gate

---

### Step 5 — API Check During/After Destroy

Run the same API call from Step 3 immediately after pushing. Look for `requiresApproval` changing to `false` before or during the destroy:

```bash
# Poll every 5 seconds to catch the transition
watch -n 5 'curl -s \
  -H "Authorization: Bearer $API_KEY" \
  "https://api.env0.com/environments/$ENV_ID" \
  | jq "{name: .name, requiresApproval: .requiresApproval, status: .status}"'
```

> 🔴 If you see `requiresApproval` flip to `false` and `status` go straight to `DESTROY_IN_PROGRESS` — **bug confirmed.**

---

### Step 6 — Run Variant Checks

After the main repro, run the variant scenarios in `CHECKLIST.md` (Section 3):

- **Variant 3.1:** Set `requiresApproval: true` inline (no anchor) — does removal still skip approval?
- **Variant 3.2:** Set `requiresApproval: true` in the env0 UI manually, then remove env from YAML
- **Variant 3.3 & 3.4:** Manual destroy from UI (should always respect `requiresApproval`)

---

## 📊 Recording Results

Fill in `CHECKLIST.md` as you go. Once complete, the checklist becomes the evidence attached to the Linear bug ticket.

---

## 🐛 Filing the Bug

If the bug is confirmed, file a Linear ticket using this template:

---

**Discovery Destroy Skips Approval Gate When Env Removed from YAML**

🐛 **Problem / Current Behavior:**
When an environment with `requiresApproval: true` (set via YAML anchor in `env0-discovery.yaml`) is removed from the discovery file, env0 triggers an immediate destroy without requesting approval. The platform appears to reset `requiresApproval` to `false` during reconciliation before the destroy is queued, causing the approval gate to be bypassed.

Slack thread: `#env0-paramount` | May 6, 2026

🪜 **Steps to Reproduce:**
1. Configure `env0-discovery.yaml` with `requiresApproval: true` on an environment (via YAML anchor or inline)
2. Trigger discovery and confirm initial deploy awaits + receives approval
3. Confirm `requiresApproval: true` in both UI and API
4. Remove the environment from `env0-discovery.yaml` and push
5. Observe: destroy runs immediately with no approval prompt

✅ **Expected Behavior:**
Destroy should enter "Waiting for Approval" before executing, respecting the `requiresApproval: true` setting that was in place at the time the environment was managed.

---

## ⚠️ Important Notes

- This repo is **safe to test with** — the `null_resource` creates no real infrastructure
- Do not test against a production env0 project
- If you need to reset between runs, re-add the env to `env0-discovery.yaml` and re-run discovery
- The `terraform/` directory has no provider credentials — the `null` provider needs none
