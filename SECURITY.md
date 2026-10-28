# Security policy

This repository contains documentation and a local test script. **Never submit actual Rocket.Chat webhook URLs**, GitLab tokens, private addresses, or confidential event payloads in an issue or pull request.

A Rocket.Chat Incoming Webhook URL is a **bearer credential**. Anyone who obtains it may be able to post into the configured channel. If leaked, **regenerate/rotate it** in Rocket.Chat and update the GitLab integration.

Use narrowly scoped outbound allowlists for private-network targets; do not disable all GitLab SSRF protections to make notifications work.

If you discover an issue in this project, open a GitHub issue **without secrets**, or use the repository's private vulnerability reporting feature when available.
