#!/bin/bash

# Script para alternar entre porta 22 e 443 para GitHub SSH

CONFIG_FILE="$HOME/.ssh/config"
BACKUP_FILE="$HOME/.ssh/config.backup"

# Função para usar porta 443 (padrão)
use_port_443() {
    echo "🔄 Configurando GitHub SSH para usar porta 443..."
    cat > "$CONFIG_FILE" << 'EOF'
# GitHub SSH Configuration
# Usa porta 443 por padrão (mais compatível com firewalls)

Host github.com
    Hostname ssh.github.com
    Port 443
    User git

# Configuração alternativa para redes que permitem porta 22
Host github-22
    Hostname github.com
    Port 22
    User git
EOF
    echo "✅ Configurado para usar porta 443 (recomendado)"
}

# Função para usar porta 22
use_port_22() {
    echo "🔄 Configurando GitHub SSH para usar porta 22..."
    cat > "$CONFIG_FILE" << 'EOF'
# GitHub SSH Configuration
# Usa porta 22 (mais rápida, mas pode ser bloqueada)

Host github.com
    Hostname github.com
    Port 22
    User git

# Configuração alternativa para redes que bloqueiam porta 22
Host github-443
    Hostname ssh.github.com
    Port 443
    User git
EOF
    echo "✅ Configurado para usar porta 22"
}

# Função para testar conexão
test_connection() {
    echo "🧪 Testando conexão SSH..."
    if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        echo "✅ Conexão SSH funcionando!"
        return 0
    else
        echo "❌ Conexão SSH falhou"
        return 1
    fi
}

# Menu principal
echo "🔧 Switch GitHub SSH Port"
echo "=========================="
echo "1. Usar porta 443 (recomendado - funciona em qualquer rede)"
echo "2. Usar porta 22 (mais rápida - pode ser bloqueada)"
echo "3. Testar conexão atual"
echo "4. Sair"
echo ""

read -p "Escolha uma opção (1-4): " choice

case $choice in
    1)
        use_port_443
        test_connection
        ;;
    2)
        use_port_22
        test_connection
        ;;
    3)
        test_connection
        ;;
    4)
        echo "👋 Até logo!"
        exit 0
        ;;
    *)
        echo "❌ Opção inválida"
        exit 1
        ;;
esac
