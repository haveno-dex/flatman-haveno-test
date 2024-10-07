#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Default FLATMAN_URL
FLATMAN_URL=${FLATMAN_URL:-http://localhost:8080}

# Check if org.flatpak.flat-manager-client is installed
if ! flatpak list | grep -q 'org.flatpak.flat-manager-client'; then
  echo -e "${YELLOW}org.flatpak.flat-manager-client is not installed.${NC}"
  read -p "$(echo -e ${YELLOW}Do you want to install it for this user? [y/n, default: n]: ${NC})" INSTALL_RESPONSE
  INSTALL_RESPONSE=${INSTALL_RESPONSE:-n}

  if [ "$INSTALL_RESPONSE" == "y" ]; then
    echo -e "${YELLOW}Installing org.flatpak.flat-manager-client...${NC}"
    flatpak install --user -y org.flatpak.flat-manager-client
  else
    echo -e "${RED}Installation aborted.${NC}"
    exit 1
  fi
fi

# Check if a directory argument is provided
if [ -z "$1" ]; then
  echo -e "${RED}Usage: $0 <directory>${NC}"
  exit 1
fi

DIR="$1"

# Check if the directory exists
if [ ! -d "$DIR" ]; then
  echo -e "${RED}Directory $DIR does not exist.${NC}"
  exit 1
fi

# Check if TOKEN_FILE environment variable is set
if [ -z "$TOKEN_FILE" ]; then
  echo -e "${RED}TOKEN_FILE environment variable is not set.${NC}"
  exit 1
fi

# Check if the token file exists
if [ ! -f "$TOKEN_FILE" ]; then
  echo -e "${RED}Token file $TOKEN_FILE does not exist.${NC}"
  exit 1
fi

# Run the commands
echo -e "${YELLOW}Creating commit...${NC}"
COMMIT=$(flatpak run org.flatpak.flat-manager-client -v --token-file="$TOKEN_FILE" create "$FLATMAN_URL" stable)

echo -e "${YELLOW}Pushing commit...${NC}"
flatpak run org.flatpak.flat-manager-client -v --token-file="$TOKEN_FILE" push --wait --wait-update --commit "$COMMIT" "$DIR"

echo -e "${GREEN}Commit created: $COMMIT${NC}"

# Ask user if they are ready to publish
read -p "$(echo -e ${YELLOW}Ready to publish? [y/n, default: n]: ${NC})" RESPONSE
RESPONSE=${RESPONSE:-n}

if [ "$RESPONSE" == "y" ]; then
  echo -e "${YELLOW}Publishing...${NC}"
  flatpak run org.flatpak.flat-manager-client -v --token-file="$TOKEN_FILE" publish --wait --wait-update "$COMMIT" 
  echo -e "${GREEN}Published successfully.${NC}"
else
  echo -e "${RED}Publish aborted.${NC}"
fi
