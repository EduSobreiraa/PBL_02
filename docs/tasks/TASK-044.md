# TASK-044 — Pré-calcular, armazenar e renderizar as 640 colunas

## Objetivo

Substituir o cálculo durante a varredura por pré-cálculo sequencial das 640 colunas, armazenamento da palavra lógica por coluna e leitura alinhada com o raster para plotagem.

## Status

APPROVED — P2 mínimo medido; full-frame, reinício do top, compilação Quartus, agregador pós-P2 e auditoria independente passaram.

## Decisões relacionadas

- DEC-065 (contrato do pipeline/RAM; status histórico ESCALATE, findings técnicos conciliados em DEC-068).
- DEC-068 (CONSENSUS): payload lógico de 41 bits e cálculo completo até igualdade/clipping.
- DEC-070 (CONSENSUS): usar biblioteca oficial `altera_mf.v` em simulação Icarus; sem modelo Verilog custom; parâmetros/ports corrigidos; tentar runner Verilator real.
- DEC-066 (CONSENSUS): `frame_ready`, BUSY/DONE e liberação da composição.
- DEC-067 (CONSENSUS): coordenadas do quadro e prioridade de máscara.

## Escopo preliminar

- Processar x de −320 a 319 uma vez por execução, em ordem e com throughput de uma coluna por ciclo após enchimento do pipeline.
- Gravar os quatro y signed9, quatro flags de validade e `intersection_hit` em 640 endereços.
- Usar RAM estrutural single-port e alinhar saída síncrona a x/y, `video_on`, `p_tick` e HS/VS, sem editar `vendor/vga/vga_sync.v`.
- Integrar `frame_ready` com reset, START, BUSY/DONE e as duas funções; esconder a tabela antiga/incompleta até o frame atual estar pronto.
- Vincular a megafunção oficial `altera_mf.v` nos runners de simulação, sem copiar a biblioteca para o repositório e sem incluir no QSF/manifesto FPGA.
- Remover `sim/models/altsyncram_m9k_model.v` e o diretório `sim/models/` se ficar vazio.

## Critérios preliminares

- Comparar f1/f2 completos antes da conversão/clipping; nunca criar hits por truncamento.
- Provar escrita ordenada e única nos 640 endereços, flags, clipping, F2 desabilitada/inválida, interseção, leitura de um ciclo e alinhamento raster.
- Medir pipeline P, recursos, Fitter e os paths de timing aplicáveis no Quartus; não declarar aprovação física.

## Implementation Brief

### Objetivo

Gerar o frame matemático antes de habilitar sua exibição: alimentar x = −320…319 em ordem, calcular os quatro resultados, comparar igualdade sobre f1/f2 completos antes de pixelizar, gravar 640 palavras lógicas em RAM de bloco e ler uma coluna por ciclo durante o raster.

### Requisitos

- `REGRAS.md` §§2, 4–7, 8 e 10.
- Resolução 640×480, x cartesiano signed10, f signed25, derivada signed18, clipping vertical −239…240.
- F1/F2, derivadas, validação independente e F2 nula/inválida conforme contratos existentes.
- `vga_sync.v` imutável; alinhamento de RGB, `video_on`, `p_tick`, HS/VS e coordenadas.

### Decisões aplicáveis

- DEC-065 (histórico): tabela por coluna, RAM single-port, `frame_ready`, throughput de uma coluna por ciclo, P como menor pipeline que fecha FF→FF ≤20 ns, sem exceções de timing; contrato restante desta DEC continua aplicável.
- DEC-068 (CONSENSUS): payload lógico e igualdade/clipping completos antes de gravação.
- DEC-070 (CONSENSUS): interface real da RAM Quartus, binding oficial Icarus e tentativa obrigatória do runner Verilator real.
- DEC-066 (CONSENSUS): reset/START, `frame_ready`, BUSY/DONE e ocultação até o frame atual.
- DEC-067 (CONSENSUS): coordenadas arredondadas/raízes e janela do quadro informativo.
- DEC-054/053: 40 ns para RGB e polaridade/fase VGA pública vigentes.

### Módulos/callers envolvidos

- `top_pbl03`: caller de entrada, controladores, dois `processador_f1`, preparação, tabela, renderizadores e compositor.
- `processador_f1`/`datapath_f1`/avaliadores/detector de hits: usar a mesma lógica aritmética para x de preparação; preservar validação e retornos de coeficientes.
- Novos módulos privados de índice/geração de x, atraso de tokens, banco RAM e seleção de hit por y; incluir DFF estrutural dedicado somente se necessário.
- `fsm_principal_pbl03`: BUSY/DONE só concluem após frame pronto e dados auxiliares da execução atual.
- `compositor_rgb` e sincronismos externos ao vendor: consumir a palavra síncrona da coluna e atrasar o restante do raster exatamente um ciclo.

