# Regras Gerais para o projeto.

1. A sintaxe está limitada a utilizar o escopo do primeiro + flip flops de sua escolha.
2. No DUT sintetizável, não utilizar `buf`, Verilog comportamental ou máquinas de estado. Exceções expressas: (a) usar `always @(posedge clk)` somente na descrição do flip-flop D, restrito a capturar o dado e aplicar reset síncrono/enable do próprio registrador conforme DEC-008/009/014; (b) na TASK-002, o contador linear de progresso da carga `0→1→2→concluído` e sua decodificação combinacional de enables estão autorizados e não serão tratados como FSM neste projeto, conforme DEC-024. Nenhum `always` ou comportamento sequencial é permitido fora da descrição dos flip-flops; datapath e lógica combinacional permanecem estruturais. Não generalizar a autorização do contador a outros controladores.
   Testbenches separados do DUT podem usar Verilog comportamental exclusivamente para estímulo, comparação e término da simulação, nos termos autorizados pelo responsável em DEC-024. Essa exceção não se aplica ao DUT nem a código sintetizável.
3. Sempre utilizar a documentação + o contexto do projeto do PBL como regras definidas (1 regras.md 2 PDF do projeto)
4. No DUT, não utilizar laços/geração como `for`, `generate` ou `genvar`. `begin`/`end` são permitidos somente na descrição do flip-flop e proibidos em qualquer outro lugar. O uso de `always` permanece limitado às exceções explícitas da regra 2. No testbench autorizado, laços e blocos podem ser usados para estímulo/verificação; não podem ser transferidos para o DUT.
5. Sempre dê preferência ao arredondamento.
