# Pomerium Zero

Connect your AI assistant to [Pomerium Zero](https://www.pomerium.com/), the
hosted control plane for Pomerium's identity-aware proxy. You can then review
and change the routes, policies, service accounts, and settings of your
Pomerium Zero clusters from a conversation.

## Requirements

- A Pomerium Zero account. Sign up at
  [console.pomerium.app](https://console.pomerium.app).
- Membership in an organization that has at least one cluster.

## What this plugin contains

The plugin has no local code. It registers one remote MCP server,
`https://mcp.pomerium.app`, which Pomerium operates. It doesn't run commands
or install packages on your machine.

## Sign in

The first time your assistant calls a tool, it opens a browser window where
you sign in to Pomerium Zero with OAuth. The server acts with your Pomerium
Zero permissions, so it sees only the organizations and clusters your account
can access. Changes made through the plugin appear in the console's
deployment history, attributed to your account.

## Tools

Read-only tools, which don't change anything:

- List the organizations and clusters you can access
- List and get routes, policies, service accounts, key pairs, and cluster
  settings
- List the log fields available for access logs

Tools that change configuration. Each one is annotated as a write, and
delete tools as destructive, so your assistant can ask you to confirm
before running them:

- Create, update, and delete routes, policies, and service accounts
- Update cluster settings
- Delete key pairs

Uploading or replacing key pairs isn't available, because key pairs contain
private keys. Use the console for those.

## Example prompts

- "Which Pomerium Zero clusters can I access?"
- "List the routes in my cluster and the policy attached to each one."
- "Create a route named grafana that sends traffic to
  http://grafana.internal:3000."

## Data and privacy

- The tool inputs your assistant sends, such as a route definition, go to
  `https://mcp.pomerium.app`. Responses contain the configuration your account
  can access.
- The plugin sends data to no other destination.
- Pomerium records which tool was called, and for which organization and
  cluster, for product analytics.

Pomerium's [privacy policy](https://www.pomerium.com/privacy-policy) covers
what data Pomerium collects, how it is used and stored, who it is shared
with, how long it is kept, and how to contact Pomerium. Use of Pomerium Zero
is subject to the
[Pomerium Zero terms and conditions](https://www.pomerium.com/zero-terms-and-conditions).

## Support

Email [support@pomerium.com](mailto:support@pomerium.com) or use
[pomerium.com/contact](https://www.pomerium.com/contact). Product
documentation is at [pomerium.com/docs](https://www.pomerium.com/docs).

## License

Apache-2.0. See [LICENSE](LICENSE).
