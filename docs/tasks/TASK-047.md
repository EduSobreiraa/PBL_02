# TASK-047 — Variante de tabela FF-only do frame pré-calculado

## Objetivo

Na branch `EduSobreiraa/PBL-03-Plus-Registers`, substituir somente o armazenamento da tabela pré-calculada 640×41 da RAM por FFs estruturais explícitos, mantendo o frame e as camadas de vídeo equivalentes à branch base.

## Status

BLOCKED — a variante FF-only sintetiza e fecha temporização, mas o gate funcional encontra uma falha preexistente no painel protegido por esta TASK: em `(520,280)`, `panel_active=1` embora a caixa contratada comece em `y=300`. O full-frame Verilator confirma a sobreposição branca no mesmo pixel. A correção pertence à tarefa do painel; não altere o overlay nesta variante.

## Decisões relacionadas

- DEC-072 (CONSENSUS): 640 palavras explícitas de 41 FFs, escrita 1/ciclo, leitura 10×64 em dois ciclos, banco inválido zero, raster atrasado conjuntamente em duas fases; restrito a esta branch variante.
- DEC-065/068/070: permanecem aplicáveis ao payload, clipping, sincronismo e regras; seus contratos RAM/M9K/`altsyncram`/latência interna de 1 ciclo são supersedidos somente nesta variante.
- DEC-066/067/071: prompt, painel, vértices, composição e preparação permanecem inalterados funcionalmente.
- TASK-044/046 APPROVED na branch base; seus resultados servem de referência, não como teste desta variante.

## Escopo

- Manter tabela lógica `{y_f1[8:0], y_df1[8:0], y_f2[8:0], y_df2[8:0], valid_f1, valid_df1, valid_f2, valid_df2, intersection_hit}`: 41 bits × 640 endereços = 26.240 bits.
- Trocar apenas o backend `coordinate_frame_ram` (ou seu nome atualizado pelo Context Analyst) por bancos de DFFs estruturais, decoder de escrita e mux de leitura síncronos em dois ciclos.
- Acrescentar uma fase raster externa alinhada ao segundo ciclo de leitura; preservar resolução/origem/cores/prompt/quadro, frame_ready, portas/pinos e periférico VGA do professor.
- Medir se o banco FF-only cabe no LE/FF do MAX 10 e fecha timing. Se não couber, registrar BLOCKED nesta branch sem voltar para RAM.

## Restrições

- Não usar `altsyncram`, M9K, array de armazenamento no RTL, `for`, `generate`, `genvar`, `assign`, `buf`, lógica comportamental fora dos DFFs dedicados ou nova FSM.
- Um módulo por arquivo `.v`; cada palavra e mux devem ser descritos/instanciados estruturalmente; scripts de geração de source não autorizam constructos proibidos no Verilog resultante.
- Não alterar o cálculo da coluna, o payload, os sinais de validade, as funções do painel/compositor, os pinos, SDC ou `vendor/vga/vga_sync.v`.
- `frame_ready=0` deve ocultar todas as leituras indefinidas até completar 640 escritas válidas em ordem; não é necessário limpar payload no reset.
- Nenhum caminho falso/multicycle para esconder setup/hold; todos os 14 endpoints VGA continuam limitados a 40 ns.

## Arquivos permitidos

- `rtl/funcao/coordinate_frame_ram.v` (preservar módulo e ports atuais) e novos módulos privados estruturais de palavra FF, decoder e mux, cada um em seu arquivo.
- `rtl/top/top_pbl03.v` e novos/atuais primitivos dedicados de FF necessários somente à fase raster extra e validade de leitura.
- `quartus/pbl03.qsf`, `verification/pbl03_sources.json`, `verification/check_pbl03_sources.py`, `verification/test_check_pbl03_sources.py` e runners afetados, para refletir a fonte ativa FF-only e remover dependência de modelo RAM no teste deste backend.
- Testes Icarus/VPI/Verilator necessários à escrita, leitura, alinhamento e full-frame; novos testes em `sim/`.
- `docs/tasks/TASK-047.md`, `docs/planejamento-pbl03.md`, `docs/decisions/DEC-072.md` somente para resultados/estado após execução.
- Evidências em `verification/results/task-047/**`.

## Arquivos protegidos

- `vendor/vga/**`, `quartus/pbl03.sdc`, `quartus/pbl03.qpf`, pin assignments e pinos públicos do top.
- Cálculos/formatadores/overlays aprovados sem relação com a memória, incluindo toda a implementação de TASK-046.
- Branches `EduSobreiraa/PBL-03` e `EduSobreiraa/PBL-03-Plus`.

