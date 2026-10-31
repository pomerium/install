# Pomerium Zero plugin

This directory packages the hosted Pomerium Zero MCP server,
`https://mcp.pomerium.app`, for the Anthropic (Claude) and OpenAI (ChatGPT
and Codex) plugin directories. Neither directory has an upload API, so an
operator submits by hand using the steps below.

| Path | Contents |
| --- | --- |
| `claude/` | The Claude plugin folder. Anthropic's directory reads it straight from this public repository, so this folder is what Claude users install. Its `README.md` is the listing description. |
| `openai/` | The OpenAI manifests in [Agent Plugins](https://agent-plugins.org/) format, and the OpenAI-only composer icon. The bundle reuses `README.md`, `LICENSE`, and the logo from `claude/`. |
| `tools/` | Pinned validators: the Claude Code CLI for `claude plugin validate`, and Ajv for JSON Schema checks. |
| `Makefile` | Build and validation targets. |

## Build and validate

You need Node.js at the version in `.tool-versions`, plus `curl` and `zip`.
From the repository root:

```bash
make zero-plugin    # same as: make -C zero/plugin bundle
```

This runs these checks and writes `zero/plugin/dist/pomerium-zero-openai-<version>.zip`:

- **Claude:** `claude plugin validate --strict claude`, Anthropic's
  [plugin validator](https://code.claude.com/docs/en/plugins/cli-reference#plugin-validate).
  The developer portal's **Validate** step runs more checks than this command,
  such as name conflicts.
- **OpenAI:** OpenAI publishes no validator, and its dashboard checks the ZIP
  on upload. Before that, `validate-openai` checks `plugin.json` and
  `mcp.json` against the official
  [Agent Plugins JSON Schemas](https://github.com/agentplugins/agent-plugins-spec/tree/main/schemas),
  checks `plugin.json` against `tools/openai-submission.schema.json` (the
  field limits and test-case counts from OpenAI's
  [submission guide](https://developers.openai.com/plugins/deploy/submission)),
  and checks that every image the listing names is in the bundle.
- **Both:** the two manifests have the same `version`.

The [Zero Plugin workflow](../../.github/workflows/zero-plugin.yaml) runs the
same build on pull requests that touch `zero/plugin/`, on `main`, and on
demand. Each run uploads a `zero-plugin` artifact that contains the OpenAI ZIP.
The workflow doesn't create GitHub releases, because `helm.yaml` publishes the
Helm chart on every release.

## Release a new version

1. Make the change, and raise `version` in both
   `claude/.claude-plugin/plugin.json` and `openai/plugin.json`. Claude Code
   keeps users on the installed `version` until it changes.
2. Merge to `main`.
3. Anthropic picks up the commit from the tracked branch and scans it. See
   [Update a published plugin](https://claude.com/docs/plugins/submit#update-a-published-plugin).
4. Upload the new ZIP to OpenAI with **Upload plugin to make changes**, as in
   step 2 of [Submit to OpenAI](#submit-to-openai).

Changing the MCP server's tools doesn't need a new plugin version. Anthropic
syncs the connector's tools from the server, and OpenAI rescans the server
daily or when you select **Rescan**.

## Before the first submission

- [ ] **OpenAI domain verification.** OpenAI asks you to serve a token as
  plain text at `https://mcp.pomerium.app/.well-known/openai-apps-challenge`.
  That path currently hits the MCP route and returns 401. Add a public route
  or direct response for it on the cluster that serves `mcp.pomerium.app`.
- [ ] **Reviewer account.** Both directories need credentials for a
  populated Pomerium Zero account: an organization with a cluster, routes, and
  policies. OpenAI's account must sign in without MFA, email or SMS codes, or
  magic links. Enter the credentials in the portals, never in this
  repository. The OpenAI test cases in `openai/plugin.json` create and delete
  a route named `review-demo`.
- [ ] **Public documentation.** Anthropic requires public setup and usage
  documentation by the publish date. The listings link to `claude/README.md`
  on GitHub. If a page on pomerium.com/docs replaces it, update `homepage` and
  `documentationUrl` in both manifests.
- [ ] **Logo.** `claude/assets/logo.png` is the console's 180×180 app icon.
  OpenAI's [package guide](https://developers.openai.com/plugins/build/plugins)
  recommends at least 256×256, so replace it with an official square mark when
  one is available.
- [ ] **Tool annotations.** Both directories check that every tool has a
  title and hints, and pomerium-zero's MCP tests enforce this. OpenAI's
  [guidelines](https://developers.openai.com/plugins/plugin-guidelines) also
  ask for an explicit `destructiveHint` on read-only tools, which the
  generated tools in `pomerium/pomerium` (`pkg/mcp/configapi`) leave out. If
  OpenAI's tool scan flags them, fix it there.

## Submit to Anthropic

Read [Publish to the directory](https://claude.com/docs/directory/publish)
first. Submit from Pomerium's claude.ai organization as an Owner, or as a
member with the **Directory** permission. The first organization to submit a
repository folder owns that listing.

Anthropic asks for two submissions: the server as an MCP connector, and the
plugin bundle that points at the same URL. You then pair them, and users who
have both see one set of tools.

### 1. MCP connector

Work through the
[connector pre-submission checklist](https://claude.com/docs/connectors/building/review-criteria),
then follow [Submit a connector](https://claude.com/docs/connectors/building/submission).
In the [developer portal](https://claude.ai/directory/manage), select
**Submit new** and then **MCP connector**:

| Step | Field | Value |
| --- | --- | --- |
| Connection | Server URL | `https://mcp.pomerium.app` |
| Listing | Name | `Pomerium Zero` |
| | One-liner | `description` from `claude/.claude-plugin/plugin.json` |
| | Description | `longDescription` from `openai/plugin.json` |
| | Categories | The closest matches, such as developer tools or security |
| | Documentation URL | `https://github.com/pomerium/install/tree/main/zero/plugin/claude#readme` |
| | Privacy policy URL | `https://www.pomerium.com/privacy-policy` |
| | Support contact | `support@pomerium.com` |
| | Icon | `claude/assets/logo.png` |
| | Slug | `pomerium-zero`. It's permanent once published. |
| Use cases | Prerequisites | A Pomerium Zero account in an organization with a cluster |
| | Reads or writes | Both |
| Company | Name and website | `Pomerium, Inc.`, `https://www.pomerium.com` |
| Authentication | Mode | OAuth with client ID metadata documents. The server advertises `client_id_metadata_document_supported` and has no dynamic client registration endpoint. |
| Data handling | API ownership | Your own first-party API. No health data and no sponsored content. |
| Test & launch | Reviewer access | The reviewer account. Confirm you ran every tool through [MCP Inspector](https://modelcontextprotocol.io/docs/tools/inspector) or as a custom connector. |
| Compliance | Acknowledgements | All seven are required. |

Escalations go to `mcp-review@anthropic.com`.

### 2. Plugin bundle

Work through the
[plugin pre-submission checklist](https://claude.com/docs/plugins/pre-submission-checklist),
then follow [Submit your plugin](https://claude.com/docs/plugins/submit).
Connect a GitHub account with push access to `pomerium/install` to the
claude.ai organization first. In the portal, select **Submit new** and then
**Plugin bundle**:

- **Source:** repository `pomerium/install`, plugin path `zero/plugin/claude`,
  and the branch or tag to track, which defaults to `main`. Select
  **Validate**, then fix any **Blocking** finding and validate again.
- **Listing details:** read from `plugin.json` and `README.md`. To change
  them, edit those files and validate again.
- **Data handling:** the plugin stores no data, sends data only to its
  declared connector, follows Pomerium's privacy policy for retention, and
  isn't intended for people under 18.
- **Compliance:** confirm the contact email and select all four
  acknowledgements.
- **Review and submit:** choose **GitHub push webhook**, which needs admin
  access to `pomerium/install`, or **Scheduled check only**. Then select
  **Submit for review**.

[Track your submission](https://claude.com/docs/directory/submission-status)
explains each status. Once the plugin and connector are both listed, pair them
from the portal.

## Submit to OpenAI

Read [Upload and submit your plugin](https://developers.openai.com/plugins/deploy/submission)
and the [plugin guidelines](https://developers.openai.com/plugins/plugin-guidelines).
Submit from Pomerium's OpenAI organization as an owner, or as a member with
**Apps Management Write**, after completing business verification in the
organization settings. The MCP server's origin can't change between plugin
versions, so `mcp.pomerium.app` is permanent once submitted.

1. Download the `zero-plugin` artifact from the latest
   [Zero Plugin](https://github.com/pomerium/install/actions/workflows/zero-plugin.yaml)
   run on `main`, or run `make zero-plugin`. GitHub wraps artifacts in a ZIP,
   so extract `pomerium-zero-openai-<version>.zip` from it.
2. In the [plugin dashboard](https://platform.openai.com/plugins), choose the
   organization, project, and verified developer identity, and upload the ZIP.
   Fix any **Metadata & Skills** findings and upload again with **Upload
   plugin to fix issues**.
   [Submission errors](https://developers.openai.com/plugins/deploy/submission-errors)
   explains each finding.
3. In the **MCPs** section, complete domain verification (see
   [Before the first submission](#before-the-first-submission)), then connect
   and authenticate. ChatGPT registers with a client ID metadata document,
   and its redirect URI is `https://chatgpt.com/connector_platform_oauth_redirect`.
   See [Authentication](https://developers.openai.com/apps-sdk/build/auth).
   Wait for the tool scan, fix any findings on the server, and select
   **Rescan**.
4. Enter the review details: the reviewer account's credentials, the login
   URL `https://console.pomerium.app`, sign-in instructions, and what data the
   account holds.
5. Select **Submit for review**, confirm the policy attestations, and follow
   **Review status**. After approval, select **Publish plugin**.

## Upgrade the validators

- **npm tools** (`tools/package.json`): Dependabot opens a weekly grouped
  `zero-plugin-tools` pull request, and the Zero Plugin workflow validates it.
- **Agent Plugins schemas:** the build downloads them from
  [agentplugins/agent-plugins-spec](https://github.com/agentplugins/agent-plugins-spec)
  at the tag set by `AGENT_PLUGINS_SPEC_VERSION` in the `Makefile`. Run
  `make -C zero/plugin update-spec` to move that pin and the `$schema` URLs in
  `openai/*.json` to the latest tag. Then run `make zero-plugin` and read the
  spec's changes before merging.
