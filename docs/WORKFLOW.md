# Workflow — fork → fix → PR → review → merge
<!-- context: https://ilm.codes/context/ -->
- **Maintainer (write access):** branch on origin `ai/<task>` or `issue/<n>` → PR → review → squash-merge.
- **External / AI collaborator (no write):** **fork** → branch → PR to upstream → review → merge.
- One task = one branch = one small, reviewable diff (patch the files that change, not the repo).
- PRs are created **loudly** (URL printed); never swallow `gh` output.
- Every script that does the work lives in `ops/bin/`, committed before/with the change it makes.
- Merge: `gh pr merge <branch> --squash --delete-branch` **from the correct repo dir**.
