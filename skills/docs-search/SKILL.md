---
name: docs-search
description: Answer a question from a project's existing documentation without changing it — read-only. Searches the structure docs-init creates (README.md, CONTRIBUTING.md, docs/usage, docs/reference, docs/internals with ADRs) audience-first instead of grepping blind, cites the exact page and heading each part of the answer came from, and reports which of three things happened: the docs answered it, the docs are silent on it, or the docs contradict the code. Use when someone asks where something is documented, what a flag, endpoint or config key does, how to carry out a task, or why the project works the way it does. Not for writing docs — use docs-update after a code change, or docs-edit to improve a page on request.
---

# docs-search

Answers a question from the project's documentation, cites where the answer came from, and says plainly when the docs don't have it.

**This skill never writes.** No edits, no new pages, no "while I was in there" fixes — not to `docs/`, not to `README.md` or `CONTRIBUTING.md`. That is what makes it safe to invoke in the middle of unrelated work, and it's the contract the user is relying on when they ask a question rather than asking for a change. When the run turns up something that should be fixed, name it and offer the skill that fixes it (§6); if the user says yes, that's a new job under `/docs-edit` or `/docs-update`, and say so as you switch.

It works on any layout. Unlike `docs-update`, this skill does not stop when the docs don't follow the convention — the convention only makes the search *faster*. An older Diátaxis-only tree (`docs/tutorials`, `docs/how-to-guides`, `docs/explanation`), someone else's structure, or a bare `README.md` all still get searched (§5).

## 1. Read the question first: fact, or map?

Two shapes arrive under the same phrasing, and they want different answers.

- **A fact question** — "what does `--strict` do", "how do I deploy to staging", "why is it built on a queue". Answer it, cite the page, done.
- **A map question** — "what do we have on authentication", "is any of this documented", "where would I read about the storage layer". The answer is a short annotated list of pages, not a paragraph of content. Don't collapse it into one page's worth of prose.

When the question is genuinely both ("where's the retry logic documented and what does it say"), give the map first, then the fact.

## 2. Locate before you read

The structure predicts where an answer lives, so start there instead of grepping the tree blind. Ask **who would have written this down** and **what kind of statement it is**:

| The question sounds like… | Look first | Then |
| --- | --- | --- |
| what a flag, endpoint, config key, env var, schema or skill/command does | `docs/reference/` | the code that defines it |
| how do I install / configure / deploy / troubleshoot X | `docs/usage/` | `docs/usage/tutorials/` |
| where do I start with this project | `README.md`, `docs/usage/tutorials/` | `docs/usage/README.md` |
| how does it work, what talks to what, what happens when | `docs/internals/` | the code |
| **why** is it this way, why that library, why not the obvious thing | `docs/internals/adrs/` | `docs/internals/` |
| how do I run the tests, set up a dev env, cut a release | `CONTRIBUTING.md` | `docs/internals/development/` |
| what is this project, what does it do | `README.md` | `docs/README.md` |

The **why → `adrs/`** row is the one worth remembering: decision records are where the alternatives and costs live, and they are the last place anyone thinks to look. A "why" question answered only from an `internals/` page usually has a better answer one directory down.

Read `docs/README.md` and the relevant section landing before grepping. They are indexes by design — cheaper to read than the tree is to scan, and they name pages whose filenames don't match the user's words.

## 3. Search technique

