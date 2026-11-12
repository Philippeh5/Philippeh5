---
name: reprise
description: Reprend automatiquement un travail interrompu (coupure de crédit, quota, crash, changement d'agent) en relisant .handoff/ du projet et en relançant la même équipe (orchestrateur + mêmes sous-agents sur les mêmes tâches). À utiliser quand l'utilisateur dit « reprends le travail », « reprise », « continue ce qui était en cours », « on a été coupé », ou change d'agent (Claude Code, Codex, Gemini/agy, Pi, FreeBuff) en cours de tâche.
---

# Reprise — reprendre le travail d'une équipe d'agents interrompue

Un hook (`handoff-snapshot`) écrit en continu, dans chaque projet, le dossier `.handoff/` :
`RESUME.md` (lecture humaine), `topology.json` (qui a lancé quoi, avec la tâche exacte de chaque sous-agent et son état), `transcripts/` (copie brute des dernières sessions).
Cette skill te dit quoi en faire. Elle est identique dans tous les outils ; adapte seulement la façon de lancer un sous-agent.

## Étapes (ne pose pas de question, exécute)

1. **Récupère le plan — première action obligatoire.** Dans le dossier de travail courant (ne va pas chercher dans d'autres dossiers), exécute la commande shell `reprise` (ou `reprise --json`). C'est elle qui choisit la bonne session à reprendre ; ne la remplace pas par une lecture à la main de `RESUME.md`.
   Si la commande n'existe pas : lis `.handoff/topology.json` et `.handoff/RESUME.md`. S'il n'y a pas de `.handoff/`, dis-le et arrête-toi : il n'y a rien à reprendre.
2. **Vérifie l'état réel.** Lance `git status` et `git diff --stat`. Le dépôt est la vérité ; `RESUME.md` n'est que la mémoire de l'intention. Regarde si les fichiers cités existent déjà.
3. **Tu es l'orchestrateur.** Si la session interrompue avait des sous-agents, ne fais pas leur travail toi-même : relance-les.
   - Un sous-agent par entrée « à RELANCER » du plan, **même nombre, même rôle (`subagent_type`), même tâche** (le prompt d'origine tel quel, précédé de : « Tu reprends un travail interrompu : vérifie d'abord git status et ce qui existe déjà, ne refais pas ce qui est fait. »).
   - Lance-les **en parallèle** si c'était le cas à l'origine (plusieurs entrées non terminées = plusieurs lancements simultanés).
   - Lance **exactement** autant de sous-agents que d'entrées « à RELANCER », pas un de plus. Un sous-agent qui a répondu est terminé : ne le relance jamais, même pour vérifier ; vérifie en lisant ses fichiers.
   - Ne relance **pas** ceux marqués « Déjà TERMINÉS » (sauf `reprise --all` demandé par l'utilisateur). Utilise leur résultat.
   - **Modèle** : prends l'équivalent disponible chez toi, le moins cher qui convient. N'escalade jamais vers un modèle premium plus cher que celui d'origine sans demander à l'utilisateur.
4. **Si ton outil n'a pas d'outil de sous-agent natif** (Codex, agy, Pi...) : exécute `reprise-launch` (ajoute `--tool pi` ou `--tool claude` si tu préfères ; défaut `agy`, gratuit). Il relance chaque tâche non terminée comme une session parallèle séparée, attend, et affiche un compte rendu par worker (logs dans `.handoff/relaunch/`). Tu restes l'orchestrateur : tu ne fais pas leur travail. Si `reprise-launch` est indisponible, exécute les tâches l'une après l'autre en les gardant séparées et dis-le.
5. **Si aucun sous-agent n'avait été lancé** : continue simplement l'objectif et la dernière demande, seul.
6. **Contrôle, ne crois pas les comptes rendus.** Pour chaque agent relancé, ouvre ses fichiers et lance les tests/commandes de vérification. Un « terminé » sans preuve n'est pas terminé.
7. **Rapporte** en quelques lignes : ce qui était déjà fait, ce que tu as relancé (nombre, rôles), le résultat vérifié, ce qui reste.

## Règles

- Ne recommence pas à zéro : l'objectif, les fichiers touchés et les commandes déjà lancées sont dans `RESUME.md`.
- Si `git status` contredit `RESUME.md`, crois `git status`.
- Besoin du détail brut d'une conversation : `grep` dans `.handoff/transcripts/<session>.jsonl`.
- Ne supprime ni ne modifie `.handoff/` toi-même : le hook le tient à jour (si tu es dans un outil sans ce hook, ne comptes pas sur une mise à jour automatique).
- Permissions : ne demande pas de confirmation pour lire `.handoff/` ni pour relancer les agents du plan.
