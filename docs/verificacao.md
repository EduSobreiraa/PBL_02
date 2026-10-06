# Plano de verificação

Este plano define verificações futuras; não contém testbenches nem resultados. IDs TEST são identificadores planejados. A precisão intermediária, semântica das flags e apresentação ainda dependem das pendências indicadas.

## Testes por módulo

| Teste | Unidade sob teste | Escopo | Requisitos/decisões | Estado |
|---|---|---|---|---|
| TEST-001 | Armazenamento de coeficientes | Reset; três gravações KEY0 com SW[7:0] em ordem a→b→c; retenção; recarga após reset; ausência de captura de resultado | REQ-001/002; DEC-008/009/014 | Planejado; condicionamento físico de KEY pendente |
| TEST-002 | Soma/subtração | Sinais, carry e overflow conforme semântica aprovada | REQ-007/008/010; PEN-004 | Planejado; semântica de C pendente |
| TEST-003 | Multiplicação | Operandos assinados e casos de fronteira para produtos usados nos caminhos | REQ-005/007/008 | Planejado; larguras conforme DEC-013 |
| TEST-004 | Raiz quadrada | Radicandos zero, quadrados perfeitos e não perfeitos; arredondar em reduções de precisão conforme DEC-016 e resultado final conforme DEC-007 | REQ-005/006; DEC-007/013/016 | Planejado; evidência numérica PEN-019 |
| TEST-005 | Divisão | Sinais, resto/quociente, divisor zero e limites de faixa | REQ-005/006 | Planejado; formato e vetores de referência pendentes |
| TEST-006 | Caminho de `y` | Extremos signed de x/coefs, sinais mistos e cancelamento; confirmar faixa signed 23-bit e OV aritmético sempre 0 para entradas válidas | REQ-003/007; DEC-012 | Planejado; vetores concretos PEN-019 |
| TEST-007 | Caminho das raízes | a=0, Δ<0, Δ=0, Δ>0; raízes positivas/negativas e arredondamento final/intermediário; ERR até reset | REQ-005/006; DEC-001/007/016 | Planejado; validação de F=16 em PEN-019 |
| TEST-008 | Conversão/display | SW[9:8] seleciona x/y/x₁/x₂; decimal com sinal; verificar `------` quando o valor completo não couber | REQ-009; DEC-011/013/017/019 | Planejado; correspondência física já documentada, validar integração |
| TEST-009 | Flags | OV, Z e ERR em casos controlados; C aguarda definição da origem | REQ-005/007/010; DEC-001/012/015 | Planejado; origem de C bloqueada em PEN-004 |

## Testes de integração e sistema

| Teste | Procedimento futuro | Requisitos/decisões |
|---|---|---|
| TEST-010 | Aplicar reset; carregar a, b, c em três gravações; conferir seleção `00=x`, `01=y`, `10=x₁`, `11=x₂` e atualização contínua sem EXECUTAR | REQ-001–004/009; DEC-008–011 |
| TEST-011 | Exercitar ambas as operações em casos normais, extremos e domínio inválido; conferir valores e LEDs | REQ-003–010; DEC-001/007/012/013 |
| TEST-012 | Exercitar estados elétricos, pressionamento/liberação e capturas de KEY; comprovar comportamento de SW[9:8] e SW[7:0] na placa | REQ-001/002/004; DEC-011; PEN-015 |
| TEST-013 | Revisão estática do HDL: escopo estrutural, exceção `always` restrita a DFF, ausência de FSM/`buf`/loops e coerência de larguras | REQ-008/011/013; DEC-014 |
| TEST-014 | Compilação/síntese Quartus, inspeção de erros/warnings, dispositivo, I/O e recursos | REQ-013/014/016 |
| TEST-015 | Validação física na DE10-Lite de controles, displays e LEDs | REQ-001–010/014; PEN-014/015 |

## Estratégia e rastreabilidade

- EDA Playground é o ambiente preferido para simulação (DEC-005); backend/versão não registrados. Separar testbench do HDL sintetizável.
- Derivar resultados esperados de cálculo independente e registrar vetores reprodutíveis; o plano de exaustão de raízes e vetores dirigidos foi aprovado em DEC-020. A precisão candidata F=16 precisa evidência antes de ser tratada como validada (PEN-019).
- Incluir `-128`, `-1`, `0`, `1`, `127` em entradas signed de 8 bits onde aplicável.
- Não há FSM: verificar armazenamento e controles sequenciais sem tratar isso como transição de máquina de estados.
- Registrar ferramentas/versões, dispositivo, comandos, warnings, resultados e evidência física quando a execução ocorrer.
- Nenhum teste foi executado nesta atualização documental.

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
