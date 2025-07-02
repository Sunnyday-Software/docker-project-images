#!/bin/bash

# Script manuale per riprodurre il workflow build-with-dockercompose.yml
# Manual script to reproduce the build-with-dockercompose.yml workflow

set -e

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funzione per stampare messaggi colorati
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Funzione per mostrare l'help
show_help() {
    echo "Script manuale per riprodurre il workflow build-with-dockercompose.yml"
    echo ""
    echo "Uso: $0 [OPZIONI]"
    echo ""
    echo "OPZIONI:"
    echo "  -h, --help              Mostra questo messaggio di aiuto"
    echo "  --amd64                 Costruisci solo immagini AMD64"
    echo "  --arm64                 Costruisci solo immagini ARM64 (richiede QEMU)"
    echo "  --multiarch             Crea solo manifest multi-architettura"
    echo "  --all                   Esegui tutti i passaggi (default)"
    echo "  --skip-multiarch        Salta la creazione dei manifest multi-architettura"
    echo ""
    echo "VARIABILI D'AMBIENTE RICHIESTE:"
    echo "  DOCKERHUB_TOKEN         Token per l'accesso a Docker Hub"
    echo ""
    echo "ESEMPI:"
    echo "  $0                      # Esegui tutti i passaggi"
    echo "  $0 --amd64              # Costruisci solo immagini AMD64"
    echo "  $0 --arm64              # Costruisci solo immagini ARM64"
    echo "  $0 --skip-multiarch     # Costruisci immagini ma salta i manifest"
}

# Funzione per verificare i prerequisiti
check_prerequisites() {
    print_info "Verifico i prerequisiti..."
    
    # Verifica Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker non è installato o non è nel PATH"
        exit 1
    fi
    
    # Verifica che Docker sia in esecuzione
    if ! docker info &> /dev/null; then
        print_error "Docker non è in esecuzione"
        exit 1
    fi
    
    # Verifica DOCKERHUB_TOKEN
    if [ -z "${DOCKERHUB_TOKEN}" ]; then
        print_error "DOCKERHUB_TOKEN non è impostato"
        print_info "Imposta la variabile d'ambiente: export DOCKERHUB_TOKEN=your_token"
        exit 1
    fi
    
    print_success "Prerequisiti verificati"
}

# Funzione per costruire immagini AMD64
build_amd64() {
    print_info "Costruisco immagini per piattaforma AMD64..."
    
    export DOCKERHUB_TOKEN="${DOCKERHUB_TOKEN}"
    export DOCKER_PLATFORM="linux/amd64"
    export PLATFORM_TAG="amd64"
    export FORCE_PLATFORM="true"
    
    print_info "Building for platform: $DOCKER_PLATFORM"
    
    chmod +x ./build-project-ci.sh
    ./build-project-ci.sh
    
    print_success "Build AMD64 completata"
}

# Funzione per costruire immagini ARM64
build_arm64() {
    print_info "Costruisco immagini per piattaforma ARM64..."
    
    # Verifica se QEMU è disponibile per l'emulazione ARM64
    if ! docker buildx ls | grep -q "linux/arm64"; then
        print_warning "QEMU potrebbe non essere configurato per ARM64"
        print_info "Configurazione Docker Buildx per ARM64..."
        
        # Setup QEMU e Buildx
        docker run --rm --privileged multiarch/qemu-user-static --reset -p yes || true
        docker buildx create --name multiarch --driver docker-container --use || true
        docker buildx inspect --bootstrap || true
    fi
    
    export DOCKERHUB_TOKEN="${DOCKERHUB_TOKEN}"
    export DOCKER_PLATFORM="linux/arm64"
    export PLATFORM_TAG="arm64"
    export FORCE_PLATFORM="true"
    
    print_info "Building for platform: $DOCKER_PLATFORM"
    
    # Esporta tutte le variabili d'ambiente in un file
    printenv > .env.full
    
    chmod +x ./build-project-ci.sh
    ./build-project-ci.sh
    
    # Pulisci il file temporaneo
    rm -f .env.full
    
    print_success "Build ARM64 completata"
}

# Funzione per creare manifest multi-architettura
create_multiarch_manifest() {
    print_info "Creo manifest multi-architettura..."
    
    export DOCKERHUB_USERNAME="${DOCKERHUB_USERNAME:-sunnydaysoftware}"
    
    print_info "Building manifests"
    chmod +x ./multiarch-project-ci.sh
    ./multiarch-project-ci.sh
    
    print_success "Manifest multi-architettura creati"
}

# Variabili per le opzioni
BUILD_AMD64=false
BUILD_ARM64=false
CREATE_MULTIARCH=false
SKIP_MULTIARCH=false

# Parse degli argomenti
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        --amd64)
            BUILD_AMD64=true
            shift
            ;;
        --arm64)
            BUILD_ARM64=true
            shift
            ;;
        --multiarch)
            CREATE_MULTIARCH=true
            shift
            ;;
        --all)
            BUILD_AMD64=true
            BUILD_ARM64=true
            CREATE_MULTIARCH=true
            shift
            ;;
        --skip-multiarch)
            SKIP_MULTIARCH=true
            shift
            ;;
        *)
            print_error "Opzione sconosciuta: $1"
            show_help
            exit 1
            ;;
    esac
done

# Se nessuna opzione specifica è stata data, esegui tutto
if [ "$BUILD_AMD64" = false ] && [ "$BUILD_ARM64" = false ] && [ "$CREATE_MULTIARCH" = false ]; then
    BUILD_AMD64=true
    BUILD_ARM64=true
    if [ "$SKIP_MULTIARCH" = false ]; then
        CREATE_MULTIARCH=true
    fi
fi

# Esecuzione principale
print_info "Inizio build manuale del progetto Docker Images"
print_info "================================================"

# Verifica prerequisiti
check_prerequisites

# Esegui i build richiesti
if [ "$BUILD_AMD64" = true ]; then
    build_amd64
fi

if [ "$BUILD_ARM64" = true ]; then
    build_arm64
fi

# Crea manifest multi-architettura solo se entrambe le architetture sono state costruite
if [ "$CREATE_MULTIARCH" = true ]; then
    if [ "$BUILD_AMD64" = true ] && [ "$BUILD_ARM64" = true ]; then
        create_multiarch_manifest
    elif [ "$BUILD_AMD64" = false ] && [ "$BUILD_ARM64" = false ]; then
        # Se è stato richiesto solo multiarch, eseguilo comunque
        create_multiarch_manifest
    else
        print_warning "Manifest multi-architettura saltato: sono necessarie entrambe le architetture AMD64 e ARM64"
    fi
fi

print_success "Build completata con successo!"
print_info "================================================"