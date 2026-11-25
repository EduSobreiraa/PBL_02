# TASK-045 — ROM de glifos e renderizador do prompt VGA

## Objetivo

Implementar a fonte combinacional estrutural `glyph_5x7` compartilhada e o renderizador isolado da frase `Insira a1.b1.c1...`. Esta TASK não integra top/compositor; essa integração conjunta é da TASK-046, após TASK-044 e TASK-045.

## Status

APPROVED

## Requisitos

- Solicitação explícita do responsável em 24/11/2026: mostrar `Insira a1.b1.c1...` antes do gráfico.
- REQ-015: produzir teste/simulação reproduzível.
- REGRAS.md §§2, 5, 6 e 8.

## Decisões aplicáveis

- DEC-066 (CONSENSUS): texto literal branco, centralizado, habilitado até `frame_ready && processing_done`; o fundo é preto e camadas gráficas/quadro ficam ocultas.
- DEC-068 (CONSENSUS): payload da tabela e validade do frame.
- DEC-069 (CONSENSUS): interface, 32 IDs, bitmaps, offsets e compartilhamento da fonte.
- DEC-051: não restaurar painel lateral nem exibição VGA de coeficientes.

## Implementation Brief

### Módulos e interface

- `glyph_5x7(input [4:0] glyph_id, input [2:0] row, input [2:0] column, output pixel)`. `row=0…6` e `column=0…4`; fora dos limites, `pixel=0`. A fonte não tem posição, enable, conteúdo ou estado.
- `renderizador_prompt_vga(input [9:0] x_pixel, input [9:0] y_pixel, input video_on, input prompt_mode, output prompt_white)`. A saída marca somente pixels brancos das letras e fica baixa quando `video_on=0`, `prompt_mode=0` ou fora da frase.
- O port `prompt_mode` vem da integração e representa `!frame_ready || !processing_done`. A camada de fundo preto e a prioridade visual são implementadas na TASK-046.
- A string tem 18 caracteres, usa células de pitch 6×8 e começa em `(267,237)`: pixels dos glifos ocupam x=267…373 e y=237…243, centralizados ao pixel mais próximo em 640×480. A separação de 1 pixel entre células e a linha inferior são apagadas.

### IDs fixos

| `glyph_id` | Glifo |
|---:|:---:|
| 0 | espaço |
| 1–10 | dígitos `0`–`9`, nessa ordem |
| 11–15 | `+`, `-`, `.`, `,`, `/`, nessa ordem |
| 16–24 | `A`, `F`, `I`, `N`, `O`, `R`, `V`, `X`, `Y`, nessa ordem |
| 25–31 | `a`, `b`, `c`, `i`, `n`, `r`, `s`, nessa ordem |

### Bitmap de referência 5×7

Cada grupo de cinco bits é uma linha de cima para baixo; o bit mais à esquerda representa a coluna 0. O VPI deve testar contra esta tabela independente.

| ID/glifo | Linhas locais 0…6 |
|---|---|
| 0 espaço | `00000 00000 00000 00000 00000 00000 00000` |
| 1 `0` | `01110 10001 10011 10101 11001 10001 01110` |
| 2 `1` | `00100 01100 00100 00100 00100 00100 01110` |
| 3 `2` | `01110 10001 00001 00010 00100 01000 11111` |
| 4 `3` | `11110 00001 00001 01110 00001 00001 11110` |
| 5 `4` | `00010 00110 01010 10010 11111 00010 00010` |
| 6 `5` | `11111 10000 10000 11110 00001 00001 11110` |
| 7 `6` | `01110 10000 10000 11110 10001 10001 01110` |
| 8 `7` | `11111 00001 00010 00100 01000 01000 01000` |
| 9 `8` | `01110 10001 10001 01110 10001 10001 01110` |
| 10 `9` | `01110 10001 10001 01111 00001 00001 01110` |
| 11 `+` | `00000 00100 00100 11111 00100 00100 00000` |
| 12 `-` | `00000 00000 00000 11111 00000 00000 00000` |
| 13 `.` | `00000 00000 00000 00000 00000 00110 00110` |
| 14 `,` | `00000 00000 00000 00000 00110 00100 01000` |
| 15 `/` | `00001 00010 00010 00100 01000 01000 10000` |
| 16 `A` | `01110 10001 10001 11111 10001 10001 10001` |
| 17 `F` | `11111 10000 10000 11110 10000 10000 10000` |
| 18 `I` | `01110 00100 00100 00100 00100 00100 01110` |
| 19 `N` | `10001 11001 11001 10101 10011 10011 10001` |
| 20 `O` | `01110 10001 10001 10001 10001 10001 01110` |
| 21 `R` | `11110 10001 10001 11110 10100 10010 10001` |
| 22 `V` | `10001 10001 10001 10001 01010 01010 00100` |
| 23 `X` | `10001 01010 00100 00100 00100 01010 10001` |
| 24 `Y` | `10001 01010 00100 00100 00100 00100 00100` |
| 25 `a` | `00000 01110 00001 01111 10001 10011 01101` |
| 26 `b` | `10000 10000 10110 11001 10001 10001 11110` |
| 27 `c` | `00000 01110 10001 10000 10000 10001 01110` |
| 28 `i` | `00100 00000 01100 00100 00100 00100 01110` |
| 29 `n` | `00000 10110 11001 10001 10001 10001 10001` |
| 30 `r` | `00000 10110 11001 10000 10000 10000 10000` |
| 31 `s` | `00000 01111 10000 01110 00001 10001 01110` |

