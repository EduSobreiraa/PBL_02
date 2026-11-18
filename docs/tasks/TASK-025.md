# TASK-025 | Isolar e modularizar a integração inicial do PBL03

## Objetivo

Iniciar a árvore RTL do PBL03 com uma integração VGA mínima, separando `top_pbl03`, transformação de coordenadas, detector de eixos e compositor RGB em arquivos próprios. Preservar os fontes e o projeto Quartus do PBL02 sem alterações.

## Status

APPROVED | implementação e auditoria independente concluídas. Simulação Icarus/VPI passou nos nove casos; Analysis & Synthesis Quartus foi executado via CLI com 0 erros e 4 warnings. Sem evidência de timing, fit ou validação física.

## Requisitos relacionados

- PBL03 PDF §4.5-6, resolução, origem, escala e periférico fornecido.
- PBL03 PDF §5.3-4, Verilog estrutural e integração com o periférico.
- `REGRAS.md` §§2, 5 e 6.

## Decisões relacionadas

- DEC-043 | organização faseada e preservação da referência PBL02.
- DEC-044 | origem, escala, clipping, paleta e composição.
- DEC-045 | invólucro Verilog estrutural com estímulos/verificação em script externo.

## Dependências

- Nenhuma.
- A revisão upstream de `vga_sync.v` deve ser identificada ao importá-la.

## Restrições aplicáveis

- Criar a integração no escopo PBL03, usando `rtl/top/` e `rtl/video/`.
- Um módulo por arquivo `.v`.
- Não modificar `rtl/*.v` do PBL02, `quartus/pbl02.*` ou seus testbenches.
- Importar `vga_sync.v` em `vendor/vga/` sem qualquer alteração e registrar URL, revisão e hash.
- A lógica desenvolvida pela equipe deve seguir `REGRAS.md`; `vga_sync.v` continua sendo periférico externo e intacto.
- Sem `assign`, `generate`, `for`, `buf`, `always` ou `initial` nos módulos estruturais da equipe.
- Não definir pin assignments nesta TASK.

## Arquivos permitidos

- `rtl/top/top_pbl03.v`
- `rtl/video/coordenadas_cartesianas.v`
- `rtl/video/detector_eixos.v`
- `rtl/video/compositor_rgb.v`
- `vendor/vga/vga_sync.v` e um registro de origem/revisão em `vendor/vga/`
- `sim/tb_video_axes.v`
- `sim/run_video_axes.do`
- `sim/video_axes_icarus_vpi.c`
- `sim/run_video_axes_icarus.sh`
- `quartus/pbl03.qpf`
- `quartus/pbl03.qsf`
- `docs/tasks/TASK-025.md`

## Arquivos protegidos

- Todos os fontes legados em `rtl/` fora dos novos diretórios `top/` e `video/`.
- `quartus/pbl02.qpf`, `quartus/pbl02.qsf`, `quartus/pbl02.sdc` e `testbench/`.
- `TEC498_2026_2_Problema3.pdf`, `REGRAS.md`, DEC-043, DEC-044 e DEC-045.
- A cópia upstream de `vga_sync.v` após sua importação nesta TASK.

## Plano

1. Importar a versão upstream de `vga_sync.v` e registrar sua origem e hash antes de qualquer integração.
2. Criar um top-level PBL03 separado do `modulo_principal` legado.
3. Conectar o raster externo aos módulos separados de coordenadas, eixos e RGB.
4. Exibir fundo preto e eixos na origem sem alterar a transformação cartesiana nem a escala.
5. Criar projeto Quartus PBL03 com somente as fontes desta integração. Deixar pinagem física para uma TASK posterior, com assignments próprios do PBL03.

## Critérios de aceite

- Os eixos cruzam o pixel (320,240); x cartesiano cobre −320…319 e y cartesiano −239…240.
- A saída fica preta fora dos eixos e respeita `video_on`.
- A origem e a escala mantêm os contratos de DEC-044.
- O top-level PBL03 usa somente os novos arquivos PBL03 e o periférico em `vendor/vga/`; não inclui fontes PBL02.
- `quartus/pbl03.qsf` define `top_pbl03` e inclui somente as fontes PBL03 e o periférico registrado. Não contém assignments de pinos nem altera `pbl02.qsf`.
- O conteúdo importado de `vga_sync.v` corresponde à revisão registrada e permanece byte a byte intacto.
- Os módulos criados seguem a restrição de um módulo por arquivo e as regras estruturais.
- A simulação confirma coordenadas, eixos, reset e apagamento fora da área visível.