### Interface e largura

- Manter inalterados todos os ports públicos do `top_pbl03` e do VGA do professor.
- Interface lógica do wrapper RAM conforme DEC-065: `clk`; `write_enable`; `write_address[9:0]`; `write_data[40:0]`; `read_address[9:0]`; `read_data[40:0]`. A RAM seleciona endereço de escrita ou leitura pelo modo; não permitir leitura durante preparação nem escrita durante exibição.
- Cada `altsyncram` do wrapper usa somente parâmetros oficiais: `operation_mode("SINGLE_PORT")`, `width_a(18/9)`, `widthad_a(10)`, `numwords_a(640)`, `width_byteena_a(1)`, `outdata_reg_a("CLOCK0")`, `ram_block_type("M9K")`, `power_up_uninitialized("TRUE")`, `intended_device_family("MAX 10")`. Remover `address_reg_a`; conectar `byteena_a(1'b1)` e `addressstall_a(1'b0)`; manter demais portas/enables definidos conforme DEC-070.
- `write_data[40:0] = {y_f1[8:0], y_df1[8:0], y_f2[8:0], y_df2[8:0], valid_f1, valid_df1, valid_f2, valid_df2, intersection_hit}`. Campos y são signed9; quando invalid, gravar zero no campo correspondente.
- Armazenamento físico: bancos 18,18,9 bits, cada um com 640 palavras e endereço comum. Os quatro bits de padding no banco final são zero/ignorados e não compõem o payload lógico.
- Token de cálculo: índice 0…639, x correspondente −320…319, valid. Dados, índice, valid, flags e igualdade atravessam P estágios em cadência alinhada; throughput 1 coluna/ciclo sem bubbles. P é selecionado após medição Quartus e registrado com cortes de pipeline e worst setup path.
- Funções matemáticas completas: f signed25, f′ signed18; clipping e igualdade antes da conversão y signed9. `intersection_hit=1` somente para f1/f2 válidas/habilitadas, completos iguais e y comum visível.
- `frame_ready` é sticky, invalidado por KEY1/reset ou START aceito; sobe só após os 640 writes ordenados/únicos (inclusive funções inválidas/desabilitadas), pipeline drenado, flags/resultados estáveis e roots/vértices atuais prontos. BUSY mantém alto até então. DONE usado pelos LEDs e handshake permanece baixo durante preparação; só sobe quando frame/results estão prontos e o início do próximo frame ativo impede exibição parcial.

### Clock e reset

- `MAX10_CLK1_50`, borda positiva a 50 MHz; sem novo clock derivado.
- KEY1 conserva reset síncrono interno para equipe e reset existente do VGA; `frame_ready` invalida com reset e START aceito.
- RAM não precisa ser zerada: não consumir seu conteúdo enquanto `frame_ready=0`, sobrescrever todos os 640 endereços antes de reabilitar exibição.

### Restrições

- DUT sintetizável segue `REGRAS.md`: estrutural fora de FF/FSM; sem `assign`, `buf`, `for`, `generate`, arrays/inferência comportamental de memória ou `always` combinacional. Aritmética deve manter módulos estruturais e larguras aprovadas.
- A simulação da RAM usa a biblioteca oficial Quartus `altera_mf.v`, localizada pelo runner: se `ALTERA_MF_V` estiver definido, ele aponta ao arquivo; caso contrário, `QUARTUS_ROOTDIR` deve apontar à raiz `quartus/` e o caminho será `$QUARTUS_ROOTDIR/eda/sim_lib/altera_mf.v`. Se nenhum caminho legível existir, falhar com mensagem clara. Não copiar, editar, baixar nem versionar a biblioteca.
- No container Docker, montar explicitamente a localização externa de `altera_mf.v` e propagar `ALTERA_MF_V` para o caminho montado ou propagar `QUARTUS_ROOTDIR` quando a instalação inteira estiver montada; a variável host não pode apontar a um path invisível ao container.
- Não criar nem manter modelo Verilog custom de `altsyncram`; não mascarar/editar o modelo oficial. O modelo não entra em QSF/manifesto.
- Sem multicycle/false-path para cálculo, escrita RAM ou display; não enfraquecer os limites de 20 ns FF→FF e 40 ns VGA.
- Preservar `vendor/vga/vga_sync.v` byte a byte, pinos, resolução, origem, escala e interfaces públicas.

