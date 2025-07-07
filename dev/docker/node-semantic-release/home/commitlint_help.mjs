#!/usr/bin/env node

import config,{typeDescriptions,scopeDescriptions} from "./commitlint.config.mjs"
import Handlebars from 'handlebars';
import { readFileSync, writeFileSync } from 'fs';

// Function to show help

// Helper per creare ASCII art con wrapping intelligente
Handlebars.registerHelper('asciiDiagram', function(types, scopes, options) {
    const maxLineLength = 90;

    // Crea la lista dei tipi
    const typesList = types.map(t => t.type).join('|');
    const scopesList = scopes.list.join('|');

    // Funzione per wrappare una stringa lunga con continuazione ASCII
    function wrapWithAscii(content, prefix, continuation) {
        // Per la prima riga usiamo prefix, per le successive continuation
        const firstLineMaxLength = maxLineLength - continuation.length;
        const continuationMaxLength = maxLineLength - continuation.length;

        if (content.length <= firstLineMaxLength) {
            return prefix + content;
        }

        const lines = [];
        let currentLine = '';
        const parts = content.split('|');
        let isFirstLine = true;

        for (let i = 0; i < parts.length; i++) {
            const part = parts[i] + (i < parts.length - 1 ? '|' : '');
            const availableLength = isFirstLine ? firstLineMaxLength : continuationMaxLength;

            if (currentLine.length + part.length <= availableLength) {
                currentLine += part;
            } else {
                if (currentLine) {
                    // Salva la riga corrente
                    const linePrefix = isFirstLine ? prefix : continuation;
                    lines.push(linePrefix + currentLine);
                    currentLine = part;
                    isFirstLine = false;
                } else {
                    // Se anche un singolo elemento è troppo lungo, lo tronchiamo
                    const linePrefix = isFirstLine ? prefix : continuation;
                    const maxPartLength = availableLength - 3; // -3 per '...'
                    lines.push(linePrefix + part.substring(0, maxPartLength) + '...');
                    currentLine = '';
                    isFirstLine = false;
                }
            }
        }

        if (currentLine) {
            const linePrefix = isFirstLine ? prefix : continuation;
            lines.push(linePrefix + currentLine);
        }

        return lines.join('\n');
    }

    // Costruisce il diagramma
    const scopesWrapped = wrapWithAscii(scopesList, '', '  │                          ');
    const typesWrapped = wrapWithAscii(typesList, '', '                     ');

    const diagram = `<type>(<scope>): <short summary>
  │       │             │
  │       │             └─⫸ Summary in present tense. Not capitalized. No period at the end.
  │       │
  │       └─⫸ Commit Scope: ${scopesWrapped}
  │
  └─⫸ Commit Type: ${typesWrapped}`;

    return new Handlebars.SafeString(diagram);
});


// Helper semplificato per liste inline
Handlebars.registerHelper('wrapList', function(items, options) {
    if (!items || items.length === 0) {
        return '';
    }

    const maxLineLength = 90;
    const prefix = '  ';
    let result = '';
    let currentLine = prefix;

    for (let i = 0; i < items.length; i++) {
        const item = `\`${items[i]}\``;
        const separator = i < items.length - 1 ? ', ' : '';
        const itemWithSeparator = item + separator;

        if (currentLine.length + itemWithSeparator.length <= maxLineLength) {
            currentLine += itemWithSeparator;
        } else {
            result += currentLine + '\n';
            currentLine = prefix + itemWithSeparator;
        }
    }

    if (currentLine.length > prefix.length) {
        result += currentLine;
    }

    return new Handlebars.SafeString(result);
});



function extractTypesData(config) {
    const types = config?.rules?.['type-enum']?.[2] || Object.keys(typeDescriptions);

    return types.map(type => ({
        type: type,
        description: typeDescriptions[type] || ''
    }));
}

function extractScopesData(config) {
    const scopes = config?.rules?.['scope-enum']?.[2];
    const scopeRequired = config?.rules?.['scope-empty']?.[1] === 'never';

    return {
        hasScopes: scopes && scopes.length > 0,
        required: scopeRequired,
        list: (scopes || []).map(scope => ({scope: scope, description: scopeDescriptions[scope] || ''}))
    };
}

