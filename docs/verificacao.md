# Plano de verificação

Este plano define as verificações do projeto; resultados executados são registrados na tabela e nas TASKs correspondentes. IDs TEST mantêm rastreabilidade. Contratos e algoritmos estão fechados em DEC-030/031; evidências ainda precisam ser executadas nas TASKs.

## Testes por módulo

| Teste | Unidade sob teste | Escopo | Requisitos/decisões | Estado |
|---|---|---|---|---|
| TEST-001 | coefficient_input/core e loaded | Reset/captura a→b→c, retenção, captura excedente, equivalência wrapper/core, loaded até reset | DEC-024/029/030 | PASS 15 verificações Icarus14; auditoria independente APPROVED 11/10/2026. Evidência verification/results/task-002.md e .log; placa não validada |
| TEST-002 | full_adder/add23/core/sub18 | 8 combinações full_adder e 37212 vetores:24808 somas exatas,12401 deltas,3 casos core modular | DEC-028/030 | PASS Icarus14 sem warnings; auditoria APPROVED 11/10/2026; verification/results/task-003.md e .log |
| TEST-003 | Multiplicação | Exaustão 65536 pares s8×s8 e 4194560 pares s8×u15 restrito a0..16384 | REQ-005/007/008; DEC-030 | PASS Icarus14:65536 signed,4194560 mistos,256 quadrados,91 dirigidos; auditoria APPROVED; verification/results/task-007.md e .log |
| TEST-004 | sqrt_u17 | Todos 131072 radicandos; S²+E=N, 0<=E<2S+1; comparação independente | REQ-005/006/008; DEC-031 | PASS Icarus14, 131072 radicandos, zero divergências; auditoria APPROVED na TASK-008 |
| TEST-005 | divide_u9_u8 | Todos 131072 pares incluindo divisor zero; Q/r e flag | REQ-005/006/008; DEC-031 | PASS Icarus14, 131072 pares, incluindo 512 divisores zero; auditoria APPROVED na TASK-009 |
| TEST-006 | Caminho de `y` | Extremos signed de x/coefs, sinais mistos e cancelamento; confirmar faixa signed 23-bit, resultado sem truncamento e OV=0 para entradas válidas | REQ-003/007; DEC-012/028 | PASS Icarus14:12413 vetores, wrapper/core,carry e OV; relatório verification/results/task-004.md; auditoria independente APPROVED11/10/2026 |
| TEST-007 | Raízes | Referência independente por limiares exatos; exaustão software256³ TASK-005 e RTL dirigido; sinais, N0, r0, E0 e correções, a negativo, empates | REQ-005/006; DEC-007/031 | Modelo software APPROVED: 16.777.216 triplas, zero divergências; RTL PASS em 10030 vetores, auditoria APPROVED na TASK-011 |
| TEST-008 | Conversão/display | SW[9:8] seleciona x/y/x₁/x₂; decimal com sinal; verificar `------` quando o valor completo não couber | REQ-009; DEC-011/013/017/019 | PASS: seletor6048, display10032, BCD/add3 16 padrões; auditoria APPROVED na TASK-006 |
| TEST-009 | Flags | OV0; ERR carregado e persistente; Z por seleção/raiz inválida; C carry×loaded×seleção | REQ-005/007/010; DEC-029/030 | PASS isolado/integrado: OV/ERR3584+53, Z240, C16+64; auditorias APPROVED nas TASK-010/018/019 |

## Testes de integração e sistema

| Teste | Procedimento futuro | Requisitos/decisões |
|---|---|---|
| TEST-010 | Aplicar reset; carregar a, b, c em três gravações; conferir seleção `00=x`, `01=y`, `10=x₁`, `11=x₂` e atualização contínua sem EXECUTAR | REQ-001–004/009; DEC-008–011 — PASS na TASK-012/013:10 cenários,660 observações |
| TEST-011 | Exercitar ambas as operações em casos normais, extremos e domínio inválido; conferir valores e LEDs | REQ-003–010; DEC-001/007/012/013 — PASS na TASK-012/013: raízes válidas/inválidas, y extremo, flags e displays |
| TEST-012 | Exercitar estados elétricos, pressionamento/liberação e capturas de KEY; comprovar comportamento de SW[9:8] e SW[7:0] na placa | REQ-001/002/004; DEC-011; pendente de validação física; procedimento em verification/hardware-procedure.md |
| TEST-013 | Revisão estática do HDL: escopo estrutural, exceção `always` restrita a DFF, ausência de FSM/`buf`/loops e coerência de larguras | REQ-008/011/013; DEC-014 — APPROVED na TASK-017, relatório compliance.md |
| TEST-014 | Compilação/síntese Quartus, inspeção de erros/warnings, dispositivo, I/O e recursos | REQ-013/014/016 — APPROVED na TASK-015; Quartus25.1std.0,2187 LEs,31 FF,0 latches, timing relatado |
| TEST-015 | Validação física na DE10-Lite de controles, displays e LEDs | REQ-001–010/014; pendente; procedimento em verification/hardware-procedure.md |

