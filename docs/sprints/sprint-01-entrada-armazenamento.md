# Sprint 1 — Entrada, reset e armazenamento

## Estado atual

**Concluída para o escopo original; acompanhamento DEC-029/030 READY.** Após DEC-025, o DUT e testbench foram atualizados sem `if`/`else`; a baseline TEST-001 passou no container Icarus e os três gates da auditoria independente foram aprovados. DEC-027 confirmou a separação entre proibição arquitetural de FSM e forma estrutural de descrever contadores, preservando DEC-024. A interpretação acadêmica dessa distinção ainda deve ser validada. DEC-029 reabriu TASK-002 para disponibilizar `loaded` derivado do contador existente; a RTL não foi atualizada, e TEST-001/auditoria devem ser repetidos antes de retornar TASK-002 a APPROVED. Pinos físicos permanecem inalterados; validação física continua prevista para Sprint 6.

## Objetivo

Implementar e revisar o caminho sequencial mínimo para reset e captura ordenada de `a`, `b` e `c`.

## Escopo planejado

- Sincronização em duas etapas das entradas KEY e evento único por pressão de KEY0, conforme DEC-019.
- Reset lógico síncrono ativo alto originado por KEY1.
- Armazenamento de três valores signed de 8 bits na ordem `a`, `b`, `c`, usando o contador linear de progresso e enables autorizados por DEC-024; depois da terceira captura, ignorar novas pressões até reset.
- Revisão do comportamento de retenção e reset; validar a operação física mais tarde na Sprint 6.

## Dependências

- Sprint 0 concluída e documentação revisada.
- TASKs em READY com forma estrutural do DFF e contratos internos descritos, sem completar portas por inferência.

## Critérios de conclusão

- TASKs de sequenciador/sincronização e armazenamento aprovadas no compliance gate.
- Evidência de simulação cobre reset, três capturas, ordem e retenção, conforme TEST-001.
- Integração mantém as interfaces externas acordadas.

## Bloqueios e limites

- Não incluir FSM nem debounce. O contador linear e seus enables são uma exceção restrita à TASK-002, autorizada por DEC-024; não generalizar para outros controles.
- O contador linear e os enables são estruturais, compostos por FFs e lógica combinacional; o contador não contém `always` comportamental. Validar academicamente com o tutor/responsável a compatibilidade dessa distinção com a proibição de FSM do enunciado, conforme DEC-027.
- O bloqueio de capturas após a terceira gravação é exigido por DEC-024. Não acrescentar indicação externa de completude.
- Qualquer dúvida de compatibilidade do DFF estrutural deve ser marcada BLOCKED e encaminhada conforme workflow; não alterar arquitetura localmente.

Em 11/10/2026, DEC-030 fechou a rota com coefficient_input_core privado e wrapper preservado; TASK002 recebeu brief e READY. A extensão será executada junto à Sprint2, sem alegar novo PASS antes dos testes.

## Encerramento da extensão — 11/10/2026

TASK002 APPROVED: wrapper/core e loaded implementados com31FF; TEST001 PASS15 e três gates independentes aprovados. Registro em verification/results/task-002.md. Referências anteriores a extensão planejada são histórico; validação física segue futura.
