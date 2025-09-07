import { existsSync, readdirSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Function to load project-specific configurations
async function loadProjectConventions() {
    const conventionsDir = '/workdir/conventions/commits';

    if (!existsSync(conventionsDir)) {
        return {};
    }

    try {
        // Read all files in the directory, filter JS files, sort alphabetically
        const files = readdirSync(conventionsDir)
            .filter(f => f.toLowerCase().endsWith('.js'))
            .sort((a, b) => a.localeCompare(b));

        if (files.length === 0) {
            return {};
        }

        // Import each file in strict alphabetical order and merge their exports
        let merged = {};
        const deepMerge = (target, source) => {
            const out = { ...target };
            for (const [k, v] of Object.entries(source || {})) {
                if (v && typeof v === 'object' && !Array.isArray(v)) {
                    out[k] = deepMerge(out[k] || {}, v);
                } else {
                    out[k] = v;
                }
            }
            return out;
        };
        for (const file of files) {
            const fullPath = join(conventionsDir, file);
            try {
                const mod = await import(fullPath);
                const cfg = mod?.default ?? mod ?? {};
                merged = deepMerge(merged, cfg);
            } catch (e) {
                console.warn(`⚠️  Unable to load project conventions from ${fullPath}: ${e.message}`);
            }
        }
        return merged;
    } catch (error) {
        console.warn(`⚠️  Error reading conventions directory ${conventionsDir}: ${error.message}`);
        return {};
    }
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
            'security',
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
    ...projectConventions.commitlint,
    rules: {
        ...defaultConfig.rules,
        ...projectConventions?.commitlint?.rules
    }
};

// If the project specifies scopes, add them to the configuration
if (projectConventions?.commitlint?.scopes && Array.isArray(projectConventions?.commitlint?.scopes)) {
    finalConfig.rules['scope-enum'] = [2, 'always', projectConventions?.commitlint?.scopes];
}

// If the project specifies custom types, replace them
if (projectConventions?.commitlint?.types && Array.isArray(projectConventions?.commitlint?.types)) {
    finalConfig.rules['type-enum'] = [2, 'always', projectConventions?.commitlint?.types];
}

export default finalConfig;

export const typeDescriptions = {
    ...(projectConventions?.typeDescriptions ?? {
        'build': 'Changes that affect the build system or external dependencies',
        'ci': 'Changes to our CI configuration files and scripts',
        'docs': 'Documentation only changes',
        'feat': 'A new feature',
        'fix': 'A bug fix',
        'perf': 'A code change that improves performance',
        'refactor': 'A code change that neither fixes a bug nor adds a feature',
        'test': 'Adding missing tests or correcting existing tests',
        'style': 'Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc)'
    })
}

export const scopeDescriptions = {
    ...(projectConventions?.scopeDescriptions ?? {
        'core': 'Core module',
        'api': 'API module',
        'ui': 'UI module',
        'auth': 'Authentication module',
        'database': 'Database module',
        'config': 'Configuration module',
        'security': 'Security module',
        'localization': 'Localization module'
    })
}