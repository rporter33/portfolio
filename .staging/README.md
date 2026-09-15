# Staging — temporary, not part of the showcase

`mtg-companion.bundle` is the complete git repository for the MTG Companion app
(all four commits, 68 files, full history) as a single file.

It is here **only** because the app was built in an ephemeral container and
`rporter33/mtg-companion` did not exist yet, so there was nowhere else to push
it. It is on this feature branch only — `main` is untouched, and the showcase
remains source-free.

## Restoring it

```bash
git clone .staging/mtg-companion.bundle mtg-companion
cd mtg-companion
npm install && npm test && npm run dev
```

## Then delete this directory

Once the standalone repo exists:

```bash
git clone .staging/mtg-companion.bundle mtg-companion
cd mtg-companion
git remote set-url origin https://github.com/rporter33/mtg-companion.git
git push -u origin main
```

Then `git rm -r .staging` on this branch. Nothing else references it.
