# TASK-046 — Quadro VGA de raízes e vértices

## Objetivo

Renderizar no canto inferior direito as raízes reais e coordenadas arredondadas dos vértices de F1/F2, identificações e swatches correspondentes às cores distintas.

## Status

APPROVED — rework DEC-071 implementado, verificado e aprovado em auditoria independente. Source-check, regressão agregada com full-frame e Quartus/TimeQuest passaram. O runner Verilator não suporta o self-loop interno do modelo oficial `altera_mf.v` e foi marcado como bloqueado, com Icarus/VPI como backend funcional. A validação física em placa/monitor permanece pendente. TASK-044 e TASK-045 estão APPROVED.

## Decisões relacionadas

- DEC-067 (CONSENSUS): retângulo, conteúdo, valores, cores, casos `N/A`/`OFF` e prioridade sobre hits coincidentes.
- DEC-066 (CONSENSUS): quadro oculto enquanto a mensagem de entrada está ativa.
- DEC-068 (CONSENSUS): coordenadas do raster e frame atual só ficam disponíveis após preparação.
- DEC-069 (CONSENSUS): interface da ROM, IDs de glifos, layout do quadro e saídas retidas de vértice.
- DEC-071 (CONSENSUS): segmentação fixed-latency estrutural da divisão/arredondamento dos vértices; `vertex_ready` sticky até reset/START; handshake persistente com preparação do frame.
- DEC-056/058/063: contratos de marcadores, raízes e validade.

## Escopo preliminar

- Desenhar o quadro dentro de `x_pixel=520…639`, `y_pixel=300…479`.
- Aplicar a camada do quadro acima de todos os hits gráficos no retângulo, mascarando-os; fora dele manter a composição aprovada.
- Mostrar raízes arredondadas signed9 e vértices derivados dos termos racionais, com empate afastado de zero; `a=0`/sem raízes reais como `N/A`, F2 nula como `OFF`.
- Usar swatches para raiz laranja e vértice verde enquanto as cores forem diferentes; identificar F1/F2 pelo texto.
- Compartilhar fonte/glifos estruturais com TASK-045 somente se a análise confirmar interface compatível.

## Critérios preliminares

- Verificar limites/cantos do retângulo, colisões de cada camada, prioridade, `video_on`, todos os estados de validade e correspondência entre valores/textos e os dados matemáticos.
- Medir temporização do compositor integrado e manter `vga_sync.v` intacto.

## Implementation Brief

### Objetivo

Integrar no top e no compositor o prompt independente de TASK-045 e o quadro DEC-067, usando o frame atual de TASK-044. Na tela ativa, a ordem é: prompt durante preparação; depois quadro opaco acima do gráfico dentro da caixa; fora da caixa, composição de gráfico atual.

### Requisitos

- Solicitações explícitas do responsável: prompt antes do gráfico; valores de raízes/vértices e cores no canto inferior direito; ocultar hits gráficos que coincidirem com o quadro.
- REGRAS.md §§2, 5–8 e 10.
- Resolução 640×480, blanking `video_on`, saída RGB de 4 bits por canal e interfaces públicas existentes.

### Decisões aplicáveis

- DEC-066 (CONSENSUS): prompt literal até `frame_ready && processing_done`; gráfico/quadro ocultos no modo prompt; BUSY/DONE alinhados à preparação.
- DEC-067 (CONSENSUS): caixa, dados, cores, casos inválidos e máscara de prioridade.
- DEC-068 (CONSENSUS): linha VGA lida da tabela síncrona, alinhamento de um ciclo e `frame_ready`.
- DEC-069 (CONSENSUS): ROM combinacional `glyph_5x7(glyph_id[4:0], row[2:0], column[2:0]) -> pixel`; dois renderizadores independentes; valores de vértices retidos.
- DEC-051: não restaurar painel lateral ou exibição VGA de coeficientes.
- DEC-071: capturar termos racionais exatos e segmentar as decisões do divisor restoring com FFs dedicados; cuts 4/8/12/16 são ponto de partida e devem ser medidos/ajustados por Quartus. Só registrar valores signed arredondados após a etapa final; manter empate para longe de zero. `vertex_ready` limpa em reset/START, seta após F1-X/Y e F2-X/Y estarem registradas e fica retida até o próximo reset/START. A preparação do frame aguarda `vertex_ready && done_f1 && done_f2 && roots_ready`.

