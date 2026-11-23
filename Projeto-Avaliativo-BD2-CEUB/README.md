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

```
bash
createdb -U postgres bd_semana_tec
psql -U postgres -d bd_semana_tec -f sql/01_estrutura.sql
psql -U postgres -d bd_semana_tec -f sql/02_dados.sql
```



# Relatório Técnico — Entrega Parcial 2 (Desafios A1 a A4)

## 1. Descrição Resumida das Tabelas (Desafio A1)
O esquema isolado `lab_inscricoes` organiza três entidades principais:
- **`estudantes`**: armazena os participantes (`id_estudante` PK, `nome`, `email` UNIQUE, `curso`, `ativo` e `criado_em`).
- **`atividades`**: armazena as oficinas da Semana de Tecnologia (`id_atividade` PK, `titulo`, `instrutor`, `capacidade` com `CHECK (capacidade > 0)`, `local_sala` e `data_horario`).
- **`inscricoes`**: relaciona estudantes e atividades (`id_inscricao` PK, `id_estudante` FK, `id_atividade` FK, `situacao` restrita a `'ativa'` ou `'cancelada'`, `data_inscricao` e `data_cancelamento`). Possui índice único parcial `uq_inscricao_ativa_estudante_atividade` sobre `(id_estudante, id_atividade) WHERE situacao = 'ativa'`, impedindo duplicidade de vaga ativa sem bloquear reinscrições futuras após cancelamento.

## 2. Análise do Controle de Acesso (Desafio A2)
Foram criados três perfis distintos (`administrador`, `operador` e `consulta`) aplicando o princípio do menor privilégio. Os testes comprovaram via `SELECT current_user, session_user;` que:
- **`consulta`** realiza `SELECT` nas tabelas, mas recebe `permission denied` ao tentar `INSERT` ou `DELETE`.
- **`operador`** consulta estudantes/atividades e executa `INSERT`/`UPDATE` em `inscricoes` (apoiado pela permissão `USAGE, SELECT` na sequence `inscricoes_id_inscricao_seq`), mas é bloqueado em `DELETE` e comandos DDL (`ALTER TABLE`).
- **`administrador`** possui controle completo sobre o esquema `lab_inscricoes` e seus objetos, podendo criar e remover tabelas dentro desse escopo.

## 3. Backup, Restauração e Tratamento de Roles Globais (Desafio A3)
- **Resultado da restauração:** Após gerar `backup.dump` (`pg_dump -Fc`) e executar `DELETE FROM lab_inscricoes.inscricoes;` no banco principal (reduzindo as inscrições de 5 para 0), a restauração em `bd_semana_tec_restaurado` via `pg_restore --no-owner --no-acl` recuperou integralmente os 10 estudantes, 3 atividades e 5 inscrições originais.
- **Por que `pg_restore` de um banco individual não restaura roles automaticamente?**  
  No PostgreSQL, usuários e perfis (`ROLE`) são **objetos globais no nível do cluster** (armazenados nos catálogos compartilhados `pg_authid` / `pg_roles`), e não objetos internos de um banco de dados específico. Como o `pg_dump` captura apenas o conteúdo lógico de um único banco, as definições de `administrador`, `operador` e `consulta` não integram o `backup.dump`.

## 4. Interpretação das Sessões em `pg_stat_activity` (Desafio A4)
- **Com 1 sessão:** a consulta retorna apenas a conexão corrente com `state = 'active'` (executando a própria query de monitoramento).
- **Com 2 sessões simultâneas:** identifica-se cada conexão por seu identificador de processo (`pid`) e usuário (`usename`). Quando a segunda sessão abre uma transação (`BEGIN`) e aguarda novos comandos do cliente sem concluir, seu estado aparece como `idle in transaction` com `wait_event_type = 'Client'` e `wait_event = 'ClientRead'` — estado crítico que, caso envolva bloqueios de linha, pode reter recursos aguardados por outras transações.
