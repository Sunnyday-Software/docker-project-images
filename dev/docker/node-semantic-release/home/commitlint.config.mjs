export default {
    extends: ['@commitlint/config-conventional'],
    rules: {
        // Lunghezza dell'header del commit (titolo)
        'header-max-length': [2, 'always', 72],
        'header-min-length': [2, 'always', 10],
        
        // Lunghezza del corpo del commit
        'body-max-line-length': [2, 'always', 100],
        'body-leading-blank': [2, 'always'],
        
        // Lunghezza del footer
        'footer-leading-blank': [2, 'always'],
        'footer-max-line-length': [2, 'always', 100],
        
        // Regole per il tipo di commit
        'type-case': [2, 'always', 'lower-case'],
        'type-empty': [2, 'never'],
        'type-enum': [2, 'always', [
            'feat',     // nuova funzionalità
            'fix',      // bug fix
            'docs',     // documentazione
            'style',    // formattazione, punto e virgola mancanti, ecc.
            'refactor', // refactoring del codice
            'perf',     // miglioramenti delle performance
            'test',     // aggiunta di test
            'chore',    // aggiornamento task di build, configurazioni, ecc.
            'ci',       // modifiche ai file di CI
            'build',    // modifiche che influenzano il sistema di build
            'revert'    // revert di un commit precedente
        ]],
        
        // Regole per lo scope
        'scope-case': [2, 'always', 'lower-case'],
        'scope-max-length': [2, 'always', 20],
        
        // Regole per la descrizione
        'subject-case': [2, 'always', 'lower-case'],
        'subject-empty': [2, 'never'],
        'subject-max-length': [2, 'always', 50],
        'subject-min-length': [2, 'always', 5],
        'subject-full-stop': [2, 'never', '.'],
        
        // Regole per i riferimenti
        'references-empty': [1, 'never'],
        
        // Regole per i signed-off-by
        'signed-off-by': [0, 'always', 'Signed-off-by:']
    }
};