## Testes e critérios de aceite

- Checker de fontes confirma ausência de `altsyncram`, inferência de RAM/arrays, `generate`, loops e construções proibidas na variante RTL.
- Teste de memória independente grava padrões únicos em todos os 640 endereços e compara os 26.240 bits; verifica endereço 0/639, escrita/overwrite, retenção das palavras não selecionadas, leitura contínua 1/ciclo, duas bordas exatas de latência, seletores inválidos zero e blanking.
- Teste top/frame verifica que `frame_ready` permanece baixo durante escrita, 640 writes ordenados, nenhum conteúdo antigo vaza e KEY1/START invalidam o frame atual.
- Captura full-frame 800×525 confirma a tabela, pixel de origem/eixos/curvas/interseção/derivada/quadro, video_on/blanking, `p_tick` e alinhamento de HS/VS/RGB às duas fases; o periférico do professor permanece intacto.
- Quartus Analysis & Synthesis/Fitter/TimeQuest real: tabela sem blocos RAM, confirmar uso real de FF/LE, Fmax ≥50 MHz, pior setup/hold não negativo no clock de 20 ns e 14 RGB paths dentro de 40 ns.
- Code Auditor independente classifica esta TASK como APPROVED somente se todos os gates funcionais e Quartus passarem. Se recurso ou timing falhar, registrar resultado BLOCKED e evidências; não alegar funcionamento na placa.

## Implementation Brief

### Contrato de interface do backend

Substituir a implementação de `coordinate_frame_ram` mantendo exatamente seus ports e larguras atuais: `clk`, `write_enable`, `write_address[9:0]`, `write_data[40:0]`, `read_enable`, `read_address[9:0]`, `read_data[40:0]`. Não alterar o top físico nem adicionar ports externos ao `top_pbl03`.

- Payload por endereço: `{y_f1[8:0], y_df1[8:0], y_f2[8:0], y_df2[8:0], valid_f1, valid_df1, valid_f2, valid_df2, intersection_hit}`; 640 endereços válidos, 0…639.
- Escrita: uma palavra por borda ativa, preservando throughput e a ordem atual 0…639. `write_address[9:6]` seleciona um dos bancos 0…9 e `[5:0]` uma linha 0…63. Bancos 10…15 não escrevem qualquer palavra. Os bits de dados só atualizam a palavra selecionada; as outras retêm seu conteúdo. Não resetar payload.
- Armazenamento: 640 palavras nomeadas/instanciadas explicitamente, 41 FFs por palavra. Não declarar memória/array RTL, indexar storage como array, nem usar `for`, `generate` ou `genvar` para construir palavras, decoders ou muxes. A seleção de escrita deve ser D estrutural com mux de retenção e DFF dedicado sem reset de payload. Decoder de endereço pode ser compartilhado; resultados de bancos inválidos devem ser zero.
- Leitura: dez muxes paralelos 64:1 selecionam `read_address[5:0]`, produzindo dez palavras parciais de 41 bits registradas na fase 1 (410 FFs). O seletor alto `[9:6]` do mesmo endereço deve permanecer alinhado à fase 1. Na fase 2, um mux 10:1 seleciona a palavra parcial do banco 0…9 e registra `read_data[40:0]` (41 FFs). Seletor alto 10…15 produz zero determinístico. Aceitar endereço em ciclos consecutivos e entregar uma palavra por ciclo após o enchimento da pipeline.
- Definição temporal para teste: endereço amostrado na borda de fase 1 produz os dez resultados parciais nessa borda; o valor final e os sinais raster correspondentes são registrados na borda de fase 2 seguinte. O scoreboard deve amarrar dados, seletor alto e coordenadas à mesma amostra, verificando as duas fases registradas sem depender de leitura de RAM/modelo Intel.
- `read_enable` é o valid/enable da pipeline: quando baixo, não declarar o `read_data` atual válido. No top, criar `read_pipeline_valid` com dois DFFs dedicados em série, amostrando `frame_memory_read_enable` nas mesmas fases da tabela; reset/START ou `read_enable=0` invalida o token. Manter a interface interna de `coordinate_frame_ram` sem novo port de validade. Após `frame_ready` subir, ocultar gráfico e overlays dependentes da tabela até `read_pipeline_valid` afirmar. Isso evita expor saída velha/indefinida durante o enchimento da leitura; não altera o momento de conclusão das 640 escritas nem a semântica de `frame_ready`.

### Alinhamento no top

