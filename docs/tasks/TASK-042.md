# TASK-042 | Corrigir a polaridade pública do sincronismo VGA

## Objetivo

Adaptar HS/VS ativos em nível baixo nas portas públicas de `top_pbl03`, sem editar o periférico vendorizado, e revalidar os limites temporais da revisão.

## Status

APPROVED

## Decisões relacionadas

- DEC-053 (CONSENSUS): inverter HS/VS somente na integração top-level; manter o arquivo vendor intacto.
- DEC-054 (CONSENSUS): os paths RGB também devem respeitar 40 ns; a otimização estrutural é tratada pela TASK-043 antes da aprovação integrada desta tarefa.
- DEC-044: periférico VGA fornecido e interface de vídeo preservados.
- DEC-045: controle e verificação externos ao Verilog são permitidos.

## Dependências

- TASK-035 | QSF/pinagem aprovados e baseline de Quartus; os relatórios dessa revisão são históricos e não valem para os arquivos atualizados.
- `verification/results/task-036/top-verilator.log` | captura baseline de quadro completo já executada nos ports públicos; serve de harness/cenário de regressão, sem exigir que TASK-036 esteja aprovada. A regressão final após a inversão será evidência desta TASK e permitirá concluir TASK-036, evitando dependência circular.

## Planejamento e aceite

- Criar nets internos para `hsync`/`vsync` brutos e usar inversores estruturais para os ports públicos `VGA_HS` e `VGA_VS`.
- Acrescentar restrição de 40 ns aos caminhos registrador→HS/VS no SDC.
- Verificar pulsos públicos baixos, larguras, frequência de raster, RGB e frame inteiro por estímulo externo.
- Reexecutar compilação, fitting e TimeQuest; registrar atrasos/slacks da nova revisão.
- Confirmar hash inalterado de `vendor/vga/vga_sync.v`.

## Arquivos

Ver lista exata no Implementation Brief. Não alterar portas públicas nem QSF/pinos.

## Resultado

Implementação da polaridade concluída. A validação inicial encontrou duas violações RGB e foi bloqueada; após a otimização estrutural aprovada na TASK-043, a revalidação integrada final passou no frame completo e nos 14 endpoints de timing. Esta TASK está **IMPLEMENTED**, aguardando auditoria de aceite.

## Restrições

- `vendor/vga/vga_sync.v` e `vendor/vga/UPSTREAM.md` permanecem byte a byte inalterados.
- Não modificar `VGA_R/G/B`, coordenadas, blanking ou parâmetros internos do periférico.
- Não inferir validação física na placa a partir de simulação/STA.

## Implementation Brief

### Objetivo

Corrigir a polaridade ativa baixa de `VGA_HS` e `VGA_VS` somente na integração `top_pbl03`, estender o SDC para medir o atraso registrador→sincronismos e validar essa revisão por simulação de quadro completo, compilação, Fitter e TimeQuest.

### Requisitos

- Manual DE10-Lite, figura 3-22: HSync ativo baixo e 96 períodos de pixel; temporização de VSync análoga, 2 linhas.
- Interface PBL03 de VGA e REQ-015: preservar sincronismos, raster e RGB, com simulação/revisão reproduzível.

### Decisões aplicáveis

- DEC-053 (CONSENSUS): inversores estruturais nos ports públicos HS/VS, vendor intacto, restrições 40 ns e verificação só nos ports públicos.
- DEC-044: transformar coordenadas e gerar RGB pelo periférico fornecido, sem alterar raster, RGB ou coordenadas.
- DEC-045: simulação por harness externo; C++/Verilator atende sem descrição comportamental de estímulo em Verilog.
- DEC-052: regressão base (quatro curvas) em TASK-036 e quinta cor/interseções somente em TASK-037.
- TASK-035: mapa de pinos, QSF e reporte aprovados são a baseline anterior; os números anteriores não são evidência para a revisão nova.

### Módulos e arquivos envolvidos

