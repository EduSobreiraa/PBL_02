# TASK-031 | Compor as quatro curvas no VGA

## Objetivo

Renderizar F1, F1′, F2 e F2′ sobre os eixos, respeitando escala, origem, visibilidade, clipping e prioridade de cores definidos em `REGRAS.md`.

## Status

APPROVED | auditoria independente aprovou Compliance, Functional e Integration sem findings.

## Dependências

- TASK-028, TASK-029 e TASK-030 | processadores e habilitação integrados.
- TASK-025 | `vga_sync` do professor integrado e preservado.

## Planejamento e aceite

- Compor resultados na coluna e linha atuais do VGA.
- Comparar resultados completos antes de mapear coordenadas.
- Preservar origem (320,240), uma unidade por pixel e `video_on`.
- Verificar cor de cada curva, eixos, fundo e prioridade em sobreposições.
- Confirmar que uma função inválida não oculta a curva válida.

## Arquivos

Ver a allowlist no Implementation Brief. A interface do compositor também é usada por `sim/tb_video_axes.v`; atualize esse wrapper, seu driver VPI e runner para conservar a regressão de vídeo.

## Resultado

A composição estrutural escolhe F1, F1′, F2, F2′, eixos e fundo nessa ordem. O top liga os quatro hits e `processing_done` ao compositor. Os hits só aparecem com DONE global, enquanto eixos continuam visíveis antes da conclusão. `video_on=0` força RGB preto.

### Arquivos modificados

- `rtl/video/compositor_rgb.v`: entradas dos quatro hits e DONE, seleção por prioridade e RGB4 estrutural.
- `rtl/top/top_pbl03.v`: conexão dos cinco sinais existentes ao compositor.
- `sim/tb_video_axes.v`: exposição das novas entradas do compositor para controle externo.
- `sim/video_axes_icarus_vpi.c`: preservação dos nove casos originais e verificação de todas as combinações de hits, DONE, vídeo e eixos.
- `sim/run_video_axes_icarus.sh`: leitura das fontes atuais do QSF para simular o wrapper e elaborar o top.
- `docs/tasks/TASK-031.md`: evidências da implementação.

### Testes executados

Com `IVERILOG_ROOT=/tmp/task028-iverilog/usr` no worktree `/tmp/task031-worktree`:

| Comando | Resultado |
|---|---|
| `sim/run_video_axes_icarus.sh` | PASS, 265 casos de composição e elaboração de `top_pbl03` com as fontes do QSF atual. |
| `sim/run_f1_processor_icarus.sh` | PASS, 92 ciclos F1 e elaboração do top. |
| `sim/run_f1_f2_processors_icarus.sh` | PASS, 25 ciclos F1/F2 e elaboração do top. |
| `sim/run_main_handshake_pbl03_icarus.sh` | PASS, 250 ciclos de handshake e elaboração do top. |
| `git diff --cached --check` | PASS. |

Após copiar os arquivos aprovados para a workspace compartilhada, repeti o runner de vídeo e as regressões TASK-028 a TASK-030 nela. Os resultados foram iguais aos do worktree. `cmp` confirmou que os seis arquivos copiados correspondem aos auditados, e a checagem de whitespace passou.

Os 265 casos incluem os nove testes originais de coordenadas, eixos, blanking e reset VGA. Os outros 256 cobrem as 16 máscaras dos quatro hits, dois níveis de DONE, dois níveis de `video_on` e quatro posições com nenhum eixo, eixo horizontal, eixo vertical ou ambos. A tabela esperada usa a paleta aprovada, sem ler a lógica interna do compositor. As combinações com hits de uma função baixos e da outra ativos confirmam que a função sem hit não oculta a válida.

### Inspeções e limitações

A inspeção das três fontes Verilog alteradas não encontrou `assign`, `always`, `initial`, `generate`, `for` ou `buf`. Não houve warning nos comandos de simulação. A comparação com a origem confirmou 67 arquivos protegidos e o QSF intactos byte a byte. Nenhuma síntese, análise de timing, fitting, execução Quartus ou validação física foi realizada. O teste de composição injeta hits na interface; os critérios numéricos e a classificação de funções permanecem nos processadores já aprovados.

## Implementation Brief

### Objetivo

