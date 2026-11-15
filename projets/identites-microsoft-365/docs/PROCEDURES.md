# Procédures de support et de gestion des accès

## Incident fictif INC-DEMO-001

Structure inspirée d'un ticket ServiceNow, conservée dans les rapports locaux. Aucune instance ServiceNow n'est utilisée par le projet.

| Champ | Valeur fictive |
|---|---|
| Utilisateur | demo-bob |
| Symptôme | Accès à la messagerie et à Teams indisponible après mobilité |
| Service | Digital Workplace |
| Priorité | P3, un utilisateur affecté |
| Diagnostic | Compte activé, inscription MFA absente, groupes métier incomplets |
| Propriétaire | Équipe Support fictive |
| Suivi | Préparer le changement CHG-DEMO-002, faire valider les droits, demander l'inscription MFA via le processus approuvé |
| Clôture | Vérifier avec l'utilisateur et joindre les preuves, ne pas fermer le ticket sur le seul succès d'un script |

## Demande, incident et changement

La démarche est inspirée des pratiques ITIL. L'arrivée d'un utilisateur constitue une demande. Une interruption de service est un incident. Un changement de groupe est un changement à autoriser et à tracer. Le laboratoire vérifie une chaîne de texte `approved`, mécanisme pédagogique qui ne constitue pas une autorisation réelle.

1. Confirmer l'identité et le besoin par un canal autorisé.
2. Relever le service, l'heure, l'erreur et l'impact. Rechercher si l'incident est individuel ou collectif.
3. Vérifier l'état du compte, les groupes, les droits et l'inscription MFA.
4. Associer les droits souhaités au rôle métier et faire approuver la demande. Appliquer le moindre privilège.
5. Préparer le plan local, vérifier les changements et obtenir l'accord du responsable avant toute action dans un vrai environnement.
6. Appliquer la modification fictive, exporter le journal et contrôler les résultats.
7. Faire confirmer le retour au service par l'utilisateur et mettre à jour la fiche de connaissance.

## Vérifications par service

| Service | Modèle local | À vérifier dans un vrai tenant de test |
|---|---|---|
| Entra ID / Azure AD | compte, groupes, état MFA | licences, rôles, logs de connexion, accès conditionnel et permissions |
| Exchange Online | droit de messagerie attribué par groupe | licence, boîte aux lettres, délégations, état de provisionnement |
| Teams | droit collaboratif | licence, appartenance à l'équipe, stratégie et état du service |
| SharePoint Online | droit de groupe | site concerné, héritage, droits spécifiques, partage externe |
| OneDrive | droit collaboratif | licence, provisionnement, accès et synchronisation |
| Microsoft Graph API | plan JSON de requêtes | documentation officielle, permissions et limites avant toute intégration |

## Départ et conservation

La simulation désactive le compte, supprime ses groupes et ferme les sessions fictives. En entreprise, la conservation des données, les obligations légales, le transfert d'accès et les sauvegardes doivent être décidés avant suppression. Aucun effacement de données n'est exécuté ici.

## Sécurité des scripts

Les identifiants utilisent le préfixe `demo-`. Aucun secret ou document d'entreprise ne doit entrer dans les fixtures ou les rapports. Les scripts ne possèdent pas de commande de connexion au cloud. Les preuves doivent être relues avant publication. L'idempotence est fondée sur un identifiant de ticket stable dans l'état sauvegardé, elle ne garantit pas les écritures concurrentes d'un vrai annuaire.