- `rtl/top/top_pbl03.v`: adicionar wires internos para `hsync_raw` e `vsync_raw`; conectar as saídas do `vga_sync` às nets e dirigir `VGA_HS`/`VGA_VS` por duas portas estruturais `not`.
- `vendor/vga/vga_sync.v`: instância existente, sem edição.
- `quartus/pbl03.sdc`: acrescentar `set_max_delay 40.000 -from [all_registers] -to [get_ports {VGA_HS VGA_VS}]`, mantendo clock 20 ns, restrição RGB e false paths estreitos de KEY. Não criar clocks fictícios, false paths ou multicycle para HS/VS.
- `sim/pbl03_top_verilator.cpp`: adaptar o harness existente para esperar sincronismos públicos ativos baixos, verificar polaridade/larguras, fases observadas externamente e o mesmo quadro completo de RGB.
- `sim/run_pbl03_top_verilator.sh`: executar a compilação e simulação adaptadas usando as fontes listadas no QSF, sem alterar o QSF.
- `verification/results/task-042/**`: guardar stdout/log da simulação, comandos/hash/versão de Verilator, relatórios Quartus e relatório TimeQuest focado nos caminhos VGA novos.
- `docs/tasks/TASK-042.md`: resultados reais e apontadores para as evidências novas.

### Interface

Não alterar ports ou assignments físicos. `VGA_HS` e `VGA_VS` continuam saídas de 1 bit, agora ativas baixas conforme o contrato público. `VGA_R/G/B[3:0]`, `KEY[1:0]`, clock, switches, LEDs e HEX permanecem sem mudança.

### Clock e reset

- `MAX10_CLK1_50`, 50 MHz, é o clock primário existente.
- O `vga_sync` recebe o mesmo clock e reset assíncrono ativo alto atual; a lógica de raster não muda.
- HS deve ficar baixo por 96 amostras de pixel em cada linha, uma janela a cada 800 pixels; VS deve ficar baixo por 2 linhas em um quadro de 525 linhas. O frame contém 800×525 períodos de pixel e a fase deve ser inferida pelos sinais públicos, sem sondas internas.

### Restrições

- Usar somente primitivas estruturais `not` no top para inverter sinais raw; sem `assign`, `buf`, alteração de estado, inversor RTL comportamental ou renomeação das portas físicas.
- Não mudar `quartus/pbl03.qsf`, pinagem (N3/N1), interface top-level ou arquivos do projeto PBL02.
- Não tocar `vendor/vga/**`; validar o SHA-256 contra `vendor/vga/UPSTREAM.md` antes/depois.
- Sem alterar RGB/blanking/coordenadas/temporizações originais do raster. O harness deve dirigir apenas ports do top.
- Não reaproveitar relatórios da TASK-035 como resultado da revisão alterada; manter aqueles artefatos e a documentação intactos.
- Simulação/STA não afirmam validação em monitor ou placa.

### Arquivos permitidos

- `rtl/top/top_pbl03.v`
- `quartus/pbl03.sdc`
- `sim/pbl03_top_verilator.cpp`
- `sim/run_pbl03_top_verilator.sh` (somente se necessário para incorporar execução/logs; preservar o propósito e fontes canônicas)
- `verification/results/task-042/**` (relatórios completos/sumários de compilação, Fitter, TimeQuest, sincronismos e hash do vendor para a nova revisão)
- `docs/tasks/TASK-042.md`

`quartus/output_files_pbl03/**` pode ser escrito como saída gerada pela compilação configurada no QSF; a evidência versionada desta revisão deve ser copiada para `verification/results/task-042/**`. Não substituir os relatórios arquivados em `verification/results/quartus/pbl03/**` que documentam TASK-035.

### Arquivos protegidos

