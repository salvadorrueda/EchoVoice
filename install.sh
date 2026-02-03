#!/bin/bash

# EchoVoice Installation Script for GNU/Linux
# This script automates the installation of EchoVoice and its dependencies.

set -e

REPO_URL="https://github.com/salvadorrueda/EchoVoice.git"
INSTALL_DIR="$HOME/.echovoice"
BIN_DIR="$HOME/.local/bin"

echo "--- Installing EchoVoice ---"

# 1. Install System Dependencies
echo "[1/4] Checking and installing dependencies..."
if command -v apt-get >/dev/null; then
    sudo apt-get update -qq
    sudo apt-get install -y -qq espeak-ng python3-requests git
else
    echo "Warning: apt-get not found. Please ensure 'espeak-ng', 'python3-requests', and 'git' are installed manually."
fi

# 2. Clone Repository
echo "[2/4] Cloning repository to $INSTALL_DIR..."
if [ -d "$INSTALL_DIR" ]; then
    echo "Directory $INSTALL_DIR already exists. Updating..."
    cd "$INSTALL_DIR"
    git pull
else
    git clone "$REPO_URL" "$INSTALL_DIR"
    cd "$INSTALL_DIR"
fi

# 3. Setup Global Command
echo "[3/4] Setting up global command 'echovoice'..."
mkdir -p "$BIN_DIR"
chmod +x "$INSTALL_DIR/main.py"
ln -sf "$INSTALL_DIR/main.py" "$BIN_DIR/echovoice"

# 4. Update PATH in .bashrc
echo "[4/4] Configuring PATH in .bashrc..."
if ! grep -q "$BIN_DIR" "$HOME/.bashrc"; then
    echo "" >> "$HOME/.bashrc"
    echo "# EchoVoice path" >> "$HOME/.bashrc"
    echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$HOME/.bashrc"
    echo "Added $BIN_DIR to PATH in .bashrc"
else
    echo "$BIN_DIR is already in PATH."
fi

echo "--- Installation Complete! ---"
echo "Please restart your terminal or run: source ~/.bashrc"
echo "Then you can use EchoVoice by typing: echovoice \"Hello world\""