### Clock, reset e comportamento

- Os dois módulos são combinacionais; não criam clock, reset ou registradores.
- A integração passa `prompt_mode` conforme DEC-066/068. O caminho que controla `frame_ready` e DONE não é alterado nesta TASK.

### Restrições

- Um módulo por arquivo Verilog.
- No DUT, estrutural; sem `assign`, `always`, `initial`, `if`/`else`, `case`, `for`, `generate`, `buf` ou `begin`/`end` fora de módulos de FF/FSM aprovados.
- Não alterar top, compositor, QSF/SDC, `vendor/vga/vga_sync.v`, pinos, interfaces públicas, entrada, FSMs, HEX/LED ou módulos do PBL02.
- Manter fonte/gates do prompt separados dos do quadro, embora usem a mesma ROM.

### Arquivos permitidos

- Novos `rtl/display/glyph_5x7.v` e `rtl/video/renderizador_prompt_vga.v`.
- Novos `sim/tb_prompt_vga.v`, `sim/prompt_vga_vpi.c` e `sim/run_prompt_vga_icarus.sh`.
- `docs/tasks/TASK-045.md`.

### Arquivos protegidos

- `rtl/top/top_pbl03.v`, `rtl/video/compositor_rgb.v`, `quartus/pbl03.qsf` e `quartus/pbl03.sdc`; integração combinada pertence à TASK-046.
- `vendor/vga/vga_sync.v`, `vendor/vga/UPSTREAM.md`, todos os arquivos PBL02 e interfaces públicas.

### Testes e casos de borda

- Icarus/VPI deve comparar os 32 glifos, 7 linhas × 5 colunas, com a bitmap desta TASK usando uma referência C independente.
- Verificar os 18 caracteres do prompt, pitch/offset, pixels das margens, bordas, espaços entre glifos e linha vazia; testar `prompt_mode=0`, `video_on=0`, coordenadas fora da janela e `row/column` fora dos limites.
- O runner usa o estilo dos testes Icarus/VPI existentes. Nenhum teste comportamental deve ser incluído no QSF/manifests de FPGA.

### Critérios de aceite

- O módulo `glyph_5x7` corresponde exatamente aos IDs e bitmaps especificados.
- O renderizador emite hits exatamente para a frase branca na caixa centrada, e nenhum hit quando desabilitado ou fora de `video_on`.
- Runner Icarus/VPI passa; lint estático de sintaxe confirma as restrições estruturais.
- Nenhuma integração end-to-end ou timing é alegada nesta TASK; a TASK-046 integra após TASK-044 e TASK-045.

### Dependências

- DEC-069 (CONSENSUS) define a ROM compartilhada.
- TASK-044 fornece o contrato/sinal `frame_ready`; integração do prompt e quadro no top/compositor/QSF é sequencial em TASK-046 após TASK-044 e TASK-045.

### Pendências

Nenhuma pendência arquitetural. Integração end-to-end, gating de BUSY/DONE e STA são de TASK-046.

**Resultado do Context Analyst: READY_FOR_IMPLEMENTATION.**

## Arquivos modificados

- `rtl/display/glyph_5x7.v` — ROM estrutural compartilhada de 32 glifos, decodificação one-hot de ID/linha/coluna e pixels por gates.
- `rtl/video/renderizador_prompt_vga.v` — renderizador estrutural da frase fixa com coordenadas e modo/blanking externos.
- `sim/tb_prompt_vga.v`, `sim/prompt_vga_vpi.c`, `sim/run_prompt_vga_icarus.sh` — harness e referência C independente.

## Testes executados

- `sh sim/run_prompt_vga_icarus.sh` (Docker `hdlc/iverilog:latest`): PASS, 8.834 casos de pixel/glifo/prompt.
- `git diff --check` nos arquivos desta TASK: PASS.
- Busca estática por `assign`, `always`, `initial`, `case`, `for`, `generate`, `buf`, `begin` e `end` nos dois DUTs: nenhuma ocorrência.

## Resultados e limites

- Os 32 glifos, as linhas/colunas válidas e inválidas, a frase de 18 caracteres, as margens, o pitch 6×8, o offset `(267,237)`, `prompt_mode` e `video_on` foram comparados à referência VPI.
- Esta TASK não altera QSF, top ou compositor por escopo; o gate RGB/STA integrado permanece em TASK-046.
- Não executei síntese Quartus nem teste físico nesta TASK.

**Resultado do Implementer: IMPLEMENTED.** Resultado da auditoria registrado abaixo.

## Auditoria

**Resultado: APPROVED.**

- Compliance: `glyph_5x7.v` e `renderizador_prompt_vga.v` não contêm `assign`, `always`, `initial`, `case`, `for`, `generate`, `buf` ou blocos `begin/end`; top, compositor, QSF e `vendor/vga/**` não foram alterados por esta TASK.
- Funcional: `sh sim/run_prompt_vga_icarus.sh` passou independentemente, com `VPI PASS: 8834 glyph/prompt pixel cases`. A referência C testa os 32 IDs, linhas/colunas válidas e fora da faixa, os pixels da frase, pitch/offset, modo prompt e `video_on`.
- Integração: a TASK entrega apenas ROM e hit isolado do prompt, conforme brief; integração RGB/STA end-to-end continua em TASK-046.
- Finding aberto: nenhum.
