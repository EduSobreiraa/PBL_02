# TASK-028 | Fechar o processador de F1 e detectar seus pixels

## Objetivo

Integrar a aritmética e a validação aprovadas na TASK-027 em um caminho F1 que só habilite a parábola e a derivada quando a função for válida. Comparar valores completos com a linha VGA corrente, aplicando clipping antes da conversão para pixel.

## Status

APPROVED | Code Auditor independente repetiu as regressões; Compliance, Functional e Integration aprovados sem findings.

## Dependências

- TASK-027 | aritmética, derivada, vértice racional e clipping de F1.
- DEC-048 | FSM F1, handshake, retenção de erros, saída de reset e fronteira de integração.

## Planejamento e aceite

- Criar ou completar a FSM de F1 conforme os contratos de `REGRAS.md`.
- Tratar `a₁=0` e vértice fora dos limites como erros, sem habilitar pixels.
- Habilitar F1 e F1′ depois da validação, mantendo cálculo combinacional para cada coluna.
- Verificar bordas da tela, clipping, sinais, erro e reset com referência independente.
- Ligar DONE real do processador ao handshake da entrada.
- Manter a FSM principal, composição RGB, F2 e saídas físicas para suas TASKs próprias.
- Deixar medição de recursos e timing para TASK-035, depois da configuração SDC adequada.

## Implementation Brief

### Objetivo

Integrar `datapath_f1` da TASK-027 a uma FSM F1, exportar o reset lógico sincronizado da entrada e ligar START/DONE no top. Os hits do datapath só ficam ativos após validação bem-sucedida e conclusão do processador.

### Requisitos

- PDF PBL03 §§4.4, 4.9-13 e 5.3-4.
- `REGRAS.md` §§2, 3.11-15, 4, 5, 7 e 10.

### Decisões aplicáveis

- DEC-044 | cálculo exato, validação e contrato START/BUSY/DONE.
- DEC-045 | wrapper estrutural e verificação externa via Icarus/VPI.
- DEC-046 | sincronização de KEYs e reset interno síncrono ativo alto.
- DEC-047 | datapath F1 combinacional standalone.
- DEC-048 | FSM F1, reset exportado, handshake e fronteira desta integração.

### Módulos envolvidos

- `rtl/funcao/fsm_funcao_f1.v` | FSM dedicada com estados `WAIT_START`, `VALIDATE` e `COMPLETE`.
- `rtl/funcao/processador_f1.v` | instancia `datapath_f1` e `fsm_funcao_f1`; combina os hits com `display_enable`.
- `rtl/funcao/datapath_f1.v` e seus módulos auxiliares da TASK-027 | cálculo, validade, erros e hits combinacionais.
- `rtl/entrada/entrada_pbl03.v` | exporta `system_reset` já derivado de KEY1 sincronizada.
- `rtl/top/top_pbl03.v` | conecta coeficientes, START, reset e DONE; mantém hits gated em fios internos.
- `quartus/pbl03.qsf` | inclui o processador e todas as fontes da TASK-027 necessárias ao top.

### Interface

Adicionar `system_reset` como saída de 1 bit em `entrada_pbl03`. O sinal é síncrono, ativo alto e vem do fio interno atual derivado de KEY1 sincronizada. Não alterar a rota física invertida de KEY1 que reseta o periférico VGA.

`processador_f1` recebe `clk`, `system_reset`, `start_pulse`, `a1`, `b1`, `c1`, `x_cartesiano` e `y_cartesiano`. `a1`, `b1` e `c1` são signed8; x e y são signed10. Produz `busy`, `done`, `error_a_zero`, `error_vertex`, `display_enable`, `f1_hit` e `f1_derivada_hit`, todos de 1 bit exceto os controles explicitados.

`fsm_funcao_f1` recebe `clk`, `system_reset`, `start_pulse`, `a1_zero`, `vertice_y_fora` e `function_valid`. Produz `busy`, `done`, `error_a_zero`, `error_vertex` e `display_enable`. Os erros são retidos em `COMPLETE`; `display_enable` só fica alto em `COMPLETE` quando a validade capturada é verdadeira.

No top, conectar `processador_f1.done` a `entrada_pbl03.processing_done`. Conectar os hits do processador somente a fios internos. Não alterar o compositor RGB nesta TASK.

### Transições e saídas da FSM

Implementar exatamente os estados e o comportamento de DEC-048:

