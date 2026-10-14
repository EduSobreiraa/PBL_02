# TASK-024 — Texto rolante para orientar a entrada dos coeficientes

## Objetivo

Durante a carga sequencial de `a`, `b` e `c`, mostrar nos seis HEX uma animação rolante das frases `Insira a`, `Insira b` e `Insira c`, escolhida pelo progresso existente. Ao concluir a carga, restaurar imediatamente a apresentação normal.

## Status

BLOCKED — implementação e compilação concluídas; as simulações funcionais exigidas não puderam ser executadas porque o ambiente não tem Icarus disponível e Questa não tem licença configurada.

## Requisitos relacionados

- REQ-002
- REQ-009

## Decisões relacionadas

- DEC-019 — polaridade e ordem dos segmentos.
- DEC-024 — protocolo de captura e contador de progresso.
- DEC-030 — integração e apresentação normal após `loaded=1`.
- DEC-040 — prompt estático anterior, supersedido apenas pela apresentação rolante e novo estado.
- DEC-041 — texto rolante, anel de 14 símbolos, glifos e cadência.
- DEC-042 — exportação privada de `pedido_rearme` e `evento_captura`, reset sincronizado prioritário e reinício após captura válida.

## Dependências

- TASK-023 APPROVED; `entrada_coeficientes_nucleo` expõe o progresso privado e `modulo_principal` seleciona o prompt.
- `exibicao_decimal` e apresentação normal atuais.

## Escopo de implementação

- Adicionar divisor estrutural de 12.500.000 ciclos do clock de 50 MHz e contador estrutural de posição módulo 14, ambos com FFs nas primitivas dedicadas permitidas.
- Rolar um anel formado pela frase de oito caracteres correspondente ao progresso mais seis espaços. Janela de seis caracteres nos HEX5..HEX0, deslocando um caractere por passo a cada 250 ms.
- Usar progresso `00/01/10` para os sufixos semânticos `a/b/c`; glifo de `c` é aproximado por `C`.
- Exportar na interface privada de `entrada_coeficientes_nucleo` os sinais combinacionais existentes `pedido_rearme` e `evento_captura`; conectar ou terminar esses sinais em todos os callers.
- `pedido_rearme` reinicia posição e divisor sincronamente com prioridade; cada `evento_captura` válido também reinicia ambos em `p=0`. O progresso atualizado seleciona a nova frase; `loaded=1` seleciona a apresentação normal sem esperar pelo divisor.
- Não modificar portas físicas, pinagem, sequência de captura, valores/flags, matemática ou wrapper público.

## Restrições aplicáveis

- Sem FSM, `if`, `else`, `buf`, loops/generate ou `assign` contínuo no DUT.
- Estado sequencial apenas em módulos primitivos dedicados de FF.
- Preservar todos os contratos prévios não supersedidos por DEC-041.
- A janela e glifos ativos baixos devem seguir DEC-019 e DEC-041.

## Arquivos permitidos

- `rtl/entrada_coeficientes.v` — adicionar as saídas privadas do core e terminar as saídas em fios não usados no wrapper; não alterar portas públicas nem lógica de captura/sincronização.
- `rtl/modulo_principal.v`
- `testbench/tb_top_module.v`
- `testbench/tb_coefficient_input.v`
- `testbench/tb_status_flags.v`
- `docs/tasks/TASK-024.md`

## Arquivos protegidos

- Portas públicas do wrapper `entrada_coeficientes`, portas físicas de `modulo_principal` e pin assignments.
- `docs/requisitos.md`, `docs/interfaces.md`, decisões DEC-019/024/030/040/041/042 e RTL fora da lista permitida.
- `docs/interfaces.md` foi atualizado pelo Orchestrator durante a propagação de DEC-041/042 antes de TASK-024 ficar READY; essa alteração é baseline da implementação e não foi feita pelo Code Implementer. Não editar novamente nesta TASK.

## Critérios de aceite

- Para cada progresso `00/01/10`, os 14 quadros do anel de oito caracteres mais seis espaços são exibidos com o mapeamento de glifos registrado em DEC-041.
- Cada passo move a janela um caractere; wrap `13→0` também é deslocamento de um caractere.
- Um passo ocorre após exatamente 12.500.000 ciclos do clock de 50 MHz.
- `pedido_rearme`, derivado do KEY1 sincronizado, reinicia divisor e posição sincronamente e tem prioridade sobre avanço e evento de captura.
- Cada `evento_captura` válido reinicia divisor e posição em `p=0` no mesmo ciclo; o progresso atualizado seleciona a nova frase. Após `loaded=1`, não há captura válida nem reinício.
- `loaded=1` restaura imediatamente os seis HEX normais em todos os seletores, sem alterar resultados carregados.
- Não há alteração de portas físicas ou de pinagem; nenhuma construção RTL proibida aparece.