- `vendor/vga/**`, `quartus/pbl03.qsf`, `quartus/pbl02.*`, todos os outros `rtl/**`, `sim/**` fora da lista permitida, `docs/decisions/**` e requisitos.
- Relatórios históricos `docs/tasks/TASK-035.md` e `verification/results/quartus/pbl03/**`; não os reescrever para refletir novos números.
- `verification/results/task-036/top-verilator.log` e `existing-runners.log`: são preflight/baseline preservados, não saídas para sobrescrever nesta TASK.

### Testes exigidos

1. Registrar revisão/hash do working tree, versão de Quartus e Verilator, comandos, stdout/stderr e resultado de cada etapa.
2. Executar `python3 verification/check_pbl03_sources.py`; garantir que a alteração continua fora do QSF e a lista de fontes/VGA permanecem canônicas.
3. Executar `sim/run_pbl03_top_verilator.sh` com o harness atualizado: capturar um quadro completo nos ports públicos, verificar 525 pulsos HS e um pulso VS ativo baixo, as larguras/intervalos de 96/800 pixels e 2 linhas, fase por transições externas, RGB/blanking e os quatro traços/eixos do quadro base. Não incluir quinta cor/interseção (TASK-037).
4. Verificar hash inalterado de `vendor/vga/vga_sync.v` contra `UPSTREAM.md`.
5. Reexecutar nesta revisão `quartus_map --read_settings_files=on --write_settings_files=off pbl03`, `quartus_fit --read_settings_files=on --write_settings_files=off pbl03` e `quartus_sta pbl03` no Quartus Prime Lite 25.1std.0.
6. Executar relatório TimeQuest específico de `[all_registers]` para `VGA_HS` e `VGA_VS`, além dos paths RGB existentes; registrar data delay e slack reais, restrição aplicada e mensagem sobre paths sem constrangimento.
7. Copiar para `verification/results/task-042/` resultados atuais de A&S/Fitter/STA, path RGB re-medido e paths HS/VS. Não apontar os arquivos da TASK-035 como resultados desta revisão.

### Casos de borda

- Contar baixo ativo, não apenas transições: HS baixo por `96×525=50.400` amostras por quadro; VS baixo por `2×800=1.600`; ambos altos fora das respectivas janelas.
- Garantir 525 intervalos de HS por quadro, 800 pixels por linha, 480×640 área ativa, syncs e blanking corretos.
- Conferir que RGB frame/reference e prioridades base permanecem idênticos ao baseline exceto pela polaridade pública de HS/VS.
- As saídas públicas não podem oscilar fora de uma única inversão de nível em relação aos sinais raw. A regressão não deve depender de hierarquia interna.
- Na STA, conferir 40 ns aplicado a cada bit de VGA_HS/VS e ao RGB; não mascarar esses paths com exceções amplas.
- Se A&S/Fitter/TimeQuest falhar ou algum dos paths 40 ns tiver slack negativo, registrar resultado real e interromper mudanças além deste escopo para decisão técnica; não inferir pass.

### Critérios de aceite

- Apenas `top_pbl03` e SDC são alterados em RTL/constraints; QSF, ports, pinos e periférico upstream permanecem idênticos.
- Os ports HS/VS observados externamente satisfazem polaridade ativa baixa, contagens e larguras documentadas.
- Regressão Verilator de quadro completo passa para RGB/blanking e sinais públicos e registra revisão e ferramenta.
- Quartus A&S/Fitter/TimeQuest executados na revisão nova, com 0 erros e sem violação dos limites máximos de 40 ns para cada caminho obrigatório HS/VS/RGB. Avisos reais e status de constrangimento são registrados.
- Relatórios completos e foco HS/VS/RGB estão sob `verification/results/task-042/**`, separados do resultado histórico TASK-035.
- SHA-256 do periférico permanece igual a `UPSTREAM.md`.

### Dependências e sequenciamento sem ciclo

