# Immagine Docker Node.js Semantic Release

Questa immagine Docker fornisce un ambiente completo per l'automazione del rilascio di pacchetti Node.js utilizzando [semantic-release](https://semantic-release.gitbook.io/).

## Caratteristiche

- **Node.js 22.x** con npm e yarn
- **Semantic-release** con plugin comuni preinstallati:
  - `@semantic-release/commit-analyzer`
  - `@semantic-release/release-notes-generator`
  - `@semantic-release/changelog`
  - `@semantic-release/npm`
  - `@semantic-release/github`
  - `@semantic-release/git`
- **Strumenti CI/CD aggiuntivi**:
  - `commitizen` con `cz-conventional-changelog`
  - `standard-version`
- **Configurazione predefinita** per semantic-release
- **Ambiente sicuro** (esecuzione come utente non-root)
- **Alias e funzioni** per semplificare l'uso

## Utilizzo Base

### Eseguire semantic-release sul progetto corrente

```bash
# Eseguire semantic-release con configurazione automatica
docker run --rm -v $(pwd):/workdir your-registry/node-semantic-release sr

# Eseguire in modalità dry-run per testare senza pubblicare
docker run --rm -v $(pwd):/workdir your-registry/node-semantic-release sr-dry

# Eseguire con debug abilitato
docker run --rm -v $(pwd):/workdir your-registry/node-semantic-release sr-debug
```

### Creare workflow GitHub Actions

```bash
# Creare il file workflow per GitHub Actions
docker run --rm -v $(pwd):/workdir your-registry/node-semantic-release create-github-workflow
```

## Comandi e Alias Disponibili

### Alias NPM
- `nr` - `npm run`
- `ni` - `npm install`
- `nid` - `npm install --save-dev`
- `nig` - `npm install -g`
- `ns` - `npm start`
- `nt` - `npm test`
- `nb` - `npm run build`

### Alias Semantic-Release
- `sr` - `semantic-release` (con configurazione globale)
- `sr-dry` - `semantic-release --dry-run`
- `sr-debug` - `semantic-release` con debug abilitato

### Funzioni Speciali
- `run-semantic-release` - Esegue semantic-release senza modificare package.json
- `create-github-workflow` - Crea il file workflow per GitHub Actions

## Configurazione

### Configurazione Automatica

L'immagine include una configurazione predefinita che viene utilizzata automaticamente se il progetto non ha già un file di configurazione semantic-release (`.releaserc.json`, `.releaserc.yml`, `.releaserc.yaml`, o `.releaserc.js`).

La configurazione predefinita include:
- Branch supportati: `main`, `master`
- Generazione automatica di CHANGELOG.md
- Pubblicazione su NPM e GitHub
- Commit automatico delle modifiche

### Configurazione Personalizzata

Se il tuo progetto ha bisogno di una configurazione specifica, puoi creare un file `.releaserc.json` nella root del progetto:

```json
{
  "branches": ["main"],
  "plugins": [
    "@semantic-release/commit-analyzer",
    "@semantic-release/release-notes-generator",
    "@semantic-release/changelog",
    "@semantic-release/npm",
    "@semantic-release/github",
    [
      "@semantic-release/git",
      {
        "assets": ["CHANGELOG.md", "package.json"],
        "message": "chore(release): ${nextRelease.version} [skip ci]\n\n${nextRelease.notes}"
      }
    ]
  ]
}
```

## Variabili d'Ambiente

### Variabili Richieste per GitHub
- `GITHUB_TOKEN` - Token per accesso a GitHub (per release e commit)
- `NPM_TOKEN` - Token per pubblicazione su NPM (opzionale)

### Variabili Preconfigurate
- `CI=true` - Indica ambiente CI
- `GITHUB_ACTIONS=true` - Indica esecuzione in GitHub Actions

## Esempi d'Uso

### Esempio 1: Release Completa

```bash
# Naviga nella directory del progetto
cd /path/to/your/project

# Esegui semantic-release
docker run --rm \
  -v $(pwd):/workdir \
  -e GITHUB_TOKEN=$GITHUB_TOKEN \
  -e NPM_TOKEN=$NPM_TOKEN \
  your-registry/node-semantic-release sr
```

### Esempio 2: Test in Dry-Run

```bash
# Testa cosa farebbe semantic-release senza pubblicare
docker run --rm \
  -v $(pwd):/workdir \
  -e GITHUB_TOKEN=$GITHUB_TOKEN \
  your-registry/node-semantic-release sr-dry
```

### Esempio 3: Uso Interattivo

```bash
# Entra nel container per uso interattivo
docker run -it --rm \
  -v $(pwd):/workdir \
  -e GITHUB_TOKEN=$GITHUB_TOKEN \
  your-registry/node-semantic-release bash

# All'interno del container puoi usare tutti gli alias:
# ni                    # npm install
# nt                    # npm test
# sr-dry               # semantic-release --dry-run
# sr                   # semantic-release
```

### Esempio 4: Integrazione con Docker Compose

```yaml
version: '3.8'
services:
  semantic-release:
    image: your-registry/node-semantic-release
    volumes:
      - .:/workdir
    environment:
      - GITHUB_TOKEN=${GITHUB_TOKEN}
      - NPM_TOKEN=${NPM_TOKEN}
    command: sr
```

## Workflow GitHub Actions

L'immagine può creare automaticamente un workflow GitHub Actions. Il file generato (`.github/workflows/release.yml`) include:

- Trigger su push ai branch `main`/`master`
- Setup di Node.js LTS
- Installazione dipendenze con `npm ci`
- Esecuzione di semantic-release

Per personalizzare il workflow, modifica il file dopo la generazione o crea il tuo workflow personalizzato.

## Convenzioni per i Commit

Semantic-release si basa sulle [Conventional Commits](https://www.conventionalcommits.org/). Esempi:

```
feat: aggiunge nuova funzionalità
fix: corregge bug critico
docs: aggiorna documentazione
style: formattazione codice
refactor: refactoring senza cambi funzionali
test: aggiunge test
chore: aggiornamento dipendenze
```

### Tipi di Release
- `fix:` → patch release (1.0.1)
- `feat:` → minor release (1.1.0)
- `BREAKING CHANGE:` → major release (2.0.0)

## Risoluzione Problemi

### Problema: "No release published"
- Verifica che ci siano commit che seguono le convenzioni
- Controlla che il branch sia configurato correttamente
- Usa `sr-dry` per vedere cosa farebbe semantic-release

### Problema: Errori di autenticazione
- Verifica che `GITHUB_TOKEN` sia impostato correttamente
- Per NPM, assicurati che `NPM_TOKEN` sia valido
- Controlla i permessi del token

### Problema: Configurazione non trovata
- L'immagine usa configurazione predefinita se non trova file di config
- Per debug, usa `sr-debug` per vedere i dettagli

## Supporto

Per problemi specifici dell'immagine Docker, consulta:
- La documentazione di [semantic-release](https://semantic-release.gitbook.io/)
- I log di debug con `sr-debug`
- Gli esempi in questo README

## Note di Sicurezza

- L'immagine esegue come utente non-root (`bashuser`)
- I token devono essere passati come variabili d'ambiente
- Non includere mai token nei file di configurazione committati