### Contrato de pipeline de vértices (DEC-071)

- Cada `processador_f1` mantém portas físicas/top-level inalteradas e acrescenta apenas uma saída interna `vertex_pipeline_valid`: pulso alinhado quando seus dois resultados X/Y já foram registrados; `vertex_x_rounded` e `vertex_y_rounded` permanecem retidos até reset/novo START.
- Termos racionais exatos de X/Y são capturados no START aceito. A divisão restauradora de 18 decisões usa latência fixa; começar pelos cortes 4/8/12/16 e ajustar apenas com evidência Quartus. O token de validade atravessa os mesmos FFs. A última etapa termina as decisões restantes, aplica `2*remainder >= denominator`, incrementa em empate e registra o signed final.
- O top usa os valid pulses alinhados de F1 e F2 para setar um único `vertex_ready` sticky, limpo por reset/START, retido até o próximo reset/START. `results_ready = done_f1 && done_f2 && roots_ready && vertex_ready`; o `fsm_frame_builder` continua esperando essa condição persistente, sem novo estado.
- Se a entrada for `a=0` (incluindo F2 totalmente nula/desabilitada), o painel exibe `N/A`/`OFF` conforme já decidido. Para manter a pipeline definida e a validade fixa sem dividir por zero, a entrada aritmética interna usa numerador zero e denominador um; a flag original governa a apresentação/erros e não muda. O token completa normalmente.
- A latência é determinada estaticamente pela captura dos termos, quantidade de grupos e FF final; não usar contador/FSM/clock derivado. A preparação BUSY/prompt esconde o intervalo até `vertex_ready`.

### Módulos e interfaces

- `top_pbl03`: usar os ports físicos existentes, sem alterá-los; ligar `frame_ready`, `processing_done`, `prompt_white`, dados de raízes e coordenadas de vértices dos dois processadores aos overlays/compositor.
- `renderizador_prompt_vga` (de TASK-045): consumir `x_pixel[9:0]`, `y_pixel[9:0]`, `video_on` e modo prompt; produzir `prompt_white`. Não alterar sua fonte/módulo nesta TASK.
- `glyph_5x7` (de TASK-045): instanciar para o quadro usando exatamente `glyph_id[4:0]`, `row[2:0]`, `column[2:0]`, `pixel`; glifos ou coordenadas fora da área útil não acendem pixel.
- Formatação numérica é uma cadeia PBL03 separada, sem incluir nem modificar `rtl/exibicao_decimal.v` (agregador legado PBL02):
  - `signed_to_magnitude14`: entrada `value signed[13:0]`; saídas `negative` e `magnitude[13:0]`. Implementação estrutural por complemento condicional; raiz signed9 e vértice X signed8 são sign-extended para 14 bits no caller.
  - `binary_to_bcd14`: entrada `magnitude[13:0]`; saída `bcd[15:0]` com quatro dígitos BCD em ordem `{thousands,hundreds,tens,ones}`, usando estágios add-3/shift estruturais totalmente desenrolados.
  - `bcd_to_glyph_id`: entrada dígito BCD `[3:0]`; saída `glyph_id[4:0]`, com 0…9 mapeando aos IDs 1…10 da ROM DEC-069.
  - `signed_to_bcd_glyphs14`: adaptador estrutural que instancia os três módulos anteriores e entrega `negative`, `sign_glyph[4:0]` (+/− IDs 11/12) e quatro `digit_glyph[4:0]` para o renderizador.
  - A divisão arredondada das coordenadas retidas deve usar `round_signed_ratio_18_10`, descrita estruturalmente e sem alterar a saída racional do validador; `dff_sync14_struct` retém y arredondado com 14 FFs.
  - `rtl/exibicao_decimal.v` e os módulos internos PBL02 que ela agrega não entram no QSF, manifesto ou runners do PBL03. `glyph_5x7.v` e `renderizador_prompt_vga.v` pertencem à TASK-045 e não serão alterados.
