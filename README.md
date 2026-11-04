# סטודיו לאוניד — Leonid Studio

Maquette bilingue (hébreu RTL / russe LTR) pour la gestion d’un studio de sport.

## Lancement

Le site est statique. Pour tester depuis un navigateur, lancez un serveur local dans ce dossier :

```bash
python -m http.server 8080
```

Ouvrez ensuite `http://localhost:8080/`. La racine redirige vers l’espace adhérent (`espace.html`). La maquette de démo est sur `demo.html`, la gestion sur `admin.html` (pages non liées publiquement, `noindex`).

## Fichiers

- `index.html` : redirige vers `espace.html` (seule page publique).
- `demo.html` : maquette de démonstration (non liée, `noindex`).
- `admin.html` : gestion pour l’équipe (non liée, `noindex`, données protégées par RLS).
- `assets/css/style.css` : styles et responsive.
- `assets/js/health.js` : fonctions de déclaration de santé.
- `assets/js/app.js` : logique de la maquette.
- `assets/health-declaration.pdf` : document PDF proposé dans le parcours médical.

## Important

**Démonstration uniquement.** Les données sont fictives ou stockées localement dans le navigateur. Aucun backend PHP, aucune authentification réelle, aucun stockage médical sécurisé, aucun envoi d'e-mails/WhatsApp et aucune facturation officielle ne sont intégrés. Ne pas utiliser de vraies données médicales, personnelles ou fiscales avec cette maquette. Pour une exploitation réelle, prévoir serveur sécurisé, base de données, droits d'accès, conservation des documents et système fiscal conforme.

## Espace adhérent (Supabase) — `espace.html`

Chaque adhérent se connecte et voit **uniquement** ses données : abonnement (jours restants), mesures (poids, % de gras, muscle, eau, IMC), reçus (liens Slate) et coordonnées. L'équipe (table `staff`) voit et modifie tout. Les règles sont appliquées par la base (RLS), pas par la page.

### Installation (une seule fois)

1. Supabase → **SQL Editor** → **New query** → coller tout `supabase/schema.sql` → **Run**.
2. Nouvelle requête → coller `supabase/seed-demo.sql` → **Run** (5 adhérents fictifs).
3. Ouvrir `/espace.html`, **créer un compte** avec `david@example.com` (mot de passe au choix), puis saisir le code `DAVID1`.

Codes de démo : `DAVID1`, `DANIEL`, `NOA123`, `MICHAL`, `YOSSI1` (chacun utilisable une seule fois, avec l'e-mail correspondant).

### Gestion par l'équipe — `admin.html`

Leonid se connecte sur `/admin.html` (compte présent dans la table `staff`) : liste des adhérents avec statut d'abonnement, ajout d'un adhérent (un code d'activation est généré, envoyable par WhatsApp), fiche avec coordonnées, abonnements (renouvellement), mesures (IMC calculé) et paiements (numéro + lien du reçu Slate, envoi WhatsApp). Tout est enregistré dans Supabase et apparaît aussitôt dans l'espace de l'adhérent.

### Donner les droits d'équipe (Leonid)

Après avoir créé son compte dans `/espace.html` :

```sql
insert into public.staff (user_id) select id from auth.users where email = 'adresse.de.leonid@example.com';
```

### Avant les vraies données

- Activer **Confirm email** et configurer un SMTP (ex. Brevo) dans Supabase.
- Recueillir l'accord des adhérents pour le stockage de leurs mesures (données sensibles).