- TASK-035 `APPROVED`: fonte do baseline QSF/pinos/SDC; seus resultados permanecem históricos.
- `verification/results/task-036/top-verilator.log`: log preexistente que revela e registra a polaridade anterior; é artefato disponível sem depender da aprovação de TASK-036.
- TASK-036 aguarda os novos artefatos desta TASK, em especial `verification/results/task-042/top-verilator-active-low.log` e relatórios Quartus/STA. Depois que TASK-042 for aprovada, TASK-036 reexecuta a regressão integrada completa com o contrato corrigido.
- DEC-053 está `CONSENSUS`; não falta decisão arquitetural.

### Pendências

- Timing externo do monitor e validação na DE10-Lite física permanecem pendentes e fora desta tarefa.
- A quinta cor/interseções não fazem parte do frame base desta TASK; permanecem para TASK-037 conforme DEC-052.

### Resultado do Context Analyst

**READY_FOR_IMPLEMENTATION.** DEC-053 fecha implementação e critério temporal; todos os arquivos e comandos estão identificados. A dependência usa o artefato de quadro existente da TASK-036, e a TASK-036 passa a consumir a evidência nova da TASK-042, eliminando o ciclo. Os relatórios TASK-035 permanecem históricos; a compilação corrente deve gerar e arquivar evidências em `verification/results/task-042/**`.

### Implementação e evidências

Arquivos de projeto alterados: `rtl/top/top_pbl03.v` (dois inversores estruturais nas saídas públicas HS/VS), `quartus/pbl03.sdc` (limite de 40 ns registrador→HS/VS) e `sim/pbl03_top_verilator.cpp` (checagem pública ativa baixa). `vendor/vga/vga_sync.v` permaneceu byte a byte inalterado.

Validações concluídas em 2026-11-18, Quartus Prime Lite 25.1std.0 Build 1129 e Verilator 5.053 devel:

- `python3 verification/check_pbl03_sources.py`: PASS; `git diff --check`: PASS.
- `sim/run_pbl03_top_verilator.sh` no container `hdlc/verilator:latest`: PASS; frame 800×525, HS baixo em 50.400 amostras/525 intervalos, VS baixo em 1.600 amostras/1 pulso, 307.200 pixels ativos, 112.800 blanking, traços/eixos e RGB conferidos; 1.680.469 checks. O frame foi alinhado por `VGA_VS` público e checado somente pelos ports do top.
- `quartus_map --read_settings_files=on --write_settings_files=off pbl03`: PASS, 0 erros, 31 avisos.
- `quartus_fit --read_settings_files=on --write_settings_files=off pbl03`: PASS, 0 erros, 3 avisos.
- `quartus_sta pbl03`: execução concluída sem erros; o projeto permanece globalmente não totalmente constrained para setup/hold, como registrado no relatório. A análise focada encontra paths registrador→HS/VS limitados a 40 ns: `VGA_HS` data delay 6.098 ns/slack 30.278 ns; `VGA_VS` 6.800 ns/29.550 ns.
- **Evidência histórica pré-TASK-043:** o relatório RGB inicial encontrou violações em `VGA_B[0]` (slack −0.061 ns) e `VGA_B[2]` (−0.016 ns). Após DEC-054 e TASK-043 aprovada, a revalidação abaixo substitui esse resultado para o estado final integrado.
- SHA-256 do periférico: `6f2e841c45f14888aeb6d8cc58e79ec7e7ca5dafddae7c32ef160381daacccc8`, igual a `vendor/vga/UPSTREAM.md`.

Evidências da implementação inicial: `verification/results/task-042/top-verilator-active-low.log`, `quartus-map.log`, `quartus-fit.log`, `quartus-sta.log`, `vga-paths.txt`, os relatórios completos `.rpt`/`.summary`, `source-check.log`, `diff-check.log` e `vendor-vga.sha256`.

### Revalidação integrada após TASK-043

Após TASK-043 `APPROVED` e DEC-054 `CONSENSUS`, os gates integrados foram repetidos sem alteração adicional em RTL/constraints nesta etapa. Evidências novas e completas estão em `verification/results/task-042/final/`.

