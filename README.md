# Classement des villageois

Page statique hébergée sur GitHub Pages, avec une base Supabase. Chaque ami crée son profil,
tout le monde voit tous les profils, et un mot de passe protège la modification.

Site: https://ssaintma.github.io/animal-classement-gab/

Pour reprendre le travail avec Claude Code, il lit `CLAUDE.md` (architecture, règles, historique).

## Contenu du dépôt

- `index.html`: l'application complète
- `sheet.webp`: les têtes des villageois, en une seule image
- `favicon.png`, `apple-touch-icon.png`: icônes (Ketchup)
- `supabase/schema.sql`: la base de données
- `scripts/build_assets.py`: régénère la planche d'images et la liste des villageois
- `CLAUDE.md`: contexte pour une nouvelle session

## Installation depuis zéro

### 1. La base (Supabase)

1. Crée un projet Supabase, puis ouvre **SQL Editor > New query**.
2. Colle tout le contenu de `supabase/schema.sql` et clique sur **Run**.
3. Dans `index.html`, mets l'adresse du projet et la clé publique (« publishable ») dans `SUPABASE_URL` et `SUPABASE_KEY`.

Les visiteurs n'ont aucun accès direct à la table. Ils passent par cinq fonctions (lire, créer, vérifier, enregistrer, supprimer)
qui contrôlent le mot de passe dans la base. Les mots de passe sont hachés (bcrypt) et jamais renvoyés.

### 2. La page (GitHub Pages)

1. Dépôt public sur GitHub, avec le contenu de ce dossier à la racine.
2. **Settings > Pages**: source **Deploy from a branch**, branche `main`, dossier `/ (root)`.
3. Le lien apparaît après une à deux minutes.

## Bon à savoir

- Limites: 20 profils au plus, nom de 30 caractères au plus.
- Mot de passe perdu: il ne peut pas être récupéré. Supprime le profil dans Supabase (**Table Editor > profiles**) et recrée-le.
- La clé publishable est visible dans la page: c'est normal, elle ne donne aucun droit sur la table. Ne mets jamais la clé `service_role` dans la page.
- Les images des villageois appartiennent à Nintendo. C'est un projet de fans.
