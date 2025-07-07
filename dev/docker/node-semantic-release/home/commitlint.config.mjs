import { existsSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Function to load project-specific configurations
async function loadProjectConventions() {
    const conventionsPath = '/workdir/conventions/commits/commitlint-config-conventional.js';

    if (existsSync(conventionsPath)) {
        try {
            // Dynamically import project configuration
            const projectConventions = await import(conventionsPath);
            return projectConventions.default || projectConventions;
        } catch (error) {
            console.warn(`⚠️  No project conventions from ${conventionsPath}:`, error.message);
            return {};
        }
    }

    return {};
}

// Default configuration
const defaultConfig = {
    extends: ['@commitlint/config-conventional'],
    rules: {
        // Commit header length (title)
        'header-max-length': [2, 'always', 140],
        'header-min-length': [2, 'always', 5],
        'header-full-stop': [2, 'never', '.'],

        // Description rules
        'subject-case': [2, 'always', 'lower-case'],
        'subject-empty': [2, 'never'],
        'subject-max-length': [2, 'always', 100],
        'subject-min-length': [2, 'always', 5],
        'subject-full-stop': [2, 'never', '.'],

        // Commit body length
        'body-max-line-length': [2, 'always', 100],
        'body-leading-blank': [2, 'always'],
        'body-case': [2, 'always', 'lower-case'],

        // Footer length
        'footer-leading-blank': [2, 'always'],
        'footer-max-line-length': [2, 'always', 100],

        // Commit type rules
        'type-case': [2, 'always', 'lower-case'],
        'type-empty': [2, 'never'],
        'type-enum': [2, 'always', [
            'build',    // changes affecting the build system
            'ci',       // CI file changes
            'docs',     // documentation
            'feat',     // new feature
            'fix',      // bug fix
            'perf',     // performance improvements
            'refactor', // code refactoring
            'test',     // adding tests
            'style'     // formatting, missing semicolons, etc.
        ]],

        // Scope rules
        'scope-case': [2, 'always', 'lower-case'],
        'scope-max-length': [2, 'always', 20],
        'scope-empty': [2, 'never'], // This enforces the presence of scope
        'scope-enum': [2, 'always', [
            'core',
            'api',
            'ui',
            'auth',
            'database',
            'config',
            'localization'
        ]],




        // Reference rules
        'references-empty': [2, 'never'],

    },
    parserPreset: {
        parserOpts: {
            referenceActions: [
                'close',
                'closes',
                'closed',
                'fix',
                'fixes',
                'fixed',
                'resolve',
                'resolves',
                'resolved'
            ],
            issuePrefixes: ['#'],
            noteKeywords: ['BREAKING CHANGE', 'BREAKING-CHANGE'],
        }
    },
    helpUrl: "file://./commit-message-guidelines.md"
};

// Load project conventions and merge with default configuration
const projectConventions = await loadProjectConventions();

// Intelligent merge of configurations
const finalConfig = {
    ...defaultConfig,
    ...projectConventions,
    rules: {
        ...defaultConfig.rules,
        ...projectConventions.rules
    }
};

// If the project specifies scopes, add them to the configuration
if (projectConventions.scopes && Array.isArray(projectConventions.scopes)) {
    finalConfig.rules['scope-enum'] = [2, 'always', projectConventions.scopes];
}

// If the project specifies custom types, replace them
if (projectConventions.types && Array.isArray(projectConventions.types)) {
    finalConfig.rules['type-enum'] = [2, 'always', projectConventions.types];
}

export default finalConfig;
