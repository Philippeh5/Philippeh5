---
name: paseo-poste
description: Piloter le poste de commande Paseo (dashboard 127.0.0.1:7070 sur Oracle) depuis une session - sessions, tâches, boîte de réception, terminaux/fenêtres, coordination entre agents. À utiliser pour lancer/fermer des sessions, marquer des tâches, ouvrir un terminal, lire un terminal, réserver un fichier ou voir qui travaille sur un projet.
---

# paseo-poste

Machine : Oracle (Linux). Pas de WSL. Dashboard `http://127.0.0.1:7070`, API `/api/v1`. Doc complète : `~/Projets/paseo-lab/dashboard/README.md` (section « Piloter le poste par un agent »).
Vérifier d'abord ce qui existe (`claude mcp list`, `postectl --help`) avant d'ajouter quoi que ce soit.

## Trois portes (mêmes handlers, mêmes garde-fous)
- **MCP `postectl`** (outils `post_*`, ~45) : `post_summary`, `post_list_sessions`, `post_send_to_session`, `post_close_session`, `post_list_tasks`/`post_create_task`/`post_start_task`/`post_close_task`/`post_restart_task`, `post_inbox_list`/`post_inbox_mark`/`post_inbox_decide`, `post_open_terminal`, `post_terminal_scrollback`, `post_groups`, `post_group_say`, `post_services`, `post_decide`.
- **CLI `postectl`** (`~/.local/bin`) : `postectl summary`, `sessions`, `tasks`, `task add|close|restart`, `inbox`, `scrollback <hôte> <terminal>`, `watch`. `--json` pour les agents.
- **MCP `paseo-coord` / CLI `coord`** : `coord_who`, `coord_set_status`, `coord_claim`, `coord_release`, `coord_check`, `coord_send`, `coord_inbox`, `coord_my_role`. Avant d'écrire dans un projet partagé : `coord who` puis `coord claim <fichier>`. Un refus est définitif, ne pas contourner.

## Règles
- Actions destructrices (fermer session/tâche, supprimer) : `confirm: true`, seulement sur ce que l'utilisateur a désigné.
- `post_open_terminal` : outil dans une liste fermée (`terminal, claude, freebuff, hermes, pi, codex`) ; pas de saisie de texte libre dans un terminal (voulu, ne pas ajouter de route `send`).
- Sans identité de session (`coord_my_role` : « pas de token »), appeler `coord_hello` et faire confirmer par Philippe dans la vue Agent > Équipe. Les sessions lancées par le poste ont leur identité.
- Toute écriture est journalisée (`dashboard/data/agent-audit.jsonl`) ; fixer `POSTECTL_AGENT` pour un nom stable.
- Lecture d'un terminal : `paseo terminal capture <id> -S` ; attendre ~2 s après `create`/`send-keys` (le shell démarre), sinon la capture est vide.
- Lancer un agent sur un autre moteur : `paseo run --provider claude-openrouter --model sonnet "..."` (voir aussi le skill claude-foreman et `/route-consent`).
- Hôte unique : `oracle` (cette machine). Le Mini PC (`local`) est abandonné : ignorer ses erreurs.
- Compte rendu d'une tâche déléguée : `postectl report <id>` (texte complet ; le résumé de la carte est coupé à 500 caractères) ; `postectl wait <id>` attend la fin puis l'affiche : à lancer en arrière-plan (run_in_background) pour être réveillé. `postectl task notify <id> <hôte:session>` (ou `task add --notify`) fait envoyer le rapport à une session agent du poste.
