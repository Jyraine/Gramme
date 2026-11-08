# Gramme

Application web pour préparer ses randonnées : inventaire du matériel avec poids par catégorie, listes par sortie, répartition du poids entre plusieurs personnes, import du GPX de ta montre COROS, bilan des sorties. Les données sont partagées entre les personnes que tu invites, et l'application s'installe sur l'écran d'accueil de l'iPhone.

Tout est en HTML, CSS et JavaScript, sans outil de compilation. Les données sont stockées dans Supabase, la page est servie par GitHub Pages. Les deux sont gratuits pour cet usage.

## Mise en ligne en 6 étapes

### 1. Créer le projet Supabase
1. Crée un compte sur [supabase.com](https://supabase.com), puis **New project**.
2. Choisis une région européenne (Paris ou Francfort) et un mot de passe de base de données (garde-le, tu n'en auras pas besoin au quotidien).

### 2. Créer les tables
1. Dans Supabase, ouvre **SQL Editor**.
2. Ouvre `schema.sql` de ce dépôt, remplace l'adresse tout en bas (`remplace-par-ton-adresse@exemple.fr`) par la tienne, copie tout le contenu dans l'éditeur et clique **Run**.

### 3. Afficher un code dans l'e-mail de connexion
Gramme connecte par code reçu par e-mail (plus fiable que le lien sur iPhone).
1. **Authentication**, puis **Email Templates**.
2. Dans les modèles **Magic Link** et **Confirm signup**, remplace le corps du message par :
   ```html
   <h2>Ton code Gramme</h2>
   <p>Saisis ce code dans l'application : <b>{{ .Token }}</b></p>
   ```

### 4. Relier l'application à Supabase
1. **Project Settings**, puis **API**.
2. Copie **Project URL** et la clé **anon public**.
3. Colle-les dans `config.js` de ce dépôt (modifiable directement sur github.com avec le crayon). Ces deux valeurs sont publiques par conception : ce sont les règles de `schema.sql` qui protègent les données.

### 5. Publier avec GitHub Pages
1. Dans ce dépôt sur GitHub : **Settings**, puis **Pages**.
2. **Source** : *Deploy from a branch*, branche `main`, dossier `/ (root)`, puis **Save**.
3. Après une minute, l'adresse apparaît en haut de la page, de la forme `https://<ton-compte>.github.io/Gramme/`.
4. Dans Supabase, **Authentication**, **URL Configuration** : mets cette adresse dans **Site URL**.

### 6. Installer sur l'iPhone
1. Ouvre l'adresse dans **Safari**.
2. Touche **Partager**, puis **Sur l'écran d'accueil**.
3. Connecte-toi avec ton adresse e-mail et le code reçu.

## Inviter des amis
Seules les adresses de la table `allowed_emails` peuvent lire et écrire. Pour en ajouter une :
1. Supabase, **Table Editor**, table `allowed_emails`, **Insert row**.
2. Saisis l'adresse de l'ami. Il peut ensuite se connecter lui-même avec cette adresse.

Pour retirer quelqu'un, supprime sa ligne. Tous les invités voient et modifient les mêmes sorties et le même inventaire.

## À savoir
- **Hors ligne** : l'application s'ouvre et affiche les dernières données enregistrées. Les modifications demandent une connexion.
- **E-mails** : l'envoi intégré de Supabase est limité à quelques messages par heure. Pour un groupe plus grand, configure un envoi personnalisé (**Authentication**, **SMTP Settings**).
- **Pause du projet** : un projet Supabase gratuit sans aucune activité pendant une semaine est mis en pause. Il se relance en un clic depuis le tableau de bord, sans perte de données.
- **Nom de domaine** : pour une adresse à toi (par exemple `gramme.fr`), achète le domaine chez un registraire, puis renseigne-le dans **Settings > Pages > Custom domain**.
- **Sauvegarde** : pense à exporter de temps en temps tes tables depuis le **Table Editor** de Supabase.

## Fichiers
| Fichier | Rôle |
| --- | --- |
| `index.html` | L'application entière |
| `config.js` | Adresse et clé du projet Supabase |
| `schema.sql` | Tables, règles d'accès et fonctions à exécuter une fois |
| `sw.js`, `manifest.webmanifest` | Installation sur l'écran d'accueil et mode hors ligne |
| `icon.svg`, `icon-192.png`, `icon-512.png`, `apple-touch-icon.png` | Icônes |
