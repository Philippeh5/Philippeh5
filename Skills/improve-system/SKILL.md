---
name: improve-system
description: Analyse les anciennes conversations Claude Code du projet courant (et ses CLAUDE.md / skills existants) pour trouver les problèmes récurrents, corrections répétées et directives jamais enregistrées, puis propose des améliorations du setup (CLAUDE.md, skills, hooks, permissions) et les applique uniquement après validation. Use for "improve system", "améliore le setup", "analyse mes conversations", "qu'est-ce que je répète tout le temps", "mets à jour le CLAUDE.md".
---

# Improve System

Deux phases, **toujours séparées par une validation de Philippe**. Périmètre = **le projet courant uniquement** (cwd). Ne jamais lire ni modifier les autres projets.

## Phase 1 — Analyse (lecture seule, ZÉRO modification)

1. **Digest de l'historique du projet** :
   ```
   node "<skills>/improve-system/scripts/extract.mjs" "<cwd>" --sessions 40
   ```
   Si `NO_HISTORY` : le dire, analyser seulement les fichiers de config du projet, et le signaler. Si le digest est trop mince, relancer avec `--sessions 100`. Pour creuser un moment précis, lire le `.jsonl` correspondant dans `~/.claude/projects/<cwd encodé>/` (grep ciblé, jamais le fichier entier).
