# Sprint 1 — Entrada, reset e armazenamento

## Estado atual

**Concluída.** Após DEC-025, o DUT e testbench foram atualizados sem `if`/`else`; TEST-001 passou novamente no container Icarus e os três gates da auditoria independente foram aprovados. A interface externa e a pinagem permanecem inalteradas; validação física continua prevista para Sprint 6.

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
- O bloqueio de capturas após a terceira gravação é exigido por DEC-024. Não acrescentar indicação externa de completude.
- Qualquer dúvida de compatibilidade do DFF estrutural deve ser marcada BLOCKED e encaminhada conforme workflow; não alterar arquitetura localmente.
