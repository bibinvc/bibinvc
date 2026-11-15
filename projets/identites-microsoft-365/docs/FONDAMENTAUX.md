# Repères pour relire et présenter le laboratoire

## Cloud Microsoft

Microsoft 365 fournit des services collaboratifs SaaS, dont Exchange Online, SharePoint Online, OneDrive et Teams. Microsoft Azure fournit aussi des services d'infrastructure et de plateforme. Ce projet représente uniquement des utilisateurs et des droits dans des documents locaux. Il ne provisionne aucune ressource Azure.

Microsoft Entra ID est le nom actuel d'Azure Active Directory, ou Azure AD. Cet annuaire de cloud concerne notamment identités, authentification et accès. Un groupe permet d'organiser des appartenances. Un groupe de sécurité, un groupe Microsoft 365, une équipe Teams et un site SharePoint ont des propriétés et des règles distinctes. La fixture simplifie ces différences en un champ `services`.

## Services collaboratifs et permissions

- Une boîte aux lettres Exchange Online possède un état de provisionnement et des droits de délégation. Le droit fictif de messagerie ne crée aucune boîte aux lettres.
- Une équipe Teams dispose de membres, de propriétaires et de stratégies. Une appartenance simulée ne permet pas de participer à une véritable équipe.
- SharePoint Online utilise des sites, des groupes et des permissions pouvant être héritées. Le modèle ne traite pas les ruptures d'héritage ni le partage externe.
- OneDrive dépend notamment du compte, de la licence, du provisionnement et de la synchronisation. Aucun de ces services n'est configuré ici.

## Authentification et gouvernance

L'authentification vérifie une identité. L'autorisation détermine les actions permises. L'inscription à une méthode MFA, l'exigence d'une MFA et la réussite d'une authentification MFA sont des états distincts. Le booléen `mfaRegistered` permet uniquement de repérer une inscription manquante dans l'exercice. Il ne prouve pas qu'une stratégie MFA est appliquée.

La procédure locale prévoit une demande, un approbateur, des droits attendus et une vérification après modification. Le principe de moindre privilège consiste à limiter les droits au besoin. La gouvernance réelle comprend aussi revue d'accès, séparation des responsabilités, conservation et traçabilité. Ces sujets demanderaient une validation spécifique dans un environnement réel.

## Automatisation et API

PowerShell transforme les fixtures, contrôle les erreurs et produit les rapports. Microsoft Graph API serait une interface d'accès aux données et services Microsoft dans une future intégration autorisée. Le plan JSON présente des formes de requêtes. Il ne contient ni authentification, ni jeton, ni client réseau.

Chaque service n'est pas intégralement administrable par une même API ou un même module. Les procédures d'Exchange Online, de SharePoint Online et de Teams doivent être vérifiées dans leurs documentations et modules respectifs.

## Vérification avec l'utilisateur et travail d'équipe

Pour un incident, relever symptôme, heure, impact, résultat attendu et vérifications déjà réalisées. Communiquer ce qui a été testé, ce qui reste à tester et les éléments utiles à une escalade. La clôture suppose une confirmation du retour au service. Les fiches de support servent à transmettre le dossier à un collègue.

## Références officielles

- [PowerShell et les services Microsoft 365](https://learn.microsoft.com/en-us/microsoft-365/enterprise/connect-to-all-microsoft-365-services-in-a-single-windows-powershell-window?view=o365-worldwide)
- [Permissions de Microsoft Graph](https://learn.microsoft.com/en-us/graph/permissions-overview)
- [Fonctionnement de Microsoft Entra MFA](https://learn.microsoft.com/en-us/entra/identity/authentication/concept-mfa-howitworks)
