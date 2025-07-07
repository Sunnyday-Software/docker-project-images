#!/usr/bin/env node

import config from "./commitlint.config.mjs"
import Handlebars from 'handlebars';
import { readFileSync, writeFileSync } from 'fs';

// Function to show help


// Type descriptions mapping
const typeDescriptions = {
    'feat': 'A new feature',
    'fix': 'A bug fix',
    'docs': 'Documentation only changes',
    'style': 'Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc)',
    'refactor': 'A code change that neither fixes a bug nor adds a feature',
    'perf': 'A code change that improves performance',
    'test': 'Adding missing tests or correcting existing tests',
    'build': 'Changes that affect the build system or external dependencies',
    'ci': 'Changes to our CI configuration files and scripts',
    'chore': 'Other changes that don\'t modify src or test files',
    'revert': 'Reverts a previous commit'
};

function extractTypesData(config) {
    const types = config?.rules?.['type-enum']?.[2] || Object.keys(typeDescriptions);

    return types.map(type => ({
        type: type,
        description: typeDescriptions[type] || 'Custom type'
    }));
}

function extractScopesData(config) {
    const scopes = config?.rules?.['scope-enum']?.[2];
    const scopeRequired = config?.rules?.['scope-empty']?.[1] === 'never';

    return {
        hasScopes: scopes && scopes.length > 0,
        required: scopeRequired,
        list: scopes || []
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

function showCommitHelp(config) {


    console.log('\n📝 REQUIRED COMMIT FORMAT (https://github.com/angular/angular/blob/main/contributing-docs/commit-message-guidelines.md):');
    console.log('<header>\n' +
        '<BLANK LINE>\n' +
        '<body?>\n' +
        '<BLANK LINE>\n' +
        '<footer?>');

    console.log('HEADER');
    console.log('<type>(<scope>): <short summary>');


    // Extract types from configuration
    const types = config?.rules?.['type-enum']?.[2] || [
        'feat', 'fix', 'docs', 'style', 'refactor', 'perf', 'test', 'chore', 'ci', 'build', 'revert'
    ];

    console.log('');
    console.log('✅ Allowed types:' + types.join(', '));

    // Extract scopes from configuration
    const scopes = config?.rules?.['scope-enum']?.[2];
    if (scopes && scopes.length > 0) {
        console.log('🎯 Allowed scopes:' + scopes.join(', '));
        console.log('');
    }

    // Check if scope is required
    const scopeRequired = config?.rules?.['scope-empty']?.[1] === 'never';
    if (scopeRequired) {
        console.log('⚠️  Scope is REQUIRED for this project');
        console.log('');
    }

    // ADDITIONAL MANDATORY CONFIGURATIONS
    console.log('📏 MANDATORY LENGTHS:');

    // Header length
    const headerMaxLength = config?.rules?.['header-max-length']?.[2];
    const headerMinLength = config?.rules?.['header-min-length']?.[2];
    if (headerMaxLength || headerMinLength) {
        console.log(`   • Header: ${headerMinLength || 'min not specified'} - ${headerMaxLength || 'max not specified'} characters`);
    }

    // Subject length
    const subjectMaxLength = config?.rules?.['subject-max-length']?.[2];
    const subjectMinLength = config?.rules?.['subject-min-length']?.[2];
    if (subjectMaxLength || subjectMinLength) {
        console.log(`   • Description: ${subjectMinLength || 'min not specified'} - ${subjectMaxLength || 'max not specified'} characters`);
    }

    // Scope length
    const scopeMaxLength = config?.rules?.['scope-max-length']?.[2];
    if (scopeMaxLength) {
        console.log(`   • Scope: maximum ${scopeMaxLength} characters`);
    }

    // Body line length
    const bodyMaxLineLength = config?.rules?.['body-max-line-length']?.[2];
    if (bodyMaxLineLength) {
        console.log(`   • Body lines: maximum ${bodyMaxLineLength} characters`);
    }

    // Footer line length
    const footerMaxLineLength = config?.rules?.['footer-max-line-length']?.[2];
    if (footerMaxLineLength) {
        console.log(`   • Footer lines: maximum ${footerMaxLineLength} characters`);
    }
    console.log('');

    // MANDATORY FORMATTING RULES
    console.log('📝 MANDATORY FORMATTING RULES:');

    // Type case
    const typeCase = config?.rules?.['type-case']?.[2];
    if (typeCase) {
        console.log(`   • Type: must be in ${typeCase === 'lower-case' ? 'lowercase' : typeCase}`);
    }

    // Subject case
    const subjectCase = config?.rules?.['subject-case']?.[2];
    if (subjectCase) {
        console.log(`   • Description: must be in ${subjectCase === 'sentence-case' ? 'sentence case' : subjectCase}`);
    }

    // Scope case
    const scopeCase = config?.rules?.['scope-case']?.[2];
    if (scopeCase) {
        console.log(`   • Scope: must be in ${scopeCase === 'lower-case' ? 'lowercase' : scopeCase}`);
    }

    // Body case
    const bodyCase = config?.rules?.['body-case']?.[2];
    if (bodyCase) {
        console.log(`   • Body: must be in ${bodyCase === 'sentence-case' ? 'sentence case' : bodyCase}`);
    }

    // Full stop rules
    const headerFullStop = config?.rules?.['header-full-stop']?.[1] === 'never';
    const subjectFullStop = config?.rules?.['subject-full-stop']?.[1] === 'never';
    if (headerFullStop || subjectFullStop) {
        console.log('   • DO NOT end header/description with a period');
    }
    console.log('');

    // MANDATORY STRUCTURAL RULES
    console.log('🏗️  MANDATORY STRUCTURAL RULES:');

    // Body leading blank
    const bodyLeadingBlank = config?.rules?.['body-leading-blank']?.[1] === 'always';
    if (bodyLeadingBlank) {
        console.log('   • Blank line required before commit body');
    }

    // Footer leading blank
    const footerLeadingBlank = config?.rules?.['footer-leading-blank']?.[1] === 'always';
    if (footerLeadingBlank) {
        console.log('   • Blank line required before footer');
    }

    // References required
    const referencesRequired = config?.rules?.['references-empty']?.[1] === 'never';
    if (referencesRequired) {
        console.log('   • References required (e.g.: issue #123, ticket ABC-456)');
    }

    // Type required
    const typeRequired = config?.rules?.['type-empty']?.[1] === 'never';
    if (typeRequired) {
        console.log('   • Type required');
    }

    // Subject required
    const subjectRequired = config?.rules?.['subject-empty']?.[1] === 'never';
    if (subjectRequired) {
        console.log('   • Description required');
    }
    console.log('');
}

// Main
async function main() {

    //showCommitHelp(config);
    writeCommitHelp(config);

}

main().catch(console.error);
