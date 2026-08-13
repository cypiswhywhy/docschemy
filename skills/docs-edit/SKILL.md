---
name: docs-edit
description: Change existing documentation because a person wants it different — clearer, restructured, in their own voice or house style — rather than because the code changed. Verifies every factual claim in the request against the repo before writing it, keeps the edit inside the docs-init convention (routing, page naming, one canonical home, relative links, diagrams), and records durable preferences in the project's CLAUDE.md so later runs don't revert them. Use for "rewrite this page", "always write it this way", "split / merge / rename these pages", "add a diagram here", or applying one style rule across the docs. Not for syncing docs to a code change (that's docs-update), scaffolding or auditing a whole tree (docs-init), or answering a question from the docs (docs-search).
---

# docs-edit

Applies a person's request to existing documentation: make this clearer, cut this in half, use our terms, split this page, add a diagram, always write it this way.

The other write-skills take their instructions from the repo — `docs-init` from a survey, `docs-update` from a diff. This one takes them from the user, which changes exactly one thing and it is the thing that matters:

> **The user decides how the docs read. The repo decides what they say.**

Everything below is downstream of that split. §2 is the rule; treat it as this skill's spine, not as a caveat.

Assumes docs that already exist. If there's no `docs/` tree, this is `/docs-init`. If the docs need changing because the *code* changed, this is `/docs-update` — that skill reads the diff, deletes what the change removed, and writes an ADR when a decision moved; none of which belongs here. If the request is really a question ("what do we say about retries?"), it's `/docs-search`, which is read-only.

## 1. Scope the request before touching anything

- **Which pages?** If the user named one, that's the scope. If they described a symptom ("the install docs are confusing"), find the pages first and say which ones you're about to change before you change them.
- **How wide?** A single page, a subject's group of pages, or one rule across the whole tree (§5) are three different jobs with three different costs. When the request is ambiguous between them, ask — one question now beats reverting a tree-wide rewrite.
- **Is it durable?** "Always", "from now on", "in all my projects", "I prefer" mean the answer outlives this run and has to be recorded (§4). "Just fix this paragraph" doesn't.
- **Read the pages end to end** before editing. This skill's edits are motivated by how a page reads, which you cannot judge from a grep hit.

Don't restructure anything the request doesn't reach. The temptation is strongest here of all four skills, because you're already reading the page critically — but an unrequested "while I was in there" rewrite is indistinguishable from drift to whoever reviews it. Note it in the summary and leave it.

## 2. Sort every instruction into style, structure, or fact

Go through the request clause by clause. Each one is exactly one of these, and they get different treatment.

**Style — the user is the authority. Apply it.** Tone, voice, terminology, sentence length, heading depth, how many examples, table versus prose, British versus American spelling, whether diagrams lead or follow. There is nothing to verify; these are preferences and the user owns them.

**Structure — apply it inside the convention, or say what it breaks.** Splitting, merging, renaming, moving, deleting pages. Most requests fit the convention fine and just need its rules applied (§3). When one doesn't — a flat `docs/deployment.md` beside the sections, a fact deliberately stated on two pages, an `index.md` landing — say in one or two sentences what the convention gives up and what it costs later, then do what the user decides. If they confirm, it's a deliberate override and gets recorded as one (§4), so the next run reads it as intent rather than as drift to correct.

**Fact — the repo is the authority. Verify before writing.** Any claim about what the software does: behavior, defaults, flag names, versions, commands, ordering, what calls what. Users misremember their own projects, and a request phrased as a wording change ("just mention that it retries three times") smuggles in an assertion that has to be true. Check each one against the code or config, then:

- **Confirmed** → write it.
- **Contradicted by the repo** → don't write it. Say what you found, with the file and line. This is not obstruction — it's the entire reason a human asked a tool that can read the code instead of editing the page themselves. If the user tells you the repo is wrong and the doc should say it anyway, that's their call: write it, and flag it in the summary.
- **Unconfirmable from the repo** → often legitimate. Deployment hosts, ops procedures, product intent and history are real facts the code simply doesn't contain, and the user is a better source than the repo is. Write it, and list it in the summary as user-sourced, unverifiable here. Use `<!-- TODO: verify -->` only when nobody has actually asserted it and you'd otherwise be guessing.

**A style rewrite must not become a fact rewrite.** This is where facts die quietly: "make it shorter" turns *retries up to 3 times with exponential backoff* into *retries a few times*, and nobody reviewing a wording change catches it. So after rewriting a passage, compare the **claims**, not the words — every command, number, name, default, condition and ordering in the old text either survives into the new text or was dropped on purpose. Anything you can't restate accurately in the new voice stays in the old words.

## 3. Keep the edit inside the convention

The convention isn't suspended because the request came from a person. `docs-init` holds the normative rules; the ones an edit-shaped run hits constantly:

- **Routing** (§2) — content that moves between pages must land in the section its audience and mode call for, not wherever the request happened to point. The `usage/` black-box boundary holds: a step needing a source checkout isn't a usage page even when a user asks for it there.
- **One mode per page** (§10) — "add how to set it up" to an explanation page produces two pages, not a mixed one. Say so and split it.
- **One canonical home per fact** (§12) — before adding a passage, grep the docs and both root files for its subject. If it already lives somewhere, link instead of restating; if the user wants it stated in both places, that's the structural override path above, not a silent second copy.
- **Naming** (§4) — a page created, renamed or split here follows its siblings: lowercase kebab-case, subject first, no doc-type suffixes, one grouping mechanism per subject. If the user's chosen filename breaks the section's pattern, say what the pattern is and offer the conforming name.
- **Moves, renames and deletions ripple** (§13) — grep the whole repo, including `CLAUDE.md`, `.claude/`, CI, tests and site-generator nav, and repoint every reference; deletions get the link removed, not repointed. Relative depth into `../assets/` changes on every move, and a broken figure renders as quiet alt text rather than an obvious error.
- **Landings index, they don't teach** (§3) — a page added or removed here updates its section `README.md` listing in the same run.
- **Relative links only**, and no invented content (§10).

**Visuals** follow `docs-init` §11 in full. "Add a diagram here" means picking the type from the content — `flowchart` / `sequenceDiagram` / `stateDiagram-v2` / `erDiagram` — and drawing only what you traced in the repo; a diagram asserts relationships as fact and reads as authoritative even when it's wrong. If the request asks for a picture of something the repo doesn't let you draw accurately, leave a `<!-- TODO: verify -->` describing the diagram it needs and say so, rather than drawing a plausible one. "Turn this paragraph into a diagram" usually also means deleting the paragraph — keeping both is the redundancy §12 exists to prevent.

**ADRs are immutable** (§8). Accepted records don't get restyled, tightened, or "improved" on request, and this skill writes none — a decision that actually changed is `/docs-update`'s job, sourced from the change that made it. If a user wants an accepted ADR rewritten, explain that the log's value is that it's a log and offer a superseding record instead; if they still want it, it's their repo — do it and say plainly in the summary that an accepted ADR was edited.

## 4. Record durable preferences so the next run honors them

A preference applied only to today's pages is undone by the next `/docs-update`, which has no way to tell a deliberate deviation from drift. Recording it is what makes the change stick — and it's the whole of "make the docs consistent with how I want them".

**Where:** the project's `CLAUDE.md`, under a `## Docs preferences` heading, as short imperative bullets. Claude Code loads that file every session, so every docs skill sees them with no extra machinery, no new file format, and nothing to install. Append to the block; never rewrite the rest of the file.

```markdown
## Docs preferences

- Use British spelling.
- Keep usage pages under 150 lines; split rather than scroll.
- Lead every internals page with its diagram, before the prose.
```

**Which scope:** a preference about *this* project goes in its `CLAUDE.md`. One the user wants everywhere ("in all my projects") goes in `~/.claude/CLAUDE.md`. If they said "always" without saying where, ask — it's one question, and the wrong choice is invisible until it shows up in an unrelated repo.

**What may be recorded:** style freely. Structural overrides only when the user confirmed one in §2, written as the override it is with a clause of why — `Deployment lives at docs/deployment.md rather than under usage/ (ops team links to that path)` — so a later run reads intent instead of correcting it. Never record something that would make the docs assert unverified facts; "don't check claims against the code" is not a preference this skill can honor.

Also *read* that block at the start of every run, and apply it alongside the request. And when a request contradicts a recorded preference, say so before applying it, then ask whether this run is an exception or the preference has changed.

## 5. Applying one rule across the docs

"Make it all consistent with X" is a sweep: one rule, every page. It's bounded — unlike a `docs-init` reconcile, which re-reads everything against every rule — so it belongs here.

- Record the rule first (§4), then apply it, so the two can't disagree.
- List the pages in scope up front and say how many you're about to touch. A sweep is the one thing here that can produce an unreviewably large diff.
- Apply only that rule. A page you opened for spelling doesn't get its structure fixed too; note anything else you saw for the summary.
- Keep §2's claim-comparison discipline on every page, not just the first few. A sweep is where a rewrite quietly loses facts, because attention runs out before pages do.
- If the sweep would touch nearly every page *and* keeps turning up unrelated staleness, stop and say a `/docs-init` reconcile is the honest tool — it audits naming, visuals and redundancy as dedicated passes, which a single-rule sweep deliberately does not.

## 6. Verify

- Resolve every relative link **and every `![…]()` figure path** in the pages you touched, and in anything that links to them, against the filesystem. Script it; a link check covering only edited files misses the landing page that still lists the page you renamed.
- If pages moved, renamed or were deleted, grep the repo for the old paths and require zero hits.
- Confirm every Mermaid block you added or edited opens with a valid diagram type and has a balanced fence — a typo'd block renders as raw text on GitHub.
- Re-read each edited page once as a whole. Style edits are judged by reading, and a paragraph that was fine in isolation can now repeat the one above it.
- Check `docs/assets/` both ways if figures moved: nothing referenced is missing, nothing left behind is unreferenced.
- Build the site if there is one; run the tests if doc paths appear in them.

## 7. Finish with a summary

Report which pages changed and what each change was — separating **style** edits from **structural** ones from anything that changed a **factual claim**, because those carry very different review weight. Then, explicitly:

- Every claim from the request that the repo **contradicted**, and what you wrote instead.
- Every claim written on the **user's authority** because the repo couldn't confirm it.
- Any **preference recorded**, quoted as written, and into which `CLAUDE.md`.
- Any **convention rule the user overrode**, and what it costs later.
- What you **deliberately left alone** — the staleness, duplication or missing diagrams you noticed outside this request's scope. Name them, don't fix them, and say that `/docs-init` reconcile is what sweeps them.