### Arquivos permitidos

- `rtl/top/top_pbl03.v`, `rtl/controle/fsm_principal_pbl03.v`.
- Novos RTL de pré-cálculo/RAM em `rtl/funcao/`, `rtl/primitivos/` e `rtl/aritmetica/` quando necessários; adaptadores em `rtl/funcao/processador_f1.v`, datapath/avaliadores/hits somente para inserir o x de cálculo sem duplicar funções.
- `rtl/video/compositor_rgb.v`, `rtl/video/coordenadas_cartesianas.v` e módulos de renderização somente para consumir os dados da tabela alinhados ao raster.
- `quartus/pbl03.qsf` apenas para incluir RTL novo; sem alteração de pinagem ou SDC.
- `sim/models/altsyncram_m9k_model.v` deve ser removido; são permitidos testbenches/runners necessários aos gates definidos nesta TASK: RAM, pipeline e full-frame Icarus/VPI, integração top de reset/START após DONE, seus auxiliares VPI e `sim/resolve_altera_mf.sh`; `sim/run_coordinate_framebuffer_icarus.sh`, `sim/run_pbl03_top_verilator.sh`, `sim/run_pbl03_regression.sh` e `sim/pbl03_top_verilator.cpp` podem ser atualizados. Esses ativos são somente de simulação e não entram na lista de fontes FPGA.
- `sim/models/` somente pode permanecer se contiver outro arquivo necessário não relacionado ao binding RAM; se vazio, removê-lo.
- O runner resolve `altsyncram_v` nesta ordem: `ALTERA_MF_V` se definido; senão `$QUARTUS_ROOTDIR/eda/sim_lib/altera_mf.v`. Exige `[ -r "$altsyncram_v" ]`, senão encerra com instrução de configuração. Compila com `iverilog -g2005 -s tb_coordinate_framebuffer -o "$build_dir/coordinate_framebuffer.vvp" "$altsyncram_v" <fontes RTL necessárias> <testbench>` e executa `vvp "$build_dir/coordinate_framebuffer.vvp"`; a lista contém o wrapper RTL real, nunca substituído pelo vendor model.
- `verification/results/task-044/**`, `docs/tasks/TASK-044.md`, `docs/planejamento-pbl03.md`.

### Arquivos protegidos

- `vendor/vga/**`, `quartus/pbl03.sdc`, `quartus/pbl03.qpf`, `quartus/pbl02.*`, pin assignments, ports públicos do top, arquivos legados fora da lista ativa.
- Modelos de simulação não entram em QSF, manifesto FPGA ou fontes sintetizáveis.

### Testes exigidos

- Modelo RAM standalone em Icarus ligado ao `altera_mf.v` oficial: três larguras físicas, writes nos endereços 0…639, leitura registrada de um ciclo, retenção de `q` com `rden_a=0`, endereços extremos e comparação exata das 640 palavras.
- Teste de pipeline: emitir índices consecutivos 0…639; provar alinhamento índice/x/results/flags/igualdade para P, throughput sem bubbles, first/last write na borda prescrita, drenagem e rejeição de fora de ordem/duplicatas.
- Referência independente signed matemática para f/f′/clipping/igualdade, incluindo negativos, extremos, results fora da tela sem wrap, derivadas, igualdade antes de pixelizar e parábolas coincidentes.
- Integração top: entrada/START, KEY1 em exibição e durante preparação, frame antigo oculto, 640 writes, BUSY/DONE/handshake, F1/F2 inválidas, F2 nula, roots_ready, nenhum frame parcial.
- Captura end-to-end Icarus/VPI de pelo menos um frame completo 800×525 com a biblioteca oficial: alinhamento de RGB, vídeo ativo/blanking, HS/VS e p_tick após a latência síncrona; manter overlays DEC-066/067 alinhados e registrar runtime real.
- Tentar o runner Verilator real do top com a biblioteca oficial e as flags atuais; registrar comando, status de saída e log. Não inferir o resultado do probe `--lint-only`; se o runner real falhar, usar a regressão Icarus/VPI como backend funcional end-to-end, sem declarar Verilator aprovado.
- `sim/run_pbl03_regression.sh`, source/manifest check, tentativa do runner Verilator real, captura Icarus/VPI, compilação Quartus, Fitter e TimeQuest final; registrar P/cortes, uso M9K/LE e todos os 14 endpoints de saída sob 40 ns, além dos piores paths FF→FF sob 20 ns. Se Quartus/licença ou hardware indisponíveis, registrar o gate não executado, sem aprovar fechamento físico.

