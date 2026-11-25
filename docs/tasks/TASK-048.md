# TASK-048 — Corrigir limite superior e inferior do quadro informativo

## Objetivo

Corrigir o detector vertical do quadro para ativá-lo somente em `y_pixel=300…479`, conforme o retângulo fixo de DEC-067. Preservar a faixa horizontal, os gates e a prioridade do compositor.

## Status

APPROVED — comparação estrutural inclusiva `y=300…479`; limites, gates, integração, 12 quadros completos e Quartus pós-correção passaram. Code Auditor aprovou sem findings.

## Requisitos relacionados

- Retângulo do painel exatamente `x_pixel=520…639`, `y_pixel=300…479`, ambos inclusivos.
- Fora desse retângulo, `panel_active=0`; dentro dele, aplicar a caixa e seus conteúdos existentes conforme os gates aprovados.
- `video_on`, `frame_ready`, `processing_done` e prioridade do compositor mantêm seu comportamento aprovado.

## Decisões relacionadas

- DEC-067 (CONSENSUS): caixa fixa opaca com prioridade sobre os hits gráficos dentro de x=520…639 e y=300…479.
- DEC-066/069: prompt e glifos permanecem integrados sem alteração.

## Módulos envolvidos

- `renderizador_quadro_info_vga`: corrigir somente a lógica estrutural que determina a inclusão vertical em `y_in_box`.
- Compositor e top: usados para verificação integrada; não requerem mudança funcional ou de interface.

## Interface

Manter a interface existente de `renderizador_quadro_info_vga` sem alterações:

- `x_pixel[9:0]`, `y_pixel[9:0]`: coordenadas do pixel atual.
- `video_on`, `frame_ready`, `processing_done`: gates atuais de área ativa e disponibilidade.
- `panel_active`: fica alto somente quando os gates existentes permitem o quadro e `520 ≤ x_pixel ≤ 639`, `300 ≤ y_pixel ≤ 479`.
- `panel_red[3:0]`, `panel_green[3:0]`, `panel_blue[3:0]`: permanecem conforme o quadro atual quando ativo; não alterá-los.

## Clock e reset

O renderer e o detector de caixa são combinacionais. Não adicionar clock, registradores, estado ou alteração de reset.

## Restrições

- Implementação estrutural conforme `docs/regras.md`: sem `assign`, `always` fora de módulo dedicado de FF, `if`/`else`, `case`, laços, `generate`, `buf` ou blocos `begin`/`end` no DUT.
- Corrigir apenas o limite vertical. Manter `x=520…639`, `video_on`, gates `frame_ready`/`processing_done`, conteúdo, cores, coordenadas, ROM e prioridade do compositor.
- Não implementar painel lateral, não reposicionar nem redimensionar o quadro.
- Não alterar `vendor/vga/vga_sync.v`, pinos, QSF/SDC ou portas públicas.

## Arquivos permitidos

- `rtl/video/renderizador_quadro_info_vga.v` — correção de `y_in_box`.
- `sim/task046_panel_reference_vpi.c` e `sim/tb_task046_panel.v` — acrescentar/verificar os casos de fronteira no teste independente do painel.
- `sim/tb_task046_top_overlays.v` e, somente se necessário, `sim/run_task046_panel_icarus.sh` / `sim/run_task046_top_overlays_icarus.sh` para executar as mesmas verificações em integração.
- `sim/pbl03_top_verilator.cpp` e `sim/run_pbl03_top_verilator.sh` — ajustar somente a verificação RGB full-frame para excluir a região fixa do painel da comparação com `referenceRgb`, contando as amostras excluídas; manter todas as verificações de raster e sincronismo.
- `docs/tasks/TASK-048.md` para resultado, evidências e status desta correção.

## Arquivos protegidos

- `rtl/video/compositor_rgb.v`, `rtl/top/top_pbl03.v`, `rtl/display/glyph_5x7.v`, `rtl/video/renderizador_prompt_vga.v` e todo o restante da RTL, salvo autorização explícita acima.
- `vendor/vga/**`, `quartus/pbl03.qsf`, `quartus/pbl03.sdc`, pin assignments e portas físicas do top.
- `docs/decisions/DEC-067.md`, `docs/tasks/TASK-046.md`, `docs/tasks/TASK-047.md` e implementação do armazenamento FF-only da branch `EduSobreiraa/PBL-03-Plus-Registers`.

## Testes exigidos

- No teste unitário do painel, com `video_on=1`, `frame_ready=1` e `processing_done=1`, verificar em uma coordenada horizontal dentro do quadro: `y=299` → `panel_active=0` e RGB do painel preto; `y=300` → borda branca e ativo; `y=479` → borda branca e ativo; `y=480` → `panel_active=0` e RGB do painel preto.
- Repetir os quatro limites no teste de top/compositor, com entradas de função escolhidas para que pixels externos não coincidam com uma curva/eixo/raiz; verificar `panel_active` diretamente e a saída RGB esperada.
- Preservar verificações dos gates: `video_on=0`, `frame_ready=0` ou `processing_done=0` não ativam o painel, inclusive em `(520,300)`.
- O teste de referência VPI do painel percorre a janela completa `120×180` em múltiplos cenários; ampliar as verificações de fronteira imediata para incluir `y=299` e `y=480`, sem duplicar o renderer em outro modelo.
- No Verilator full-frame, manter toda a validação 800×525 do raster, HS/VS, blanking, cadência e alinhamento. Comparar RGB com `referenceRgb()` apenas fora de `x=520…639, y=300…479`; não implementar uma segunda referência do painel em C++. Contar e afirmar exatamente **21.600 amostras ativas excluídas** da comparação RGB por frame (`120×180`).
- Rodar os runners de painel, top-overlay e Verilator full-frame previstos pela implementação e registrar logs reais. Não alegar execução nesta etapa de planejamento.

