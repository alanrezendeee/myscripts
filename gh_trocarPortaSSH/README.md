# 🔧 Solução para Problemas de SSH com GitHub

## 📋 Problema
Erro de timeout na conexão SSH com GitHub:
```
ssh: connect to host github.com port 22: Operation timed out
fatal: Could not read from remote repository.
```

## 🎯 Solução: Usar Porta 443 (HTTPS)

### Por que a porta 22 falha?
- **Firewalls corporativos** bloqueiam a porta 22
- **ISPs** podem restringir acesso
- **Redes públicas** (café, hotel, universidade) bloqueiam

### Por que a porta 443 funciona?
- ✅ **Raramente bloqueada** - usa o mesmo tráfego HTTPS
- ✅ **Atravessa firewalls** - passa por proxies HTTPS
- ✅ **Funciona em qualquer rede** - compatibilidade máxima
- ✅ **Mais segura** - em redes públicas

## 🔧 Configuração SSH

### 1. Configuração Automática (Recomendada)
```bash
# Criar/editar ~/.ssh/config
cat > ~/.ssh/config << 'EOF'
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
```

### 2. Adicionar Chave SSH ao Agente
```bash
# Adicionar sua chave SSH
ssh-add ~/.ssh/id_ed25519_gh

# Testar conexão
ssh -T git@github.com
```

## 🚀 Script de Alternância de Portas

### Script Completo
```bash
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
```

### Como usar o script
```bash
# Salvar como ~/switch-github-port.sh
chmod +x ~/switch-github-port.sh

# Executar
~/switch-github-port.sh

# Ou criar alias no ~/.zshrc
echo 'alias github-port="~/switch-github-port.sh"' >> ~/.zshrc
```

## 📊 Comparação das Portas

| Aspecto | Porta 22 | Porta 443 |
|---------|----------|-----------|
| **Velocidade** | ⚡ Mais rápida | 🐌 Ligeiramente mais lenta |
| **Compatibilidade** | ❌ Frequentemente bloqueada | ✅ Funciona em qualquer rede |
| **Segurança** | ⚠️ Pode ser interceptada | 🔒 Mais segura |
| **Firewall** | ❌ Bloqueada por firewalls | ✅ Atravessa firewalls |
| **Rede Pública** | ❌ Pode falhar | ✅ Sempre funciona |

## 🌐 Cenários de Uso

| Tipo de Rede | Porta Recomendada | Motivo |
|--------------|-------------------|--------|
| **Casa** | 443 ou 22 | 22 pode ser mais rápida |
| **Trabalho** | 443 | Firewalls corporativos |
| **Café/Hotel** | 443 | Redes públicas restritivas |
| **Universidade** | 443 | Firewalls institucionais |
| **Aeroporto** | 443 | Redes muito restritivas |

## ⚡ Comandos Úteis

### Testes e Diagnósticos
```bash
# Testar conexão SSH
ssh -T git@github.com

# Ver configuração atual
cat ~/.ssh/config

# Verificar chaves SSH
ls -la ~/.ssh/

# Adicionar chave ao agente
ssh-add ~/.ssh/id_ed25519_gh
```

### Git Operations
```bash
# Push (funciona automaticamente)
git push

# Pull
git pull

# Clone
git clone git@github.com:usuario/repositorio.git
```

### Alternância Manual
```bash
# Usar porta 22 manualmente (se configurada)
ssh -T git@github-22

# Usar porta 443 manualmente
ssh -T git@github-443
```

## 🔍 Troubleshooting

### Problema: "Permission denied (publickey)"
```bash
# Verificar se a chave está no agente
ssh-add -l

# Adicionar chave novamente
ssh-add ~/.ssh/id_ed25519_gh

# Verificar se a chave está no GitHub
cat ~/.ssh/id_ed25519_gh.pub
```

### Problema: "Connection timed out"
```bash
# Testar conectividade
ping github.com

# Testar porta 443 especificamente
nc -zv ssh.github.com 443

# Usar script para alternar portas
~/switch-github-port.sh
```

### Problema: "Host key verification failed"
```bash
# Limpar hosts conhecidos (cuidado!)
rm ~/.ssh/known_hosts

# Ou adicionar manualmente
ssh-keyscan -H github.com >> ~/.ssh/known_hosts
```

## 📝 Arquivos Importantes

| Arquivo | Propósito | Pode Excluir? |
|---------|-----------|---------------|
| `~/.ssh/config` | **Configuração SSH principal** | ❌ **NUNCA** |
| `~/.ssh/id_ed25519_gh` | **Chave SSH privada** | ❌ **NUNCA** |
| `~/.ssh/id_ed25519_gh.pub` | **Chave SSH pública** | ❌ **NUNCA** |
| `~/.ssh/known_hosts` | **Hosts conhecidos** | ❌ **NUNCA** |
| `~/.ssh/config.backup` | Backup da configuração | ✅ **Sim** |
| `~/.ssh/known_hosts.old` | Backup de hosts | ✅ **Sim** |

## 🎉 Resultado Final

Após a configuração:
- ✅ **Push/Pull funcionando** em qualquer rede
- ✅ **Conexão SSH estável** com GitHub
- ✅ **Script para alternar** portas quando necessário
- ✅ **Configuração permanente** e automática

## 🚀 Próximos Passos

1. **Teste a conexão**: `ssh -T git@github.com`
2. **Faça um push**: `git push`
3. **Configure o script**: Salve e torne executável
4. **Crie o alias**: Para facilitar o uso
5. **Teste em diferentes redes**: Casa, trabalho, café

---

**💡 Dica**: A porta 443 é a escolha mais segura e confiável. Use-a como padrão e alterne para 22 apenas em redes confiáveis onde você sabe que funciona.