### Casos de borda

- Colunas 0 e 639; x −320 e 319; y −239, 240 e exatamente fora de ambas as bordas.
- F1/F2 independentes válida/inválida, `a=0`, F2 nula; `f1=f2`, valores distintos que arredondariam ao mesmo pixel, derivadas coincidentes sem interseção de função.
- START/KEY1 antes da primeira escrita, durante pipeline, após endereço 639 e durante exibição; roots prontos/desabilitados e `frame_ready` sticky só para execução atual.
- Leitura durante blanking, limites do raster, primeiro pixel ativo e transição de frame, com atraso de um ciclo sem desalinhamento ou wrap.

### Critérios de aceite

- Payload e outputs RAM correspondem bit a bit a referência independente para todas as 640 colunas.
- O gráfico nunca lê dados antigos/parciais; `frame_ready`, BUSY, DONE, sinais RGB e auxiliaries pertencem à mesma execução.
- Frame completo e sobreposições corretos; video blanking e sinais públicos preservam a temporização/fase aprovada.
- Sintaxe/manifestos passam, periférico mantém hash original, regressões e Quartus são documentados com resultados reais.
- P é o menor valor medido que fecha FF→FF ≤20 ns; todos os 14 endpoints VGA fecham ≤40 ns sem exceções mascaradoras. Sem evidência, a TASK permanece TESTING/BLOCKED, não APPROVED.

### Dependências

- DEC-065/068/066/067 e portas/intermediários atuais de `top_pbl03`/`processador_f1`.
- Gate técnico de compilação do `altsyncram` no Quartus; se o primitivo não resolver, voltar ao Decision Workflow sem adicionar IP/QIP por conta própria.
- TASK-042 e TASK-043 são baselines de sincronismo e timing; gerar evidências novas desta revisão.
- Icarus exige `ALTERA_MF_V` legível ou `QUARTUS_ROOTDIR` com `eda/sim_lib/altera_mf.v`; no container, a montagem deve tornar esse mesmo arquivo visível.

### Pendências

- Não há decisão funcional aberta para o payload; resultados reais de mapeamento, P/timing e hardware permanecem evidência de implementação.

**Estado após revisão de DEC-070: READY_FOR_IMPLEMENTATION.** O bloqueio anterior ficou resolvido pelo binding oficial e pela atualização deste brief.

## Registro de execução — 2026-11-24

### Status na ocasião deste registro (antes de DEC-070)

`BLOCKED` naquele momento. Este é um registro histórico da implementação parcial; o bloqueio foi resolvido por DEC-070 e o brief acima reabre a TASK em `READY`.

### Evidência do bloqueio

- Foi tentada a elaboração Icarus do wrapper `rtl/funcao/coordinate_frame_ram.v` usando o modelo oficial instalado em `.../quartus/eda/sim_lib/altera_mf.v` (Quartus Lite 25.1 Standard). A compilação rejeitou os parâmetros `address_reg_a`, `address_reg_b` e `rdaddress_reg_a` usados pelo wrapper, reportando `parameter ... not found` nas linhas 18–20 do wrapper.
- Inspeção do `altsyncram` no modelo oficial confirmou que a interface publicada inclui `address_reg_b`, mas não `address_reg_a` nem `rdaddress_reg_a`. Portanto, o contrato de parâmetros descrito em DEC-065 não pode ser compilado literalmente contra esta biblioteca oficial instalada.
- O modelo custom em `sim/models/altsyncram_m9k_model.v` contém comportamento Verilog (`always`/condicionais/armazenamento) e não foi aceito como solução: as regras atuais não trazem uma exceção para `sim/models/*.v`. Ele não deve ser tratado como conforme até decisão explícita.

### Progresso preservado, ainda não validado

Foram adicionados o gerador de frame, formatador de payload, wrapper RAM, detector de hits e registradores auxiliares; houve integração preliminar no top, inclusão de fontes e criação de runner/testbench da RAM. Esses arquivos permanecem sujeitos à revisão após DEC-070. Os resultados funcionais e de timing exigidos nesta TASK ainda não foram obtidos.

### Verificações já executadas