O top atual tem uma fase raster (`raster_x_delay`, `raster_y_delay`, `raster_hsync_delay`, `raster_vsync_delay`, `raster_video_delay`, `raster_tick_delay`). Preservá-la como fase 1 e adicionar uma fase DFF para x, y, video_on e p_tick. O valor alto de x da fase 1 seleciona o banco na fase 2; `read_data` final e raster de fase 2 devem referir-se à mesma amostra VGA. Migrar hits da tabela, eixos, raízes, prompt, quadro informativo e compositor para fase 2. O `vga_sync` fornecido já registra HS/VS a partir da contagem anterior; por isso a saída física usa uma FF adicional no top, cuja latência efetiva é a mesma fase 2 de x/y. Uma segunda FF no top atrasava HS/VS em um pixel. `vga_sync.v`, resolução, origem, escala, pinos e SDC ficam intactos. O gated display/prompt deve usar a validade da saída fase 2 junto de `frame_ready` e `processing_done`; reset/START invalida a validade da leitura e mantém o frame anterior oculto.

### Fontes/build e runners

- Remover `coordinate_frame_ram` da implementação `altsyncram`; o nome do módulo/arquivo pode continuar para manter o caller, mas a hierarquia sintetizada não deve conter `altsyncram`, inferência de RAM nem blocos M9K para a tabela.
- QSF e manifesto mantêm uma entrada por módulo/arquivo e listam os novos módulos privados/FFs uma única vez. Atualizar o checker e seu teste para conferir que as fontes ativas da variante incluem o backend FF-only, não declaram fonte `altsyncram` de projeto, e respeitam as proibições de array/laço/geração/`assign`/`buf`/comportamental fora do FF dedicado. Não relaxar o checker geral para branches base; registrar que este workspace/branch é a variante `PBL-03-Plus-Registers`.
- Atualizar `sim/run_coordinate_framebuffer_icarus.sh` e `sim/run_coordinate_framebuffer_full_icarus.sh`, seus testbenches/VPI e `sim/run_pbl03_regression.sh` para testar o backend FF-only e a latência/priming sem carregar `altera_mf.v` nem exigir `ALTERA_MF_V`/`QUARTUS_ROOTDIR`. Como `coordinate_frame_ram` é a única fonte RTL ativa que instancia `altsyncram`, retirar essa dependência dos demais runners PBL03 que compilam o top/QSF (`run_video_axes_icarus.sh`, `run_f1_processor_icarus.sh`, `run_f1_f2_processors_icarus.sh`, `run_coordinate_frame_function_pipeline_icarus.sh`, `run_frame_reset_pbl03_icarus.sh`, `run_main_handshake_pbl03_icarus.sh`, `run_status_errors_pbl03_icarus.sh`, `run_task046_top_overlays_icarus.sh` e `run_pbl03_top_verilator.sh`). O agregado deve executar sem montar ou localizar a biblioteca oficial de RAM. Remover do escopo de execução da variante os testes que exijam o backend RAM antigo; não remover nem reescrever evidências históricas da branch base.

### Estado necessário e minimização

O payload exige 26.240 bits distintos. A leitura exige 410 bits da fase 1 e 41 bits finais na fase 2; os 24 FFs de raster adicionados são x/y (20), video_on/p_tick/hsync/vsync (4). Acrescentar somente os tokens de validade necessários para identificar as duas fases de leitura e os FFs estruturais dedicados para retenção. Não replicar payload nem resetar a tabela. A estimativa de 28.482 FFs totais usa o baseline pós-pipeline registrado em DEC-072; ela não garante recursos de LEs nem timing.

### Casos adicionais obrigatórios

- Ler todos os 640 payloads únicos após gravação; provar `bank0,row0` em endereço 0 e `bank9,row63` em 639, escrita overwrite, retenção das outras palavras e endereços inválidos 640…1023 com saída zero e sem escrita.
- Ler em ciclos consecutivos sem bolhas e verificar fase 1/fase 2 para endereço e dados, inclusive transições de banco 63→64, 127→128, 575→576, bordas de linha, início/fim da área ativa e blanking. Verificar saída final zero para seletores 10…15.
- Reset/START durante DISPLAY e durante preparação: `frame_ready` permanece baixo até exatamente 640 escritas do novo frame; o token de leitura também recomeça inválido; nenhum pixel da tabela anterior ou de pipeline não preenchida aparece.
- Full-frame: 800×525 clocks raster, mas só contar amostras em `p_tick` segundo a cadência VGA real; comparar coordenadas/data e RGB de fase 2, HS/VS, video_on/blanking, eixos, curvas/derivadas, interseção, raízes, painel e prompt.

