# Diagnóstico Inicial e Pontos para Discussão — Entrega Parcial 1 (T1 e T2)

## 1. Resultados Observados

### Desafio T1 (COMMIT e ROLLBACK)
- **Atomicidade (`ROLLBACK`):** Ao alterar `local_sala` da atividade `3` dentro de `BEGIN`, a própria sessão passou a enxergar o novo valor, mas após `ROLLBACK` o registro retornou integralmente ao estado original (`Lab 03 - Bloco C`), comprovando a execução "tudo ou nada".
- **Durabilidade (`COMMIT`):** Ao repetir o `UPDATE` e encerrar com `COMMIT`, a alteração tornou-se definitiva e visível para outras conexões, sendo persistida pelo SGBD via *Write-Ahead Log* (WAL).

### Desafio T2 (Disputa pela Última Vaga em `READ COMMITTED`)
- **Sequência executada:**
  1. **Sessão A** abriu transação (`BEGIN`) e consultou `atividades` + `inscricoes` para `id_atividade = 1`, obtendo `capacidade = 1` e `inscricoes_ativas = 0`.
  2. **Sessão B** (antes do `COMMIT` de A) abriu transação (`BEGIN`) e executou a mesma consulta, obtendo igualmente `capacidade = 1` e `inscricoes_ativas = 0`.
  3. **Sessão A** executou `INSERT` para `id_estudante = 1`; **Sessão B** executou `INSERT` para `id_estudante = 2`. Nenhuma das sessões foi bloqueada.
  4. **Sessão A** executou `COMMIT` e, em seguida, **Sessão B** executou `COMMIT`.
- **Estado final observado:** A oficina `1` ficou com **2 inscrições ativas** (`Ana Clara Souza` e `Bruno Henrique Lima`) para uma capacidade máxima de **1 vaga** (`vagas_disponiveis = -1`), violando a regra de negócio.

---

## 2. Diagnóstico Técnico Inicial

1. **Por que o índice único e as constraints não impediram o erro?**  
   As restrições declarativas da tabela `inscricoes` (`CHECK`, `FK` e o índice único parcial `uq_inscricao_ativa_estudante_atividade`) validam apenas a integridade de **cada linha isoladamente** (impedindo o *mesmo* aluno de se inscrever duas vezes). Como as transações inseriram estudantes distintos (`1` e `2`), nenhuma restrição de unicidade foi violada.

---

## 3. Dúvidas e Pontos de Discussão com o Professor