| Estado | BUSY | DONE | Erros/display | Transição |
|---|---:|---:|---|---|
| `WAIT_START` | 0 | 0 | erros e display limpos | START aceito → `VALIDATE`; senão permanece |
| `VALIDATE` | 1 | 0 | erros e display desabilitados | no próximo clock captura `a1_zero`, `vertice_y_fora` e `function_valid`, depois → `COMPLETE` |
| `COMPLETE` | 0 | 1 | erros capturados; display habilitado só se validade capturada | START aceito → `VALIDATE`; senão permanece |

`system_reset` síncrono ativo alto tem prioridade em qualquer estado e retorna a `WAIT_START`, limpando DONE, BUSY, erros e habilitação. Aceitar START em `WAIT_START` e `COMPLETE`; ignorar START em `VALIDATE`. Ao aceitar START em `COMPLETE`, baixar DONE na mesma borda e limpar saídas retidas. `processador_f1.done` alimenta diretamente `entrada_pbl03.processing_done`, permitindo que a FSM de entrada observe baixo e depois alto após START.

`f1_hit` e `f1_derivada_hit` do processador são o AND estrutural entre os hits do datapath e `display_enable`. O compositor, o gate RGB por `video_on` e a saída visual da curva ficam para TASK-031.

### Clock e reset

- Clock: `MAX10_CLK1_50`, borda de subida.
- Reset da FSM F1: `system_reset`, síncrono ativo alto, origem na KEY1 sincronizada.
- Não usar KEY físico como clock ou reset da FSM. Preservar a rota assíncrona existente exclusivamente para `vga_sync`.

### Restrições

- A FSM dedicada pode usar a sintaxe comportamental permitida para FSM em `REGRAS.md`; datapath e demais módulos combinacionais continuam estruturais.
- Um módulo por arquivo. Não usar `buf` nem alterar nenhum RTL PBL02.
- Não modificar `compositor_rgb.v`, `vendor/vga/vga_sync.v`, pin assignments ou SDC.
- Não medir nem afirmar timing nesta TASK. O gate Quartus/timing pertence à TASK-035 com SDC adequado.
- Não implementar FSM principal, F2, LEDs ou displays nesta TASK.

### Arquivos permitidos

- `rtl/funcao/fsm_funcao_f1.v`.
- `rtl/funcao/processador_f1.v`.
- `rtl/entrada/entrada_pbl03.v`.
- `rtl/top/top_pbl03.v`.
- `quartus/pbl03.qsf`.
- `sim/tb_f1_processor.v` (wrapper estrutural).
- `sim/f1_processor_vpi.c`.
- `sim/run_f1_processor_icarus.sh`.
- `docs/tasks/TASK-028.md`.

No QSF, adicionar os módulos acima e todas as dependências da TASK-027: `rtl/aritmetica/full_adder_1bit.v`, `addsub_16.v`, `addsub_18.v`, `addsub_20.v`, `addsub_25.v`, `conditional_negate_8.v`, `conditional_negate_10.v`, `conditional_negate_16.v`, `conditional_negate_18.v`, `conditional_negate_25.v`, `multiply_unsigned_8x8.v`, `multiply_unsigned_8x10.v`, `multiply_unsigned_8x17.v`, `multiply_unsigned_10x10.v`, `signed_less_10.v`, `signed_less_18.v`, `rtl/funcao/avaliador_quadratico_f1.v`, `avaliador_derivada_f1.v`, `validador_vertice_f1.v`, `detector_hits_f1.v` e `datapath_f1.v`.

### Arquivos protegidos

- `rtl/` legado do PBL02 e `quartus/pbl02.*`.
- `rtl/video/compositor_rgb.v` e demais módulos de vídeo fora do top.
- `vendor/vga/vga_sync.v`, `REGRAS.md`, `TEC498_2026_2_Problema3.pdf` e DEC-044 a DEC-048.
- `quartus/pbl03.sdc` e pin assignments, que permanecem fora do escopo.

### Testes exigidos

- VPI externo com referência independente para reset, START, BUSY de um ciclo, DONE retido, captura de validade/erros, display/hits gated, nova execução e START ignorado em `VALIDATE`.
- Cobrir função válida, `a1=0`, vértice fora, reset em cada estado, hits antes/depois de `display_enable` e retenção de erro/DONE.
- Verificar que START aceito em `COMPLETE` baixa DONE na mesma borda e que o handshake rebaixa e eleva `processing_done` para rearmar a entrada.
- Reexecutar `sim/run_coefficient_input_pbl03.sh` sem alterar a TASK-026. A saída adicional de `system_reset` não pode quebrar os callers existentes.
- Elaborar `top_pbl03` com a lista completa do QSF e verificar que o top liga `processador_f1.done` a `entrada_pbl03.processing_done`.
- Executar `sim/run_f1_processor_icarus.sh`, inspeção estrutural e `git diff --check`. A FSM F1 pode usar comportamento autorizado; os datapaths e wrappers devem permanecer nos limites de suas regras.
- Não executar síntese/timing como critério desta TASK. Registrar apenas o que for realmente executado.

