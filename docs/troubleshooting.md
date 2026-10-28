# Troubleshooting

Work the pipeline from **receiver to sender**: Rocket.Chat → direct POST → GitLab outbound policy → GitLab integration test → real event.

## `Invalid user [error-invalid-user]`

In **Rocket.Chat → Manage → Workspace → Integrations**, `Post as` must be an *existing Rocket.Chat username*, not an arbitrary display label. Verify it exists and is active. `Alias` can be a friendly visual name; it does not create a user.

## `The user must exist and have the message-impersonate permission`

Rocket.Chat may require `message-impersonate` for the sender of your incoming integration. Verify the bot user exists, belongs to the target channel, and that its role has the permission under **Manage → Workspace → Permissions**. Do not make every user an admin to fix this.

## `Webhook is blocked: Requests to the local network are not allowed`

GitLab enforces SSRF protection against private, loopback and other special network addresses. If the chat hostname resolves to a private IP *from the GitLab container*, GitLab blocks requests by default — even if the hostname looks public and HTTPS works from your laptop.

1. On GitLab Self-Managed, an administrator opens **Admin → Settings → Network → Outbound requests**.
2. Add **only the needed hostname plus port**, e.g. `chat.example.internal:443`, under **Local IP addresses and domain names that hooks and integrations can access**.
3. Keep the **global local network access setting off** and DNS-rebinding protections enabled.
4. Save and retry the GitLab integration.
5. For split DNS / Docker hosts, verify the destination using a read-only command such as:

   ```bash
   docker exec <gitlab-container-name> getent ahostsv4 chat.example.internal
   ```

   Replace the placeholders with your own names. Do not copy someone's private IP or disable security controls for an entire subnet.

If a DNS rebinding policy still prevents access, inspect the actual resolved address, the DNS mapping GitLab uses, and instance logs. Avoid disabling DNS-rebinding protection as a shortcut.

## Direct `curl` works, GitLab doesn't

**This is not contradictory.** `curl` from your Mac validates Rocket.Chat and network access **from the Mac**. GitLab's service has its own outbound security rules and can have a different DNS view.

Run the integration's **Test settings** action after verifying DNS and allowlisting. Check GitLab admin logs if the test doesn't reach Rocket.Chat. HTTP 2xx alone does not prove that the message appeared in the desired channel.

## Integration saves but no messages arrive

- Check the project/group inheritance and the **Active** flag.
- Enable a trigger for the event being tested.
- Verify the webhook URL is still valid, without exposing it in issue logs.
- Confirm the Rocket.Chat incoming integration has **Script Enabled = OFF** for the Slack compatibility mode.
- Leave channel overrides blank unless your Rocket.Chat integration allows channel overrides and you intend to use them.
- Verify that pipeline filters / labels / selected branches aren't excluding the event.

## Slack notifications integration is missing

GitLab deprecated it in 15.9 and hides it for some fresh projects on 19.5. Don't try to bypass the product lifecycle with undocumented hacks. Use [native GitLab Webhooks](native-webhooks.md) and an official Rocket.Chat formatting script instead.

## Security reminders

- Do **not** paste your `https://…/hooks/<id>/<token>` URL into GitHub issues, CI logs or screenshots.
- Rotate exposed webhook tokens.
- Never broadly allow entire RFC1918 ranges just to make a single notification work.
- Prefer separate integrations and channels for different trust levels or audiences.

### References

- [GitLab security: outbound requests](https://docs.gitlab.com/security/webhooks/)
- [Rocket.Chat integration requirements](https://docs.rocket.chat/docs/integrations)
