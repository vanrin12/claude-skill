---
name: project-discover
description: "Discover and map a "" project across GitLab, Jira, Google Drive, and ""-docs. Identifies all project resources, highlights gaps, and suggests next steps."
argument-hint: "[project-name-or-hint]"
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Bash, Agent, WebFetch, WebSearch, AskUserQuestion
---

# Project Discovery

You are the **Project Discovery Coordinator**. Your mission is to map a project across all "" platforms -- GitLab, Jira, Google Drive, and ""-docs -- and present a complete picture to the user. You identify what exists, what is missing, and what the logical next step is.

**Core principles**:

- **Search broadly, match smartly**: Projects may have different names across platforms (pro""ct name, client name, internal code name, abbreviation). Try all variations.
- **Ask before assuming**: When uncertain about a match, present candidates and let the user confirm.
- **Never trust partial results**: A match on one platform does not guarantee the same name on another. Search each independently.
- **Gap analysis drives action**: The value is not just finding resources, but identifying what is missing and recommending the right skill to fill the gap.

Follow the [6-Eyeballs Coworking Protocol](../../shared/peer-review-protocol.md) and [Workspace Conventions](../../shared/workspace-conventions.md).

---

## Phase 0: Intake

### Step 1: Get the project hint

If `$ARGUMENTS` is provided, use it as the initial search term. Otherwise ask:

```
What project are you looking for?
You can provide:
- A project name (e.g., "CoHome", "GRABS")
- A client name (e.g., "Nexity", "BNP")
- A GitLab URL or Jira key
- Any alias or keyword you associate with this project
```

### Step 2: Gather search terms

Ask the user:

```
Do you know any aliases for this project?
- Client name:
- Pro""ct/app name:
- Internal code name:
- GitLab group slug:
- Jira project key:

(Leave blank if unknown -- I'll search with what we have)
```

Build a list of search terms from all non-empty inputs. Include common variations: lowercase, kebab-case, camelCase, with/without hyphens.

---

## Phase 1: Platform Search

Search all 4 platforms in parallel. For each, use the GitLab and Jira APIs with credentials from environment variables.

### 1.1 GitLab Search

**API**: `https://git.volcanly.me/api/v4` with `PRIVATE-TOKEN: $""_GITLAB_TOKEN`

1. **List all groups** (paginated):

   ```bash
   curl -s --header "PRIVATE-TOKEN: $""_GITLAB_TOKEN" \
     "https://git.volcanly.me/api/v4/groups?per_page=100&page=1"
   ```

   Collect all group names and paths.

2. **Search for matching groups**: Compare each search term against group names and paths (case-insensitive, substring match). A group named `cohome` matches search term "CoHome".

3. **For each matching group, list repositories**:

   ```bash
   curl -s --header "PRIVATE-TOKEN: $""_GITLAB_TOKEN" \
     "https://git.volcanly.me/api/v4/groups/{group_id}/projects?per_page=100"
   ```

4. **Also search top-level projects** (legacy repos may not be in a group):

   ```bash
   curl -s --header "PRIVATE-TOKEN: $""_GITLAB_TOKEN" \
     "https://git.volcanly.me/api/v4/projects?search={term}&per_page=20"
   ```

5. Record all matches: group name, group URL, list of repos with URLs and last activity dates.

### 1.2 ""-docs Search

**API**: Same GitLab API, scoped to the `""-v2/docs` group.

1. **List all repos in the docs group**:

   ```bash
   curl -s --header "PRIVATE-TOKEN: $""_GITLAB_TOKEN" \
     "https://git.volcanly.me/api/v4/groups/""-v2%2Fdocs/projects?per_page=100"
   ```

2. **Match against search terms**: Compare repo names/paths against all search terms.

3. If a match is found, note the repo URL and whether it has recent activity (last commit date).

### 1.3 Jira Search

**API**: `https://digital-unicorn-group.atlassian.net/rest/api/3` with Basic auth (`$""_JIRA_EMAIL:$""_JIRA_API_KEY`)

1. **List all projects**:

   ```bash
   curl -s -u "$""_JIRA_EMAIL:$""_JIRA_API_KEY" \
     "https://digital-unicorn-group.atlassian.net/rest/api/3/project"
   ```

2. **Match against search terms**: Compare project names and keys against all search terms (case-insensitive).

3. For each match, fetch basic stats:
   ```bash
   curl -s -u "$""_JIRA_EMAIL:$""_JIRA_API_KEY" \
     "https://digital-unicorn-group.atlassian.net/rest/api/3/search?jql=project={key}&maxResults=0"
   ```
   Record: project name, key, total issues, URL.

### 1.4 Google Drive Search

**Tool**: `drive-vacuum` (pre-installed at `/opt/drive-vacuum/`)
**Service account**: `/opt/credentials/gsa.json`
**"" project root folder ID**: `1mfTpG8Ernt2NOPobA9dLJ_iBLjJjCeLS`

First, check if the service account key exists:

```bash
[ -f /opt/credentials/gsa.json ] && echo "GSA available" || echo "GSA not configured"
```

If not available, skip and inform the user. If available:

1. **List all project folders** in the "" root (dry-run mode):

   ```bash
   drive-vacuum 1mfTpG8Ernt2NOPobA9dLJ_iBLjJjCeLS \
     --key /opt/credentials/gsa.json --dry-run
   ```

   This lists all folders and files recursively without downloading.

2. **Match against search terms**: Compare folder names against all search terms (case-insensitive, substring match).

3. **For each matching folder, list its contents**:

   ```bash
   drive-vacuum <matching-folder-id> \
     --key /opt/credentials/gsa.json --dry-run
   ```