- `python3 verification/check_pbl03_sources.py`: PASS; `git diff --check`: PASS.
- Harness Verilator 5.053 devel (`hdlc/verilator:latest`): PASS; frame público 800×525, HS baixo em 50.400 amostras/525 períodos, VS baixo em 1.600 amostras/1 pulso, 307.200 pixels ativos, 112.800 blanking, RGB, quatro curvas/eixos e fase conferidos; 1.680.469 checks e 1.661.568 ciclos de clock.
- Quartus Prime Lite 25.1std.0 Build 1129: A&S PASS (0 erros, 31 avisos); Fitter PASS (0 erros, 3 avisos); TimeQuest PASS (0 erros, 0 avisos). A STA global ainda informa que setup/hold não estão totalmente constrained.
- `vga-paths-full.log` detalha os 14 endpoints sob max delay de 40.000 ns no modelo slow. Todos têm slack positivo. `endpoint-summary.txt` lista startpoint, data arrival e slack; menor margem é 2.112 ns em `VGA_R[2]`. RGB R/G/B[3:0]: 2.138/2.127/2.112/2.133 ns; 2.446/2.833/2.494/2.484 ns; 2.555/2.538/2.685/2.626 ns. `VGA_HS`: 30.907 ns; `VGA_VS`: 30.742 ns.
- SHA-256 de `vendor/vga/vga_sync.v`: `6f2e841c45f14888aeb6d8cc58e79ec7e7ca5dafddae7c32ef160381daacccc8`, conforme `UPSTREAM.md`.

Os arquivos `quartus-map.log`, `quartus-fit.log`, `quartus-sta.log`, `pbl03.*.rpt`, `pbl03.*.summary`, `top-verilator-active-low.log`, `vga-paths-full.log`, `endpoint-summary.txt`, hashes e check logs preservam esta revisão. Avisos reais (incluindo `inside_y` do Verilator) permanecem registrados. Não houve validação em monitor ou placa física.

**APPROVED.** A integração final está revalidada após TASK-043. TASK-036 permanece em seu próprio fluxo de regressão; esta aprovação não afirma validação física.

### Auditoria independente

**APPROVED — 2026-11-18.**

- **Compliance Gate:** HS/VS recebem saídas raw do `vga_sync` e são invertidos por duas portas estruturais `not` no top. O SDC acrescenta somente max delay 40 ns para HS/VS, sem false path ou multicycle novo. Ports e pin assignments não mudaram; QSF e `vendor/vga/**` estão inalterados. Hash do VGA é igual a `UPSTREAM.md`.
- **Functional Gate:** a evidência final do Verilator observa somente ports públicos, cobre um frame de 800×525, 525 pulsos HS e um VS ativo baixo, 50.400 amostras HS baixas, 1.600 VS baixas, 307.200 pixels ativos, 112.800 em blanking e comparação RGB/curvas/eixos; 1.680.469 checks passaram.
- **Timing Gate:** Map/Fitter/STA concluíram sem erros (31/3/0 avisos). O relatório slow-model detalha todos os 14 endpoints a 40 ns; todos têm slack positivo. O menor é +2.112 ns em `VGA_R[2]`; HS +30.907 ns e VS +30.742 ns.
- **Integration Gate:** o harness e a integração do top foram repetidos após TASK-043, sem alteração de RTL/constraints nessa revalidação. Os relatórios iniciais com slack RGB negativo continuam preservados como histórico; não são usados para sustentar o resultado final. QSF, portas e periférico do professor permanecem preservados.
- **Findings HIGH/CRITICAL:** nenhum.
- **Limitação registrada:** TimeQuest ainda informa que setup/hold não estão totalmente constrained globalmente. Todos os endpoints VGA exigidos nesta tarefa estão individualmente limitados e medidos. Não houve validação em monitor ou placa física.

Evidências finais: `verification/results/task-042/final/`.
