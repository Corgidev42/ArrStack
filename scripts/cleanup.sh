#!/bin/bash
#==============================================================================
# Script de Nettoyage Radical - ArrStack
# Description: Supprime tous les conteneurs, volumes, configs et données
# Usage: make clean  ou  chmod +x scripts/cleanup.sh && ./scripts/cleanup.sh
#==============================================================================

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Se placer à la racine du projet
cd "$(dirname "$0")/.."

echo -e "${YELLOW}=== Nettoyage Radical de ArrStack ===${NC}\n"

# Confirmation de sécurité
echo -e "${RED}⚠️  ATTENTION: Cette action va supprimer :${NC}"
echo -e "  • Tous les conteneurs de la stack"
echo -e "  • Tous les volumes Docker (configs persistantes)"
echo -e "  • Le réseau media-network"
echo -e "  • Les configs locales (prowlarr/, radarr/, sonarr/, recyclarr/)"
echo -e ""
read -p "Continuer ? (oui/non): " confirmation
if [ "$confirmation" != "oui" ]; then
    echo -e "${RED}Annulation.${NC}"
    exit 0
fi

# Demander si on supprime aussi les données média
echo -e ""
read -p "Supprimer aussi les données (downloads + médias) ? (oui/non): " del_data

#==============================================================================
# Étape 1 : Arrêt et suppression des conteneurs
#==============================================================================
echo -e "\n${YELLOW}Étape 1: Arrêt et suppression des conteneurs...${NC}"

CONTAINERS=(
    "gluetun"
    "qbittorrent"
    "flaresolverr"
    "jackett"
    "prowlarr"
    "radarr"
    "sonarr"
    "jellyseerr"
    "jellyfin"
    "jellystat"
    "jellystat-db"
    "recyclarr"
    "rdtclient"
)

for container in "${CONTAINERS[@]}"; do
    if docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
        echo -e "  ${RED}→${NC} Suppression de ${container}..."
        docker stop "$container" 2>/dev/null || true
        docker rm -f "$container" 2>/dev/null || true
    fi
done

#==============================================================================
# Étape 2 : Suppression des volumes Docker
#==============================================================================
echo -e "\n${YELLOW}Étape 2: Suppression des volumes Docker...${NC}"

VOLUMES=(
    "gluetun_config"
    "qbittorrent_config"
    "prowlarr_config"
    "radarr_config"
    "sonarr_config"
    "jellyseerr_config"
    "jellyfin_config"
    "jellystat_db"
    "jackett_config"
    "rdtclient_config"
)

for volume in "${VOLUMES[@]}"; do
    if docker volume ls --format '{{.Name}}' | grep -q "^${volume}$"; then
        echo -e "  ${RED}→${NC} Suppression du volume ${volume}..."
        docker volume rm "$volume" 2>/dev/null || true
    fi
done

echo -e "  ${YELLOW}→${NC} Nettoyage des volumes orphelins..."
docker volume prune -f 2>/dev/null || true

#==============================================================================
# Étape 3 : Suppression du réseau Docker
#==============================================================================
echo -e "\n${YELLOW}Étape 3: Suppression du réseau Docker...${NC}"
docker network rm media-network 2>/dev/null || true

#==============================================================================
# Étape 4 : Suppression des configs locales du projet
#==============================================================================
echo -e "\n${YELLOW}Étape 4: Suppression des configs locales...${NC}"

LOCAL_DIRS=(
    "./prowlarr"
    "./radarr"
    "./sonarr"
    "./config-exports"
)

for dir in "${LOCAL_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo -e "  ${RED}→${NC} Suppression de ${dir}..."
        rm -rf "$dir"
    fi
done

# Recyclarr : supprimer les données générées mais garder recyclarr.yml
if [ -d "./recyclarr" ]; then
    echo -e "  ${RED}→${NC} Nettoyage recyclarr (logs, state, resources)..."
    rm -rf ./recyclarr/logs ./recyclarr/state ./recyclarr/resources ./recyclarr/configs ./recyclarr/includes
    rm -f ./recyclarr/settings.yml
fi

#==============================================================================
# Étape 5 : Suppression des données (optionnel)
#==============================================================================
if [ "$del_data" = "oui" ]; then
    DATA_PATH="${DATA_PATH:-/Users/dev/data}"
    echo -e "\n${YELLOW}Étape 5: Suppression des données (${DATA_PATH})...${NC}"
    if [ -d "$DATA_PATH" ]; then
        echo -e "  ${RED}→${NC} Suppression de ${DATA_PATH}/downloads..."
        rm -rf "${DATA_PATH}/downloads"
        echo -e "  ${RED}→${NC} Suppression de ${DATA_PATH}/media..."
        rm -rf "${DATA_PATH}/media"
    fi
else
    echo -e "\n${YELLOW}Étape 5: Données conservées.${NC}"
fi

#==============================================================================
# Résumé
#==============================================================================
echo -e "\n${GREEN}✅ Nettoyage terminé !${NC}"
echo -e "${BLUE}Pour redéployer :${NC}"
echo -e "  ${GREEN}make setup${NC}\n"
