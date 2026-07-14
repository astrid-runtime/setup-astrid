# Releasing `setup-astrid`

The action is distributed through signed Git tags. An immutable full-version
tag records the release, while the matching major tag is the stable reference
used by workflows.

## Publish v2 after the preparation PR merges

Do not create either v2 tag from a pull-request branch. Once the preparation
PR is merged and `main` is green:

```bash
git fetch origin main --tags
release_commit="$(git rev-parse 'origin/main^{commit}')"
git log -1 --show-signature "${release_commit}"

git tag -s v2.0.0 "${release_commit}" -m "setup-astrid v2.0.0"
git tag -s v2 "${release_commit}" -m "setup-astrid v2 (moving major tag)"
git push --atomic origin refs/tags/v2.0.0 refs/tags/v2
```

The two tags must initially resolve to the same commit:

```bash
test "$(git rev-list -n1 v2.0.0)" = "$(git rev-list -n1 v2)"
```

Then exercise the published tag rather than the branch:

```bash
gh workflow run test.yml --ref v2
```

Do not move `v1`. It retains the original action implementation for existing
consumers. Future compatible v2 updates move only the signed `v2` major tag;
each release also receives a new immutable signed `v2.x.y` tag.
