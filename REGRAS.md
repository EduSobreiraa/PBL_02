# REGRAS — PBL03

Versão: 1.2 — 16/11/2026

## 1. Escopo e fontes

Esta especificação consolida o enunciado `TEC498_2026_2_Problema3.pdf`, os esclarecimentos do professor relatados pela equipe e as decisões discutidas para implementação. Os esclarecimentos complementam o PDF. Decisões de implementação podem ser revistas, desde que os requisitos sejam preservados e a alteração documentada.

O sistema será implementado na FPGA DE10-Lite e exibirá até duas funções quadráticas e suas derivadas:

- f1(x) = a1*x² + b1*x + c1; f1'(x) = 2*a1*x + b1.
- f2(x) = a2*x² + b2*x + c2; f2'(x) = 2*a2*x + b2.

## 2. Restrições obrigatórias de Verilog

1. Verilog comportamental é permitido exclusivamente em módulos específicos de flip-flop e de Máquina de Estados Finitos (FSM).
2. Nos demais módulos, utilizar Verilog estrutural com instanciações explícitas de módulos e portas lógicas permitidas.
3. Fora dos módulos de flip-flop e FSM, não utilizar `assign`, `generate`, `for`, `buf`/buffers ou construções equivalentes, conforme a restrição informada pelo professor. Também não utilizar blocos comportamentais `always` ou `initial` nesses módulos.
4. Não transferir operações aritméticas para dentro de uma FSM apenas para contornar a restrição: o controle pertence às FSMs; os circuitos de processamento devem respeitar a implementação estrutural.
5. Todas as etapas do sistema, inclusive as reaproveitadas do projeto anterior, devem ser coordenadas por máquinas de estados. Componentes combinacionais, como somadores, não precisam de uma FSM individual.
6. Separar cada módulo em seu próprio arquivo `.v`, incluindo módulos auxiliares e flip-flops.
7. Aplicar as restrições também ao código reaproveitado do PBL02.
8. O módulo VGA fornecido pelo professor é um periférico externo e deve permanecer intacto, mesmo contendo construções não permitidas nos módulos desenvolvidos pela equipe.

## 3. Entrada e armazenamento de coeficientes

1. Retirar obrigatoriamente a entrada em complemento de 2 exigida do usuário no projeto anterior.
2. A entrada usa magnitude em `SW[7:0]` e sinal em `SW[8]`, com 0 para positivo e 1 para negativo. Aceitar valores de -128 a 127: magnitude máxima 127 para sinal positivo e 128 para sinal negativo. Normalizar a entrada de sinal negativo e magnitude zero para zero.
3. Converter valores aceitos para complemento de 2 signed8 para armazenamento e processamento.
4. Preservar o requisito do PDF: coeficientes inteiros com sinal de 8 bits. Caso seja adotado complemento de 2 internamente, atender à faixa de -128 a 127, incluindo -128.
5. Capturar sempre os seis coeficientes na ordem: **a1 → b1 → c1 → a2 → b2 → c2**.
6. Manter dois conjuntos independentes de registradores para os coeficientes.
7. Para exibir somente uma função, o usuário deve inserir **a2 = b2 = c2 = 0**. Não encerrar a entrada depois de c1.
8. O segundo conjunto inteiramente nulo significa **F2 desabilitada**, sem gerar erro por a2 = 0.
9. Se a2 = 0 e algum dos demais coeficientes de F2 for diferente de zero, F2 está habilitada e deve gerar erro de função inválida.
10. F1 não possui convenção de desabilitação por conjunto nulo: a1 = 0 deve gerar erro.
11. Cada evento válido de `KEY0` confirma o coeficiente corrente. Entrada inválida não captura nem avança. Depois de confirmar c₂, um novo evento de `KEY0` inicia o processamento. `KEY1` reinicia a entrada completa e limpa coeficientes, progresso, estados e resultados.
12. Sincronizar `KEY0` e `KEY1` com dois DFFs em série no clock `MAX10_CLK1_50`; não usar os botões como clocks. Os KEY são ativos baixos. Gerar um pulso de um ciclo para KEY0 na transição sincronizada de liberado para pressionado; manter o botão pressionado não repete o evento.
13. A KEY1 sincronizada gera reset lógico interno síncrono ativo alto, com prioridade sobre captura. Durante o reset, ignorar eventos de KEY0, limpar o estado da entrada e preparar o histórico do detector de KEY0 como liberado. KEY0 deve permanecer liberado durante o reset.
14. Preservar a conexão de KEY1 físico, invertido, ao reset assíncrono ativo alto do periférico VGA. Essa rota não substitui o reset síncrono interno nem reseta o sincronizador de KEY1.
15. Após energizar, o operador deve pressionar KEY1 e aguardar a propagação pela cadeia antes de inserir coeficientes. Não presumir inicialização de power-on dos sincronizadores. Ajustar `SW[8:0]` antes de pressionar KEY0 e mantê-lo estável até a borda em que o registrador captura o coeficiente. A sincronização de SW não faz parte deste contrato.
16. A placa condiciona os KEY por Schmitt/debounce conforme o manual da DE10-Lite citado em DEC-019. Não acrescentar filtro digital por contador nesta etapa nem alegar garantia física contra metastabilidade.