## Verificações exigidas

- Teste integrado do top-level percorre quadros, progresso, glifos e o wrap; pode acelerar contadores no testbench sem alterar o RTL e ainda deve verificar separadamente a contagem nominal de ciclos.
- Verificar KEY1 sincronizado sem estágios duplicados, reset durante carga e sua prioridade quando coincide com avanço/captura.
- Verificar pulso único `evento_captura`, reinício em `p=0` e do divisor após cada captura válida, progresso atualizado, bloqueio em `loaded=1`, prioridade da apresentação normal e independência de `SW[9:8]`.
- Atualizar todos os callers encontrados: top-level, wrapper público (terminar fios) e testbenches diretos `tb_coefficient_input` e `tb_status_flags`.
- Executar compilação/simulação dos testbenches afetados, inspeção estrutural do RTL e `git diff --check`; registrar comandos e resultados reais.
- Síntese Quartus, análise de timing/recursos e validação física não são alegadas se não executadas.

## Implementation Brief

### Objetivo

Durante a carga, percorrer nos seis displays HEX a frase correspondente ao próximo coeficiente (`Insira a`, `Insira b` ou `Insira c`) e restaurar a apresentação numérica normal imediatamente quando `loaded=1`.

### Requisitos

- REQ-002
- REQ-009

### Decisões aplicáveis

- DEC-019 — KEY ativos baixos e sincronizados; HEX ativo baixo com segmentos `[0..6]=[a,b,c,d,e,f,g]`.
- DEC-024 — captura sequencial `a→b→c` por KEY0.
- DEC-030 — integração top-level, progresso privado e apresentação normal.
- DEC-040 — prompt estático anterior, supersedido somente conforme DEC-041.
- DEC-041 — anel rolante de 14 símbolos, janela de seis caracteres, glifos e cadência nominal.
- DEC-042 — sinais privados de reset sincronizado e captura válida, prioridades e reinício da animação.

### Módulos envolvidos

- `modulo_principal` em `rtl/modulo_principal.v`: mantém portas físicas e conecta clock, reset, progresso, `loaded`, displays normais e prompt.
- `prompt_entrada_coeficientes` em `rtl/modulo_principal.v`: implementação atual combinacional do prompt A/b/C; será substituída/estendida para selecionar a janela rolante.
- `entrada_coeficientes_nucleo` em `rtl/entrada_coeficientes.v`: origem de `loaded` e `progresso[1:0]`, com estados `00→01→10→11`.
- Primitivas `flipflop_simples` e `flipflop_reset_sincrono` existentes em `rtl/entrada_coeficientes.v` podem ser instanciadas para estado estrutural, respeitando a semântica existente.
- `tb_top_module` em `testbench/tb_top_module.v`: verificar apresentação no contexto integrado sem enfraquecer as verificações atuais de LEDs e valores numéricos.

### Interface

- Interface física de `modulo_principal` permanece congelada: `MAX10_CLK1_50` entrada de 1 bit; `KEY[1:0]` entrada de 2 bits; `SW[9:0]` entrada de 10 bits; `LEDR[9:0]` saída de 10 bits; `HEX0..HEX5[6:0]` saídas de 7 bits cada.
- `entrada_coeficientes_nucleo`: `loaded` (1 bit), `progresso[1:0]`, `pedido_rearme` (reset síncrono ativo alto após sincronizador existente de KEY1) e `evento_captura` (pulso combinacional de um ciclo, captura válida após sincronização/qualificação). As duas novas saídas são privadas e não acrescentam estado.
- A animação recebe clock, `pedido_rearme` e `evento_captura` por conexões privadas no top-level. Não usar KEY1 bruto, duplicar sincronizadores/detectores nem acesso hierárquico; portas físicas não mudam.
- Ordem da janela: HEX5 é o símbolo mais à esquerda, HEX0 o mais à direita.

### Clock e reset

- Clock: `MAX10_CLK1_50`, 50 MHz, avanço em borda de subida.
- Cadência definida: um passo de posição a cada exatamente 12.500.000 ciclos (250 ms nominais).
- Reset KEY1 chega por `pedido_rearme`, derivado do sincronizador existente, e é síncrono ativo alto; reinicia divisor/posição com prioridade.
- `evento_captura` reinicia divisor/posição em `p=0` no mesmo ciclo da captura e atualização de progresso. A nova frase começa no primeiro quadro; não registrar cópia do evento nem adicionar sincronizador.