- `python3 verification/check_pbl03_sources.py` — passou antes do bloqueio, verificando o manifesto de fontes.
- Elaboração Icarus com `altera_mf.v` oficial — falhou pelo contrato de parâmetros incompatível descrito acima.
- Regressão RAM/pipeline/top e compilação, Fitter e TimeQuest do Quartus — não executados após a identificação do bloqueio. Não há alegação de aprovação de síntese, timing ou hardware.

### Resolução

DEC-070 alcançou CONSENSUS: usar binding externo oficial `altera_mf.v`, retirar o modelo custom e corrigir parâmetros/ports. Retomar a implementação e executar os gates definidos no Implementation Brief. O comando e resultado de elaboração anteriores permanecem evidência histórica do bloqueio, não da versão corrigida.

## Execução após DEC-070 — 2026-11-24

### Implementação em teste

- P mínimo medido: P1, com matemática combinacional e apenas FF de saída payload/address/valid, falhou setup em `−4,888 ns`; P2 foi adotado após passar Quartus com setup `+1,084 ns`. No P2, o primeiro estágio registra os termos parciais `x²`, `ax`, `bx`, sinais e coeficientes; a matemática final, formatador e registro do payload formam o segundo estágio. `issue_index` e `issue_valid` atravessam dois estágios, mantendo um token por ciclo.
- A unidade P2 tem latência observável de um ciclo entre amostragem de entrada e saída; a borda de captura do payload e o endereço/valid do estágio 2 escrevem o mesmo token na RAM na borda seguinte. O teste do pipeline e o full-frame final devem provar esse alinhamento.
- As entradas raster do datapath auxiliar de `processador_f1` ficam constantes no top porque seus hits/valores pontuais deixaram de ser usados após TASK-044; a plotagem vem apenas da tabela. Erros e numeradores/denominadores do vértice continuam recebendo os coeficientes atuais.
- O FSM de frame permanece em `DRAIN_PIPELINE` até observar `staged_write_valid && staged_frame_address == 639`. A RAM consome essa palavra na mesma borda; `frame_ready` fica alto após essa borda, depois da gravação do endereço 639.
- A asserção do full-frame foi movida do pixel `(330,220)`, sobreposto pelo rótulo da raiz, para `(370,140)` (coordenada cartesiana `(50,100)`), onde a derivada deve aparecer cyan. Debug top confirmou no ponto antigo `payload df1=20`, `df1_hit=1`, `root_label_hit=1`, `RGB=f80`; no ponto novo confirmou `df1_hit=1`, sem marcador/rótulo e `RGB=0ff`.
- O TB full-frame usa clock/assertions Verilog nativos (`case`, sem `if/else`) e imprime progresso a cada 200k ciclos. Em cada uma das 640 escritas, calcula uma referência inteira independente para `f1=f2=x²+10`, `f′=2x`, clipping e igualdade, e compara os 41 bits com o payload gravado. O plugin VPI acompanha a conclusão do frame e exige `write_count=640`. A primeira captura corrigida completou um frame 800×525 em 4305 s; a captura final P2 completou em 2059 s.

### Testes e resultados reais

