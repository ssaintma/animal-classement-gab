# Tier lists des villageois

Page statique (`site/`) hébergée sur GitHub Pages, avec une base Supabase (`supabase/schema.sql`).
Chaque ami crée son profil, tout le monde voit tous les profils, et un mot de passe protège la modification.

## 1. Préparer la base (Supabase)

1. Ouvre le projet Supabase, puis **SQL Editor > New query**.
2. Colle tout le contenu de `supabase/schema.sql` et clique sur **Run**. Tu dois voir « Success ».
3. La page contient déjà l'adresse du projet et la clé publique (« publishable »). Rien à changer.

Les visiteurs n'ont aucun accès direct à la table. Ils passent par cinq fonctions (lire, créer, vérifier, enregistrer, supprimer) qui contrôlent le mot de passe dans la base. Les mots de passe sont hachés (bcrypt) et jamais renvoyés.

## 2. Publier la page (GitHub Pages)

1. Crée un dépôt public sur GitHub, par exemple `tierlist-villageois`.
2. Dépose le **contenu** du dossier `site/` à la racine du dépôt (`index.html` et `sheet.webp`).
3. Dans le dépôt: **Settings > Pages > Build and deployment**, source **Deploy from a branch**, branche `main`, dossier `/ (root)`.
4. Après une minute, le lien apparaît en haut de la page Pages: `https://<ton-compte>.github.io/tierlist-villageois/`.

## Bon à savoir

- Limites prévues: 200 profils au plus, nom de 30 caractères au plus.
- Mot de passe perdu: il ne peut pas être récupéré. Supprime le profil depuis Supabase (**Table Editor > profiles**) et recrée-le.
- Les images des villageois appartiennent à Nintendo. C'est un projet de fans.
- Ne mets jamais la clé `service_role` de Supabase dans la page.
