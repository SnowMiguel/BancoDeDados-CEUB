# Projeto Avaliativo — Administração de Banco de Dados e Transações (PostgreSQL)

**Disciplina:** Banco de Dados II — CEUB (2026.2)  
**Professor:** Me. Michel Junio Ferreira Rosa  
**Diretório no Repositório:** `Projeto-Avaliativo-BD2-CEUB/`  
**Cenário:** Controle de inscrições em oficinas da *Semana de Tecnologia* (*Desafio prático: a última vaga*)

## Integrantes da Equipe

| Nome Completo | RA |
| :--- | :--- |
| Miguel Moreira Neves | 22611825 |
---

## Escopo da Entrega Parcial (16/11)

Esta entrega parcial contempla a preparação da base de laboratório e os experimentos iniciais de processamento de transações:
- **Base de Laboratório (`A1`):** criação do esquema isolado `lab_inscricoes`, tabelas (`estudantes`, `atividades`, `inscricoes`), restrições de integridade, índices e carga inicial fictícia.
- **Desafio `T1` — Confirmação e Cancelamento:** validação prática de `BEGIN`, `UPDATE`, `ROLLBACK` e `COMMIT` associada às propriedades de **atomicidade** e **durabilidade**.
- **Desafio `T2` — Disputa pela Última Vaga:** reprodução da condição de corrida entre duas sessões simultâneas (**Sessão A** e **Sessão B**) no nível de isolamento padrão (`READ COMMITTED`), registro da linha do tempo e diagnóstico inicial.

---

## Ambiente e Pré-requisitos

- **SGBD:** PostgreSQL 16 ou superior (testado em PostgreSQL 18).
- **Cliente SQL:** `psql`, pgAdmin 4.
- **Banco de Dados de Laboratório:** criar um banco exclusivo (ex.: `bd_semana_tec`) antes de executar os scripts.

---

## Como Reproduzir os Experimentos

### Passo 1 — Criar o banco de laboratório
No terminal (`psql` conectado ao banco `postgres`) ou via interface gráfica:

## Escopo da Entrega Parcial (23/11)
Esta entrega parcial contempla a criação de ROLES como administrador, operador e consulta e também restauração e criação de backup
- **Consolidação de `A1` a `A4`:**
  - **A1:** Esquema `lab_inscricoes`, tabelas (`estudantes`, `atividades`, `inscricoes`), integridade e consulta de ocupação.
  - **A2:** Perfis `administrador`, `operador` e `consulta` (`CREATE ROLE`, `GRANT`, `REVOKE`, `CONNECT`, `USAGE`) com comprovação via `SELECT current_user, session_user;`.
  - **A3:** Backup lógico customizado (`backup.dump` via `pg_dump -Fc`), simulação de perda acidental, restauração em banco secundário (`pg_restore --no-owner --no-acl`), comparação de registros e tratamento de roles globais (`pg_dumpall --globals-only`).
  - **A4:** Monitoramento de 1 e 2 sessões simultâneas via `pg_stat_activity`.

---

## Procedimentos que Dependem de Privilégios Administrativos (Superuser / CREATEDB / CREATEROLE)

Durante a execução dos desafios `A1` a `A4`, os seguintes comandos exigem conexão com usuário administrador do cluster PostgreSQL (ex.: `postgres`):
1. **Criação e remoção de bancos de dados (`A1` e `A3`):** `CREATE DATABASE bd_semana_tec;` e `createdb bd_semana_tec_restaurado` exigem privilégio `CREATEDB` ou `SUPERUSER`.
2. **Criação, alteração e limpeza de perfis globais (`A2`):** `CREATE ROLE`, `DROP OWNED BY`, `DROP ROLE` e `GRANT CONNECT ON DATABASE` operam no nível do cluster/banco e exigem `CREATEROLE` / `SUPERUSER`.
3. **Backup de objetos globais (`A3`):** `pg_dumpall --globals-only` exige leitura dos catálogos globais de roles e senhas (`pg_authid`), restrita a superusuários.
4. **Visibilidade irrestrita de sessões (`A4`):** consultar `pg_stat_activity` exibindo `query`, `wait_event_type` e `wait_event` de **outras** sessões conectadas ao servidor exige privilégio de superusuário ou pertencimento à role interna `pg_read_all_stats`.

---

## Adaptações Realizadas na Implementação

1. **Isolamento de esquema e privilégios padrão (`A1` / `A2`):** Todos os objetos foram isolados no esquema `lab_inscricoes` (evitando poluir o esquema `public`), e o privilégio padrão `CREATE` no esquema `public` foi revogado de `PUBLIC` para reforçar o princípio do menor privilégio.
2. **Concessão explícita em `SEQUENCES` para o perfil `operador` (`A2`):** Como a chave primária `inscricoes.id_inscricao` utiliza `SERIAL` (sequência `inscricoes_id_inscricao_seq`), conceder apenas `INSERT` na tabela geraria erro de permissão na sequência. Foi adicionado `GRANT USAGE, SELECT ON SEQUENCE lab_inscricoes.inscricoes_id_inscricao_seq TO operador;`.
3. **Índice único parcial para reinscrição após cancelamento (`A1`):** Em vez de uma restrição `UNIQUE (id_estudante, id_atividade)` simples (que impediria um aluno que cancelou de se inscrever novamente), criou-se o índice parcial `uq_inscricao_ativa_estudante_atividade ... WHERE situacao = 'ativa'`.
4. **Restauração desacoplada de proprietários (`A3`):** No `pg_restore`, foram utilizadas as flags `--no-owner --no-acl` para evitar falhas de dependência de roles caso o backup seja restaurado em outro servidor ou cluster limpo.

---

## Como Reproduzir os Experimentos (`A1` a `A4`)

### 1. Criar o banco e carregar estrutura/dados (`A1`)
```bash
createdb -U postgres bd_semana_tec
psql -U postgres -d bd_semana_tec -f sql/01_estrutura.sql
psql -U postgres -d bd_semana_tec -f sql/02_dados.sql