## Casos de borda

- `y=299`: imediatamente acima, painel inativo.
- `y=300`: primeira linha, borda branca ativa.
- `y=479`: última linha, borda branca ativa.
- `y=480`: imediatamente abaixo, painel inativo.
- Preservar também as bordas horizontais `x=520` e `x=639`; não estender ou reduzir a caixa.

## Critérios de aceite

- `panel_active` é verdadeiro somente dentro do retângulo inclusivo `520…639 × 300…479` e quando os gates existentes permitem exibição.
- Os quatro pixels/casos de fronteira acima passam no teste unitário e integrado.
- O Verilator full-frame continua validando raster e sincronismos; as comparações RGB excluem exatamente 21.600 pixels da região aprovada do painel, sem falsa falha causada por um modelo C++ que não implementa o painel.
- O compositor e as prioridades fora do defeito permanecem inalterados.
- Regras estruturais verificadas; resultados e logs registrados antes de avançar o status além de `IMPLEMENTED`/`TESTING`.

## Dependências

- TASK-047, branch `EduSobreiraa/PBL-03-Plus-Registers`: estava bloqueada pelo leak em `(520,280)`. TASK-048 corrige o RTL do painel compartilhado; após a auditoria e revalidação dos gates combinados, TASK-047 foi recomendada APPROVED.
- DEC-067 (CONSENSUS), que define os limites do quadro.

## Pendências

Nenhuma para iniciar a implementação. Execução dos testes e revisão independente permanecem pendentes.

## Resultado da implementação

### Arquivos modificados

- `rtl/video/renderizador_quadro_info_vga.v`: substituí a soma errada dos termos de `y_low_ge44` por `y[6] | (y[5] & y[4]) | (y[5] & y[3] & y[2])`. Isso representa exatamente 44…127 no grupo 256…383; o grupo 384…479 existente não mudou.
- `sim/task046_panel_reference_vpi.c`: o test driver agora verifica `y=299,300,479,480` com os gates ativos e termina somente depois dos quatro novos limites.
- `sim/tb_task046_top_overlays.v`: acrescentei os quatro limites integrados no pixel `x=520`, verificando coordenada da fase 2, `panel_active`, `video_on` e RGB; também mantém o pixel fora da caixa em `y=280` preto.
- `sim/pbl03_top_verilator.cpp`: a oracle full-frame mantém todas as comparações RGB fora da caixa e verifica exatamente 21.600 amostras ativas por frame dentro dela, que são excluídas da comparação por não haver modelo C++ duplicado do painel. As verificações de 800×525, HS/VS, blanking, cadência, alinhamento e RGB fora da caixa seguem ativas.

### Testes executados

- Painel Icarus/VPI: `TASK-048 PANEL PASS: 86407 full-window/reference pixel checks across valid, N/A, OFF, gates and y=299/300/479/480 limits`; exit 0 em `verification/results/task-048/panel-icarus-final.log`. O container Icarus não inclui compilador C; compilei a VPI com GCC host contra os headers oficiais do container e rodei o mesmo testbench no `vvp`. O GCC host exigiu suprimir somente o aviso `-Wformat-truncation` do valor de referência; a RTL/testbench não foi alterada por essa opção.
- Top overlay Icarus: `TASK-048 TOP OVERLAY PASS: phase-2 prompt, real roots/vertex, panel content and y=299/300/479/480 boundaries`; exit 0, em `verification/results/task-048/top-overlays-final-20261125T080810Z.log`.
- Verilator top full-frame: PASS em 12 casos, 19.383.562 vector checks e 35.889.792 clocks de sistema. Cada frame valida 800×525, HS/VS, blanking, ticks, dados e RGB fora do painel e reporta `RGB panel samples excluded=21600`. Log: `verification/results/task-048/top-verilator-final-20261125T080917Z.log`.
- Fonte estrutural: `python3 verification/check_pbl03_sources.py` PASS; `python3 -m unittest verification.test_check_pbl03_sources -q` PASS, 22 testes. `git diff --check` e `sh -n` dos runners envolvidos PASS.
- Quartus 25.1std compile/Fitter/TimeQuest: comando `QUARTUS_ROOTDIR=/home/edupires/altera_lite/25.1std/quartus /home/edupires/altera_lite/25.1std/quartus/bin/quartus_sh --flow compile quartus/pbl03 -c pbl03`; PASS, 0 erros e 36 warnings. Fitter: 45.217/49.760 LEs (91%), 28.485 FFs, 960 bits de memória de lógica existente fora da tabela FF-only. Fmax slow 85C = 51,0 MHz; pior setup +0,392 ns e hold +0,188 ns. `quartus_sta` detalhado: 14 endpoints VGA, 0 violados, pior slack +5,510 ns sob o `max_delay` de 40 ns; 20 caminhos FF→FF setup pior +0,392 ns e hold pior +0,188 ns. Logs e relatórios em `verification/results/task-048/quartus/`.

### Resultado

A caixa está inativa em `y=299` e `y=480`, e ativa com borda branca em `y=300` e `y=479`. O leak em `(520,280)` desapareceu. Code Auditor aprovou TASK-048 sem findings. A mesma revisão independente reavaliou TASK-047 no worktree combinado e recomendou APPROVED: os gates FF-only, reset/display, full-frame, painel, checker e Quartus passaram. O log histórico Icarus full-frame continua inconclusivo e não é usado como evidência de PASS. Validação física em DE10-Lite/monitor permanece pendente como entrega de projeto; não foi executada nem alegada nesta TASK.
