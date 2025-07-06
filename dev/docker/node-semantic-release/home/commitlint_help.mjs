#!/usr/bin/env node

import config from "./commitlint.config.mjs"


// Function to show help
function showCommitHelp(config) {
    console.log('\n📝 REQUIRED COMMIT FORMAT (https://www.conventionalcommits.org/en/v1.0.0/#specification):');
    console.log('   <type>(scope): <subject>');
    console.log('');
    console.log('   body?');
    console.log('');
    console.log('   footer?');

    // Extract types from configuration
    const types = config?.rules?.['type-enum']?.[2] || [
        'feat', 'fix', 'docs', 'style', 'refactor', 'perf', 'test', 'chore', 'ci', 'build', 'revert'
    ];

    console.log('✅ ALLOWED TYPES:');
    console.log('   ' + types.join(', '));
    console.log('');

    // Extract scopes from configuration
    const scopes = config?.rules?.['scope-enum']?.[2];
    if (scopes && scopes.length > 0) {
        console.log('🎯 ALLOWED SCOPES:');
        console.log('   ' + scopes.join(', '));
        console.log('');
    }

    // Check if scope is required
    const scopeRequired = config?.rules?.['scope-empty']?.[1] === 'never';
    if (scopeRequired) {
        console.log('⚠️  SCOPE REQUIRED for this project');
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

    showCommitHelp(config);
}

main().catch(console.error);