- Cada instância `processador_f1` de TASK-044 fornece: `root_x1/root_x2` signed9 já arredondados; `root_domain_valid`; `root_result_valid`; `vertex_x_rounded` signed8; `vertex_y_rounded` signed14; estado `error_a_zero`; F2 também usa `f2_enabled`. Não recalcular raízes nem vértices nesta TASK.
- Novo `renderizador_quadro_info_vga`: entradas `x_pixel[9:0]`, `y_pixel[9:0]`, `video_on`, `frame_ready`, `processing_done`, `f2_enabled`, flags F1/F2 `a_zero` e `root_domain_valid`, raízes F1/F2 signed9 (`x1`,`x2`) e vértices F1/F2 (`x_rounded` signed8, `y_rounded` signed14); saídas `panel_active`, `panel_red[3:0]`, `panel_green[3:0]`, `panel_blue[3:0]`. `panel_active` cobre a caixa inteira quando habilitada, inclusive o fundo preto opaco.
- `compositor_rgb`: acrescentar entradas internas `prompt_mode`, `prompt_white`, `panel_active` e RGB do quadro. Prioridade: `!video_on` → preto; `prompt_mode` → prompt branco quando `prompt_white`, senão preto; `panel_active` → RGB do quadro; caso contrário, composição gráfica aprovada. `prompt_mode = !frame_ready || !processing_done`.
- ROM: enumeração de IDs 0…31 em ordem: espaço=0; dígitos `'0'…'9'`=1…10; `+`=11, `-`=12, `.`=13, `,`=14, `/`=15; maiúsculas `A,F,I,N,O,R,V,X,Y`=16…24 nessa ordem; minúsculas `a,b,c,i,n,r,s`=25…31 nessa ordem. Preservar a ROM de TASK-045 como fonte única.

### Layout e formatação

- Caixa inclusiva: x=520…639 e y=300…479. Fundo RGB preto opaco e borda branca de 1 pixel nos quatro limites.
- Cada linha usa glifos 5×7 com pitch 6×8. Swatches 4×4 em x=524…527, y=`row_top+1…row_top+4`; texto começa em x=532. Topos das quatro linhas: y=320, 336, 360 e 376.
- Textos-base, substituindo placeholders por valores: `R F1 X1,X2`; `R F2 X1,X2`; `V F1 XV,YV`; `V F2 XV,YV`. Largura máxima é 14 células (84 pixels a pitch 6), terminando no máximo em x=615.
- Root: signed9, sinal explícito e largura 4, `+000` para zero, intervalo válido exibido −129…+129; sem raízes reais/a=0 mostra `N/A`; conjunto F2 nulo mostra `OFF`.
- Vértices: coordenadas cartesianas rounded signed8/signed14 com sinal explícito; `a=0` mostra `N/A`; F2 totalmente nula mostra `OFF`. Vértice fora da área continua sendo apresentado como valor; sua apresentação não altera a validade do gráfico.
- Swatch de root laranja `(15,8,0)`; de vértice verde `(0,15,0)`. Identificar F1/F2 por texto, pois a cor varia pelo tipo do marcador.
- Os dois pares de vértices são retidos em `processador_f1` até reset/START aceito e devem preceder `frame_ready`; não usar uma saída de execução antiga.
- O formatter recebe magnitude sem sinal com largura máxima de 14 bits e converte a quatro dígitos BCD. Raízes são renderizadas com sinal explícito e três dígitos (`+000`, `−129`); vértice X usa sinal e dois dígitos sem zero à esquerda; vértice Y usa sinal e de um a quatro dígitos sem zeros à esquerda. As posições vazias são glyph ID 0. Zero de vértice é `+0`; zero de raiz é `+000`.