### Dependências

- TASK-027 aprovada | interface pública `datapath_f1` e hits brutos sem estado.
- DEC-048 em `CONSENSUS` | sequência FSM F1, saídas retidas, reset e handshake.
- TASK-026 aprovada | `entrada_pbl03`, `start_pulse` e contrato baixo→alto de `processing_done`.

### Pendências

Não há pendência de decisão para esta fatia. Timing, FSM principal, compositor, F2 e sinalização externa ficam nas TASKs posteriores indicadas.

## Resultado

APPROVED. O processador F1 contém a FSM `WAIT_START` → `VALIDATE` → `COMPLETE`, retém DONE e erros, limpa saídas ao aceitar novo START e habilita os hits somente após validação válida. `entrada_pbl03.system_reset` exporta o mesmo reset síncrono derivado de KEY1 sincronizada usado pelos blocos de entrada. O top conecta esse reset e o handshake real `processador_f1.done` → `entrada_pbl03.processing_done`; a rota física `not(KEY[1])` para `vga_sync` foi preservada. A lista QSF foi completada com as dependências aritméticas, datapath e FSM/processador F1.

### Evidências executadas

- `IVERILOG_ROOT=/tmp/task028-iverilog/usr sim/run_f1_processor_icarus.sh` — passou: 92 ciclos VPI, incluindo reset nos estados, START ignorado em VALIDATE, conclusão e retenção, erro `a₁=0`, vértice externo, gating dos hits, captura dos seis coeficientes e duas execuções pelo handshake baixo→alto; elaborou `top_pbl03` com a lista completa de fontes do QSF.
- `IVERILOG_ROOT=/tmp/task028-iverilog/usr sim/run_coefficient_input_pbl03.sh` — passou: 187 passos VPI da regressão da TASK-026, confirmando compatibilidade do caller após a saída aditiva `system_reset`.
- `IVERILOG_ROOT=/tmp/task028-iverilog/usr sim/run_f1_function_icarus.sh` — passou: 3421 casos do datapath F1 da TASK-027.
- Inspeção de integração: `top_pbl03` liga diretamente `processador.done` a `entrada.processing_done`; `entrada.system_reset` deriva de `key1_sync_n`, e `not(reset_vga, KEY[1])` permanece conectado ao reset VGA físico.
- Inspeção estrutural nos módulos alterados: comportamento sequencial está somente na FSM autorizada; wrapper e integração usam instanciação/conexões estruturais. Nenhum `assign`, `buf` ou primitivo identidade foi introduzido nos módulos combinacionais/wrapper.
- `git diff --check` — passou.
- `vendor/vga/vga_sync.v` permaneceu intacto; SHA-256 observado: `6f2e841c45f14888aeb6d8cc58e79ec7e7ca5dafddae7c32ef160381daacccc8`.
- Icarus Verilog 13.0 (stable), extraído localmente em `/tmp/task028-iverilog` dos RPMs Fedora 44 em `/tmp/task027-iverilog-rpm`; `rpm -K` confirmou `digests signatures OK` nos RPMs Icarus e dependências. Nenhuma instalação no sistema foi feita.

Não foi executada síntese, análise de timing ou validação física; esses gates permanecem na TASK-035.

## Resultado da revisão

APPROVED. O Code Auditor repetiu as três regressões e confirmou Compliance, Functional e Integration sem findings.

## Histórico

- 16/11/2026 | Context Analyst marcou BLOCKED: faltam diagrama/tabela da FSM, reset sincronizado acessível no top, allowlist detalhada e base SDC para qualquer alegação de timing. DEC-048 aberta; timing passa ao gate Quartus da TASK-035.
- 16/11/2026 | DEC-048 chegou a CONSENSUS: FSM F1, interface de reset sincronizado, START/DONE, integração top/QSF e escopo de testes definidos. Timing permanece na TASK-035.
- 16/11/2026 | Implementação concluída e evidências registradas pelo Code Implementer; status `IMPLEMENTED`, aguardando auditoria independente.
- 16/11/2026 | Code Auditor repetiu 92 ciclos F1, 187 passos da entrada e 3421 casos datapath; aprovou os três gates sem findings.
