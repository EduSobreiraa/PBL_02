# Regras Gerais para o projeto.

1. A sintaxe está limitada a utilizar o escopo do primeiro + flip flops de sua escolha.
2. Não utilizar `buf`, Verilog comportamental ou máquinas de estado. Exceção autorizada pelo responsável e registrada em DEC-014: usar `always @(posedge clk)` somente na descrição do flip-flop D, restrito a capturar o dado e aplicar reset síncrono/enable do próprio registrador conforme DEC-008/009. Nenhum `always` ou comportamento sequencial é permitido fora da descrição dos flip-flops; datapath e lógica combinacional permanecem estruturais.
3. Sempre utilizar a documentação + o contexto do projeto do PBL como regras definidas (1 regras.md 2 PDF do projeto)
4. Não utilizar laços/geração como `for`, `generate` ou `genvar`. `begin`/`end` são permitidos somente na descrição do flip-flop e proibidos em qualquer outro lugar. O uso de `always` permanece limitado à exceção explícita da regra 2.
5. Sempre dê preferência ao arredondamento.