### Clock e reset

- Só lógica combinacional para renderizadores; todos os dados de raízes/vértices e sincronismos já são retidos/alinhados pelo contrato de TASK-044.
- `frame_ready` e `processing_done` habilitam o quadro; `prompt_mode` domina enquanto qualquer um estiver baixo.
- Não criar clock derivado nem estado do overlay. KEY1/reset/START atuam pelas flags existentes; nenhuma camada do frame anterior pode aparecer após invalidar `frame_ready`.

### Restrições

- Um módulo por `.v`; lógica sintetizável estrutural, sem `assign`, `always` combinacional, `initial`, `if`/`else`, `case`, `for`, `generate`, `buf` ou `begin`/`end` fora dos módulos autorizados de FSM/FF. Não codificar ROM com inicialização comportamental.
- Não mudar cálculo de raízes/vértices nem validade; apresentação não retroalimenta função/error.
- Não alterar `vendor/vga/vga_sync.v`, `UPSTREAM.md`, portas públicas, pinagem, resolução/origem/escala ou restrições do SDC.
- TASK-045 é dona dos arquivos da ROM e prompt; esta TASK só os integra e os testa end-to-end.

### Arquivos permitidos

- `rtl/top/top_pbl03.v`, `rtl/video/compositor_rgb.v`.
- `rtl/funcao/processador_f1.v` to retain rounded signed8/signed14 vertex coordinates from the rational terms; do not alter the rational validation result or its error gates.
- `rtl/aritmetica/round_signed_ratio_18_10.v` and `rtl/primitivos/dff_sync14_struct.v` for independent rounding and 14-bit retention.
- Novos módulos PBL03 de pipeline/estado parcial do divisor restoring e FFs estruturais dedicados; `rtl/funcao/processador_f1.v`, `rtl/top/top_pbl03.v`, `rtl/controle/fsm_frame_builder.v`, QSF e manifesto podem ser ajustados para a latência fixed-latency e flag sticky, preservando as portas físicas.
- Fontes do rework DEC-071: `rtl/aritmetica/restoring_division_18_step10.v`, `rtl/aritmetica/restoring_division_18_group4.v`, `rtl/aritmetica/restoring_division_18_group2.v`, `rtl/aritmetica/round_signed_ratio_18_10_pipeline.v`; FFs `rtl/primitivos/dff_sync2_struct.v`, `dff_sync6_struct.v`, `dff_sync10_struct.v`, `dff_sync18_struct.v` e `dff_sync22_struct.v`.
- Novos módulos de exibição: `rtl/video/renderizador_quadro_info_vga.v`, `rtl/display/signed_to_magnitude14.v`, `rtl/display/bcd_add3_digit.v`, `rtl/display/bcd_stage14.v`, `rtl/display/binary_to_bcd14.v`, `rtl/display/bcd_to_glyph_id.v`, `rtl/display/signed_to_bcd_glyphs14.v`.
- Helper estrutural de arredondamento de vértice: `rtl/aritmetica/round_signed_ratio_18_10.v`; FF dedicado `rtl/primitivos/dff_sync14_struct.v`.
- `quartus/pbl03.qsf` e `verification/pbl03_sources.json` somente para registrar as fontes PBL03 novas; não alterar pin assignments.
- Harnesses de integração e pipeline: `sim/pbl03_top_verilator.cpp`, `sim/run_pbl03_top_verilator.sh`, `sim/run_pbl03_regression.sh`, `sim/run_f1_processor_icarus.sh`, `sim/run_f1_f2_processors_icarus.sh`, `sim/run_video_axes_icarus.sh`, `sim/tb_video_axes.v`, `sim/video_axes_icarus_vpi.c`, `sim/tb_vertex_rounding_pipeline.v`, `sim/run_vertex_rounding_pipeline_icarus.sh`, `sim/tb_frame_reset_pbl03.v`, `sim/run_frame_reset_pbl03_icarus.sh`, `sim/tb_task046_numeric.v`, `sim/tb_task046_compositor.v`, `sim/tb_task046_panel.v`, `sim/task046_panel_reference_vpi.c`, `sim/tb_task046_top_overlays.v` e seus runners Icarus.
- `verification/results/task-046/**`, `docs/tasks/TASK-046.md`, `docs/planejamento-pbl03.md`.

