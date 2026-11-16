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

## Escopo desta Entrega Parcial (16/11)

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
```sql
CREATE DATABASE bd_semana_tec;
