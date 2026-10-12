# Sprint 2 — Aritmética e caminho de y

## Estado

**CONCLUÍDA — 11/10/2026.** TASK-002 (extensão loaded), TASK-003, TASK-007 e TASK-004 APPROVED após testes reais e auditoria independente. Interfaces públicas preservadas;31 FF na entrada, zero FF nos blocos aritméticos.

## Objetivo

Entregar loaded estrutural e caminho exato y=((a·x²)+(b·x))+c, com unidades combinacionais reutilizáveis e carry privado sem modificar interfaces públicas.

## Sequência de execução

1. Implementation Orchestrator usa briefs vigentes e encaminha TASK-002 e TASK-003 ao Code Implementer. São arquivos independentes; testes/auditoria separados.
2. TASK-003 entrega arithmetic_cells/full_adder; implementar TASK-007 respeitando ownership do arquivo compartilhado. Modelo/vetores de multiplicação podem ser preparados antes, pois contrato já foi fechado.
3. Executar TEST-001/002/003 e auditoria independente; correções concretas retornam ao implementer. APPROVED somente com evidências reais e zero HIGH/CRITICAL.
4. Quando 003/007 estiverem APPROVED, promover 004 a READY sem nova decisão/ratificação; implementar polynomial_y/core e executar TEST-006.
5. Auditar conformidade e integração privada dos blocos. Qualificação/exibição de C e top-level ficam nas TASKs posteriores; nesta sprint a origem carry_y é produzida/testada.

## Contratos fechados

- TASK-002 mantém wrapper coefficient_input original; core privado publica loaded decodificando11, com 31 FF totais e mesma sequência/reset.
- TASK-003 usa ripple-carry fixo: add23/core e sub18, exatos nos domínios consumidores. Sem promessa impossível para qualquer par signed23 arbitrário.
- TASK-007 usa produtos parciais e somas espaciais: s8×s8→s16 e s8×u15→s22 com rhs0..16384. Sem temporalização.
- TASK-004 usa duas somas 23 na associação aprovada, produtos completos e extensões explícitas; y signed23 e OV0. carry_y é só carry da última soma, por porta privada do core. Wrapper público permanece a,b,c,x→y,OV.

## Dependências e limites

TASK-001 APPROVED e DEC-030 CONSENSUS atendem baseline/decisão. Não há gate de consulta humana nem topologia a decidir posteriormente. Os quatro blocos são independentes do cálculo das raízes/DEC-031. Testes de placa, síntese final e flags de apresentação são posteriores; não afirmar aprovação acadêmica do contador ou mínimo global de LEs.

## Critérios de conclusão

- TASK-002 extensão e TASK-003/007/004 APPROVED, com seus testes e auditorias registrados.
- TEST-003 exaustivo no domínio especificado; TEST-006 com referência independente, extremos, sinais e cancelamentos.
- Interfaces públicas preservadas; rotas privadas sem referência hierárquica ou duplicação;31FF na entrada e zero na aritmética.
- Fontes DUT sem construções proibidas, nenhum HIGH/CRITICAL aberto, comandos/versões/contagens/logs reprodutíveis.

## Histórico

- 2026-10-09 — Sprint planejada após DEC-028, ainda dependia de escolhas técnicas.
- 2026-10-11 — Sprint único de decisões concluiu DEC-030; planejamento anterior supersedido por briefs concretos. Sprint2 preparada para execução, incluindo extensão pequena de TASK-002. Nenhum RTL/teste foi produzido nesta atualização documental.

## Início de execução — 11/10/2026

Sprint de decisões encerrada e auditada. TASK002 e TASK003 encaminhadas ao Code Implementer; seguir testes e Code Auditor antes de APPROVED. TASK007 executa após as células003, e004 após003/007 aprovadas.

## Encerramento — 11/10/2026

| TASK | Evidência executada | Auditoria |
|---|---|---|
| 002 | TEST-001 PASS15 verificações de captura/reset/loaded | APPROVED |
| 003 | TEST-002 PASS8 combinações full_adder e37212 vetores | APPROVED |
| 007 | TEST-003 PASS65536 pares signed,4194560 mistos,256 quadrados,91 dirigidos | APPROVED |
| 004 | TEST-006 PASS12413 vetores; y,wrapper/core,carry e OV | APPROVED |

Execuções Icarus14, código0, sem warnings de compilação; fontes, comandos, versões e hashes em verification/results/task-002/003/007/004.md e respectivos logs. Nenhum finding aberto. A composição y não foi testada exaustivamente nas2³² entradas; a cobertura dirigida/cartesiana/aleatória prevista foi cumprida e as unidades multiplicadoras foram testadas exaustivamente em seus domínios.

A próxima entrega é Sprint3: RTL de sqrt/divisão e raízes. TASK005 foi antecipada e APPROVED: modelo software exaustivo,16.777.216 triplas sem divergências; não substitui simulação do futuro RTL. Síntese, temporização e placa permanecem nas sprints previstas.
