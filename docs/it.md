# GitLab → Rocket.Chat senza usare Slack 🇮🇹

**Il trucco:** GitLab può inviare notifiche formattate per Slack direttamente a un Incoming Webhook di Rocket.Chat. **Non serve un account Slack né un servizio intermedio.**

Questo percorso è stato verificato in pratica su un'installazione GitLab Self-Managed: il test eseguito **dalla UI GitLab** è arrivato nel canale Rocket.Chat.

> **Attenzione alla compatibilità:** l'integrazione **Slack notifications** di GitLab è deprecata dalla 15.9 e, dalla 19.5, può non apparire per progetti che non l'avevano già utilizzata. Per una nuova integrazione duratura, consulta [l'alternativa nativa](native-webhooks.md).

## Procedura

1. **Rocket.Chat → Manage → Workspace → Users:** crea `gitlab-bot` o scegli un utente tecnico esistente. Deve essere attivo e membro del canale di destinazione.
2. **Manage → Workspace → Permissions:** verifica il permesso `message-impersonate` per il ruolo dell'utente; evita di dargli privilegi amministrativi.
3. **Manage → Workspace → Integrations → New → Incoming:** attiva l'integrazione, imposta `Post to Channel` a `#dev-notifications`, `Post as` a `gitlab-bot`, `Alias` a `GitLab`, `Script Enabled` su **OFF**. Salva.
4. **Testa prima Rocket.Chat:** `bash scripts/test-webhook.sh`. Quando richiesto, incolla privatamente l'URL dell'integrazione. Controlla il codice HTTP **e l'effettiva comparsa del messaggio**.
5. **Se GitLab blocca la LAN:** un amministratore deve entrare in `Admin → Settings → Network → Outbound requests` e aggiungere alla allowlist solo il dominio necessario, con porta `:443` (per esempio `chat.example.internal:443`). **Non disabilitare** globalmente le protezioni SSRF e DNS-rebinding.
6. **GitLab → Project → Settings → Integrations → Slack notifications:** attiva l'integrazione, seleziona merge request/issue/pipeline/deploy, incolla l'URL del webhook Rocket.Chat in `Webhook`, lascia vuoti i canali per usare quello predefinito di Rocket.Chat, salva.
7. Premi **Test settings** in GitLab e verifica la notifica sul canale. A quel punto il percorso completo è operativo.

## Errori che abbiamo risolto

| Errore | Cosa fare |
| --- | --- |
| `Invalid user [error-invalid-user]` | L'utente di `Post as` deve esistere |
| `The user must exist and have the message-impersonate permission` | Controllare permesso e appartenenza al canale |
| `Webhook is blocked: Requests to the local network are not allowed` | GitLab blocca IP privati: usare allowlist stretta del dominio + porta |
| `curl` restituisce 200 ma GitLab non invia | Il test diretto bypassa le regole outbound di GitLab: eseguire *Test settings* |
| Mancanza di `Slack notifications` | Valutare Webhooks nativi e script Rocket.Chat |

Per le diagnosi più dettagliate, consulta [Troubleshooting](troubleshooting.md).

## Sicurezza

Il webhook contiene un **token segreto nell'URL**. Non va mai pubblicato in repository, ticket, screenshot o chat condivise. Se è stato esposto, **rigeneralo** da Rocket.Chat e aggiorna l'integrazione GitLab.

Questo progetto dimostra una compatibilità: non è un'integrazione ufficiale né una garanzia per versioni future.

[← README principale](../README.md) · [Alternativa nativa](native-webhooks.md)
