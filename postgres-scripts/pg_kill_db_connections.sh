#!/usr/bin/env bash
set -euo pipefail

echo "PostgreSQL — bloquear e derrubar conexões (com opção de DROP)"
read -r -p "Host [127.0.0.1]: " HOST; HOST=${HOST:-127.0.0.1}
read -r -p "Porta [5432]: " PORT; PORT=${PORT:-5432}
read -r -p "Usuário [postgres]: " USERNAME; USERNAME=${USERNAME:-postgres}
read -r -p "Database alvo (o que será bloqueado/derrubado): " DBNAME
read -r -p "Database de manutenção para conectar [postgres]: " MAINTDB; MAINTDB=${MAINTDB:-postgres}

# senha (não ecoa)
read -r -s -p "Senha do usuário ${USERNAME} (ENTER se não tiver): " PGPASS; echo
export PGPASSWORD="${PGPASS:-}"

PSQL="psql -h ${HOST} -p ${PORT} -U ${USERNAME} -d ${MAINTDB} -v ON_ERROR_STOP=1 -q"

echo ">> Bloqueando novas conexões em \"${DBNAME}\"..."
$PSQL -c "REVOKE CONNECT ON DATABASE \"${DBNAME}\" FROM PUBLIC;"
$PSQL -c "UPDATE pg_database SET datallowconn = FALSE WHERE datname = '${DBNAME}';"

echo ">> Detectando coluna de PID em pg_stat_activity..."
PID_COL=$($PSQL -tAc "SELECT CASE
  WHEN EXISTS (
    SELECT 1 FROM pg_attribute
    WHERE attrelid='pg_catalog.pg_stat_activity'::regclass AND attname='pid'
  ) THEN 'pid' ELSE 'procpid' END;")
PID_COL=$(echo "$PID_COL" | xargs)

echo ">> Derrubando sessões ativas de \"${DBNAME}\" (coluna: ${PID_COL})..."
$PSQL -c "SELECT pg_terminate_backend(s.${PID_COL})
          FROM pg_stat_activity s
          WHERE s.datname='${DBNAME}' AND s.${PID_COL} <> pg_backend_pid();"

# opção de DROP
read -r -p "Deseja DROPPAR o banco \"${DBNAME}\" agora? [y/N]: " DO_DROP
if [[ "${DO_DROP:-N}" =~ ^[Yy]$ ]]; then
  echo ">> DROP DATABASE \"${DBNAME}\"..."
  $PSQL -c "DROP DATABASE IF EXISTS \"${DBNAME}\";"
  echo ">> Feito. Banco removido."
else
  echo ">> Mantendo o banco. Deseja reabilitar conexões agora? [y/N]: "
  read -r REENABLE
  if [[ "${REENABLE:-N}" =~ ^[Yy]$ ]]; then
    echo ">> Reabilitando conexões em \"${DBNAME}\"..."
    $PSQL -c "UPDATE pg_database SET datallowconn = TRUE WHERE datname = '${DBNAME}';"
    $PSQL -c "GRANT CONNECT ON DATABASE \"${DBNAME}\" TO PUBLIC;"
  else
    echo ">> Conexões continuam BLOQUEADAS em \"${DBNAME}\"."
  fi
fi

echo ">> Concluído."