## Testes

- Testbench dedicado para os limites de x/y, origem, eixos, `video_on` e reset.
- Invólucro Verilog estrutural e driver externo VPI para estímulo e comparação com Icarus, conforme DEC-045. `sim/run_video_axes.do` permanece como alternativa para Questa.
- Compilar e elaborar o top com Icarus 13.0 e executar o driver C via `vvp`, verificando coordenadas, eixos, RGB, `video_on` e polaridade do reset.
- Checagem de integridade do arquivo importado contra o hash registrado.
- Inspeção estrutural e `git diff --check`.
- Executar Analysis & Synthesis do projeto PBL03 pela interface do Quartus e registrar resultado e warnings.
- Não alegar síntese ou teste físico nesta TASK.

## Resultado da implementação

RTL da integração mínima criado. `detector_eixos` compara as coordenadas cartesianas signed10 com zero; assim, reutiliza diretamente a transformação cartesiana do mesmo fluxo.

### Arquivos modificados

- `rtl/top/top_pbl03.v`
- `rtl/video/coordenadas_cartesianas.v`
- `rtl/video/detector_eixos.v`
- `rtl/video/compositor_rgb.v`
- `vendor/vga/vga_sync.v`
- `vendor/vga/UPSTREAM.md`
- `sim/tb_video_axes.v`
- `sim/run_video_axes.do`
- `sim/video_axes_icarus_vpi.c`
- `sim/run_video_axes_icarus.sh`
- `quartus/pbl03.qpf`
- `quartus/pbl03.qsf`
- `docs/tasks/TASK-025.md`

### Testes executados

- `sha256sum vendor/vga/vga_sync.v` | corresponde ao hash registrado.
- `git diff --check` | passou.
- `quartus_map pbl03` no diretório `quartus/` | Analysis & Synthesis passou, 0 erros.
- `sim/run_video_axes_icarus.sh` | passou; compilou o driver VPI com GCC, elaborou a árvore estrutural com Icarus 13.0 e `vvp` informou `VPI PASS` para todos os nove casos.
- Verificação negativa: alterei temporariamente a expectativa inicial de x para provocar divergência; o driver imprimiu `VPI FAIL` e o script saiu com status 1. Restaurei a expectativa e reexecutei o comando normal, que passou os nove casos.
- `vsim -c -do sim/run_video_axes.do` na raiz do repositório | tentativa anterior não iniciou por licença Questa ausente; esse `.do` é opcional e o gate funcional foi executado com Icarus.
- `whereis iverilog` e busca de executável em `/usr`, `/opt` e `/home/edupires` | na primeira tentativa, o Icarus não estava instalado. Depois, Icarus 13.0 e `iverilog-devel` foram extraídos em `/tmp/iverilog-local`, sem instalação de sistema.
- `/tmp/iverilog-local/usr/bin/iverilog -g2005 -s top_pbl03 -o /tmp/pbl03.vvp ...` | compilação/elaboração do top, módulos de vídeo e `vga_sync.v` passou. Isso não substitui a simulação funcional.
- Inspeção do shell estrutural e `rg -n '\b(assign|generate|for|buf|always|initial)\b' rtl/top rtl/video sim/tb_video_axes.v` | sem ocorrências proibidas nos módulos RTL e wrapper. `git diff --check` não reportou whitespace. Os diretórios de saída temporários gerados pelo Quartus foram removidos.

### Warnings e observações