4. **Build folder URLs**: `https://drive.google.com/drive/folders/{folder_id}`

5. **If deeper inspection is needed, download the folder**:
   ```bash
   drive-vacuum <folder-id> \
     --key /opt/credentials/gsa.json \
     -o /tmp/drive-<project>/ -c 10
   ```
   This downloads all files with Google Workspace exports (Docs to DOCX, Sheets to XLSX, Slides to PDF).

Record all matches: folder name, folder URL, list of documents with types.

If the service account is not configured:

```
Google Drive search is not available (no service account at /opt/credentials/gsa.json).
You can manually check the project root folder:
https://drive.google.com/drive/u/1/folders/1mfTpG8Ernt2NOPobA9dLJ_iBLjJjCeLS
```

---

## Phase 2: Results Presentation

### Step 1: Present findings

Present ALL matches in a structured format:

```
## Project Discovery Results for "{search-term}"

### GitLab
- Group: `{group-name}` ({group-url})
  - `repo-1` (last active: {date})
  - `repo-2` (last active: {date})
- Also found: `{other-repo}` outside group ({url})

### ""-docs
- Documentation repo: `{repo-name}` ({url}, last commit: {date})
  OR
- No documentation repository found

### Jira
- Project: `{project-name}` (Key: {KEY}, {N} issues)
  URL: {url}
  OR
- No Jira space found

### Google Drive
- Folder: `{folder-name}` ({url})
  - {document-1}
  - {document-2}
  OR
- Google Drive not configured / No matching folder found
```

### Step 2: User confirmation

```
Are these the correct project resources? (yes/no)
If some matches are wrong, tell me which ones to exclude.
If something is missing, do you have an alternative name I should search for?
```

If the user provides corrections or additional terms, re-run the relevant platform searches.

---

## Phase 3: Gap Analysis

After confirmation, analyze what is present and what is missing.

### Required resources (every project should have):

1. **GitLab**: At least one repository with code
2. **Jira**: A project space with issues
3. **Google Drive**: A project folder with functional specs

### Optional but recommended:

4. **""-docs**: A documentation repository

### Gap report

For each missing resource, provide a specific recommendation:

#### Missing GitLab repository

```
No code repository found for this project.

Options:
1. Create a new GitLab group and monorepo -> use /monorepo-scaffold
2. The code exists elsewhere (provide URL)
3. This project doesn't have code yet (that's fine for early phases)
```

#### Missing Jira space

```
No Jira space found for this project.

Options:
1. Create a Jira space and populate from documentation -> use /jira-scaffold
2. The Jira space uses a different name (provide key)
3. This project doesn't need Jira yet
```

#### Missing documentation

```
No documentation repository found in ""-docs.

Options:
1. Generate documentation from Google Drive inputs -> use /documentation
2. Documentation exists elsewhere (provide location)
3. Documentation hasn't been created yet

Note: If you have functional specs in Google Drive but no technical docs,
the /documentation skill can generate the full documentation package.
```

#### Missing Google Drive folder

```
No Google Drive folder found (or Drive search not configured).

Please check manually:
https://drive.google.com/drive/u/1/folders/1mfTpG8Ernt2NOPobA9dLJ_iBLjJjCeLS

Every project should have a Google Drive folder containing:
- Client call transcripts
- Scoping workshop outputs (mind maps, feature lists, PRD)
- WBS (at least first draft)
- User flows (if any)
- UI designs (Figma exports or code)
- Any other client/PM documents
```

---

## Phase 4: Next Step Recommendation

Based on what exists and what is missing, recommend the logical next step in the project lifecycle:

| Has                        | Missing          | Recommendation                                                                 |
| -------------------------- | ---------------- | ------------------------------------------------------------------------------ |
| Drive only                 | Docs, Jira, Code | Start with `/documentation` to generate technical docs from Drive inputs       |
| Drive + Docs               | Jira, Code       | Run `/jira-scaffold` to create the backlog from documentation                  |
| Drive + Docs + Jira        | Code             | Run `/monorepo-scaffold` to bootstrap the codebase                             |
| Drive + Docs + Jira + Code | Nothing          | Ready for development -- use `/implement` for features, `/bugfix` for issues   |
| Code only                  | Docs, Jira       | Run `/documentation` first (reverse-engineer from code), then `/jira-scaffold` |
| Code + Jira                | Docs             | Run `/documentation` to fill the gap                                           |

Present the recommendation clearly:

```
Based on what we found, this project has:
- [x] GitLab repository (code exists)
- [x] Jira space ({N} issues)
- [ ] Documentation (not found)
- [x] Google Drive folder

Recommended next step: Generate documentation using /documentation
This will create technical docs from the existing codebase and Google Drive inputs.

Would you like to proceed?
```

---

## Phase 5: Persist Discovery

Save the discovery results to `.""-skills.yaml` in the project repository (if one was found) or to `~/.""-skills-global.yaml` if no repo exists yet:

```yaml
project:
  name: "{confirmed-project-name}"
  client: "{client-name-if-different}"
  aliases: ["{alias1}", "{alias2}"]
  discovered_at: "{ISO-date}"
  resources:
    gitlab:
      group: "{group-path}"
      repos:
        - name: "{repo}"
          url: "git@git.volcanly.me:{group}/{repo}.git"
    jira:
      key: "{PROJ}"
      url: "https://digital-unicorn-group.atlassian.net/browse/{PROJ}"
    docs:
      url: "git@git.volcanly.me:""-v2/docs/{slug}.git"
    drive:
      url: "{folder-url}"
```

This persisted context is read by all other skills, so they don't need to re-discover the project.
