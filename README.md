# governance-AGENTS_MASTER.md

Fonte unica di `AGENTS_MASTER.md`, lo standard di governance comune a tutti i progetti.

**Si modifica solo qui.** Ogni progetto in `projects.txt` ne contiene una copia generata (gli agenti AI devono trovarla dentro il repository), con una prima riga che indica il commit di origine e l'hash del contenuto.

## Aggiornare la governance

1. Modifica `AGENTS_MASTER.md` qui, fai commit e push.
2. Con i progetti clonati nella stessa cartella di questo repository (pierluigiavvanzo-creator/governance-AGENTS_MASTER.md) (es. `Documents\GitHub\`), esegui:

   ```powershell
   .\sync-governance.ps1
   ```

   Lo script aggiorna `AGENTS_MASTER.md` e `.github/workflows/governance-copy.yml` in ogni progetto. Non fa commit: in ogni progetto controlla `git diff`, poi commit e push.
3. Solo verifica, senza scrivere: `.\sync-governance.ps1 -Check`. Se i progetti sono altrove: `-ProjectsRoot <cartella>`.

## Controlli automatici

- **In ogni progetto** (`governance-copy.yml`): fallisce se qualcuno modifica a mano `AGENTS_MASTER.md` nel progetto.
- **Qui** (`drift-check.yml`, a ogni push e ogni giorno alle 06:00 UTC): fallisce se un progetto non ha la copia, l'ha modificata a mano o non è aggiornato all'ultima versione. Legge i progetti pubblicamente; se un progetto diventa privato serve un token.

## Aggiungere un progetto

Aggiungi il nome del repository a `projects.txt` ed esegui `.\sync-governance.ps1`.
