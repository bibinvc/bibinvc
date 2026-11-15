# Création de comptes et gestion des accès Microsoft 365

Comment préparer les accès d’une personne qui arrive, change de service ou quitte une organisation ? Ce projet pédagogique, réalisé avec une assistance IA, traite trois demandes approuvées dans un annuaire fictif. Il s’exécute hors ligne avec PowerShell 7.

## Exécution

```powershell
pwsh -NoProfile -File ./Test-Lab.ps1
pwsh -NoProfile -File ./Run-Demo.ps1
```

Le premier script vérifie les règles de traitement. Le second repart des données initiales, crée un compte fictif, modifie les groupes d’un autre utilisateur et désactive un compte sortant. Relancer une demande déjà traitée ne réapplique pas le changement.

## Vérification des droits

Les groupes représentent les droits d’accès à Exchange Online, SharePoint Online, OneDrive et Teams. Le diagnostic repère les droits manquants, une inscription absente à l’authentification multifacteur et les accès résiduels après un départ. Un journal relie chaque changement à sa demande.

- [Demandes et utilisateurs de départ](fixtures/)
- [Résultats des tests](evidence/test-results.json)
- [Journal des changements](evidence/demo/audit.csv)
- [Exemples de requêtes Microsoft Graph](evidence/demo/request-plan.json)
- [Procédures de diagnostic et de traitement](docs/PROCEDURES.md)
- [Repères sur les identités et les services Microsoft](docs/FONDAMENTAUX.md)

Les identités et les droits existent uniquement dans les fichiers JSON. Les requêtes Microsoft Graph illustrent les opérations envisagées et restent hors ligne. Aucune boîte aux lettres ni ressource Microsoft 365 réelle n’est créée.
