# ✅ Verification Checklist — Discovery Destroy Approval Bug

Use this checklist to systematically confirm the bug (or a fix) during testing.
Check off each item as you go and record your observations in the Notes column.

---

## Phase 1 — Initial Setup Checks

| # | Check | Expected | Notes |
|---|-------|----------|-------|
| 1.1 | env0 discovers `noop-approval-test-env` from the YAML | Environment appears in project |Done|
| 1.2 | Initial deploy triggers and enters "Waiting for Approval" | Approval gate shown |Done|
| 1.3 | After approving, apply completes successfully | `null_resource.noop` created |Done|
| 1.4 | UI shows `requiresApproval: true` on the environment settings page | Toggle is ON |Done|
| 1.5 | API confirms `requiresApproval: true` (see API check below) | `"requiresApproval": true` in response |Done|

---

## Phase 2 — Bug Trigger Checks

| # | Check | Expected | Actual | Pass/Fail |
|---|-------|----------|--------|-----------|
| 2.1 | After removing env from YAML and pushing, env0 detects removal | Destroy queued | | |
| 2.2 | **Does destroy enter "Waiting for Approval"?** | ✅ YES — approval required | | |
| 2.3 | Does the environment's `requiresApproval` value change before destroy? | Should stay `true` | | |
| 2.4 | Is the destroy auto-approved without user action? | ❌ Should NOT be | | |
| 2.5 | Destroy completes without approval prompt | Bug confirmed if YES | | |

---

## Variant Checks

| # | Variant | Expected | Actual |
|---|---------|----------|--------|
| 3.1 | `requiresApproval: true` set **inline** (not via anchor) — then env removed | Approval required | |
| 3.2 | `requiresApproval: true` set in env0 UI manually — then env removed from YAML | Approval required | |
| 3.3 | Manual destroy from env0 UI (env still in YAML) | Approval required | |
| 3.4 | Manual destroy from env0 UI (env NOT in YAML) | Approval required | |

---

## API Verification Steps

Run these before and after removing the env from YAML to track `requiresApproval` changes.

```bash
# Get environment ID from the env0 UI URL, then:
ENV_ID="<your-environment-id>"
ORG_ID="<your-org-id>"
API_KEY="<your-api-key>"

curl -s \
  -H "Authorization: Bearer $API_KEY" \
  "https://api.env0.com/environments/$ENV_ID" \
  | jq '{id: .id, name: .name, requiresApproval: .requiresApproval}'
```

Record output at each phase:

| Timing | `requiresApproval` value |
|--------|--------------------------|
| After Phase 1 deploy (baseline) | |
| Immediately after YAML removal pushed | |
| At the moment destroy is triggered | |

---

## Observations / Notes

```
[Fill in during testing]
```

---

## Result

- [ ] **Bug confirmed** — destroy fired without approval
- [ ] **Bug not reproduced** — approval gate respected
- [ ] **Partial** — describe:
