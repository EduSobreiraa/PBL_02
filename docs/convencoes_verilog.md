# Convenções e restrições de Verilog

## Autoridade

As restrições abaixo vêm de `docs/regras.md` e do enunciado PBL. Recomendações de síntese são identificadas separadamente e fundamentadas no handbook Intel Quartus disponível, edição 17.1 (2018). A instalação local é Quartus Prime Standard Lite 25.1std.0 Build 1129 (DEC-021); handbook e ferramenta instalada têm versões diferentes.

## Regras obrigatórias do projeto

- HDL estrutural dentro do escopo de sintaxe do PBL1, acrescido de flip-flops escolhidos para a lógica sequencial.
- Não utilizar `buf`, Verilog comportamental ou FSM no DUT, com a exceção estrita de `always @(posedge clk)` incondicional em módulos dedicados exclusivamente a flip-flops para capturar a entrada D já calculada, autorizado em DEC-014/025/026. Reset síncrono, enable, seleção e demais funções devem ser combinados estruturalmente na entrada D. As palavras-chave `if` e `else` são proibidas em todos os fontes Verilog, inclusive testbenches (DEC-025); a autorização comportamental de DEC-024 permite outras construções de estímulo/verificação no testbench separado. Não encapsular lógica de controle ou datapath comportamental em módulo chamado de flip-flop.
- Utilizar o menor número de bits de armazenamento que cumpra a função e as decisões aprovadas, preservando sincronização e temporização. Justificar em cada TASK/revisão os estados/funções que exigem memória, estados distinguíveis e codificação adotada (DEC-026).
- Não utilizar laços/geração `for`, `generate` ou `genvar`. `begin`/`end` só são permitidos na descrição do flip-flop e são proibidos fora dela.
- Preferir arredondamento quando o requisito oficial não estabelecer outro comportamento. Para as raízes, o PDF literal exige truncamento; por autorização expressa do professor, DEC-007 adota arredondamento ao inteiro mais próximo, com empates para longe de zero, como exceção de implementação neste projeto. Preservar o texto do requisito e a exceção lado a lado; não descrever arredondamento como cumprimento literal da palavra “truncar”.
- Em reduções necessárias de precisão intermediária, preservar os bits disponíveis enquanto possível e arredondar ao inteiro mais próximo, com empate para longe de zero (DEC-016). Essa política não valida por si só a precisão candidata F=16; verificação permanece em PEN-019.
- Os módulos aritméticos de soma/subtração, multiplicação, raiz quadrada e divisão devem ser descritos estruturalmente (PBL §4, req. 8).

O arquivo de regras usa “escopo do primeiro” sem enumerar uma lista normativa completa de construções. O HDL reformulado foi observado usando módulos, portas, `wire`, vetores, instanciações, `supply0`/`supply1` e primitivas `not`, `and`, `or`, `nor`, `xor`; isto é evidência do exemplo, não autorização automática de qualquer construção adicional. DEC-014/025 autorizam `always @(posedge clk)` incondicional apenas na descrição do DFF; reset síncrono e enable devem ser lógica estrutural na entrada D.

DEC-006 restringiu `begin`/`end` à descrição do flip-flop. A autorização posterior em DEC-014 permite `always @(posedge clk)` somente nessa descrição; as demais construções comportamentais continuam proibidas.

## Estilo documental recomendado (não decisão de linguagem)

- Escrever instâncias repetidas explicitamente, pois laços/generate são vedados pelas regras atuais.
- Nomear módulos e sinais de modo consistente e documentar finalidade, largura e sinal sempre que definidos.
- Manter testbenches separados do HDL destinado à síntese; testbench não é parte dos entregáveis sintetizáveis e a compatibilidade com as regras deve ser confirmada com o responsável antes da sua redação.
- Usar `wire` para conexões estruturais conforme estilo da base observada. A necessidade/uso de `reg` depende da forma sequencial que vier a ser aprovada; não implica autorização de `always`.
- No DUT, não introduzir parâmetros, operadores aritméticos, construções condicionais ou módulos primitivos não confirmados como parte do escopo autorizado. Em testbench separado, `case` é permitido para comparação conforme DEC-025, sem uso de `if`/`else`.

## Reset e lógica sequencial

DEC-008 define `MAX10_CLK1_50`, borda de subida, e reset lógico síncrono ativo alto originado por KEY1. DEC-019 confirma KEY ativo baixo e aprova sincronização em duas etapas e captura por evento único. O tipo DFF e sua forma de descrição estão autorizados por DEC-014; a integração ainda precisa de síntese/verificação no ambiente real, usando Quartus Standard Lite 25.1std.0 Build 1129.

## Latches e warnings (recomendação oficial do handbook)

O Intel Quartus Prime Standard Edition Handbook v17.1, capítulo 11.2.1.2, recomenda evitar inferência não intencional de latches e observa que a síntese emite warning quando isso ocorre; também alerta sobre complexidade de temporização e glitches. Aplicação ao projeto: revisar todos os warnings e investigar os de latches, loops combinacionais, largura e clock. Isso é recomendação técnica do handbook, não requisito textual do PBL.

O handbook está atualizado para Quartus 17.1 e foi publicado em 2018. Usá-lo como referência fornecida, verificando comandos, suporte e recomendações contra a versão instalada antes de agir.

## Síntese e testbench

O manual Intel consultado contém seção de suporte de síntese Verilog/SystemVerilog (cap. 16.2.1) e integração de simulação. Não determina o simulador deste trabalho. O HDL de síntese e estímulos de simulação devem ser separados em arquivos/entidades próprios; nomes, ferramenta e fluxo do testbench estão pendentes. Não executar síntese ou testes até a arquitetura e as interfaces serem revisadas.