### Gate de viabilidade

Somente Quartus real nesta branch decide se a forma estrutural cabe: zero memória/M9K para a tabela, armazenamento das 26.240 bits em FFs, relatórios reais de LE/FF, setup e hold não negativos no clock MAX10_CLK1_50 de 20 ns, Fmax ≥50 MHz e 14 endpoints RGB dentro de 40 ns. Sem modificar SDC ou adicionar exceções. Se Fitter estourar recurso ou TimeQuest falhar, manter a variante documentada como BLOCKED com os relatórios; não alterar payload nem voltar para RAM.

## Resultado da implementação

### Implementado e medido

- O backend usa DFFs estruturais explícitos para as 640 palavras, leitura em duas fases e token de validade alinhado. A auditoria funcional da fase2 encontrou e corrigiu o deslocamento HS/VS de um pixel sem tocar no VGA do professor: a saída raw do `vga_sync` já inclui um FF em relação a x/y; a saída top usa um FF adicional, com latência efetiva igual a fase2. Ver `rtl/top/top_pbl03.v` e o check de alinhamento em `sim/tb_coordinate_framebuffer_full.v`.
- Checker de fontes passou (`python3 verification/check_pbl03_sources.py`); suíte do checker passou (22 testes). `git diff --check` e `sh -n` dos runners passaram.
- Icarus backend FF PASS: 640 escritas, 640 leituras ordenadas e readback completo após endereços inválidos 640…1023, alinhamento em duas fases, overwrite/retenção e bancos inválidos. Log: `verification/results/task-047/coverage/coordinate-frame-readback-20261125T061157Z.log`.
- Icarus reset/display PASS após a correção de HS/VS: KEY1 em DISPLAY1 e START em DISPLAY2 limpam e mascaram o frame anterior; ambos os frames registraram 640 escritas. Incluído no log `verification/results/task-047/coverage/focused-post-sync-*.log`.
- Main-handshake/status-errors não verificados: a imagem Icarus não contém compilador C para os observers VPI e a instalação de GCC falhou por timeout/404 do mirror Debian. Isso é limitação de ambiente, não resultado de teste RTL; log em `verification/results/task-047/coverage/status-handshake-*.log`.
- Quartus real, comando `QUARTUS_ROOTDIR=/home/edupires/altera_lite/25.1std/quartus /home/edupires/altera_lite/25.1std/quartus/bin/quartus_sh --flow compile quartus/pbl03 -c pbl03`: compile/Fitter/TimeQuest PASS, 0 erros e 36 warnings; 45.022 LEs (90%), 28.486 FFs, 960 memory bits de lógica existente (a tabela não usa memória), Fmax 51,27 MHz, setup +0,494 ns, hold +0,187 ns. Log e snapshots em `verification/results/task-047/coverage/quartus-sync-align/`.
- O runner Icarus full-frame foi corrigido para exigir sentinelas `FULL FRAME PASS:` do TB e `VPI PASS: ...` do observador. O log histórico `verification/results/task-047/regression-20261125T034127Z.log` não contém essas sentinelas, embora mostre `RUN PASS`; é inconclusivo e não prova quadro completo. Não foi executada outra captura Icarus full-frame devido ao runtime histórico superior a duas horas.

### Bloqueio funcional herdado

- O teste de overlay em `(520,280)` mostra `x_cart=200`, `y_cart=-40`, eixos/hits/raízes=0, mas `panel_active=1` e RGB `fff`. Isso viola a caixa aprovada `x=520…639, y=300…479`. O log reproduzível é `verification/results/task-047/coverage/top-overlay-panel-boundary-fail-20261125T070000Z.log`.
- O RTL do painel está protegido pelo brief TASK-047 e é idêntico ao da branch base; a variante de armazenamento não deve modificá-lo. O painel faz a regressão Icarus focada falhar no pixel acima da caixa.
- O Verilator full-frame passou pelo novo pixel-alignment conhecido (x302 preto, x303 preto, x304 vermelho, x305 preto), e depois encontrou o mesmo painel em x520,y280: esperado RGB 000, observado RGB fff. Resultado literal em `verification/results/task-047/coverage/verilator-sync-align-20261125T065054Z.log`.
- Portanto a implementação FF-only compila e fecha timing, mas a aceitação funcional/full-frame permanece BLOCKED até a correção do painel no escopo autorizado. Não alterar/mascarar o teste nem marcar APPROVED nesta TASK.
