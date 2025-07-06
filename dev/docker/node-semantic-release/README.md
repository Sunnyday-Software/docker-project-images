# Container Docker Node.js Semantic Release e Conventional Commits

Questo container Docker fornisce un ambiente completo e preconfigurato per l'automazione del rilascio di pacchetti e la validazione dei commit utilizzando [semantic-release](https://semantic-release.gitbook.io/) e [commitlint](https://commitlint.js.org/).

## Scopo del Container

Il container incapsula le funzionalità di **semantic release** e **conventional commits** per essere riutilizzato da qualsiasi progetto senza dover configurare questi strumenti da zero. L'obiettivo è fornire una soluzione già configurata che non richiede modifiche al progetto sottostante, mantenendo al contempo la possibilità di personalizzazione attraverso convenzioni definite.

## Caratteristiche Principali

- **Node.js 22.x** con npm
- **Commitlint** per la validazione dei conventional commits
- **Semantic-release** con plugin essenziali preinstallati
- **Script personalizzato `check-commit`** per validazione flessibile dei commit
- **Configurazione intelligente** che si adatta al progetto montato
- **Ambiente sicuro** (esecuzione come utente non-root)


## Guida ai Conventional Commits

### Formato Base
```
<tipo>[scope opzionale]: <descrizione>

[corpo opzionale]

[footer opzionale]
```

### Tipi di Commit Supportati
- `feat` - Nuova funzionalità per l'utente
- `fix` - Correzione di bug
- `docs` - Modifiche alla documentazione
- `style` - Formattazione, punto e virgola mancanti, ecc. (nessun cambiamento al codice)
- `refactor` - Refactoring del codice (né fix né feature)
- `perf` - Miglioramenti delle performance
- `test` - Aggiunta o correzione di test
- `chore` - Aggiornamento task di build, configurazioni, ecc.
- `ci` - Modifiche ai file e script di CI
- `build` - Modifiche che influenzano il sistema di build o dipendenze esterne
- `revert` - Revert di un commit precedente

### Esempi di Commit Validi
```bash
# Feature semplice
feat: aggiunge autenticazione utente

# Fix con scope
fix(api): corregge validazione email

# Breaking change
feat!: cambia API di autenticazione

# Con corpo e footer
feat(auth): aggiunge login con OAuth

Implementa il login tramite provider OAuth2 supportando
Google, GitHub e Microsoft.

Closes #123
BREAKING CHANGE: rimuove il login con username/password
```

### Impatto sui Rilasci
- `fix` → **PATCH** release (1.0.1)
- `feat` → **MINOR** release (1.1.0)
- `BREAKING CHANGE` o `!` → **MAJOR** release (2.0.0)


## Utilizzo Base

### Validazione dei Commit

```bash
# Validazione di un messaggio di commit da stdin
echo "feat: aggiunge nuova funzionalità" | docker run --rm -i -v $(pwd):/workdir your-registry/node-semantic-release check-commit

# Validazione di un messaggio di commit come argomento
docker run --rm -v $(pwd):/workdir your-registry/node-semantic-release check-commit "fix: corregge bug critico"

# Validazione di un commit da file
docker run --rm -v $(pwd):/workdir your-registry/node-semantic-release check-commit /path/to/commit-message-file

# Validazione dell'ultimo commit del repository
docker run --rm -v $(pwd):/workdir your-registry/node-semantic-release npm run commitlint:check
```

### Esecuzione di Semantic Release

```bash
# Esecuzione di semantic-release
docker run --rm \
  -v $(pwd):/workdir \
  -e GITHUB_TOKEN=$GITHUB_TOKEN \
  -e NPM_TOKEN=$NPM_TOKEN \
  your-registry/node-semantic-release semantic-release

# Esecuzione in modalità dry-run (test senza pubblicare)
docker run --rm \
  -v $(pwd):/workdir \
  -e GITHUB_TOKEN=$GITHUB_TOKEN \
  your-registry/node-semantic-release semantic-release --dry-run
```

### Uso Interattivo

```bash
# Accesso interattivo al container
docker run -it --rm \
  -v $(pwd):/workdir \
  -e GITHUB_TOKEN=$GITHUB_TOKEN \
  your-registry/node-semantic-release bash

# All'interno del container sono disponibili:
# check-commit          # Script personalizzato per validazione commit
# commitlint           # Strumento di validazione commitlint
# semantic-release     # Strumento per release automatiche
# npm run commitlint:* # Script npm preconfigurati
```

## Configurazione e Personalizzazione

### Configurazione Commitlint

Il container utilizza una configurazione commitlint intelligente che:

1. **Cerca configurazioni del progetto** in `/workdir` nell'ordine:
   - `commitlint.config.mjs`
   - `commitlint.config.js`
   - `.commitlintrc.mjs`
   - `.commitlintrc.js`
   - `.commitlintrc.json`
   - `.commitlintrc`

2. **Utilizza configurazione di default** se nessuna configurazione del progetto è trovata

### Personalizzazione tramite Convenzioni

Per personalizzare il comportamento del container per il tuo progetto, crea il file:
`/workdir/conventions/commits/commitlint-config-conventional.js`

Esempio di file di convenzione:

```javascript
// /workdir/conventions/commits/commitlint-config-conventional.js
export default {
  // Scope specifici del progetto
  scopes: [
    'api',
    'ui',
    'database',
    'auth',
    'config',
    'docs'
  ],

  // Tipi di commit personalizzati (opzionale)
  types: [
    'feat',
    'fix',
    'docs',
    'style',
    'refactor',
    'perf',
    'test',
    'chore',
    'ci',
    'build',
    'revert',
    'hotfix'  // tipo personalizzato
  ],

  // Regole aggiuntive (opzionale)
  rules: {
    'scope-max-length': [2, 'always', 15],
    'subject-max-length': [2, 'always', 60]
  }
};
```


### Uso in CI/CD Pipeline

#### GitHub Actions
```yaml
name: Release
on:
  push:
    branches: [main]

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0

      - name: Validate commits
        run: |
          docker run --rm -v ${{ github.workspace }}:/workdir \
            your-registry/node-semantic-release \
            npm run commitlint:check

      - name: Release
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
        run: |
          docker run --rm -v ${{ github.workspace }}:/workdir \
            -e GITHUB_TOKEN -e NPM_TOKEN \
            your-registry/node-semantic-release semantic-release
```




### Script di Automazione Locale

```bash
#!/bin/bash
# validate-and-release.sh

set -e

echo "🔍 Validazione commit..."
docker run --rm -v $(pwd):/workdir \
  your-registry/node-semantic-release \
  npm run commitlint:check

echo "🧪 Test dry-run semantic-release..."
docker run --rm -v $(pwd):/workdir \
  -e GITHUB_TOKEN=$GITHUB_TOKEN \
  your-registry/node-semantic-release \
  semantic-release --dry-run

read -p "Procedere con la release? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🚀 Esecuzione release..."
    docker run --rm -v $(pwd):/workdir \
      -e GITHUB_TOKEN=$GITHUB_TOKEN \
      -e NPM_TOKEN=$NPM_TOKEN \
      your-registry/node-semantic-release \
      semantic-release
fi
```
