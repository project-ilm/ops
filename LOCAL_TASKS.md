# LOCAL_TASKS — run on ilm01-lin
<!-- context: https://ilm.codes/context/ -->
1. Merge programme PR:   gh pr merge ai/programme-docs -R project-ilm/ilm.codes --squash --delete-branch
2. Per-image DOIs:       ZENODO_TOKEN=*** bash ops/bin/mint_poster_dois.sh   (rotate the leaked token first)
3. Scaffold specs:       bash ops/bin/gen_specs.sh   then merge its PR
4. Localize hi/ur/fa:    export TRANSLATE_CMD='trans -b en:hi'; bash ops/bin/localize.sh   (or paste Google-translate)
5. Triage issues:        see ops/issues_snapshot.md -> ai/issue-<n> branches per WORKFLOW.md
6. Verify PDFs:          open /programme/<slug>/ , Print -> Save as PDF , confirm submission-ready
7. Private sheet:        keep 13554 'Operating Level' OUT of public repos (store in project-ilm/record if retaining)