- `python3 verification/check_pbl03_sources.py` — PASS.
- `git diff --check` — PASS.
- `sim/run_coordinate_frame_function_pipeline_icarus.sh` com Icarus e a biblioteca oficial — PASS no P2: latência observável de um ciclo, throughput 1/ciclo, negativos e extremos signed. Os quatro ciclos pertenciam ao corte P5 anterior e não descrevem a implementação atual.
- `sim/run_coordinate_framebuffer_icarus.sh` com biblioteca oficial — PASS: 640 writes/reads, payload de 41 bits, leitura síncrona e retenção de `q`.
- `sim/run_f1_processor_icarus.sh` — PASS: 118 ciclos; elaboração de `top_pbl03` PASS.
- `sim/run_f1_f2_processors_icarus.sh` — PASS: 25 ciclos; elaboração de `top_pbl03` PASS.
- `sim/run_main_handshake_pbl03_icarus.sh` — PASS; elaboração de `top_pbl03` PASS.
- `sim/run_status_errors_pbl03_icarus.sh` — PASS após alinhar a expectativa aos erros previamente retidos durante BUSY e ao DONE postergado; testes isolados cobrem as combinações de status/HEX.
- `sim/run_video_axes_icarus.sh` — após o fix do compositor, exit 0; `VPI PASS: all 284 video composition cases passed`, incluindo uma flag de interseção sem hit vertical e interseção magenta com hit; elaboração do top pela lista QSF também passou.
- `sim/run_frame_reset_pbl03_icarus.sh` — PASS em Icarus com `altera_mf.v` oficial. No top real, capturou coeficientes e verificou 640 writes, frame_ready/DONE e pixel magenta (330,130); KEY1 em DISPLAY limpou frame_ready/BUSY/DONE e tornou RGB preto. Após nova entrada e novo frame, START real em DISPLAY também limpou o frame antigo, manteve RGB preto e iniciou BUSY. Timeout de 120 s; runtime observado abaixo de 10 s, sem warnings fora das coerções/padding oficiais de RAM.
- Compilação C do plugin VPI com `gcc -std=c99 -Wall -Wextra -Werror -fPIC -shared` e elaboração Icarus do TB full-frame atualizado — PASS; warnings da biblioteca oficial são as coerções inout e o padding físico de 9→5 bits já registrados.
- Runner Verilator real com `hdlc/verilator:latest` e a biblioteca oficial `altera_mf.v` — exit 1. Verilator 5.053 rejeitou a lógica interna do modelo oficial como loop combinacional em `altera_mf.v:49239` (`i_good_to_write_a2 = i_good_to_write_a`). Houve warnings de pinos B não conectados e larguras, separados desse erro.
- Full-frame Icarus/VPI após o fix do compositor — PASS; 840000 ciclos, 614400 active samples, 307200 active ticks, 100800 HS-low, 3200 VS-low; verificou origem cyan, interseção magenta, pixel fora da curva preto na mesma coluna e derivada cyan.
- Teste integrado adicional de KEY1/START no display — PASS; duas preparações de 640 colunas; termina em `FRAME RESET PASS: KEY1 in DISPLAY1 and START in DISPLAY2 cleared/masked old frame after 640 writes`; `$finish` em `31611000`. Sem varrer um frame completo. Force limitado a alinhar h/v na borda de frame real após pixel tick natural e, depois de DONE, manter h/v=(330,130)/pixel_reg=0 para leitura síncrona de pixel; nenhum sinal de controle, RAM, status ou RGB foi forçado.

### Gates finais

- Quartus/Fitter/TimeQuest P2 final após fixar as entradas do datapath auxiliar — PASS: full compile 0 erros/40 warnings, setup `+1,084 ns`, hold `+0,242 ns`, Fmax `52,87 MHz`, 9.072 LEs, 1.233 registradores e 16 M9K. Paths VGA: 14/14 sem violação, pior slack `+6,128 ns`. Relatórios reais em `verification/results/task-044/pipeline-p2-final.fit.rpt`, `pipeline-p2-final.sta.rpt` e `pipeline-p2-vga-outputs.rpt`.
- `sim/run_frame_reset_pbl03_icarus.sh` — PASS repetido no P2 adotado; top real verifica KEY1 em DISPLAY1 e START em DISPLAY2 após duas preparações de 640 colunas.
- Full-frame Icarus/VPI pós-P2 — PASS em 2.059 s, com comparação independente de todas as 640 palavras e raster/sincronismos completos, conforme resultado detalhado acima.
- Tentativa Verilator real após P2 — FAIL conhecido da ferramenta/modelo oficial: Verilator 5.053 reporta loop combinacional em `altera_mf.v:49239` (`i_good_to_write_a2 = i_good_to_write_a`). O gate funcional Icarus/VPI passou.

Status da implementação: `APPROVED`.

## Auditoria independente — 2026-11-24

**Resultado final: APPROVED.** A variante P1 falhou e P2 passou Quartus, documentando o menor corte medido. Full-frame, reinício top, Quartus e agregador pós-P2 passaram no corte P2 final.

### Finding FIND-044-AUD-001 — expectativa de eixo na origem (resolvida no TB)

- **Arquivo/localização:** `sim/tb_coordinate_framebuffer_full.v:137-142`.
- **Severidade:** MEDIUM (histórico; corrigido no TB atual).
- **Problema:** o primeiro TB exigia branco no pixel de origem `(320,240)`, mas a fixture usa `f1=f2=x²+10`; em `x=0`, ambas as derivadas valem zero e coincidem com o eixo horizontal. A prioridade aprovada coloca curvas acima dos eixos, então a cor correta após corrigir o defeito de interseção abaixo é ciano para `f1′`.
- **Evidência/correção:** o TB atual exige ciano em `(320,240)` e branco no eixo vertical `(320,250)`, pixel fora dos hits de curva para essa fixture. Ambos passaram na captura full-frame de 2026-11-24.

### Finding FIND-044-AUD-002 — interseção aplicada à coluna inteira