- Quartus emitiu dois warnings de truncamento de parâmetros inteiros para 10 bits na fonte externa imutável `vga_sync.v` e um warning de `KEY[0]` não dirigir lógica nesta fatia (reservado para etapas posteriores; o detalhe de dependência de saída aparece como warning associado). A advertência de contagem de processadores foi eliminada configurando `NUM_PARALLEL_PROCESSORS 2` no QSF PBL03.
- O Analysis & Synthesis foi executado pela ferramenta `quartus_map` em linha de comando; a GUI Quartus não foi exposta como app controlável nesta sessão. Nenhuma análise de timing, fit ou validação física foi executada.
- A simulação funcional e de polaridade de reset passou via Icarus/VPI. O `.do` opcional do Questa não foi executado por indisponibilidade de licença.
- `vga_sync.v` foi importado da revisão `ad9560eb32b1a143e268274feb912a81b64d6155`; SHA-256 esperado e observado: `6f2e841c45f14888aeb6d8cc58e79ec7e7ca5dafddae7c32ef160381daacccc8`.


## Resultado das ferramentas

Analysis & Synthesis aprovado por `quartus_map pbl03`: 0 erros, 4 warnings no total (dois truncamentos na fonte externa `vga_sync.v`, `KEY[0]` sem uso nesta fatia e detalhe associado). O driver VPI/Icarus executou e passou os nove casos, incluindo os limites cartesianos, origem, eixos, cor, clipping `video_on` e polaridade KEY1.

## Resultado da revisão

**APPROVED | auditoria independente, ciclo 2.** O finding `FIND-025-001` do ciclo anterior foi resolvido: o runner externo Icarus/VPI executou os casos funcionais com sucesso. Nenhum finding aberto.

### Gates atuais

- **Compliance | PASS:** módulos RTL da equipe e o wrapper são estruturais, um módulo por arquivo, sem construções proibidas. O driver C/VPI é externo ao Verilog e compatível com DEC-045. QSF sem pin assignments e sem fontes PBL02.
- **Functional | PASS:** executei independentemente `sim/run_video_axes_icarus.sh`; os nove casos passaram. Cobertura: limites x=0/639 e y=0/479, origem, eixos, pixel fora dos eixos, RGB preto durante `video_on=0` e os níveis pressionado/solto de KEY1. As expectativas são valores fixos independentes da lógica estrutural. O VPI também falha explicitamente em divergência.
- **Integration | PASS:** top-level, larguras, polaridade do reset e conexões são coerentes. O QSF define `top_pbl03` e contém somente os RTL PBL03 e o `vga_sync.v` registrado. Os arquivos legados PBL02 e seu projeto permanecem sem alterações. O hash observado do periférico confere com a revisão documentada.

### Caveat do Quartus

O resultado disponível é **Analysis & Synthesis via `quartus_map` na CLI**, com 0 erros e 4 warnings, não execução pela GUI. Dois warnings referem-se a truncamentos de parâmetros inteiros no `vga_sync.v` externo e imutável; os demais indicam `KEY[0]` sem uso nesta fatia e o detalhe associado de dependência de saída. Isso não demonstra timing, fit, recursos finais nem operação na placa; essas verificações não fazem parte da aprovação desta TASK.

### Finding resolvido

- **FIND-025-001 | resolvido:** a execução do runner confirmou os nove checks e terminou com `VPI PASS: all 9 video axis cases passed`.

### Evidência de simulação

Comando repetido durante esta auditoria na raiz do repositório: `sim/run_video_axes_icarus.sh`. Os nove marcadores `VPI PASS` foram observados, inclusive o marcador final. O runner compilou o driver C com `-Wall -Wextra -Werror`, elaborou as fontes e executou o driver via `vvp`.

Saída:

```text
VPI PASS: left x boundary and horizontal axis
VPI PASS: right x boundary
VPI PASS: top y boundary and vertical axis
VPI PASS: bottom y boundary and vertical axis
VPI PASS: origin activates both axes
VPI PASS: off-axis pixel is black
VPI PASS: video_on clips axis pixel to black
VPI PASS: KEY1 pressed asserts active-high VGA reset
VPI PASS: KEY1 released deasserts VGA reset
VPI PASS: all 9 video axis cases passed
```

## Pendências

- Definir pin assignments VGA em tarefa separada.
- Expandir o top-level para entrada, displays e LEDs nas TASKs correspondentes.

## Histórico

- 15/11/2026 | TASK criada como PLANNED para isolar a base PBL03 sem alterar o projeto PBL02.
- 15/11/2026 | DEC-045 definiu shell Verilog estrutural e script externo, sem exceção comportamental para testbench.
- 15/11/2026 | Auditoria independente, ciclo 2: Compliance, Functional e Integration aprovados; finding FIND-025-001 fechado após execução Icarus/VPI dos nove casos. Quartus limitado a Analysis & Synthesis via CLI; timing, fit e validação física não executados.

