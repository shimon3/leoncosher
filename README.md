# סטודיו לאוניד — Leonid Studio

Maquette bilingue (hébreu RTL / russe LTR) pour la gestion d’un studio de sport.

## Lancement

Le site est statique. Pour tester depuis un navigateur, lancez un serveur local dans ce dossier :

```bash
python -m http.server 8080
```

Ouvrez ensuite `http://localhost:8080/`. Le point d’entrée est `index.html`.

## Fichiers

- `index.html` : structure du site.
- `assets/css/style.css` : styles et responsive.
- `assets/js/health.js` : fonctions de déclaration de santé.
- `assets/js/app.js` : logique de la maquette.
- `assets/health-declaration.pdf` : document PDF proposé dans le parcours médical.

## Important

**Démonstration uniquement.** Les données sont fictives ou stockées localement dans le navigateur. Aucun backend PHP, aucune authentification réelle, aucun stockage médical sécurisé, aucun envoi d'e-mails/WhatsApp et aucune facturation officielle ne sont intégrés. Ne pas utiliser de vraies données médicales, personnelles ou fiscales avec cette maquette. Pour une exploitation réelle, prévoir serveur sécurisé, base de données, droits d'accès, conservation des documents et système fiscal conforme.