### Restrições

- DUT estrutural: sem FSM, `if`, `else`, `buf`, loops/generate, `assign` contínuo ou blocos comportamentais fora de primitiva dedicada de FF.
- Usar o menor estado sequencial compatível: 24 bits para o divisor e 4 bits para posição (28 FFs adicionais). Core de captura não recebe FF adicional; não duplicar estado/sincronizadores/eventos.
- Preservar portas/pinagem, ordem e protocolo de captura, valores carregados, LEDs, matemática e apresentação normal quando `loaded=1`.
- Glifos e polaridade conforme tabela final de DEC-041; `c` usa aproximação `C`.

### Arquivos permitidos

- `rtl/entrada_coeficientes.v` — somente saídas privadas no core e terminação no wrapper.
- `rtl/modulo_principal.v`
- `testbench/tb_top_module.v`
- `testbench/tb_coefficient_input.v`
- `testbench/tb_status_flags.v`
- `docs/tasks/TASK-024.md` para registrar brief, implementação e evidências.

### Arquivos protegidos

- Portas públicas do wrapper, portas físicas, pinagem, requisitos, interfaces canônicas, decisões e RTL fora da lista permitida.
- `docs/interfaces.md` já estava atualizado pelo Orchestrator antes de a TASK ficar READY; o Implementer não pode editá-lo nesta TASK.

### Testes exigidos

- Teste integrado de todas as 14 posições para progresso `00`, `01` e `10`, conferindo glifos e espaço conforme DEC-041.
- Verificar `p=0`, `1`, `8`, `9`, `13` e wrap `13→0` como especificados na decisão.
- Verificar cadência nominal, KEY1 sincronizado sem duplicação, prioridade de reset, reinício após cada evento válido, pulso único por pressão, mudança de progresso/frase em `p=0`, evento bloqueado após carga completa, independência de `SW[9:8]` e retorno imediato dos HEX normais.
- Preservar verificações pré-existentes de resultados e LEDs em `tb_top_module`.
- Executar compilação/simulação dos testbenches afetados, inspeção estrutural e `git diff --check`, registrando resultados reais. Não alegar síntese, timing ou validação de placa sem execução.

### Casos de borda

- Wrap de `p=13` para `p=0` deve deslocar somente um símbolo.
- KEY1 sincronizado durante rolagem reinicia estado; reset prevalece sobre avanço e captura coincidentes.
- Captura válida muda progresso `00→01→10→11` e reinicia divisor/posição em `p=0`; capturas adicionais com `loaded=1` não reiniciam animação.
- Todos os callers conectam/terminam saídas privadas; portas físicas e wrapper público preservam interfaces.
- Seletores SW[9:8] não interferem no prompt antes de conclusão.
- Ao concluir a terceira captura, apresentação normal deve prevalecer sem aguardar o próximo passo do divisor.

### Critérios de aceite

- Frase apresentada corresponde ao próximo coeficiente: `Insira a`, depois `Insira b`, depois `Insira c`, avançando com as capturas válidas.
- Cada posição mostra seis caracteres da janela do anel de 14 símbolos, movendo um caractere por passo conforme DEC-041.
- Passo ocorre a cada 12.500.000 ciclos de 50 MHz; `pedido_rearme` sincronizado tem prioridade e cada `evento_captura` válido reinicia divisor/posição em `p=0` conforme DEC-042.
- Core privado exporta somente sinais já existentes sem novos FFs; callers são atualizados e wrapper público permanece intacto.
- `loaded=1` recupera imediatamente os seis HEX normais sem afetar os dados nem os LEDs.
- Nenhuma alteração de interface física/pinagem e nenhuma construção RTL proibida.

### Dependências

- TASK-023 APPROVED: core de coeficientes fornece progresso e top-level já seleciona a apresentação.
- DEC-041 CONSENSUS: glifos, anel e cadência.
- DEC-042 CONSENSUS: exportação dos sinais existentes, reset sincronizado/prioridades e reinício após captura.
- Callers diretos verificados: top-level, wrapper, `tb_coefficient_input` e `tb_status_flags`.

### Pendências

- Nenhuma pendência arquitetural identificada. Execução de compilação/simulação, inspeção estrutural e `git diff --check`, além de síntese/timing/placa, pertence à implementação e ainda não foi realizada pelo Context Analyst.

