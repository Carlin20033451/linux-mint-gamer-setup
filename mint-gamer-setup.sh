#!/bin/bash

# Linux Mint 22.x Gamer Setup
# Foco: Jogos, Emulação e Uso Diário

set -e

echo "=================================================="
echo "         LINUX MINT GAMER SETUP"
echo "=================================================="

install_apt() {
    local pkg="$1"

    if dpkg -s "$pkg" >/dev/null 2>&1; then
        echo "[OK] $pkg já instalado."
    else
        echo "[INSTALANDO] $pkg..."
        sudo apt install -y "$pkg"
    fi
}

install_flatpak_search() {

    local APP_NAME="$1"

    if flatpak list --app | grep -iq "$APP_NAME"; then
        echo "[OK] $APP_NAME já instalado."
        return
    fi

    APP_ID=$(flatpak search "$APP_NAME" --columns=application 2>/dev/null | head -n 1)

    if [ -z "$APP_ID" ]; then
        echo "[ERRO] Não foi possível localizar $APP_NAME no Flathub."
        return
    fi

    echo "[INSTALANDO] $APP_NAME ($APP_ID)"
    flatpak install -y flathub "$APP_ID"
}

echo
echo "=================================================="
echo "ATUALIZANDO O SISTEMA"
echo "=================================================="

sudo apt update
sudo apt upgrade -y

echo
echo "=================================================="
echo "VERIFICAÇÃO DE BLOATWARES"
echo "=================================================="

BLOATS=(
    thunderbird
    firefox
    hypnotix
    celluloid
    rhythmbox
    pix
    drawing
    transmission-gtk
    warpinator
    hexchat
    matrix
)

ENCONTRADOS=()

for pkg in "${BLOATS[@]}"
do
    if dpkg -s "$pkg" >/dev/null 2>&1; then
        ENCONTRADOS+=("$pkg")
    fi
done

echo
echo "Aplicativos encontrados para remoção:"

if [ ${#ENCONTRADOS[@]} -eq 0 ]; then
    echo "Nenhum encontrado."
else
    for pkg in "${ENCONTRADOS[@]}"
    do
        echo " - $pkg"
    done
fi

echo
echo "Pacotes LibreOffice encontrados:"
dpkg -l | grep libreoffice || true

echo
echo "=================================================="
echo "ATENÇÃO"
echo "=================================================="
echo "Os seguintes pacotes serão removidos:"
echo
echo "- LibreOffice"
echo "- Thunderbird"
echo "- Firefox"
echo "- Hypnotix"
echo "- Celluloid"
echo "- Rhythmbox"
echo "- Pix"
echo "- Drawing"
echo "- Transmission"
echo "- Warpinator"
echo "- Hexchat"
echo "- Matrix"
echo

read -rp "Deseja remover esses pacotes? [s/N]: " CONFIRMAR

if [[ "$CONFIRMAR" =~ ^[sS]$ ]]; then

    echo
    echo "Removendo aplicativos..."

    sudo apt purge -y \
        thunderbird \
        firefox \
        hypnotix \
        celluloid \
        rhythmbox \
        pix \
        drawing \
        transmission-gtk \
        warpinator \
        hexchat \
        matrix || true

    echo
    echo "Removendo LibreOffice..."

    sudo apt purge -y "libreoffice*" || true

    sudo apt autoremove --purge -y

    echo
    echo "[OK] Remoção concluída."

else

    echo
    echo "[CANCELADO] Nenhum aplicativo foi removido."

fi

echo
echo "=================================================="
echo "INSTALANDO PACOTES APT"
echo "=================================================="

install_apt gamemode
install_apt vulkan-tools
install_apt mint-meta-codecs
install_apt steam
install_apt curl

echo
echo "=================================================="
echo "CONFIGURANDO SSD (TRIM)"
echo "=================================================="

sudo systemctl enable --now fstrim.timer

echo "[OK] TRIM ativado."

echo
echo "=================================================="
echo "VERIFICANDO SUPORTE VULKAN"
echo "=================================================="

if command -v vulkaninfo >/dev/null 2>&1; then
    vulkaninfo --summary || true
else
    echo "[ERRO] Vulkan não encontrado."
fi

echo
echo "=================================================="
echo "FLATPAK"
echo "=================================================="

if ! command -v flatpak >/dev/null 2>&1; then
    echo "Instalando Flatpak..."
    sudo apt install -y flatpak
else
    echo "[OK] Flatpak já instalado."
fi

sudo flatpak remote-add \
--if-not-exists \
flathub \
https://flathub.org/repo/flathub.flatpakrepo

echo
echo "=================================================="
echo "INSTALANDO BRAVE"
echo "=================================================="

if ! command -v brave-browser >/dev/null 2>&1; then

    sudo curl -fsSLo \
        /usr/share/keyrings/brave-browser-archive-keyring.gpg \
        https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg

    echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | \
        sudo tee /etc/apt/sources.list.d/brave-browser-release.list >/dev/null

    sudo apt update
    sudo apt install -y brave-browser

else
    echo "[OK] Brave já instalado."
fi

echo
echo "=================================================="
echo "INSTALANDO APLICATIVOS FLATPAK"
echo "=================================================="

FLATPAK_APPS=(
    "Discord"
    "Spotify"
    "OBS"
    "ProtonUp-Qt"
    "ZapZap"
    "Prism Launcher"
    "Heroic"
    "Sober"
    "PPSSPP"
    "PCSX2"
    "RPCS3"
)

for app in "${FLATPAK_APPS[@]}"
do
    install_flatpak_search "$app"
done

echo
echo "=================================================="
echo "CONFIGURANDO OBS"
echo "=================================================="

OBS_ID=$(flatpak search OBS --columns=application | head -n 1)

if [ -n "$OBS_ID" ]; then
    flatpak override --user \
        --filesystem=home \
        --device=all \
        "$OBS_ID"

    echo "[OK] Permissões do OBS configuradas."
else
    echo "[AVISO] OBS não encontrado para aplicar permissões."
fi

echo
echo "=================================================="
echo "FINALIZAÇÃO"
echo "=================================================="

echo "3. Reinicie o computador."
echo
echo "=================================================="
echo "SETUP CONCLUÍDO!"
echo "=================================================="
