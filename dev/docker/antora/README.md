# Antora Documentation Image

Container image for building Antora documentation sites in Sunnyday Software project templates.

The image follows the same architecture as `node-semantic-release`:

- it is based on the shared `sunnydaysoftware/bash` image;
- it installs Node.js inside the image;
- it installs project tooling under `/home/devuser`;
- it exposes command binaries through `/home/devuser/node_modules/.bin`;
- it can run project scripts mounted under `/workdir`.

Included tooling:

- Antora CLI and site generator;
- `asciidoctor-kroki`;
- the default Antora UI bundle at `/opt/antora/ui/ui-bundle.zip`.

The expected runtime pair is a project-local Compose stack with `docs-antora` and `docs-kroki` services. The Antora playbook should point Kroki to `http://docs-kroki:8000`.