function extractLengthRules(config) {
    const rules = [];

    // Header length
    const headerMax = config?.rules?.['header-max-length']?.[2];
    const headerMin = config?.rules?.['header-min-length']?.[2];
    if (headerMax || headerMin) {
        const min = headerMin ? `${headerMin}` : 'no minimum';
        const max = headerMax ? `${headerMax}` : 'no maximum';
        rules.push({
            label: 'Header',
            rule: `${min} - ${max} characters`
        });
    }

    // Subject length
    const subjectMax = config?.rules?.['subject-max-length']?.[2];
    const subjectMin = config?.rules?.['subject-min-length']?.[2];
    if (subjectMax || subjectMin) {
        const min = subjectMin ? `${subjectMin}` : 'no minimum';
        const max = subjectMax ? `${subjectMax}` : 'no maximum';
        rules.push({
            label: 'Description',
            rule: `${min} - ${max} characters`
        });
    }

    // Scope length
    const scopeMax = config?.rules?.['scope-max-length']?.[2];
    if (scopeMax) {
        rules.push({
            label: 'Scope',
            rule: `maximum ${scopeMax} characters`
        });
    }

    // Body line length
    const bodyMax = config?.rules?.['body-max-line-length']?.[2];
    if (bodyMax) {
        rules.push({
            label: 'Body lines',
            rule: `maximum ${bodyMax} characters`
        });
    }

    // Footer line length
    const footerMax = config?.rules?.['footer-max-line-length']?.[2];
    if (footerMax) {
        rules.push({
            label: 'Footer lines',
            rule: `maximum ${footerMax} characters`
        });
    }

    return rules;
}

function extractFormattingRules(config) {
    const rules = [];

    // Type case
    const typeCase = config?.rules?.['type-case']?.[2];
    if (typeCase) {
        const caseDesc = typeCase === 'lower-case' ? 'lowercase' : typeCase;
        rules.push({
            label: 'Type',
            rule: `must be in ${caseDesc}`
        });
    }

    // Subject case
    const subjectCase = config?.rules?.['subject-case']?.[2];
    if (subjectCase) {
        const caseDesc = subjectCase === 'sentence-case' ? 'sentence case' : subjectCase;
        rules.push({
            label: 'Description',
            rule: `must be in ${caseDesc}`
        });
    }

    // Scope case
    const scopeCase = config?.rules?.['scope-case']?.[2];
    if (scopeCase) {
        const caseDesc = scopeCase === 'lower-case' ? 'lowercase' : scopeCase;
        rules.push({
            label: 'Scope',
            rule: `must be in ${caseDesc}`
        });
    }

    // Full stop rules
    const headerFullStop = config?.rules?.['header-full-stop']?.[1] === 'never';
    const subjectFullStop = config?.rules?.['subject-full-stop']?.[1] === 'never';
    if (headerFullStop || subjectFullStop) {
        rules.push({
            label: 'Punctuation',
            rule: 'NO period at the end of header/description'
        });
    }

    return rules;
}

function extractStructuralRules(config) {
    const rules = [];

    // Body leading blank
    const bodyLeading = config?.rules?.['body-leading-blank']?.[1] === 'always';
    if (bodyLeading) {
        rules.push('Blank line required before commit body');
    }

    // Footer leading blank
    const footerLeading = config?.rules?.['footer-leading-blank']?.[1] === 'always';
    if (footerLeading) {
        rules.push('Blank line required before footer');
    }

    // References required
    const referencesRequired = config?.rules?.['references-empty']?.[1] === 'never';
    if (referencesRequired) {
        rules.push('References required (e.g., issue #123, ticket ABC-456)');
    }

    // Type required
    const typeRequired = config?.rules?.['type-empty']?.[1] === 'never';
    if (typeRequired) {
        rules.push('Type is required');
    }

    // Subject required
    const subjectRequired = config?.rules?.['subject-empty']?.[1] === 'never';
    if (subjectRequired) {
        rules.push('Description is required');
    }

    return rules;
}


function writeCommitHelp(config) {

    const template = Handlebars.compile(readFileSync('./templates/commit-message-guidelines.md', 'utf8'));
    // Estrai i dati dalla configurazione
    const typesArray = extractTypesData(config);
    const scopesData = extractScopesData(config);
    const lengthRules = extractLengthRules(config);
    const formattingRules = extractFormattingRules(config);
    const structuralRules = extractStructuralRules(config);

    // Prepara i dati per il template
    const templateData = {
        types: typesArray,
        scopes: scopesData,
        rules: {
            length: lengthRules.length > 0 ? lengthRules : null,
            formatting: formattingRules.length > 0 ? formattingRules : null,
            structural: structuralRules.length > 0 ? structuralRules : null
        },
        examples: {
            scope: scopesData.list?.[0] || 'api'
        },
        generatedAt: new Date().toISOString()
    };

    const result = template(templateData);

    writeFileSync('/workdir/commit-message-guidelines.md', result,'utf8');
}

// Main
async function main() {

    //showCommitHelp(config);
    writeCommitHelp(config);

}

main().catch(console.error);