## 4. Controle e arquitetura

Decisões atuais da equipe, sujeitas a revisão documentada:

- Utilizar uma FSM principal, uma FSM de entrada e uma FSM por processador de função.
- A FSM de entrada emite `START` como pulso após c₂ quando recebe novo evento de `KEY0`.
- `BUSY` permanece ativo durante a preparação e a validação das funções, antes de habilitar a exibição. `DONE` fica retido até um novo `START` ou `KEY1`.
- Depois de `DONE`, um novo evento de `KEY0` inicia nova validação/execução com os coeficientes retidos. `DONE` habilita a exibição; os cálculos combinacionais continuam respondendo às coordenadas do VGA.
- As FSMs controlam etapas e estados. Operações aritméticas permanecem em datapaths estruturais.
- Manter dois caminhos de processamento em paralelo, um para cada função.
- Desenvolver e validar primeiro F1 e sua derivada. Somente depois implementar F2.
- Preferir duas instâncias do mesmo conjunto de módulos de função, evitando versões divergentes de F1 e F2.
- Compartilhar a integração com a saída VGA e a composição final das cores.
- Calcular f(x) e f'(x) combinacionalmente a partir do x corrente do VGA, com caminhos paralelos para F1 e F2.
- Verificar o custo do paralelismo e a temporização na síntese; não afirmar que o circuito é mínimo sem avaliação.

## 5. VGA e coordenadas

1. Resolução obrigatória: **640 × 480 pixels**.
2. Origem cartesiana no pixel **(320, 240)**.
3. Escala fixa: **um pixel representa uma unidade**, sem escala adicional.
4. Transformação: x_cartesiano = x_pixel - 320; y_pixel = 240 - y_cartesiano.
5. Os 640 valores inteiros de x visíveis são **-320 até 319**.
6. O contador de coluna deve percorrer **0 até 639**, inclusive. O valor 640 pode servir como condição de término, mas não como coluna adicional a processar.
7. A faixa vertical visível, para coordenadas cartesianas, é **-239 até 240**.
8. Usar pelo menos 10 bits com sinal para x cartesiano. A subtração de 320 deve preservar corretamente o sinal.
9. Redimensionar multiplicadores, somadores e resultados intermediários: o `polinomio_y` anterior, com x de 8 bits, não atende diretamente ao domínio atual. Para a avaliação direta, usar x signed10, x² unsigned17, f(x) signed25 e f'(x) signed18. A demonstração de limites está em DEC-044; síntese e temporização ainda precisam de evidência real.
10. Calcular f(x) e f'(x) para cada um dos 640 valores inteiros de x e para cada função habilitada e válida.
11. Aplicar clipping antes de utilizar resultados como coordenadas de desenho. Pontos fora da tela não devem provocar coordenadas inválidas nem overflow na interface VGA.
12. Respeitar `video_on` e a temporização fornecida pelo periférico VGA.

## 6. Periférico VGA imutável

Fonte: https://github.com/LordWalace/Controlador-VGA-DE10-Lite

- Preservar integralmente o `vga_sync.v` fornecido pelo professor.
- Integrar pelas entradas e saídas existentes: clock, reset, sincronismos, `video_on`, `p_tick`, x e y.
- Desenvolver externamente transformação de coordenadas, eixos, curvas, clipping, textos e seleção de cores.
- Criar o módulo principal da equipe para a integração. O exemplo de desenho do repositório não substitui a lógica do PBL03.

## 7. Validação, erros e sinalização

1. Calcular o vértice de cada parábola antes de iniciar sua plotagem.
2. Para cada função habilitada, a = 0 deve gerar erro e impedir sua plotagem como parábola.
3. Vértice fora da área visível deve invalidar a função para plotagem.
4. O display de sete segmentos deve identificar a função e o tipo de erro, por exemplo: `ERR F1`, `ERR F2`, `ERR V1` e `ERR V2`. Se houver mais de um erro, mostrar uma mensagem pela prioridade `ERR F1` > `ERR V1` > `ERR F2` > `ERR V2`. Usar `HEX5` a `HEX0`, da esquerda para a direita, para `E`, `R`, `R`, espaço, `F` ou `V`, e `1` ou `2`. Deixar os displays apagados sem erro e enquanto DONE estiver baixo.
5. O erro de uma função não deve impedir a exibição da outra função válida.
6. Uma função inválida não deve contribuir com sua parábola ou derivada para a imagem.
7. LEDs ativos altos: `LEDR[0]=BUSY`, `LEDR[1]=DONE`, `LEDR[2]=ERR_F1` e `LEDR[3]=ERR_F2`; manter `LEDR[9:4]=0`. Cada indicador de erro é o OR dos dois tipos de erro da função correspondente, de forma que os dois LEDs ERR possam acender simultaneamente.
8. Não reutilizar o erro de discriminante negativo do PBL02 como condição de invalidação da parábola: ausência de raízes reais não impede a plotagem.
9. Validar o vértice como número racional exato, sem arredondar antes da validação. Para a diferente de zero, xᵥ = -b/(2a) e yᵥ = (4ac-b²)/(4a). O vértice deve pertencer aos limites inclusivos xᵥ∈[-320,319] e yᵥ∈[-239,240]. Usar ponto fixo apenas para textos e extras que precisem de marcadores, com formato definido antes de implementar esses extras.