### Arquivos protegidos

- `vendor/vga/**`, `quartus/pbl03.sdc`, `quartus/pbl03.qpf`, pin assignments/ports do top, fontes legadas e arquivos de TASK-044/045 fora dos itens de integração explicitamente permitidos.
- `rtl/display/fonte_glifos_vga.v` e `rtl/video/renderizador_prompt_vga.v`: pertencem à TASK-045.
- Não alterar resultados históricos da TASK-035/042/043; guardar evidências em `verification/results/task-046/**`.

### Testes exigidos

- Teste independente do quadro: pixels nos quatro limites/cantos; borda/fundo; swatches; início/fim de cada glifo/célula; linhas 320/336/360/376; último pixel de conteúdo e espaço interno.
- Referência independente (C/C++) das linhas formatadas, flags de `N/A`/`OFF`, sinais/limites numéricos e posição/pixel, sem reutilizar o decoder RTL para produzir expectativa.
- Teste isolado da cadeia PBL03 signed→magnitude→BCD→glyph IDs para zero, +/−, limites signed9/8/14, `+000`, ±129, ±64, −4224/+4223, padding de espaços e todos os glifos emitidos; a expectativa C deve formatar os inteiros independentemente do DUT.
- Colisão forçada de F1/F1′/F2/F2′, eixos, interseção, raízes, labels e vértices dentro da janela: painel deve ser opaco nesses pixels; fora da janela manter as cores anteriores.
- Teste de integração do prompt: antes do frame pronto somente a frase branca aparece sobre preto na área ativa; gráfico/quadro ocultos. Depois, prompt desaparece e quadro/gráfico aparecem no ciclo correto.
- Teste de handshake DEC-071: demonstrar `vertex_ready` alto antes de `roots_ready`, mantê-lo retido enquanto `roots_ready=0`, então liberar as raízes e verificar saída de `WAIT_RESULTS`, uma preparação com exatamente 640 escritas e `frame_ready`. Reset/START deve limpar o ready e ocultar o frame anterior até os quatro resultados arredondados novos estarem registrados.
- Teste da pipeline de vértices: verificar latência/validade fixa, retenção das saídas, exatidão do quociente/resto e empate para longe de zero contra referência independente, em F1/F2, positivos/negativos e limites; `a=0`/F2 nula concluem com valor interno determinístico, sem exibir o placeholder e sem alterar erros.
- Casos: `+000`, raízes ±129, raiz dupla, `Δ<0`, F2 nula/OFF, `a=0` em F1/F2, função inválida, vértices −64/+64 e −4224/+4223, empate de arredondamento e vértices fora da tela.
- Capturar frame público completo 800×525, conferir blanking/p_tick/HS/VS/RGB e sincronismo após RAM de um ciclo. Rodar regressão agregada, source/manifest check, Quartus compile/Fitter/TimeQuest e todos os 14 endpoints VGA ≤40 ns, sem exceções mascaradoras.
- Analisar setup/hold de cada fronteira nova da pipeline, domínio MAX10_CLK1_50 a 20 ns e pior caminho global sem violação; revalidar os 14 endpoints VGA em até 40 ns.

### Dependências

- TASK-044 APPROVED: gera `frame_ready`, outputs retidos de vertices, tabela e sinais de raster atrasados.
- TASK-045 APPROVED: fornece `glyph_5x7` e `renderizador_prompt_vga`; integração não implementa nem altera esses módulos.
- DEC-051/056/058/063/066/067/068/069.

