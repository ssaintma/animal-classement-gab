# CLAUDE.md : Classement des villageois (Animal Crossing)

Contexte pour reprendre ce projet dans une nouvelle session. Lis aussi `README.md`.

## Ce que c'est

Petite application web pour classer les 413 villageois d'Animal Crossing: New Horizons en cinq rangs
(Parfait, Bien, Ça va, Bof, Poubelle). Chaque personne crée un profil protégé par mot de passe;
tout le monde voit tous les profils. Destinée au fils de l'utilisateur et à ses amis (usage iPad inclus).

- Dépôt: https://github.com/ssaintma/animal-classement-gab (public, compte GitHub `ssaintma`, `gh` est connecté)
- Site: https://ssaintma.github.io/animal-classement-gab/ (GitHub Pages, branche `main`, racine)
- Base: projet Supabase `https://vsigyozovdrgbmjmjqeo.supabase.co`

## Architecture

Pas de build, pas de framework: une seule page statique.

| Fichier | Rôle |
|---|---|
| `index.html` | Toute l'application (HTML, CSS, JS vanilla). Les données des villageois sont dans la constante `DATA`. |
| `sheet.webp` | Planche de 21 colonnes × 20 lignes d'icônes 64 px. La tête du villageois n° i est à la colonne `i % 21`, ligne `floor(i / 21)`. |
| `favicon.png`, `apple-touch-icon.png` | Tête de Ketchup (canard, `duk13.png`). iOS utilise `apple-touch-icon` pour l'écran d'accueil, pas le favicon. |
| `supabase/schema.sql` | Table et fonctions de la base. À exécuter à la main dans Supabase > SQL Editor. |
| `scripts/build_assets.py` | Régénère `sheet.webp` et `DATA` (voir plus bas). |

## Base de données (Supabase)

- La table `public.profiles` (id uuid, name, rank jsonb, pw_hash, dates) n'est **pas** accessible directement
  aux visiteurs (RLS activée, aucun droit pour `anon`).
- Tout passe par cinq fonctions `security definer`, appelées en REST `POST /rest/v1/rpc/<fonction>`:
  `list_profiles`, `create_profile`, `check_password`, `save_rank`, `delete_profile`.
  Les mots de passe sont hachés en bcrypt (pgcrypto) et vérifiés dans la base, jamais renvoyés.
- Limites: 20 profils au plus (dans `create_profile`), nom de 30 caractères au plus, mot de passe de 4 à 72.
- `rank` est un objet `{ "<index du villageois>": <rang 0 à 4> }`. 0 = Parfait, 4 = Poubelle.
- L'adresse du projet et la clé **publishable** sont écrites dans `index.html` (`SUPABASE_URL`, `SUPABASE_KEY`).
  C'est voulu: cette clé est publique par conception et ne donne aucun droit sur la table.
  Un site statique ne peut pas la cacher (le navigateur doit l'envoyer). Ne jamais mettre la clé `service_role`.
- Je n'ai pas d'accès à Supabase depuis Claude Code: les changements de base se font en donnant du SQL
  à l'utilisateur, qui le colle dans le SQL Editor. Le passage de 200 à 20 profils a été donné sous cette
  forme; l'utilisateur a répondu « Parfait », mais je n'ai pas vérifié qu'il l'a exécuté.

## Règles à respecter

- **Ne jamais compromettre les profils existants.** Consigne explicite de l'utilisateur. Pas de `drop`, `truncate`,
  `delete` ou `update` sur `profiles`, pas de changement de forme de `rank` ou de hachage des mots de passe sans
  l'expliquer d'abord et obtenir un accord clair. Préférer `create or replace function` à toute modification de table.
- **Les index des villageois sont gelés.** Les `rank` enregistrés pointent vers la position dans `DATA`
  (= l'index dans la planche). Ne jamais réordonner, insérer au milieu ni retirer un villageois.
  Pour en ajouter, les mettre **à la fin** (le script `scripts/build_assets.py` le fait ainsi).
- Thème **clair uniquement**, voulu par l'utilisateur. Pas de mode sombre.
- Interface en français, tutoiement.
- Les changements de la page se publient avec un `git push` normal sur `main` (jamais de push forcé sans accord).
  Pages se met à jour en une à deux minutes.
- Pas de variable GitHub ni de masquage de la clé: discuté et refusé, car sans effet réel sur un site statique.
- Les images des villageois appartiennent à Nintendo (projet de fans, mention en bas de page). Le dépôt est public.

## Données et sources

- Liste, noms français (`translations.eUfr`), espèces et icônes: `Norviah/animal-crossing` sur GitHub,
  fichier `json/data/Villagers.json`. Les icônes sont téléchargées depuis `acnhcdn.com`.
- `DATA` contient `Nom|Espèce` séparés par `;`, noms français, espèces en anglais (traduites par `SPECIES_FR` dans le JS).
- Le tri alphabétique à l'écran est fait dans le JS (`ORDER`), indépendamment de l'index.

## Si le nombre de villageois change

Le CSS fixe la taille de la planche (`.h56` et `.h48`, propriété `background-size`). Si le nombre de lignes de
la planche change, ces deux valeurs doivent suivre. `scripts/build_assets.py` les met à jour.
Le script n'a été vérifié que pour sa syntaxe, pas de bout en bout: relis le résultat avant de pousser.

## Historique utile

- Des prototypes existent sur claude.ai (artefacts privés, sans lien avec le site actuel et abandonnés):
  une toile « Design » puis une page avec la base de Claude, qui n'est lisible que par des comptes connectés.
  Le site GitHub Pages + Supabase les remplace.
- Titre de la page: « Classement des villageois ». Favicon: Ketchup.

## Idées non faites

- Comparer deux profils côte à côte.
- Partager un classement par image.
- Récupération d'un mot de passe perdu (aujourd'hui: supprimer le profil dans Supabase > Table Editor et le recréer).
