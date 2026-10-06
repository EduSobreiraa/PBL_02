# Sprint 1 — Entrada, reset e armazenamento

## Objetivo

Implementar e revisar o caminho sequencial mínimo para reset e captura ordenada de `a`, `b` e `c`.

## Escopo planejado

- Sincronização em duas etapas das entradas KEY e evento único por pressão de KEY0, conforme DEC-019.
- Reset lógico síncrono ativo alto originado por KEY1.
- Armazenamento de três valores signed de 8 bits, com deslocamento em três capturas na ordem `a`, `b`, `c`.
- Revisão do comportamento de retenção e reset; validar a operação física mais tarde na Sprint 6.

## Dependências

- Sprint 0 concluída e documentação revisada.
- TASKs em READY com forma estrutural do DFF e contratos internos descritos, sem completar portas por inferência.

## Critérios de conclusão

- TASKs de sequenciador/sincronização e armazenamento aprovadas no compliance gate.
- Evidência de simulação cobre reset, três capturas, ordem e retenção, conforme TEST-001.
- Integração mantém as interfaces externas acordadas.

## Bloqueios e limites

- Não incluir FSM nem detector de carga incompleta/excedente (DEC-009).
- Qualquer dúvida de compatibilidade do DFF estrutural deve ser marcada BLOCKED e encaminhada conforme workflow; não alterar arquitetura localmente.
