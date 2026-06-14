#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 AppGrid Contributors
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Regenerates CHANGELOG.md from Conventional-Commit messages.
#
# Branch-aware: a single `git cliff` call walks only the current branch's
# ancestry, so tags that live on a maintenance branch (e.g. the 1.8.x patches on
# maintenance/1.8.x) would be missed. This covers the current branch in full,
# then each maintenance/* line from where it branched off HEAD's history up to
# its newest stable tag — discovered dynamically, no hardcoded versions.
#
# Divergence handling: a release may be tagged on a maintenance line that has
# since diverged from HEAD (e.g. v1.9.0 lives on maintenance/1.9.x while main
# carries the same work, partly as shared history, partly cherry-picked with new
# hashes, and untagged). Without correction every such commit shows up as
# "Unreleased" on main even though it shipped. So for each release tag we render
# its section from the branch point (BASE..tag, which includes shared history),
# then drop every HEAD-side copy of that tag's work from the Unreleased pass —
# both same-hash shared commits and cherry-pick equivalents — via --skip-commit.
#
# The per-range cliff blocks are then merged and ordered globally (Unreleased
# first, then by version descending) so a maintenance patch sits in version
# order rather than appended after the whole main line.
#
# Runs --offline so cliff doesn't enrich commits via the GitHub API. PR numbers
# still render — the Conventional Commits already carry "(#N)".

set -euo pipefail

cd "$(dirname "$0")/.."

ROOT=$(git rev-list --max-parents=0 HEAD | tail -1)

# Range 1: everything reachable from the current branch — its own line plus
# every tag merged into it. This is the only range that yields an Unreleased
# section. Ranges 2..N: each maintenance line's released history.
HEAD_RANGE="${ROOT}..HEAD"
ranges=("$HEAD_RANGE")

# HEAD-side commits that belong to a release tagged off a diverged maintenance
# line (shared-history copies and cherry-pick equivalents alike). Skipped from
# the Unreleased pass so released work doesn't masquerade as unreleased.
skip_shas=()

# Unique maintenance line names, newest first. A line may exist locally,
# remotely, or both; collapse to one name and prefer the local checkout.
while IFS= read -r line; do
    [ -n "$line" ] || continue
    ref="$line"
    git rev-parse --verify -q "$ref" >/dev/null 2>&1 || ref="origin/$line"
    git rev-parse --verify -q "$ref" >/dev/null 2>&1 || continue
    # The line's newest STABLE tag that isn't already on HEAD. Unreleased /
    # rc-only maintenance work is deliberately excluded: the changelog tracks
    # released versions, and main's range is the only Unreleased contributor.
    # `|| true`: grep exits 1 with no match, which would trip set -e / pipefail.
    tag=$(git tag --merged "$ref" --no-merged HEAD --sort=-v:refname 2>/dev/null \
          | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | head -1 || true)
    [ -n "$tag" ] || continue

    # Branch point: the newest stable tag the line shares with HEAD's history,
    # i.e. reachable from where the line forked off (the merge base). Rendering
    # from BASE..tag (instead of HEAD..tag) keeps the shared pre-fork commits in
    # the release's section rather than orphaning them into Unreleased. Falls
    # back to the repo root when no stable tag predates the fork.
    mb=$(git merge-base HEAD "$tag")
    base=$(git tag --merged "$mb" --sort=-v:refname 2>/dev/null \
           | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | head -1 || true)
    [ -n "$base" ] || base="$ROOT"
    ranges+=("${base}..${tag}")

    # Everything on HEAD that this release already contains: all HEAD commits
    # since the branch point, minus the ones with no equivalent in the tag
    # (git's --cherry-pick drops patch-equivalents, so the leftovers are the
    # genuinely-unreleased commits). The difference is what to skip.
    while IFS= read -r sha; do
        [ -n "$sha" ] && skip_shas+=("$sha")
    done < <(comm -23 \
        <(git rev-list --no-merges "${base}..HEAD" | sort) \
        <(git rev-list --no-merges --right-only --cherry-pick "${tag}...HEAD" | sort))
done < <(
    git for-each-ref --format='%(refname:short)' \
        refs/heads/maintenance/ refs/remotes/origin/maintenance/ 2>/dev/null \
        | sed 's#^origin/##' | sort -urV
)

# Build the --skip-commit flag list once. Empty-array-safe under `set -u`.
skip_args=()
for sha in ${skip_shas[@]+"${skip_shas[@]}"}; do
    skip_args+=(--skip-commit "$sha")
done

# Field separator between the sort key and the section body; record marker that
# stands in for a section's internal newlines so each section is one sort line.
# Both are control chars that never appear in changelog text.
SEP=$'\037'
NL=$'\036'

sections=$(
    for range in "${ranges[@]}"; do
        # --skip-commit applies only to the Unreleased pass. The BASE..tag
        # release passes must keep their shared-history commits, which carry the
        # same hashes that appear in the skip list.
        if [ "$range" = "$HEAD_RANGE" ]; then
            git cliff --offline --strip all ${skip_args[@]+"${skip_args[@]}"} "$range"
        else
            git cliff --offline --strip all "$range"
        fi
    done | awk -v sep="$SEP" -v nl="$NL" '
        function flush() {
            if (body == "") return
            gsub(/\n/, nl, body)
            print key sep body
            body = ""
        }
        /^## \[/ {
            flush()
            if ($0 ~ /\[Unreleased\]/)
                key = "9999.9999.9999"   # sort above every real version
            else { v = $0; sub(/^## \[/, "", v); sub(/\].*/, "", v); key = v }
            body = $0 "\n"
            next
        }
        { body = body $0 "\n" }
        END { flush() }
    ' | sort -t"$SEP" -k1,1 -rV | cut -d"$SEP" -f2- | tr "$NL" '\n'
)

{
    printf '# Changelog\n\n'
    printf '<!-- Auto-generated by scripts/changelog.sh from Conventional Commits.\n'
    printf '     Hand-edits get clobbered on the next run. Put release narrative\n'
    printf '     in the GitHub release notes (gh release create) instead. -->\n\n'
    printf 'All notable changes to AppGrid are documented here.\n\n'
    printf '%s\n' "$sections"
} > CHANGELOG.md

echo "wrote CHANGELOG.md ($(wc -l < CHANGELOG.md) lines) from ${#ranges[@]} range(s):"
printf '  %s\n' "${ranges[@]}"
