# pg_kill_db_connections.sh

Script para **bloquear novas conexões**, **derrubar sessões ativas** de um banco PostgreSQL específico e, opcionalmente, **dropar** esse banco — executado via macOS/Linux com `psql`.

> Compatível com PostgreSQL **9.2+** (detecta automaticamente se a coluna de processos em `pg_stat_activity` é `pid` ou `procpid`).

---

## Sumário

- [O que faz](#o-que-faz)
- [Requisitos](#requisitos)
- [Instalação](#instalação)
- [Uso (interativo)](#uso-interativo)
- [Exemplo de sessão](#exemplo-de-sessão)
- [Como funciona (detalhes)](#como-funciona-detalhes)
- [Boas práticas](#boas-práticas)
- [Backup (opcional)](#backup-opcional)
- [Solução de problemas](#solução-de-problemas)
- [Segurança](#segurança)
- [Compatibilidade](#compatibilidade)
- [Próximos passos](#próximos-passos)

---

## O que faz

1. Conecta a um **banco de manutenção** (p. ex., `postgres`) — nunca ao banco alvo.
2. **Revoga CONNECT** no banco alvo (impede novas conexões).
3. **Desativa `datallowconn`** no banco alvo (reforça o bloqueio).
4. **Termina** (`pg_terminate_backend`) **todas as sessões ativas** do banco alvo.
5. (Opcional) **DROP DATABASE** do banco alvo.
6. Se não fizer o DROP, oferece **reabilitar** conexões ao final.

---

## Requisitos

- Cliente `psql` instalado:
  ```bash
  # macOS (Homebrew)
  brew install postgresql@16
  ```
- Usuário com privilégios adequados (idealmente **superuser** `postgres`) para:
  - `REVOKE/GRANT CONNECT`
  - `UPDATE pg_database`
  - `SELECT pg_stat_activity`
  - `SELECT pg_terminate_backend(...)`
  - `DROP DATABASE` (se optar)

---

## Instalação

1. Salve o script como **`pg_kill_db_connections.sh`**.
2. Conceda permissão de execução:
   ```bash
   chmod +x pg_kill_db_connections.sh
   ```

---

## Uso (interativo)

```bash
./pg_kill_db_connections.sh
```

O script solicitará:
- **Host** (padrão `127.0.0.1`)
- **Porta** (padrão `5432`)
- **Usuário** (padrão `postgres`)
- **Database alvo** (DB a ser bloqueado/derrubado)
- **Database de manutenção** (padrão `postgres`)
- **Senha** (sem eco)
- Se deseja fazer **DROP** do DB alvo
- Caso não faça DROP: opção para **reabilitar** conexões

---

## Exemplo de sessão

```
PostgreSQL — bloquear e derrubar conexões (com opção de DROP)
Host [127.0.0.1]:
Porta [5432]:
Usuário [postgres]:
Database alvo (o que será bloqueado/derrubado): sagep_core_db
Database de manutenção para conectar [postgres]:
Senha do usuário postgres (ENTER se não tiver):
>> Bloqueando novas conexões em "sagep_core_db"...
>> Detectando coluna de PID em pg_stat_activity...
>> Derrubando sessões ativas de "sagep_core_db" (coluna: pid)...
Deseja DROPPAR o banco "sagep_core_db" agora? [y/N]: y
>> DROP DATABASE "sagep_core_db"...
>> Feito. Banco removido.
>> Concluído.
```

---

## Como funciona (detalhes)

- **Bloquear novas conexões**
  ```sql
  REVOKE CONNECT ON DATABASE "<DB_ALVO>" FROM PUBLIC;
  UPDATE pg_database SET datallowconn = FALSE WHERE datname = '<DB_ALVO>';
  ```
- **Detectar coluna de PID (compatibilidade 9.2+)**
  ```sql
  SELECT CASE
    WHEN EXISTS (
      SELECT 1 FROM pg_attribute
      WHERE attrelid='pg_catalog.pg_stat_activity'::regclass AND attname='pid'
    ) THEN 'pid' ELSE 'procpid' END;
  ```
- **Encerrar sessões**
  ```sql
  SELECT pg_terminate_backend(<PID_COL>)
  FROM pg_stat_activity
  WHERE datname='<DB_ALVO>' AND <PID_COL> <> pg_backend_pid();
  ```
- **Dropar o banco (opcional)**
  ```sql
  DROP DATABASE IF EXISTS "<DB_ALVO>";
  ```

---

## Boas práticas

- **Pare a aplicação** que usa o DB antes de rodar o script (evita reconexões imediatas).
- **Nunca** conecte ao **banco alvo** durante a operação; use um **banco de manutenção** (ex.: `postgres`).
- Se for ambiente crítico, execute primeiro em **homologação**.

---

## Backup (opcional)

Antes de dropar, gere um dump:
```bash
pg_dump -h <HOST> -p <PORTA> -U <USUARIO> -d <DB_ALVO> -Fc -f </caminho/backup.dump>
```

Para restaurar:
```bash
createdb -h <HOST> -p <PORTA> -U <USUARIO> <DB_NOVO>
pg_restore -h <HOST> -p <PORTA> -U <USUARIO> -d <DB_NOVO> </caminho/backup.dump>
```

---

## Solução de problemas

- **Permissão negada** em `UPDATE pg_database`/`DROP DATABASE`  
  → Use um usuário **superuser** (ex.: `postgres`).  
- **Reconexões constantes** mesmo após revogar CONNECT  
  → **Interrompa a app/serviço** (PM2/Docker/K8s) e rode novamente.  
- **`psql: command not found`**  
  → Instale via Homebrew: `brew install postgresql@16`.  
- **Coluna `pid` inexistente**  
  → O script detecta e usa `procpid` em versões antigas (9.2/9.3).

---

## Segurança

- A senha é lida sem eco e exportada para `PGPASSWORD` **apenas** durante a execução.
- O script **não imprime** a senha e evita expô-la no histórico.

---

## Compatibilidade

- **macOS / Linux** (bash/zsh)  
- **PostgreSQL 9.2+** (lida com `pid`/`procpid`)  
- Requer **`psql`** disponível no PATH

---

## Próximos passos

- Versão **não interativa** (flags) para CI/CD, ex.:
  ```bash
  ./pg_kill_db_connections.sh     --host 127.0.0.1 --port 5432 --user postgres     --db-alvo sagep_core_db --maint-db postgres     --password '***' --drop
  ```
  > Se quiser, posso fornecer essa variante (`getopts`) e adicionar a seção “Modo não interativo” aqui.