Expandir `compositor_rgb` para selecionar as cores de F1, F1′, F2 e F2′ sobre os eixos e o fundo. Conectar os quatro hits dos processadores e o DONE global em `top_pbl03`. Preservar as saídas já clipadas pelos detectores de hit e respeitar `video_on`.

### Requisitos

- PDF PBL03 §§4.5–6 e 5.3–4: plotagem VGA, coordenadas, pixels ativos e implementação estrutural.
- `REGRAS.md` §§2, 5, 6, 7.5–6 e 8: curvas habilitadas/validas, clipping, periférico imutável, paleta e ordem de composição.

### Decisões aplicáveis

- DEC-044: resolução 640×480, origem (320,240), uma unidade por pixel, domínio vertical −239…240, clipping antes do pixel, paleta RGB e prioridades.
- DEC-045: wrapper de teste estrutural com estímulo/verificação externos via VPI.
- DEC-049: DONE principal só sobe após ambos os processadores concluírem e habilita a exibição global.

### Módulos envolvidos

- `compositor_rgb` em `rtl/video/compositor_rgb.v`: receber e priorizar sinais de eixo e hits, gerar RGB.
- `top_pbl03` em `rtl/top/top_pbl03.v`: passar hits de F1/F1′/F2/F2′ e `processing_done` ao compositor.
- `tb_video_axes` e seu driver VPI: injetar combinações de hits e verificar o RGB.
- `run_video_axes_icarus.sh`: compilar as fontes atuais do QSF antes de elaborar top e wrapper; o top agora instancia entrada, FSM e processadores além do caminho VGA.

### Interface

`compositor_rgb` recebe `video_on`, `eixo_horizontal`, `eixo_vertical`, `processing_done`, `f1_hit`, `f1_derivada_hit`, `f2_hit` e `f2_derivada_hit`, todos de 1 bit. Recebe os hits já clipados e gated pela validade de cada processador; `processing_done` aplica o gate global da sessão. Produz `red`, `green` e `blue`, cada um com 4 bits.

`top_pbl03` conecta diretamente os sinais existentes com os mesmos nomes. Não altera as interfaces de `processador_f1`, `fsm_principal_pbl03`, entrada ou VGA.

O wrapper de vídeo expõe os sinais de controle/hits do compositor para o driver VPI, além das coordenadas e do estado dos eixos já usados. Cores esperadas em RGB4: F1 azul `(0,0,15)`, F1′ ciano `(0,15,15)`, F2 vermelho `(15,0,0)`, F2′ amarelo `(15,15,0)`, eixos branco `(15,15,15)` e fundo preto `(0,0,0)`.

### Prioridade e clipping

Prioridade, da maior para a menor nesta TASK: F1, F1′, F2, F2′, eixos, fundo. DEC-051 remove o painel textual; interseções continuam como extra de prioridade acima das curvas. Quando `video_on=0`, RGB deve ser preto. Quando `processing_done=0`, os hits não devem aparecer, mas os eixos ativos continuam visíveis.

Os processadores entregam hits somente quando o resultado completo coincide com o y cartesiano atual e está no intervalo visível −239…240. A composição não converte nem trunca resultados numéricos. Funções inválidas ou desabilitadas têm seus hits baixos no processador e não podem suprimir curvas da outra função.

### Clock e reset

O compositor e o caminho de hits são combinacionais, sem clock ou reset. O raster preserva o clock/reset atuais e `vendor/vga/vga_sync.v` permanece byte a byte intacto.

### Restrições

- Manter aritmética e comparações numéricas fora do compositor; consumir os hits existentes.
- `compositor_rgb`, top e wrapper Verilog permanecem estruturais. Sem `assign`, `buf`, `generate`, laços, `always` ou `initial` nesses módulos.
- Um módulo por arquivo `.v`; não alterar portas públicas do top nem dos processadores.
- Não implementar painel/texto, interseções, raízes, mensagens, LEDs ou mudanças de pinagem/SDC.
- O `vga_sync.v` fornecido permanece inalterado. O QSF já lista o compositor e não precisa de novas fontes.

### Arquivos permitidos

- `docs/tasks/TASK-031.md`.
- `rtl/video/compositor_rgb.v`.
- `rtl/top/top_pbl03.v`.
- `sim/tb_video_axes.v`.
- `sim/video_axes_icarus_vpi.c`.
- `sim/run_video_axes_icarus.sh`.