## Implementation Brief

### Objetivo

Criar uma integração VGA inicial do PBL03, separada do top-level PBL02, com transformação de coordenadas, detecção dos eixos, composição RGB e o periférico `vga_sync.v` importado sem alterações. Preservar o RTL e o QSF PBL02.

### Requisitos

- TEC498_2026_2_Problema3.pdf §§4.5-6 e 5.3-4.
- `REGRAS.md` §§2, 5 e 6.

### Decisões aplicáveis

- DEC-043 | roteiro faseado, isolamento do PBL02 e auditoria de fontes reutilizadas.
- DEC-044 | raster direto, origem, escala, paleta, reset do periférico e composição.
- DEC-045 | estímulos e comparações pelo script do simulador, sem Verilog comportamental no testbench.

### Módulos envolvidos

- `top_pbl03` | nova integração de clock, KEY1, `vga_sync`, coordenadas, eixos e RGB.
- `vga_sync` | periférico externo existente na fonte upstream; portas `clk`, `reset`, `hsync`, `vsync`, `video_on`, `p_tick`, `x[9:0]` e `y[9:0]`.
- `coordenadas_cartesianas` | recebe x/y pixel de 10 bits e produz x/y cartesiano signed10.
- `detector_eixos` | recebe x/y cartesiano signed10 e indica os eixos nos valores zero, mantendo-se derivado das coordenadas VGA transformadas.
- `compositor_rgb` | recebe `video_on` e detecção dos eixos; produz RGB de 4 bits por canal, branco nos eixos e preto no restante.

### Interface

- `top_pbl03`: entrada `MAX10_CLK1_50` (1 bit), entrada `KEY[1:0]`, saídas `VGA_HS` e `VGA_VS` (1 bit cada), `VGA_R`, `VGA_G` e `VGA_B` (4 bits cada).
- Nesta fatia, `KEY[1]` dirige o reset do periférico VGA. `KEY[0]` e as portas de entrada, display e LEDs do sistema completo ficam para TASKs posteriores.
- `coordenadas_cartesianas`: entradas `x_pixel[9:0]`, `y_pixel[9:0]`; saídas `x_cartesiano[9:0]` e `y_cartesiano[9:0]`, ambas signed.
- `detector_eixos`: entradas x/y cartesiano signed10; saídas `eixo_horizontal` e `eixo_vertical`.
- `compositor_rgb`: entradas `video_on`, `eixo_horizontal`, `eixo_vertical`; saídas `red[3:0]`, `green[3:0]`, `blue[3:0]`.
- Usar conexões nomeadas ao instanciar `vga_sync`; não alterar sua declaração nem implementação.

### Clock e reset

- Clock de entrada: `MAX10_CLK1_50`, 50 MHz.
- A interface de `vga_sync.v` usa reset assíncrono ativo alto. O botão KEY1 da DE10-Lite é ativo baixo; o top converte a polaridade para dirigir a porta `reset` existente.
- Esta TASK não define o circuito de reset das FSMs do sistema completo.

### Restrições

- Criar um módulo por arquivo nos caminhos permitidos.
- Implementar a lógica da equipe estruturalmente, sem `assign`, `generate`, `for`, `buf`, `always` ou `initial` nos módulos combinacionais.
- O invólucro Verilog de simulação também é estrutural. O driver VPI externo fornece estímulos e verifica as saídas, conforme DEC-045; o `.do` é uma alternativa para Questa.
- `vga_sync.v` é externo, contém lógica comportamental e fica isento destas restrições conforme `REGRAS.md` §2.8. Importar uma revisão identificada e registrar URL, commit e hash SHA-256.
- Não definir pin assignments nem alterar `quartus/pbl02.*`.
- Avaliar somente a área ativa. Durante blanking, `video_on=0` e a saída RGB deve ser preta.

### Arquivos permitidos