### Critérios de aceite

- Os dois overlays integram sem alteração de portas/pinos públicos ou do periférico do professor.
- Prompt governa a tela até frame atual pronto; nenhum pixel do frame anterior aparece em recomputação.
- Quadro mostra todos os valores/casos requeridos e suas cores; dentro da caixa oculta qualquer hit, fora dela saída conserva a composição aprovada.
- Glifos/posições/formatos batem com referência independente; todos os gates de simulação e análise Quartus são registrados.
- Sem evidência real de Quartus, a parte timing fica BLOCKED/TESTING e não pode ser declarada aprovada; teste físico continua pendente até placa/monitor.

## Resultado da implementação

Status atual: **APPROVED (rework DEC-071)** — pipeline e handshake sticky implementados. A cadeia aritmética tem quatro grupos de quatro decisões restoring e um grupo final de duas decisões, com captura inicial e captura final dos valores; o token do divisor chega após cinco bordas e o processador registra X/Y e emite `vertex_pipeline_valid` na borda seguinte. `vertex_ready` top é sticky e limpa em reset/START. Source checker, regressão agregada com full-frame, testes direcionados, integração de frame/reset, Quartus/Fitter/TimeQuest e análise RGB passaram; auditoria independente aprovada. `rtl/exibicao_decimal.v` permanece legado PBL02 e fora das fontes ativas.

### Arquivos alterados nesta implementação

- `rtl/aritmetica/round_signed_ratio_18_10.v`
- `rtl/aritmetica/restoring_division_18_step10.v`, `rtl/aritmetica/restoring_division_18_group4.v`, `rtl/aritmetica/restoring_division_18_group2.v`, `rtl/aritmetica/round_signed_ratio_18_10_pipeline.v`
- `rtl/primitivos/dff_sync2_struct.v`, `dff_sync6_struct.v`, `dff_sync10_struct.v`, `dff_sync18_struct.v`, `dff_sync22_struct.v`
- `rtl/primitivos/dff_sync14_struct.v`
- `rtl/funcao/processador_f1.v`
- `rtl/display/signed_to_magnitude14.v`
- `rtl/display/bcd_add3_digit.v`
- `rtl/display/bcd_stage14.v`
- `rtl/display/binary_to_bcd14.v`
- `rtl/display/bcd_to_glyph_id.v`
- `rtl/display/signed_to_bcd_glyphs14.v`
- `rtl/video/renderizador_quadro_info_vga.v`
- `rtl/video/compositor_rgb.v`
- `rtl/top/top_pbl03.v`
- `quartus/pbl03.qsf`
- `verification/pbl03_sources.json`
- `sim/tb_task046_numeric.v`, `sim/tb_task046_compositor.v`, `sim/tb_task046_panel.v`, `sim/task046_panel_reference_vpi.c`, `sim/tb_task046_top_overlays.v`
- `sim/run_task046_numeric_icarus.sh`, `sim/run_task046_compositor_icarus.sh`, `sim/run_task046_panel_icarus.sh`, `sim/run_task046_top_overlays_icarus.sh`, `sim/run_f1_processor_icarus.sh`, `sim/run_f1_f2_processors_icarus.sh`, `sim/run_video_axes_icarus.sh`, `sim/tb_video_axes.v`, `sim/video_axes_icarus_vpi.c`, `sim/run_pbl03_regression.sh`
- evidências em `verification/results/task-046/`

### Gates executados