- **Severidade:** HIGH.
- **Arquivo/localização:** `rtl/video/compositor_rgb.v:2469`; caller em `rtl/top/top_pbl03.v:220`.
- **Problema:** `intersection_hit` representa a igualdade de f₁/f₂ da coluna e é armazenado por endereço. O compositor originalmente fazia `pixel_intersection = processing_done && intersection_hit`, sem exigir que o y do pixel fosse o y comum das funções. Assim, uma coluna em que as funções coincidem ficava toda magenta, em vez de destacar somente o ponto da curva.
- **Requisito/regra relacionada:** DEC-068 define `intersection_hit` por coluna somente quando f₁/f₂ completos são iguais e o y comum é visível; REGRAS.md §8 exige destaque dos pontos de interseção com prioridade sobre curvas. A posição vertical ainda deve corresponder aos dados armazenados e aos hits por y.
- **Evidência:** no TB, `f1=f2=x²+10`. Em `x=0`, a coluna tem interseção válida em y=10, mas a origem y=0 pertence às derivadas. A captura integral anterior falhou no sample da origem após verificar 640 escritas e a derivada cyan.
- **Correção aplicada:** `pixel_intersection` agora exige `processing_done && intersection_hit && f1_hit`, limitando o destaque ao y real da curva. A comparação matemática completa continua antes do clipping na flag gravada na RAM.
- **Cobertura:** o TB full-frame exige cyan na origem `(320,240)`, magenta no ponto da interseção `(330,130)`, preto no pixel fora da curva mas na mesma coluna `(330,131)`, e branco no eixo vertical sem sobreposição `(320,250)`. `sim/run_video_axes_icarus.sh` passou 284 casos, incluindo interseção sem f1 hit não colorida.

**Estado de FIND-044-AUD-002:** corrigido e verificado por `run_video_axes_icarus.sh` e pela captura full-frame completa.

### Finding FIND-044-AUD-003 — falta de teste de reinício do top após DONE

- **Severidade:** MEDIUM.
- **Arquivos/localização:** `sim/main_handshake_pbl03_vpi.c` e `sim/tb_coordinate_framebuffer_full.v`.
- **Problema inicial:** os testes exercitavam DONE/START/reset na FSM de forma isolada e a captura full-frame provava uma execução completa, sem reiniciar o top já em DISPLAY.
- **Requisito/regra relacionada:** TASK-044 — integração top exige KEY1 em exibição, frame anterior oculto e reset/START invalidando `frame_ready`; DEC-066/DEC-065 exigem que apenas a execução atual apareça.
- **Evidência/correção:** `sim/run_frame_reset_pbl03_icarus.sh` passou no top real. O teste monta dois frames com 640 writes cada; em DISPLAY1, KEY1 síncrono limpa `frame_ready`, BUSY/DONE e mascara RGB para preto; após uma segunda preparação, START real em DISPLAY2 também limpa `frame_ready`/DONE, ativa BUSY e mantém preto enquanto a nova tabela está sendo preparada. Saída literal: `FRAME RESET PASS: KEY1 in DISPLAY1 and START in DISPLAY2 cleared/masked old frame after 640 writes`; `$finish` em `31611000`.

**Estado de FIND-044-AUD-003:** corrigido e verificado pela regressão top pós-DONE.

### Finding FIND-044-AUD-004 — P mínimo não demonstrado (resolvido por medição)

- **Severidade:** MEDIUM.
- **Arquivos/localização:** `rtl/funcao/coordinate_frame_function_pipeline.v`; relatório Quartus `quartus/output_files_pbl03/pbl03.sta.rpt`.
- **Problema inicial:** antes da medição comparativa, não havia evidência de P mínimo. Este finding foi fechado com as medições P1/P2 reportadas pelo Orchestrator.
- **Requisito/regra relacionada:** DEC-065 §§105/130/181 e TASK-044 critérios de aceite: escolher/registrar o menor P medido que fecha ≤20 ns, sem multicycle/false-path.
- **Evidência/correção:** em cópias isoladas, P1 falhou setup (`−4,888 ns`) e P2 passou (`+1,084 ns`, hold `+0,242 ns`, Fmax `52,87 MHz`, 14/14 endpoints RGB sob limite, pior `+6,128 ns`). O RTL usa P2; o TB do pipeline passou com latência observável de um ciclo e throughput 1/ciclo. Full-frame, teste de reinício top e Quartus do top final passaram após a adoção de P2; recursos finais: 9.072 LE, 1.233 registradores e 16 M9K.

### Gates registrados na auditoria