## Estratégia e rastreabilidade

### Vetores dirigidos de TEST-006

Os valores esperados abaixo são calculados pela expressão matemática `a*x*x + b*x + c` usando inteiros sem limite de largura, independentemente de qualquer implementação RTL. Cada resultado deve ser comparado ao valor signed de 23 bits; todos cabem nessa faixa e portanto `OV=0`.

| a | b | c | x | y esperado | Caso |
|---:|---:|---:|---:|---:|---|
| 0 | 0 | 0 | 0 | 0 | zeros |
| 127 | -128 | -128 | 0 | -128 | limite de `c` |
| 1 | -16 | 64 | 8 | 0 | cancelamento exato |
| -3 | 5 | -7 | -2 | -29 | sinais mistos |
| -128 | 127 | -128 | -128 | -2,113,536 | limite mínimo matemático de `y` |
| 127 | -128 | 127 | -128 | 2,097,279 | limite máximo matemático de `y` |
| 0 | -128 | 127 | 127 | -16,129 | termo linear e sinais opostos |

O modelo de referência deve computar diretamente a expressão, sem reutilizar somadores, multiplicadores, larguras internas ou conversões do DUT. Os vetores detalham a cobertura aprovada em DEC-028; não promovem TASK-004 nem representam execução de teste.

**Clarificação local do TEST-001:** casos anteriores que esperavam deslocamento dos coeficientes nas capturas após a terceira contradizem a retenção ratificada em DEC-024. TEST-001 verifica agora que as capturas excedentes são ignoradas até reset. A decisão não foi alterada.

**Atualização DEC-030 do TEST-001 (11/10/2026):** wrapper/core com loaded implementado, testado e auditado. O PASS atual cobre loaded=0 durante progresso parcial, 1 após c e retorno0 no reset. A evidência anterior à extensão permanece no histórico de TASK002.

- EDA Playground mantém preferência visual (DEC-005); automação usa Icarus local/container ou Verilator compilado para exaustões custosas conforme DEC-030, com versão/digest real por execução. Separar testbench do HDL sintetizável.
- Derivar resultados esperados de cálculo independente e registrar vetores reprodutíveis; a exaustão de raízes de DEC-020 passa a validar o algoritmo exato DEC-031 em TASK-005. F16 foi substituído, não validado; evidências de software/RTL ainda são obrigatórias.
- Incluir `-128`, `-1`, `0`, `1`, `127` em entradas signed de 8 bits onde aplicável.
- Não há FSM: verificar armazenamento e controles sequenciais sem tratar isso como transição de máquina de estados.
- Registrar ferramentas/versões, dispositivo, comandos, warnings, resultados e evidência física quando a execução ocorrer.
- O sprint de decisões não executou testes. As Sprints2–4 produziram os resultados indicados por TASK e nesta tabela; futuras TASKs continuam sem PASS até execução.

| Requisito | Evidência planejada |
|---|---|
| REQ-001/002 | TEST-001, TEST-010, TEST-012 |
| REQ-003 | TEST-006, TEST-010/011/015 |
| REQ-004 | TEST-010/012/015 |
| REQ-005/006 | TEST-004/005/007/011 |
| REQ-007/008 | TEST-002/003/006/009/011/013 |
| REQ-009 | TEST-008/010/015 |
| REQ-010 | TEST-009/011/015 |
| REQ-011/013 | TEST-013/014 e revisão de arquitetura |
| REQ-012 | Revisão da especificação detalhada do circuito mínimo |
| REQ-014 | TEST-014/015 |
| REQ-015 | Registro dos TEST-001–015 executados e resultados |
| REQ-016 | Revisão do relatório, síntese, testes e análise |

## Atualização numérica e de cobertura — DEC-030/031

TEST-006 inclui produto cartesiano de {-128,-127,-1,0,1,126,127}, extremos/cancelamentos e 10000 vetores com seed registrada. Comparar y por inteiros independentes e carry pela soma unsigned dos padrões signed23 da última adição. TEST-008 inclui fronteiras 999999/1000000 e -99999/-100000, máscara de carga/erro, branco/sinal/segmentos. Exaustão software das raízes em TASK-005 não substitui TEST-004/005/007 do RTL. Síntese reporta clock registrado20ns e acomodação combinacional1ms separadamente. Estado de cada execução está na TASK e nos logs reais.

## Evidência numérica posterior — TASK-005, 11/10/2026

Modelo software DEC-031: exaustão de16.777.216 triplas,10.463.208 válidas,6.314.008 inválidas,20.926.416 comparações de raízes válidas,zero divergências. Contratos dos primitivos de software:131072 radicandos e131072 pares dividendo/divisor;30 vetores dirigidos. Auditor independente APPROVED; relatório em docs/evidence/roots-exhaustive.json. TEST-004/005/007 do RTL foram executados nas TASK-008/009/011; a exaustão de software continua uma evidência independente e não equivale a exaustão RTL da composição.
