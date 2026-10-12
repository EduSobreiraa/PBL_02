# Relatório do PBL02 — conteúdo para aplicar ao modelo oficial

> Rascunho de conteúdo. Aplicar ao modelo e às instruções oficiais do tutor antes da entrega. Validação física ainda pendente.

## Introdução

Este projeto implementa, em uma FPGA MAX 10 da placa DE10-Lite, a avaliação de um polinômio quadrático e o cálculo de suas raízes. O trabalho integra circuitos combinacionais e sequenciais, representação signed, aritmética estrutural, entrada por switches e botões, displays de sete segmentos e LEDs de estado.

## Metodologia

O projeto foi desenvolvido a partir de requisitos rastreáveis e decisões documentadas. As operações aritméticas foram descritas estruturalmente com portas e instâncias explícitas. O único comportamento sequencial fica nos módulos dedicados a flip-flops. O controlador FSM é proibido; a captura usa um contador estrutural de progresso.

Os resultados esperados foram calculados por referências independentes. A verificação combinou testes unitários, exaustões dos domínios dos primitivos, testes de integração e auditoria estática. Por fim, o projeto foi compilado, ajustado e analisado no Quartus Prime.

## Descrição do circuito

`SW[7:0]` fornece os coeficientes durante a sequência de captura `a`, `b`, `c`, e fornece `x` após a carga. `KEY0` captura o coeficiente atual. `KEY1` aplica reset lógico. Os dois botões são ativos em nível baixo na placa e passam por sincronização.

Depois da carga, `SW[9:8]` seleciona `x`, `y`, `x₁` ou `x₂`. O caminho de `y` calcula `((a·x²)+(b·x))+c`. O caminho das raízes calcula `Δ=b²−4ac`, obtém a raiz quadrada inteira e aplica divisão e arredondamento ao resultado final. A flag `ERR` cobre `a=0` e discriminante negativo. `OV` segue DEC-012. `Z` indica se o resultado selecionado é zero. `C` é o carry-out da última soma de 23 bits do caminho de `y`, visível somente após carga completa e na seleção `y`.

Os displays HEX0–HEX5 apresentam valores decimais com sinal. Valores fora da faixa de apresentação usam o padrão de erro especificado. LEDR0–LEDR3 apresentam OV, Z, C e ERR, nessa ordem.

## Implementação e armazenamento

O top-level conecta o armazenamento de coeficientes, os caminhos aritméticos, o seletor de resultado, as flags e a conversão decimal. O circuito usa 31 flip-flops: 24 bits para `a`, `b` e `c`; dois bits para o progresso de captura; e cinco bits para sincronização e histórico dos botões. A validação de síntese reportou zero latches.

A implementação mantém os contratos matemáticos aprovados. Produtos e somas preservam larguras explícitas. O caminho das raízes mantém os resíduos exatos até o arredondamento final, conforme DEC-031. O arredondamento adotado nas raízes é para o inteiro mais próximo, com empate para longe de zero, conforme DEC-007. O texto original de REQ-006 pede truncamento; DEC-007 registra a autorização acadêmica para arredondar como exceção de implementação. O PDF não foi alterado.

## Verificação funcional e estática

| Escopo | Resultado registrado |
|---|---|
| Soma/subtração | 37.212 vetores, sem divergências |
| Multiplicadores | 65.536 pares signed e 4.194.560 pares mistos no domínio aprovado, sem divergências |
| Raiz quadrada | 131.072 radicandos, sem divergências |
| Divisão | 131.072 pares, incluindo divisor zero, sem divergências |
| Modelo independente das raízes | 16.777.216 triplas, sem divergências |
| Raízes RTL | 10.030 vetores dirigidos, sem divergências |
| Apresentação e flags | TEST-008/009 e TASK-018/019 aprovados, conforme `docs/verificacao.md` |
| Sistema integrado | 10 cenários e 660 observações de simulação, sem divergências |
| Auditoria estática | 12 fontes RTL e 11 testbenches; zero violações críticas ou altas abertas |

Os resultados detalhados, comandos e logs estão nas TASKs e em `verification/results/`. A simulação não substitui a validação física.

## Síntese e temporização

A compilação aprovada usou Quartus Prime 25.1std.0 Build 1129 SC Lite para o dispositivo 10M50DAF484C7G. O fitting reportou 2.187 logic elements, 2.182 funções combinacionais, 31 flip-flops, zero latches, zero bits de memória, zero multiplicadores embarcados e zero PLLs.

O clock usado é 50 MHz, com período de 20 ns. O pior slack de setup registrado foi 15,669 ns e o pior hold foi 0,153 ns. O maior atraso reportado até uma saída foi 160,472 ns, dentro do orçamento modelado de 1 ms. Esses resultados descrevem a análise de timing documentada. Não comprovam estabilidade elétrica de entradas assíncronas, hold externo dos displays, MTBF dos sincronizadores ou funcionamento físico da placa.

## Limitações e trabalho pendente

A validação física na DE10-Lite ainda não foi executada. O procedimento está em `verification/hardware-procedure.md`; seus resultados devem ser preenchidos após programar a placa. O projeto também aguarda o modelo e as instruções oficiais do tutor para formatar o relatório final. Este arquivo contém o texto técnico disponível e não representa uma entrega no formato final.

## Referências

- Enunciado TEC498, 2026, Problema 2.
- Terasic, *DE10-Lite User Manual*, 24 jan. 2017.
- Intel/Altera, Quartus Prime 25.1std.0 Build 1129 SC Lite, relatórios de compilação e timing arquivados no projeto.
- Decisões DEC-007, DEC-012, DEC-030 e DEC-031.
- Documentos e evidências citados em `docs/requisitos.md`, `docs/verificacao.md` e nas TASKs aprovadas.