- `rtl/top/top_pbl03.v`
- `rtl/video/coordenadas_cartesianas.v`
- `rtl/video/detector_eixos.v`
- `rtl/video/compositor_rgb.v`
- `vendor/vga/vga_sync.v` e registro da origem em `vendor/vga/`
- `sim/tb_video_axes.v`
- `sim/run_video_axes.do`
- `sim/video_axes_icarus_vpi.c`
- `sim/run_video_axes_icarus.sh`
- `quartus/pbl03.qpf`
- `quartus/pbl03.qsf`
- `docs/tasks/TASK-025.md`

### Arquivos protegidos

- RTL legado de PBL02 na raiz `rtl/`, inclusive `rtl/modulo_principal.v`.
- `quartus/pbl02.qpf`, `quartus/pbl02.qsf`, `quartus/pbl02.sdc` e `testbench/`.
- PBL03 PDF, `REGRAS.md`, DEC-043, DEC-044, DEC-045 e qualquer arquivo não listado como permitido.
- Depois de importado, `vendor/vga/vga_sync.v` deve permanecer byte a byte igual à fonte identificada.

### Testes exigidos

- Exercitar x/y nas bordas e na origem (320,240), verificar as faixas cartesianas −320…319 e −239…240.
- Verificar cada eixo, o cruzamento da origem, fundo preto, `video_on=0` e reset.
- Comparar o hash do periférico com o hash registrado.
- Executar o invólucro estrutural com `sim/run_video_axes_icarus.sh`, inspeção estrutural e checagem de whitespace; registrar comandos e resultados reais. O `.do` é opcional e específico para Questa.
- Executar Analysis & Synthesis do novo projeto PBL03 sem pin assignments. Registrar resultado e warnings; usar `quartus_map` pela CLI quando a GUI não estiver disponível. Timing e fit de placa ficam fora desta TASK.

### Casos de borda

- Pixel (320,240) ativa os dois eixos.
- x=0 e x=639 mapeiam para −320 e 319.
- y=0 e y=479 mapeiam para 240 e −239.
- Pixels de blanking nunca acendem RGB mesmo quando os bits de coordenada coincidirem com uma condição de eixo.
- KEY1 pressionado gera nível alto no reset do periférico; solto gera nível baixo.

### Critérios de aceite

- O top-level PBL03 instancia apenas os módulos PBL03 desta TASK e o `vga_sync` registrado; nenhum arquivo PBL02 entra nesta integração.
- Os eixos cruzam o centro da tela, a transformação preserva origem e escala, e a saída é preta fora dos eixos e da área visível.
- `vga_sync.v` permanece intacto e sua origem, commit e hash estão registrados.
- A simulação e as checagens estruturais passam; registrar separadamente a evidência de Analysis & Synthesis. Não alegar timing, fit ou validação física.

### Dependências

- DEC-043 CONSENSUS.
- DEC-044 CONSENSUS.
- DE10-Lite User Manual, §3.3 para polaridade de KEY1.
- Upstream `LordWalace/Controlador-VGA-DE10-Lite`, revisão específica a registrar na importação.

### Pendências

- Pin assignments e análise de timing ficam fora desta TASK.

### Resultado do Context Analyst

**READY_FOR_IMPLEMENTATION** | DEC-045 define invólucro estrutural e estímulos/verificações externos. Interfaces e reset do VGA estão especificados; o periférico upstream foi fixado na revisão `ad9560eb32b1a143e268274feb912a81b64d6155` com hash SHA-256 `6f2e841c45f14888aeb6d8cc58e79ec7e7ca5dafddae7c32ef160381daacccc8`. Questa Altera Starter FPGA Edition 2025.2 e Quartus Prime 25.1std.0 estão instalados. A task não exige pin assignments, síntese física ou teste na placa. Nenhuma simulação ou compilação Quartus foi executada nesta análise inicial. Uma análise de contexto posterior confirmou a compatibilidade do driver VPI com DEC-045 após Icarus 13.0 e `iverilog-devel` serem extraídos localmente.

- 15/11/2026 | RTL, projeto Quartus PBL03, registro do periférico e script externo criados; Analysis & Synthesis passou via CLI. Simulação marcada BLOCKED por licença Questa indisponível.

- 15/11/2026 | driver C via VPI e script Icarus executados: nove casos funcionais passaram; finding de ausência de simulação fica resolvido, status atualizado para IMPLEMENTED aguardando auditoria.