## 8. Cores e funcionalidades extras

### Obrigatório

- Cores distintas para F1, F1', F2 e F2'.
- Cor identificável para os eixos.
- Paleta e prioridade de sobreposição documentadas.
- Paleta RGB de 4 bits por canal: F1 azul `(0,0,15)`, F1' ciano `(0,15,15)`, F2 vermelho `(15,0,0)`, F2' amarelo `(15,15,0)`, eixos branco `(15,15,15)` e interseções magenta `(15,0,15)`.
- Prioridade de composição: interseções, curvas, eixos e fundo, nessa ordem. Entre curvas, F1, F1', F2 e F2', nessa ordem.
- A transformação cartesiana usa origem `(320,240)` e escala de uma unidade por pixel.

### Extras opcionais do projeto

- Exibir no VGA as coordenadas dos vértices V1 e V2 e das raízes X1 e X2, identificando a função correspondente.
- Destacar com a quinta cor as colunas inteiras em que f₁(x) = f₂(x), comparando os valores completos antes de converter y para pixel. Não incluir cruzamentos envolvendo derivadas. Interseções com x fracionário não são destacadas. Parábolas coincidentes usam a quinta cor em todos os pontos válidos e visíveis.
- Destacar as raízes com uma sexta cor.

Os extras devem ser implementados depois do funcionamento dos requisitos obrigatórios. A ordem entre os extras ainda não está fechada. A conversão em ponto fixo dos marcadores extras também precisa de definição antes de sua implementação.

## 9. Reaproveitamento do PBL02

Base de referência: https://github.com/EduSobreiraa/PBL_02/tree/feature/led-bcd-input

- Reaproveitar componentes compatíveis, após revisão das restrições e interfaces.
- Adaptar a captura para os seis coeficientes e usar magnitude em `SW[7:0]` com sinal em `SW[8]`.
- Revisar larguras e sinal de toda a aritmética usada no novo domínio.
- Criar uma nova integração principal controlada por FSMs.
- Reaproveitar partes do display para mensagens e erros.
- Cálculo de raízes e raiz quadrada não são necessários à plotagem obrigatória, mas podem ser úteis aos extras. A precisão da exibição dos marcadores deve preservar o contrato exato de f(x), f'(x) e da validação racional do vértice.
- Preservar a versão do PBL02 como referência antes de alterar a implementação.

## 10. Validação e documentação de entrega

- Documentar arquitetura, papel dos módulos, interfaces, reset, operação dos botões/chaves, representação numérica e cores.
- Produzir diagrama de estados e tabela de transições/saídas das FSMs.
- Simular a entrada dos seis coeficientes na ordem definida, incluindo `+127`, `-128`, entradas fora da faixa e normalização de `-0`.
- Verificar que entrada inválida não avança, que KEY0 inicia após c₂, que KEY1 limpa a sessão, que START pulsa, que BUSY termina após validação e que DONE permanece retido até novo início/reset.
- Verificar F2 desabilitada pelo conjunto nulo e F2 inválida com a2 = 0 e conjunto não nulo.
- Verificar uma função válida, duas válidas, erros independentes, vértices dentro, nas bordas e fora da tela, e clipping.
- Verificar igualdade em x inteiro, parábolas coincidentes e ausência de destaque para interseções com x fracionário.
- Conferir processamento das 640 colunas e ausência de overflow nos intermediários.
- Verificar conformidade de sintaxe, um módulo por arquivo e integridade do periférico VGA.
- Registrar resultados reais de simulação, síntese, utilização de recursos, temporização e teste na placa.
- Não apresentar testes ou aprovação do professor como realizados sem evidência.

## 11. Decisões pendentes

1. Formato e arredondamento dos marcadores de vértice e raízes nos extras.
2. Cor e prioridade do marcador de raízes, conforme a ordem de implementação dos extras.
3. Viabilidade do caminho combinacional direto, recursos e temporização, a confirmar por síntese Quartus.

As FSMs principal, de entrada e de função estão especificadas em DEC-049, DEC-046/DEC-044 e DEC-048, respectivamente. DEC-050 fecha a prioridade das mensagens de erro e o mapeamento dos LEDs. As escolhas fechadas em DEC-044 deixam de ser pendências. Nenhum dos itens restantes deve ser tratado como escolha já aprovada.