- **Translate the vocabulary first.** The user's word is often not the repo's word — "login" vs `auth`, "job" vs `task`, "cluster" vs `pool`. If a search on the user's term comes back empty, grep the *code* for it, find the real identifier, and search the docs for that. Reporting "not documented" because you searched the wrong noun is the most common way this skill gets an answer wrong.
- **Grep `README.md` and `CONTRIBUTING.md` too.** They sit outside `docs/` and hold real content — the quickstart, every contributor procedure — so a search scoped to `docs/` misses a whole audience's worth of answers.
- **Follow the link rather than trusting the hit.** The convention puts every fact in exactly one canonical home and links to it from everywhere else (`docs-init` §12), so a grep hit is frequently a one-line mention plus a link — not the answer. Follow it. The canonical page is what you cite.
- **Read the page, not the grep line.** You need the surrounding heading to cite it and the surrounding paragraphs to know whether the line still means what it looks like in isolation.
- **Search the diagrams.** A component, a queue, or a state can be named *only* inside a Mermaid block or an image's alt text. Those are text and grep finds them — but a prose paraphrase won't match the identifier, so when a term comes back thin, scan the diagrams on the pages that ought to cover it.
- **Check for `<!-- generated by: … -->`** at the top of a reference page. It's still an answer; it's just only as fresh as the last time that command ran, which is worth one clause when you cite it.
- **Note `<!-- TODO: verify -->` markers** on anything you're about to cite. That marker means a previous run refused to guess — passing its neighborhood off as settled fact is worse than saying the docs are unsure.

## 4. Cite only what you have read

Every citation is a relative path from the repo root plus the heading — `docs/reference/cli.md#strict` — so the user can open it. Two rules make citations worth anything:

- **Never cite a page you didn't open, and never cite a heading you didn't see.** A plausible-looking path that doesn't exist, or a real page that doesn't actually contain the claim, is the characteristic failure of doc search, and it costs the user more than "I couldn't find it" ever would.
- **Never answer from general knowledge of how projects like this usually work.** If it isn't in this repo's docs or this repo's code, it is not an answer — it's a guess wearing an answer's clothes. Say the docs are silent and stop.

Lead with the answer, then the citation; don't narrate the search. Summarize rather than pasting the page — quote only the line that carries the fact (an exact command, a default value). When the honest answer spans two sections — the how-to in `usage/`, the why in an ADR — give both, briefly, with both citations.

## 5. Three outcomes, and say which one it was

The user needs to know how much to trust the answer, and that depends entirely on where it came from.

**The docs answer it.** Answer and cite. Verify against the code when the claim is *operational and cheap to check* — a command, a flag name, a path, a default — because those are what someone is about to act on, and one grep settles them. Don't re-derive a subsystem to double-check an explanation page.

**The docs are silent.** Say that first, plainly: "this isn't documented" is a real answer and the user needs it, because their next move depends on it. Then answer from the code if you can, marking clearly which parts came from code rather than docs. Name where the answer *should* live per the §2 table — that turns a dead end into a gap someone can close.

**The docs contradict the code.** This is the most valuable thing this skill finds, and it only surfaces at the moment someone actually cares about the page. Report both readings, say the code is what runs, and cite the page and line that are wrong. Don't fix it here (§6).

Two partial cases worth naming rather than rounding off: an answer that's **right but incomplete** (the flag is documented, its interaction with the other flag isn't), and one that's **stale but not wrong** (still true, describes a version behind). Say which you've got.

**When there is no docs tree at all**, or it follows a different convention, search what exists — `README.md`, code-adjacent Markdown, docstrings, config comments — answer from it, and mention `/docs-init` once at the end. Don't refuse, and don't turn a question into a pitch.

## 6. Hand off what you found, don't fix it

Close with whatever the search exposed about the docs themselves, phrased as an offer rather than an edit:

- **A gap** (the docs are silent) → `/docs-edit` if it's a page that should exist or be extended; `/docs-update` if the thing is undocumented because a recent change added it.
- **A contradiction** (docs disagree with the code) → `/docs-update` when a code change caused it, `/docs-edit` when the page was simply wrong.
- **Something structurally off** — a fact duplicated across two pages that now disagree, an orphan page nothing links to, a whole section that's empty — → `/docs-init` reconcile, which is the pass that sweeps those.

One line each. A question that got answered shouldn't turn into a documentation project unless the user wants one.

## 7. Finish

Give the answer, its citations, and — in a sentence — where you looked if the answer was thin or absent, so the user can tell a genuine gap from a search that missed. If you answered from code rather than docs, say so explicitly rather than letting the citation-shaped output imply otherwise. List any doc gaps, contradictions or `<!-- TODO: verify -->` markers you crossed, and stop there: this skill's whole value is that it can be trusted not to have touched anything.