2. **Inventaire de l'existant** (pour ne rien dupliquer) : `CLAUDE.md` du projet (+ sous-dossiers), `.claude/settings*.json`, `.claude/skills/`, `.claude/commands/`, `~/.claude/CLAUDE.md`, `~/.claude/skills/` (liste des noms/descriptions), dossier `memory/` du projet s'il existe.
3. **Chercher ces signaux** :
   - **Corrections / frustrations** : `[!]`, « non », « je t'ai déjà dit », « encore », « pourquoi tu… » → quelle règle manquait ?
   - **Directives permanentes** données une fois (« à chaque fois », « pour tout le projet », « toujours », « n'oublie pas », « oublie pas le / ») qui ne sont dans aucun CLAUDE.md.
   - **Prompts / instructions répétés** d'une session à l'autre → candidat **skill** ou commande.
   - **Erreurs d'outils récurrentes** (mauvais chemin, mauvaise commande, build cassé) → note de contexte dans CLAUDE.md, ou règle de permission/hook.
   - **Refus de permission répétés** → proposition d'allowlist.
   - **Sessions qui s'arrêtent trop tôt / à moitié finies** → règles de complétion.
   - **Contexte redécouvert à chaque session** (stack, chemins, ports, conventions, commandes de test/run) → CLAUDE.md.
4. **Filtrer sévèrement** : une proposition n'existe que si elle est (a) appuyée par ≥1 preuve citée (date + extrait court), idéalement ≥2, (b) pas déjà couverte par l'existant, (c) non dérivable du code. Pas de remplissage générique. Ne jamais citer ni recopier de secrets/tokens vus dans les logs.

5. **Skill existante avant de créer** — pour **chaque** proposition de type Skill/Commande (jamais pour du CLAUDE.md), chercher d'abord si ça existe déjà :
   1. **Local** : `~/.claude/skills/`, `.claude/skills/`, skills listées dans la session, plugins installés (`~/.claude/plugins/`). Si une skill locale couvre le besoin → proposer de **l'utiliser/l'étendre**, pas d'en créer une autre.
   2. **Catalogue public** : `npx --yes skills find "<2-3 mots-clés en anglais>"` (CLI skills.sh ; essayer 2 formulations ; si une skill « find-skills » est installée, l'utiliser à la place). Réseau coupé ou commande en échec → le dire et passer à la création.
   3. **Juger la pertinence honnêtement** : les résultats sont triés par popularité, pas par pertinence — ignorer les hors-sujet. Pour un candidat sérieux, lire son `SKILL.md` **en entier** (page `https://skills.sh/<owner>/<repo>/<skill>` ou repo GitHub) avant de le proposer.
   4. Classer chaque proposition Skill en **une** de ces 3 options :
      - **Reprendre tel quel** (couvre ≥80 % du besoin),
      - **Reprendre + adapter** (copier dans `.claude/skills/<nom>/` et modifier les petits écarts : langue, chemins, conventions du projet) — **option par défaut si un candidat est proche**,
      - **Créer de zéro** (rien de proche) — dernier recours, à justifier en une ligne (« aucun résultat pertinent pour : <requêtes> »).
   5. Une skill tierce = **code non fiable** : indiquer la source et le nombre d'installs, lister ce qu'elle exécute (scripts, shell, réseau), et ne rien installer avant validation en phase 2.

### Format du rapport (en français, concis)

```
# Improve System — <projet>  (N sessions analysées, du <date> au <date>)

## Constats
- <problème> — preuves : <date: « extrait »>, …

## Propositions
| # | Type | Cible | Changement | Pourquoi (preuve) | Impact |
|---|------|-------|-----------|-------------------|--------|
| 1 | CLAUDE.md | ./CLAUDE.md | + « <règle exacte, 1-2 lignes> » | … | élevé |
| 2 | Skill | .claude/skills/x/ | **adapter** `owner/repo@x` (changer : …) — ou « créer » si rien de proche | prompt répété 4× | moyen |
| 3 | Hook/Permission | .claude/settings.json | … | … | … |
| 4 | Nettoyage | ./CLAUDE.md | retirer règle obsolète/contradictoire | … | faible |

## Ce que je n'ai PAS retenu (et pourquoi)
```
Pour chaque Skill, indiquer la **source** (locale / skills.sh `owner/repo@skill` + installs / de zéro + requêtes tentées) et l'option choisie.
Types possibles : `CLAUDE.md` (projet / global), `Skill`, `Commande`, `Hook`, `Permission`, `Mémoire`, `Nettoyage`. Pour chaque ligne, écrire le **texte exact** qui sera ajouté (diff lisible), pas une intention vague. Préférer le CLAUDE.md du projet ; global (`~/.claude`) seulement si la règle vaut clairement pour tous les projets — et le signaler explicitement.

Finir par : « Dis-moi lesquelles appliquer : `tout`, `1,3`, `sauf 2`, ou corrige/reformule ». **Puis s'arrêter et attendre.** Rien n'est écrit en phase 1.

## Phase 2 — Application (après la réponse de Philippe)

1. N'appliquer **que** les propositions validées, avec les modifications demandées.
2. Avant d'éditer un fichier existant : le lire ; **ajouter/éditer sans écraser** le reste ; pas de doublon ; garder le CLAUDE.md court (règles courtes, regroupées par thème, avec le *pourquoi* en une ligne quand non évident). Si le fichier n'existe pas, le créer.
3. Skills, selon l'option validée : **reprendre** → `npx skills add <owner/repo@skill>` (ou copie du dossier) ; **adapter** → copier dans `.claude/skills/<nom>/`, éditer `SKILL.md` (+ scripts) pour les écarts convenus, noter la source d'origine en tête du fichier ; **créer** → `.claude/skills/<nom>/SKILL.md` (frontmatter `name` + `description` riche en déclencheurs), complexe → `anthropic-skills:skill-creator`. Relire tout script tiers avant de le garder.
4. Hooks / permissions : utiliser le skill `update-config` ; ne jamais élargir les permissions au-delà de ce qui est validé.
5. **Vérifier** : relire chaque fichier modifié, valider le JSON des settings, confirmer que la structure d'un skill est correcte. Ne pas déclarer « fait » sans ça.
6. **Rapport final** : liste fichier par fichier de ce qui a changé (+ comment annuler : suppression de la ligne / du dossier). Aucun commit sauf demande explicite.

## Règles

- Phase 1 = lecture seule, sans exception. Phase 2 = uniquement le validé.
- Un projet à la fois : si lancée à la racine d'un dossier non-projet, demander de se placer dans un projet.
- Directive donnée en cours de session (« à chaque fois on fait X ») : si Philippe lance `/improve-system` après, la traiter comme preuve prioritaire et vérifier qu'elle est bien enregistrée.
- Écrire dans la langue de Philippe (français), règles ajoutées aux fichiers dans la langue dominante du fichier cible.