### Resultado do Context Analyst

**READY_FOR_IMPLEMENTATION** — DEC-041 e DEC-042 estão em CONSENSUS; clock, reset sincronizado, evento de captura, prioridades, interfaces privadas, callers, arquivos, critérios e testes estão definidos. Nenhuma escolha arquitetural adicional é necessária para iniciar.

### Resultado da implementação

Arquivos modificados:

- `rtl/entrada_coeficientes.v` — core privado exporta `pedido_rearme` e `evento_captura`; wrapper público termina ambos em fios locais, sem alterar suas portas.
- `rtl/modulo_principal.v` — contador estrutural de 24 bits, posição módulo 14, seleção estrutural dos glifos da janela e mux imediato para HEX normais quando `loaded=1`.
- `testbench/tb_top_module.v` — expectativa atualizada para `Insira` no quadro inicial, percorre 14 posições mais o wrap para cada progresso e inclui verificação isolada dos 12.500.000 ciclos nominais.
- `testbench/tb_coefficient_input.v` — callers atualizados e contagem dos três pulsos válidos, confirmando que não há pulso após `loaded=1`.
- `testbench/tb_status_flags.v` — caller direto atualizado.

Ferramentas e evidências:

- `vlog -work /tmp/task024_questa/work rtl/entrada_coeficientes.v rtl/somador_completo.v rtl/somador_subtrator.v rtl/multiplicadores.v rtl/polinomio_y.v rtl/raiz_quadrada_u17.v rtl/divisor_9_por_8.v rtl/raizes_quadraticas.v rtl/seletor_resultado.v rtl/exibicao_decimal.v rtl/sinalizadores_status.v rtl/modulo_principal.v testbench/tb_top_module.v testbench/tb_coefficient_input.v testbench/tb_status_flags.v` — PASS, Questa/Altera Starter vlog 2025.2, zero erros e zero warnings.
- `git diff --check` — PASS.
- Inspeção estática dos RTL alterados — sem ocorrências de `if`, `else`, `buf`, `for`, `generate`, `genvar` ou `assign`; interfaces físicas do top-level e wrapper público preservadas.
- `iverilog -g2012 -Wall ...` — não executado: `iverilog` não está instalado no ambiente.
- Execução alternativa pelo container `hdlc/iverilog:latest` — bloqueada pelo ambiente: acesso ao socket Docker negado.
- `vsim -c -lib /tmp/task024_questa/work -do 'run -all; quit -f' tb_top_module` — bloqueado antes da simulação: licença Questa ausente (`SALT_LICENSE_SERVER` não configurado).
- TEST-001/009/010/011 e a nova cobertura de quadros permanecem sem evidência funcional desta implementação; compilação não foi tratada como simulação.
- Síntese, análise de timing/recursos e validação física não executadas.

Pendência: obter um simulador funcional ou licença Questa para executar os testbenches requeridos; então encaminhar à auditoria independente. Não alegar que a frequência foi validada em placa.

### Resultado da revisão independente — Code Auditor

**BLOCKED** — a auditoria estática não encontrou violação estrutural obrigatória no RTL, mas os critérios de aceite funcionais não podem ser aprovados sem simulação. Questa `vlog` compilou as fontes conforme evidência registrada; isso não executa nenhum testbench. Icarus não está instalado e `vsim` não iniciou por falta de licença. Não há log de simulação ou síntese registrado.

#### Compliance Gate — PASS

- Inspeção dos RTL alterados: sem `if`, `else`, `buf`, loops/generate ou `assign` contínuo; o estado novo usa as primitivas de FF existentes. Não encontrei mudança nas portas físicas do top-level nem nas portas públicas do wrapper.
- As instâncias diretas conhecidas de `entrada_coeficientes_nucleo` (top-level, wrapper e dois testbenches) conectam ou terminam as novas saídas privadas.
- `docs/interfaces.md` foi atualizado pelo Orchestrator na propagação de DEC-041/042 antes da TASK ficar READY; a TASK identifica essa mudança como baseline e proíbe nova edição durante implementação. Considero reconciliada a ressalva de escopo da primeira rodada.

#### Functional Gate — BLOCKED

