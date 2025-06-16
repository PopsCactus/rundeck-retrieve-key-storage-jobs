#!/bin/bash

set -euo pipefail

# Couleurs et symboles pour l'affichage visuel
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

usage() {
    echo -e "${YELLOW}Usage:${NC} $0 -u <rundeck_url> -t <api_token> [-v <api_version>] [-o <output_dir>]"
    echo -e "  -u  URL de Rundeck (ex: http://localhost:4440)"
    echo -e "  -t  Token API Rundeck"
    echo -e "  -v  Version de l'API (défaut: 52)"
    echo -e "  -o  Répertoire de sortie (défaut: ./rundeck_jobs)"
    echo -e "  -h  Affiche cette aide"
    exit 1
}

# Valeurs par défaut
API_VERSION="52"
OUTPUT_DIR="./rundeck_jobs"

# Lecture des paramètres
while getopts ":u:t:v:o:h" opt; do
  case $opt in
    u) RUNDECK_URL="$OPTARG" ;;
    t) API_TOKEN="$OPTARG" ;;
    v) API_VERSION="$OPTARG" ;;
    o) OUTPUT_DIR="$OPTARG" ;;
    h) usage ;;
    \?) echo -e "${RED}Option invalide: -$OPTARG${NC}" >&2; usage ;;
    :) echo -e "${RED}L'option -$OPTARG requiert un argument.${NC}" >&2; usage ;;
  esac
done

# Vérification des paramètres obligatoires
if [ -z "${RUNDECK_URL:-}" ] || [ -z "${API_TOKEN:-}" ]; then
    usage
fi

mkdir -p "$OUTPUT_DIR"

list_projects() {
    curl -s -H "X-Rundeck-Auth-Token: $API_TOKEN" \
         -H "Accept: application/json" \
         "$RUNDECK_URL/api/$API_VERSION/projects" | jq -r '.[].name'
}

export_jobs() {
    local project="$1"
    local output_file="$OUTPUT_DIR/${project}_jobs.json"
    
    echo -e "${YELLOW}==============================${NC}"
    echo -e "${BLUE}🚀 Exporting jobs for project: ${YELLOW}$project${NC}"
    echo -e "${YELLOW}------------------------------${NC}"
    
    curl -s -H "X-Rundeck-Auth-Token: $API_TOKEN" \
         -H "Accept: application/json" \
         "$RUNDECK_URL/api/$API_VERSION/project/$project/jobs/export?format=json" > "$output_file"
    
    # Extraction des storage_paths
    mapfile -t storage_paths < <(jq -r '.[] | select(.options != null) | .options[]?.storagePath // empty' "$output_file")
    if [ "${#storage_paths[@]}" -gt 0 ]; then
        echo -e "${GREEN}✔ Jobs exported to $output_file${NC}"
        echo -e "${BLUE}🔍 Extracting storage path from $output_file${NC}"
        for path in "${storage_paths[@]}"; do
            echo "$path"
        done
    else
        # Si aucun storage_path, ne rien afficher pour ce projet
        echo -e "${YELLOW}Aucun key storage trouvé pour le projet: $project${NC}"
    fi
    echo -e "${YELLOW}==============================${NC}\n"
}

echo -e "${YELLOW}=========================================${NC}"
echo -e "${BLUE}🔗 Vérification de la connexion à Rundeck...${NC}"

response=$(curl -sk -o /dev/null -w "%{http_code}" -H "X-Rundeck-Auth-Token: $API_TOKEN" "$RUNDECK_URL/api/40/system/info")

if [ "$response" -ne 200 ]; then
  echo -e "${RED}❌ Erreur : Impossible de se connecter à Rundeck (code HTTP $response)${NC}"
  exit 1
fi

echo -e "${GREEN}✔ Connexion à Rundeck réussie !${NC}"
echo -e "${YELLOW}=========================================${NC}\n"

for project in $(list_projects); do
    export_jobs "$project"
done
