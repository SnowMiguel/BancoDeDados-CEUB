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
2. **Por que o isolamento `READ COMMITTED` permitiu a anomalia (*Write Skew*)?**  
   Sob o controle de concorrência multiversão (MVCC) no nível `READ COMMITTED`, cada consulta `SELECT` enxerga apenas os dados confirmados (`COMMIT`) antes do início daquela instrução, sem bloquear leituras nem escritas de outras transações em linhas diferentes. Como ambas as sessões leram o mesmo *snapshot* antes de qualquer `COMMIT` e tomaram decisões com base em uma contagem agregada (`COUNT(*)`), ocorreu uma **distorção de escrita (*write skew*)**.
3. **Encaminhamento para o Desafio T3:**  
   Para serializar o acesso à última vaga sem depender de bloqueios de tabela inteira, será necessário aplicar bloqueio explícito em nível de linha sobre a atividade disputada (`SELECT ... FOR UPDATE` em `lab_inscricoes.atividades WHERE id_atividade = 1`) antes de contabilizar as inscrições ativas e efetuar o `INSERT`.

---

## 3. Dúvidas e Pontos de Discussão com o Professor

1. **Encapsulamento da regra de concorrência:** No Desafio `T3`, a validação com `SELECT ... FOR UPDATE` deve ser demonstrada apenas via bloco transacional explícito no script `05_concorrencia.sql` (para evidenciar passo a passo o bloqueio entre Sessão A e Sessão B), ou também é recomendável encapsulá-la em uma `FUNCTION`/`PROCEDURE` no banco?
2. **Comparação entre estratégias de isolamento:** Na etapa final (`T4`), além da solução com `SELECT ... FOR UPDATE` em `READ COMMITTED`, vale incluir no relatório um teste comparativo mostrando o erro de serialização (`SQLSTATE 40001`) ao executar o mesmo cenário em nível `SERIALIZABLE` sem bloqueio explícito?