- Quartus/Fitter/TimeQuest após o pipeline, antes do fix do compositor — PASS reportado pelo Orchestrator: 0 erros; setup slack `+0,731 ns`; hold slack `+0,236 ns`; Fmax `51,9 MHz`; 14/14 endpoints RGB sem violação (pior slack `+5,167 ns`); 9.287 LE, 1.606 registradores e 16 M9K.
- Quartus/Fitter/TimeQuest após o fix do compositor — PASS reportado pelo Orchestrator: 0 erros; setup slack `+0,202 ns`; hold slack `+0,240 ns`; Fmax `50,51 MHz`; 14/14 endpoints RGB sem violação (pior slack `+4,748 ns`); 9.262 LE, 1.606 registradores e 16 M9K.
- Full-frame Icarus/VPI atualizado antes do finding 002 — FAIL no sample da origem. O teste verificou payload independente das 640 escritas, DONE no pixel alinhado e derivada ciano em `(370,140)` antes da falha; não concluiu os 800×525 nem produziu PASS final.
- Full-frame Icarus/VPI após corrigir finding 002 — PASS. Saída literal: `FULL FRAME PASS: 840000 cycles, 614400 active samples, 307200 active ticks, 100800 HS-low, 3200 VS-low; axis/intersection/df1 pixels aligned`; `VPI PASS: native TB completed one full 800x525 raster after all 640 oracle-checked writes`; `$finish` em `33600172000`; runtime `4305 s` (71 min 45 s). Os 640 writes passaram pelo oracle independente e em ordem; amostras de origin cyan, interseção magenta em `(330,130)`, fora da curva preto em `(330,131)` e derivada cyan passaram.
- Repetição final pós-migração para P2 e com entradas x/y do processador auxiliar fixas — PASS, 2026-11-24. Saída: `FULL FRAME PASS: 840000 cycles, 614400 active samples, 307200 active ticks, 100800 HS-low, 3200 VS-low; axis/intersection/df1 pixels aligned`; `VPI PASS: native TB completed one full 800x525 raster after all 640 oracle-checked writes`; runtime `2059 s`. O testbench comparou independentemente todas as 640 palavras e verificou pixels de origem, eixo, interseção, ponto fora da curva na mesma coluna e derivada.
- Restart KEY1/START em DISPLAY no top após migração para P2 — PASS, conforme FIND-044-AUD-003.
- Variante P1 — FAIL setup `−4,888 ns`; P2 — PASS Quartus conforme acima, escolhido como menor P medido. Pipeline unitário, reinício top e captura full-frame end-to-end após adoção de P2 — PASS.
- Runner Verilator real — FAIL documentado: Verilator 5.053 rejeita o self-loop em `altera_mf.v:49239` (`i_good_to_write_a2 = i_good_to_write_a`). Não conta como aprovação do gate Verilator; Icarus/VPI é o backend funcional requerido.
- `ALTERA_MF_V=/home/edupires/altera_lite/25.1std/quartus/eda/sim_lib/altera_mf.v bash sim/run_pbl03_regression.sh` — agregador pós-P2 PASS, exit 0, em 2026-11-24: todos os runners Icarus passaram, incluindo full-frame, e source check final passou. O relatório separa explicitamente o runner Verilator como `UNSUPPORTED_OFFICIAL_ALTERA_MODEL_LOOP`, sem declará-lo aprovado. Log: `verification/results/task-036/regression-20261124T232151Z.log`; manifesto: `verification/results/task-036/tree-manifest-20261124T232151Z.sha256`.
- Compliance estática revisada — datapaths/pipeline, formatador, wrapper RAM, FSM de frame, reset/START, manifesto/QSF e testbench não apresentaram outros findings. A porta identidade antes observada em `coordinate_frame_hits` foi removida; `intersection_hit` segue conectado diretamente a `frame_read_data[0]` no top e é qualificado por `f1_hit` no compositor.

**Resultado final da auditoria independente: APPROVED.** Os datapaths/larguras, alinhamento P2/payload/RAM, FSM de preparação, reset/START, clipping/interseção, compositor, QSF/manifesto e fontes permitidas foram revisados. Os findings registrados foram corrigidos e seus gates passaram. O agregador pós-P2 saiu com exit 0; Verilator real ficou marcado `UNSUPPORTED_OFFICIAL_ALTERA_MODEL_LOOP` por causa do self-loop conhecido da biblioteca Quartus oficial, sem declarar esse backend aprovado. Icarus/VPI forneceu a validação funcional end-to-end.