- A revisão estática conferiu a representação do anel de 14 símbolos, os códigos de glifo ativos baixos e o decodificador combinacional contra a tabela de DEC-041. A lógica observada implementa reset do divisor em `pedido_rearme`, `evento_captura` ou terminal; a posição reinicia no wrap e nos dois eventos e avança no terminal.
- Os testbenches contêm verificações de quadros, wrap, contagem nominal e contagem de pulsos, mas nenhum resultado de execução está disponível. Portanto, não há evidência de que os critérios funcionais passaram.
- **FIND-024-001 — resolvido por cobertura adicionada, ainda sem execução:** `capture_from_mid_animation` em `testbench/tb_top_module.v` coloca a animação em `p=1` com divisor 9 antes de pressionar KEY0; depois do pulso válido verifica `p=0`, divisor zero e progresso `01`, e confirma o sufixo `b` no quadro `p=2`. A inspeção estática confirma que o cenário cobre a lacuna levantada na primeira rodada. A simulação ainda precisa passar.
- **FIND-024-002 — fechado como falso positivo no RTL; oráculo corrigido:** a leitura correta de `segment_1` e `segment_3` mostra que `gsuf_a` ativa `hex[5]` e `hex[1:0]`, não `hex[3]`; portanto gera `7'b0100011` conforme DEC-041. `gsuf_b` ativa `hex[1:0]` e gera `7'b0000011`, também correto. O defeito encontrado estava somente em `codificar_prompt` código 7, que esperava `7'b0001000`; o Implementer corrigiu para `7'b0100011`. Não há finding aberto no decodificador RTL após esta revisão; a cobertura de glifos continua sem resultado de simulação.

#### Integration Gate — PASS estático; execução BLOCKED

- As conexões visíveis preservam os contratos públicos e passam pelas instâncias conhecidas; `loaded` ainda muxa a apresentação normal combinacionalmente.
- `docs/interfaces.md` descreve os novos sinais privados e a apresentação; sua atualização de baseline pelo Orchestrator foi registrada na TASK antes do estado READY.
- Sem simulação, a compatibilidade temporal integrada, transição imediata para HEX normal e os efeitos reais em todos os callers não foram demonstrados.

#### Evidência e ação para desbloqueio

- Artefatos de compilação de `vlog` estão em `/tmp/task024_questa/work`; a TASK registra o comando e o resultado `PASS`, zero warnings. O diretório não contém transcript bruto do compilador.
- Os bloqueios de Icarus, Docker e licença Questa estão registrados na seção de ferramentas. Nenhuma simulação funcional, síntese, análise de timing ou validação física foi executada/observada nesta auditoria.
- Manter `BLOCKED` até que os testbenches obrigatórios sejam executados e passem. A cobertura do reinício por captura foi corrigida source-level, e o escopo documental está reconciliado; nenhuma dessas verificações substitui simulação.

Histórico:

- 2026-10-14 — implementação estrutural concluída e compilada sem erros/warnings em Questa vlog 2025.2; TASK bloqueada para simulação funcional devido à indisponibilidade de licença/ferramenta no ambiente.
- 2026-10-14 — Code Auditor ciclo 1 concluiu gates estáticos, manteve TASK BLOCKED e registrou gaps de cobertura e de oracle; a divergência documental foi reconciliada como baseline do Orchestrator.
- 2026-10-14 — Code Auditor ciclo 2 confirmou source-level as correções de cobertura e do oráculo; sem simulação funcional, a TASK permanece BLOCKED.

### Rework dos findings — Code Implementer

- **FIND-024-001:** `tb_top_module` agora força um avanço até `p=1`, deixa o divisor em 9, provoca uma captura válida e verifica no ciclo de captura que posição e divisor voltam a zero e o progresso muda para `01`. Depois verifica o sufixo `b` em HEX0 no quadro `p=2`, e retorna a posição a zero antes de continuar a cobertura dos quadros.
- **FIND-024-002:** `codificar_prompt` agora espera `7'b0100011` para o código do sufixo `a`. A inspeção das conexões do decoder confirma `gsuf_a` nos bits HEX5, HEX1 e HEX0, sem termo em HEX3, portanto o RTL atual já resulta em `0100011`; não alterei essa rede porque adicionar HEX3 produziria o padrão incorreto `0101011`. A varredura dos 14 quadros testa o sufixo `a` contra a tabela corrigida quando executada.
- Recompilação com `vlog` Questa/Altera Starter 2025.2 usando a lista de fontes acima — PASS, 0 erros e 0 warnings.
- Verificação source-level das dez linhas de glifo contra DEC-041 — PASS; `gsuf_a=0100011`. Este assert de conexões não substitui simulação.
- `git diff --check` — PASS.
- A simulação permanece indisponível por ausência de licença Questa; não atribuo PASS funcional aos novos casos.

Status permanece **BLOCKED** até a execução real dos testbenches e revisão independente dos findings corrigidos.
