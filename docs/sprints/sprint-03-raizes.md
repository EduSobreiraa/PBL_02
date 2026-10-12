# Sprint 3 — Discriminante e raízes

## Objetivo

Implementar a arquitetura exata de DEC-031: sqrt inteira com resíduo, divisão inteira com resto e intermediário signed10/F=1 acompanhado de descritores até o arredondamento final DEC-007. F16 deixou de ser candidato; PEN-019 está encerrada como escolha técnica.

## Status

CONCLUÍDA — TASK-005, TASK-008, TASK-009 e TASK-011 estão APPROVED, com execução real e auditoria independente.

## Escopo e sequência

| TASK | Estado de entrada | Entrega |
| --- | --- | --- |
| TASK-005 | APPROVED | Referência independente e exaustão 256³ das raízes, com evidência real. |
| TASK-008 | APPROVED | sqrt_u17: todos os 131.072 radicandos aprovados e auditados. |
| TASK-009 | APPROVED | divide_u9_u8: todos os 131.072 pares aprovados e auditados. |
| TASK-011 | APPROVED | quadratic_roots: 10.030 vetores RTL passaram e a auditoria confirmou os três gates. |

TASK-005/008/009 podem avançar em paralelo; TASK-011 usa uma sqrt e duas divisões simultâneas. Nenhum desses módulos precisa de flip-flops/FSM. A sequência se refere às dependências de implementação, não a estados de hardware.

## Dependências

- DEC-030/031 em CONSENSUS e briefs registrados nas TASKs.
- TASK-003/007 aprovadas para composição do discriminante; TASK-008/009 aprovadas para composição de raízes.
- TASK-005 executada/auditada como condição de aprovação funcional da cadeia; não é nova decisão sobre F.
- Integração posterior qualifica loaded/domain_error e preserva ERR até reset; domain_error desta sprint é combinacional.

## Critérios de conclusão

- TASK-005/008/009/011 APPROVED com evidências reais e auditoria independente.
- TEST-004 cobre todo unsigned17; TEST-005 cobre todos os pares unsigned9×unsigned8; TEST-007 compara RTL com vetores independentes, domínio inválido, extremos, sinais e meios inteiros.
- TASK-005 registra exaustão dos 16.777.216 triplos contra referência matemática independente, com zero divergências. Esse resultado não é apresentado como simulação RTL.
- Nenhum resíduo descartado antes do arredondamento; x1 sempre ramo +, x2 ramo −, inclusive a<0; saídas zero no domínio inválido.
- Compliance Gate aprovado: estrutura, larguras, extensões, ausência de estado, FSM e construções proibidas.

## Limites e evidências pendentes

Não há decisão técnica aberta nesta sprint. Síntese, timing e placa permanecem por fazer. A simulação RTL da TASK-011 é amostral; a exaustão de 16.777.216 triplas pertence ao modelo independente da TASK-005. Não declarar síntese, timing ou placa aprovados com base nessas evidências.

## Histórico

- 2026-10-11 — Replanejada após DEC-031: substituído bloqueio F16 por contratos exatos e dependências de execução; unidades autossuficientes liberadas READY.

## Adiantamento independente — 11/10/2026

TASK-005 APPROVED: exaustão software256³ e referência independente com zero divergências, auditoria concluída. Os requisitos de evidência do modelo estão atendidos; unidades RTL008/009 e composição011 foram posteriormente implementadas, testadas e auditadas.

## Encerramento — 11/10/2026

- TASK-008 APPROVED: TEST-004 cobriu os 131.072 radicandos, sem divergência.
- TASK-009 APPROVED: TEST-005 cobriu os 131.072 pares, incluindo 512 divisores nulos, sem divergência.
- TASK-011 APPROVED: TEST-007 passou 10.030 vetores, 6.255 válidos e 3.775 inválidos; o auditor conferiu estruturas, sinais, resíduos, arredondamento, log e hashes.

Comandos, versões, hashes e pareceres estão nas TASKs. A Sprint 4 pode iniciar pelos módulos independentes de seleção, apresentação e flags.