- `python3 verification/check_pbl03_sources.py` — PASS antes e depois da agregada; repetido após a captura full-frame e a limpeza dos arquivos temporários — PASS. `sh -n` nos runners F1/F1-F2/eixos e `git diff --check` — PASS.
- `sim/run_task046_numeric_icarus.sh` — PASS: BCD exaustivo 0–8192; signed glyphs zero, ±129 e −4224/+4223; arredondamento racional por grade de numeradores/denominadores e empates ±1/2.
- `sim/run_task046_panel_icarus.sh` — PASS: 86.403 pixels comparados contra referência C independente, cobrindo a janela completa para dados válidos, `N/A`, `OFF`, `a=0`, e gating de frame/DONE/video.
- `sim/run_task046_compositor_icarus.sh` — PASS: prompt domina painel, painel opaco domina hits, fallthrough de curva/eixo e blanking.
- `sim/run_task046_top_overlays_icarus.sh` — PASS: prompt antes da preparação, painel oculto, 640 escritas reais, glyph/borda/swatch e fundo opaco no top integrado.
- `sim/run_frame_reset_pbl03_icarus.sh` — PASS após a integração: `vertex_ready` subiu antes de `roots_ready`, ficou retido durante quatro clocks sem emitir writes; cada frame subsequente gerou exatamente 640 writes; KEY1 em DISPLAY1 e START em DISPLAY2 limparam `vertex_ready` e mascararam frame antigo.
- `sim/run_vertex_rounding_pipeline_icarus.sh` — PASS: referência inteira independente para denominadores 1…510, sinais, extremos signed18, empates half-away-from-zero, safe-zero e latência fixa de cinco bordas até o candidato arredondado do divisor.
- A primeira tentativa agregada falhou antes do full-frame por ausência dos módulos novos nas listas standalone de F1; `sim/run_f1_processor_icarus.sh` e `sim/run_f1_f2_processors_icarus.sh` foram corrigidos para listar as dependências e compilar o top pela lista QSF. As duas regressões standalone passaram antes da agregada final.
- Baseline histórico pré-DEC-071: `bash sim/run_pbl03_regression.sh` passou com 840.000 ciclos de raster, 614.400 amostras ativas, 307.200 p_ticks, 100.800 ciclos HS baixos e 3.200 VS baixos; runtime 2.214 s. Este resultado não é a regressão atual do rework. O Verilator segue sem suporte nesta integração por rejeitar self-loop do modelo oficial `altera_mf.v` no `altsyncram`.
- Baseline histórico pré-DEC-071: Quartus compilou com 46 warnings, 13.126 LEs, 1.277 FFs, 16 M9Ks; setup −65,978 ns, hold +0,254 ns e Fmax 11,63 MHz. Esses relatórios estão preservados no diretório pai `verification/results/task-046/` e não representam o RTL atual. Avisos Icarus de coerção `inout`/padding 9→5 do modelo oficial são separados das métricas Quartus.
- Baseline histórico pré-pipeline: setup −65,978 ns, hold +0,254 ns e Fmax 11,63 MHz, reportados no bloco da tentativa original. Não representa o RTL DEC-071 atual.
- Quartus final pós-pipeline: `quartus_sh --flow compile pbl03` (Quartus 25.1 Standard Lite) — Analysis & Synthesis, Fitter e TimeQuest PASS, 0 errors; 43 warnings; Fmax slow 85°C 51,84 MHz; global FF→FF setup +0,710 ns e hold +0,243 ns. Snapshots congelados em `verification/results/task-046/pipeline/{quartus-compile-pipeline.log,pbl03.map.rpt,pbl03.fit.rpt,pbl03.sta.rpt}`.
- `quartus_sta -t ../verification/results/task-046/pipeline/report_ff_paths.tcl` — 20 caminhos setup sem violação, pior slack +0,710 ns; 20 caminhos hold sem violação, pior slack +0,243 ns. Relatórios `pipeline/ff-setup-paths.rpt` e `pipeline/ff-hold-paths.rpt`.
- `quartus_sta -t ../verification/results/task-046/pipeline/report_vga_outputs.tcl` — 14 caminhos aos ports VGA sem violação, pior slack +4,583 ns sob max_delay 40 ns; relatório `pipeline/vga-output-paths.rpt`.
- `ALTERA_MF_V=/home/edupires/altera_lite/25.1std/quartus/eda/sim_lib/altera_mf.v bash sim/run_pbl03_regression.sh` — PASS agregado (exit 0) em `verification/results/task-046/pipeline/regression-final-pipeline.log`; source check passou e os runners Icarus listados completaram. Full-frame: 840.000 ciclos, 614.400 amostras ativas, 307.200 p_ticks ativos, 100.800 ciclos HS baixos, 3.200 VS baixos; runtime 2.336 s dentro da simulação. Espera inicial validou 640 writes ordenados antes de frame_ready; VPI oracle conferiu a tabela completa e pixels de interseção, eixo e derivada. Hash-manifest do tree congelado no início: `pipeline/tree-manifest-pipeline.sha256`.
- Gate Verilator no agregador: `RUN BLOCKED sim/run_pbl03_top_verilator.sh` porque Verilator 5.053 detecta self-loop combinacional na biblioteca oficial `altera_mf.v` (`altsyncram`, `i_good_to_write_a2`). Não substituímos o modelo oficial por um RAM custom; Icarus/VPI concluiu a regressão funcional.
- O modelo oficial `altera_mf.v` em Icarus emitiu warnings de coerção `inout` e padding 9→5; a simulação completou.

