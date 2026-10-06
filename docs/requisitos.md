# Requisitos do PBL02

**Fonte normativa:** `TEC498_2026_2_Problema2.pdf` (P0). Este arquivo contém requisitos do enunciado, sem decisões de implementação. As regras de trabalho do repositório permanecem em `docs/regras.md`.

## Requisitos rastreáveis

| ID | Descrição | Origem | Tipo | Observações | Clareza |
|---|---|---|---|---|---|
| REQ-001 | O sistema deve possuir mecanismo de inicialização/reset claramente definido e documentado. | PBL §4, req. 1, p. 2 | Funcional | DEC-008/019 define clock, reset lógico e sincronização; KEY1 é eletricamente ativo baixo. | Explícito; decisão documental fechada, validação física pendente |
| REQ-002 | `a`, `b` e `c` devem ser números inteiros com sinal de 8 bits, inseridos sequencialmente nessa ordem. | PBL §4, req. 2, p. 2 | Funcional | A forma de inserir cada valor não é prescrita. | Explícito |
| REQ-003 | Na Opção 2, `x` deve vir de `SW[7:0]` da DE10-Lite, com `SW[7]` como bit de sinal; devem ser usados os coeficientes previamente inseridos. | PBL §4, req. 3, p. 2 | Funcional/interface | A representação signed é indicada pelo bit de sinal, sem formato adicional especificado. | Explícito |
| REQ-004 | Após carregar os coeficientes, o usuário deve poder selecionar Opção 1 (raízes) ou Opção 2 (valor de `y`). A equipe deve definir e documentar o mapeamento de botões/chaves para seleção, execução e reset. | PBL §4, req. 4, p. 2 | Funcional/interface | DEC-010/011 documentam resultados contínuos sem botão EXECUTAR separado; SW[9:8] seleciona a visualização x/y/x₁/x₂. | Explícito; mapeamento de equipe decidido |
| REQ-005 | Na Opção 1, calcular `Δ = b² − 4ac`; se `Δ ≥ 0` e `a ≠ 0`, determinar `x₁` e `x₂`. Se `a = 0` ou `Δ < 0`, ativar `ERR`. | PBL §4, req. 6, p. 2 | Funcional | O texto não define comportamento de exibição das raízes quando `ERR` está ativo. | Explícito; saída em erro pendente |
| REQ-006 | Representar as raízes em ponto fixo com sinal e truncar para números inteiros. | PBL §4, req. 6, p. 2 | Funcional/representação numérica | A quantidade de bits fracionários intermediários não é indicada. | Explícito; precisão interna pendente |
| REQ-007 | Na Opção 2, calcular `y = ax² + bx + c` com largura interna suficiente para evitar perda indevida de informação e indicar overflow do resultado por flag específica. | PBL §4, req. 7, p. 2 | Funcional/precisão | A largura interna e o critério de overflow não são quantificados. | Explícito; detalhes pendentes |
| REQ-008 | Descrever em Verilog estrutural os módulos aritméticos de soma/subtração, multiplicação, raiz quadrada e divisão. | PBL §4, req. 8, p. 2 | Implementação | Não especifica algoritmos ou arquitetura desses módulos. | Explícito |
| REQ-009 | Permitir selecionar nos displays de sete segmentos a visualização de `x`, `y`, `x₁` ou `x₂`, priorizando representação decimal com sinal. | PBL §4, req. 9, p. 2 | Interface/saída | DEC-017 define `------` se o valor decimal signed completo não couber nos seis displays. | Explícito; fallback de equipe definido |
| REQ-010 | Apresentar nos LEDs no mínimo overflow aritmético (`OV`), zero (`Z`), carry (`C`) e erro (`ERR`). Flags adicionais são opcionais. | PBL §4, req. 10, p. 2 | Interface/saída | O significado exato e a origem da flag `C` não são detalhados. | Explícito; semântica pendente |
| REQ-011 | Combinar circuitos combinacionais e sequenciais e empregar registradores e módulos aritméticos necessários às duas operações, sem FSM. | PBL §3, p. 1–2 | Não funcional/implementação | “Sem FSM” é exigência do próprio enunciado. | Explícito |
| REQ-012 | Entregar especificação detalhada do circuito mínimo. | PBL §5, item 1, p. 3 | Entregável | “Mínimo” é exigência, sem métrica de minimização definida. | Explícito; critério de mínimo pendente |
| REQ-013 | Implementar a estrutura no Quartus usando Verilog estrutural. | PBL §5, item 2, p. 3 | Entregável/ferramenta | A versão do Quartus não é informada. | Explícito |
| REQ-014 | Sintetizar o sistema na plataforma DE10-Lite. | PBL §5, item 3, p. 3 | Entregável/hardware | O manual identifica a placa; o enunciado não fornece pin assignments. | Explícito |
| REQ-015 | Produzir estruturas de testes, simulações e demais elementos usados na validação do funcionamento. | PBL §5, item 4, p. 3 | Verificação/entregável | O enunciado não determina simulador, cobertura ou formato de testbench. | Explícito; método pendente |
| REQ-016 | O relatório deve conter introdução contextualizada, metodologias fundamentadas, descrição em alto nível dos periféricos/módulos/conexões, função dos módulos, resultados de síntese (incluindo LEs), testes e análise. | PBL §8, “Relatório”, p. 5–6 | Documentação | O modelo deve ser obtido com o tutor. Cópias de materiais existentes não são admitidas. | Explícito |

## Exceção de implementação registrada

REQ-006 acima preserva literalmente a exigência publicada no PBL de truncar as raízes. DEC-007 registra que o professor autorizou/incentivou arredondar as raízes finais como desafio do projeto; a equipe adota arredondamento ao inteiro mais próximo, com empate para longe de zero, como exceção de implementação. Isso não retifica o PDF nem altera o texto deste requisito. Relatórios e documentação de comportamento devem declarar a divergência.

## Objetivos de aprendizagem (contexto, não critérios adicionais de circuito)

O PBL declara objetivos de aprendizagem sobre circuitos combinacionais e sequenciais síncronos, registradores, contadores e pilhas; caminho de dados aritmético; integração de controle e datapath; representação com sinal/ponto fixo e tratamento de erros; simulação, depuração, teste e documentação. Fonte: PBL §2, p. 1.

## Delimitação

Este documento não incorpora as restrições adicionais de `docs/regras.md` como se fossem requisitos do PDF. Elas são consolidadas em `docs/convencoes_verilog.md` e referenciadas em `docs/fontes.md`.