### Arquivos protegidos

- `rtl/funcao/`, `rtl/controle/`, `rtl/entrada/` e `rtl/primitivos/`.
- `rtl/video/coordenadas_cartesianas.v` e `rtl/video/detector_eixos.v`.
- `quartus/pbl03.qsf` (o compositor já está listado; nenhuma nova fonte é necessária).
- `vendor/vga/vga_sync.v`, arquivos de pinagem/SDC e todo o PBL02.
- Os runners VPI das TASK-026 a TASK-030. `run_main_handshake` extrai a lista do QSF, e os runners das TASK-028/029 já elaboram o top com a interface de compositor conectada.

### Testes exigidos

- Atualizar o driver VPI da TASK-025 para verificar cores individuais de cada curva, fundo, eixos, `video_on`, gate por DONE global e todas as sobreposições para confirmar a prioridade.
- Reexecutar `sim/run_video_axes_icarus.sh`; o runner deve elaborar o top usando a lista corrente do `quartus/pbl03.qsf`.
- Reexecutar regressões TASK-028, TASK-029 e TASK-030 para confirmar que as fontes explícitas e a lista QSF continuam elaborando o top.
- Executar checagem de sintaxe/whitespace e inspeção das fontes estruturais.

### Casos de borda

- Todos os hits baixos: fundo preto, exceto pixels de eixo.
- Cada hit sozinho mostra exatamente a cor atribuída.
- Hits simultâneos escolhem a curva de maior prioridade, inclusive sobre o eixo.
- `processing_done=0` suprime curvas; `video_on=0` suprime toda saída RGB.
- Hit baixo de uma função inválida/desabilitada não muda o desenho da outra função.
- No pixel (320,240), ambos os eixos estão ativos e a prioridade de uma curva coincidente segue a tabela acima.

### Critérios de aceite

- As quatro cores, o branco dos eixos e o preto do fundo correspondem a DEC-044.
- As prioridades entre curvas, eixos e fundo são verificadas por VPI.
- `video_on` e DONE global controlam as curvas conforme seus contratos.
- A transformação cartesiana, os detectores de hit/clipping e `vga_sync.v` não mudam.
- O top elabora com o QSF atual e as regressões de integração previstas passam.
- Auditoria independente aprova os gates de conformidade, função e integração.

### Dependências

- TASK-025, TASK-028, TASK-029 e TASK-030 aprovadas.
- Paleta e prioridade fechadas em DEC-044 e `REGRAS.md` §8.
- Processadores entregam hits gated por validade/display e clipping.

### Pendências

Não há decisão pendente que bloqueie a composição das quatro curvas. Interseções e marcadores extras pertencem a tarefas posteriores. Quartus/timing e validação física permanecem fora desta TASK.

## Histórico

- 16/11/2026 | Context Analyst confirmou contratos em DEC-044 e encontrou o caller do compositor em `tb_video_axes`; atualizou allowlist e regressão do runner, TASK marcada `READY`.
- 16/11/2026 | Iniciada implementação isolada do compositor e integração dos quatro hits no top.
- 16/11/2026 | Code Implementer concluiu composição e quatro runners passaram; TASK marcada `IMPLEMENTED`, aguardando Code Auditor.

## Resultado da revisão

**APPROVED.** Compliance, Functional e Integration passaram, sem findings.

- A paleta RGB4 e a prioridade F1, F1′, F2, F2′, eixos e fundo correspondem a DEC-044. O gate global por `processing_done` afeta somente curvas; `video_on=0` apaga toda saída.
- Os 256 casos exaustivos verificam todas as combinações de hits, DONE, vídeo e posição dos eixos. Os nove casos originais de coordenadas, reset e blanking também passaram.
- Os runners TASK-028, TASK-029 e TASK-030 passaram novamente. O runner de vídeo elaborou `top_pbl03` com a lista QSF atual.
- As fontes estruturais respeitam as restrições de sintaxe. As pastas protegidas, o QSF, os detectores de coordenadas/eixos e `vendor/vga` coincidem byte a byte com a origem.
- `git diff --cached --check` passou.

Não foram executados Quartus, síntese, fitting, análise de timing ou validação física. Os hits de curva foram injetados no teste de compositor; a avaliação numérica permanece coberta pelos processadores já aprovados.