### Pendências para finalizar

- Validação física segue pendente até placa e monitor estarem disponíveis.

## Resultado da revisão independente

Status: **APPROVED**.

### Findings

- **Nenhum finding aberto.** Revisados o corte de pipeline 4/4/4/4/2, o transporte alinhado de resto/quociente/divisor/sinal, a comparação `2*remainder >= denominator`, a reaplicação do sinal e o caso de denominador seguro para `a=0`/F2 desabilitada. Os limites legais das coordenadas de vértice cabem no quociente e nas saídas signed8/signed14; os testes independentes exercitam sinais, extremos, empates e divisores seguros.
- Não foi introduzida FSM de cálculo, clock derivado ou lógica comportamental combinacional na implementação revisada. Os FFs usam módulos dedicados; o pipeline mantém validade fixa. O compositor aplica prompt, painel opaco, gráfico e blanking na prioridade aprovada. `vertex_ready` é sticky, limpa em reset/START, e o frame builder só inicia após `done_f1 && done_f2 && roots_ready && vertex_ready`.
- `vendor/vga/vga_sync.v` permanece intacto (SHA-256 `6f2e841c45f14888aeb6d8cc58e79ec7e7ca5dafddae7c32ef160381daacccc8`). O QSF/manifest inclui as fontes novas; não inclui o conversor legado `rtl/exibicao_decimal.v` nem altera as atribuições de pinos nesta integração.

### Evidências verificadas

- Regressão agregada Icarus/VPI: PASS, exit 0; full-frame de 840.000 ciclos, 614.400 amostras ativas, 307.200 p_ticks, HS-low 100.800 e VS-low 3.200; a tabela recebeu 640 escritas ordenadas e passou as verificações do oracle e das camadas. Log: `verification/results/task-046/pipeline/regression-final-pipeline.log`.
- Testes direcionados de números/BCD, referência independente do painel, prioridade do compositor, integração dos overlays, reset/START durante exibição e pipeline de vértices: PASS, conforme runners e log agregado.
- Quartus 25.1 Standard Lite: 0 erros; setup +0,710 ns, hold +0,243 ns, Fmax 51,84 MHz. Os 20 caminhos setup e 20 hold reportados não violam; os 14 endpoints RGB passaram o limite de 40 ns, pior slack +4,583 ns. Evidências em `verification/results/task-046/pipeline/`.
- Source/manifest check, sintaxe dos runners e `git diff --check`: PASS. Verilator permanece `UNSUPPORTED_OFFICIAL_ALTERA_MODEL_LOOP` por self-loop no modelo oficial `altera_mf.v`; isso não substitui nem invalida a regressão funcional concluída em Icarus/VPI.

A aprovação cobre os critérios de implementação e síntese desta TASK. A validação física em placa/monitor ainda não foi executada e permanece pendente.
