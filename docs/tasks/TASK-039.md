# TASK-039 | Calcular e marcar vértices como extra

## Objetivo

Expor os termos racionais exatos dos vértices de F1/F2 até o top e marcar cada vértice válido como uma cruz verde de cinco pixels no VGA. A conversão para pixel serve apenas à apresentação e não pode alterar validação, clipping ou erros já aprovados.

## Status

APPROVED

DEC-057 Rodada 2 alcançou CONSENSUS após corrigir as inclusões nos extremos do predicado de vizinhança. A reimplementação corrigida passou os gates funcionais e STA; a auditoria independente final aprovou a implementação.

## Requisitos relacionados

- Manter a avaliação e validação exatas de F1 e F2 estabelecidas em DEC-044/047.
- Desenhar marcadores somente após a operação estar concluída, para funções habilitadas e válidas.
- Respeitar `video_on`, área ativa 640×480 e coordenadas cartesianas existentes.

## Decisões relacionadas

- DEC-044: vértices racionais exatos e limites inclusivos; sem arredondamento na validação.
- DEC-051: sem painel lateral ou tela de coeficientes.
- DEC-056 (CONSENSUS): termos exportados, larguras, arredondamento, forma/cor do marcador e prioridade.
- DEC-057 (CONSENSUS): detectar centro e vizinhança da cruz por intervalos racionais exatos, sem calcular quocientes na rota VGA; não inserir FSM/pipeline nem alterar fase VGA.

## Dependências

- TASK-028 e TASK-029: validadores racionais exatos de F1/F2.
- TASK-036: regressão agregada, harness de quadro completo e requisitos de sua reexecução após alteração.
- `top_pbl03` instancia dois `processador_f1`; os sinais de vértice devem ser propagados pelos dois caminhos sem mudar a interface física do top.

## Implementation Brief

### Objetivo

Manter os quatro termos racionais de cada função e renderizar a cruz definida em DEC-056, substituindo a materialização combinacional de quocientes por predicados de centro/vizinhança de DEC-057. A implementação é estrutural e alinhada ao pixel VGA corrente.

### Requisitos e decisões

- Requisitos: preservar cálculo/validação exatos de F1/F2, habilitação de exibição após processamento, clipping natural de cada pixel e sincronismos VGA existentes.
- Decisões: DEC-044/047 (matemática/validade), DEC-051 (sem painel), DEC-053/054 (VGA e 40 ns), DEC-055 (interseção) e DEC-056/057 (vértice e predicados de apresentação).

### Módulos e interfaces

- Cadeia de termos: `validador_vertice_f1` → `datapath_f1` → `processador_f1` → duas instâncias F1/F2 no `top_pbl03`.
- Composição: `compositor_rgb` recebe coordenadas cartesianas correntes, numeradores/denominadores de F1/F2, elegibilidade e hits de curva/interseção. Mantém interface física de `top_pbl03` inalterada.
- Termos: x `signed[8:0]/unsigned[8:0]`; y `signed[17:0]/unsigned[9:0]`; denominadores positivos.

### Clock/reset

Não adicionar estado, clock, reset, FSM ou pipeline para a conversão. Usar o alinhamento e `video_on` correntes do `vga_sync`; sinais de validação/handshake existentes só habilitam a apresentação após conclusão válida.

### Arquivos e gates

Seguir as allowlists/proteções e testes listados abaixo. O report de auditoria da implementação 1 identificou dois cenários ausentes, agora obrigatórios: frame de F2 válida isolada e clipping de braços em `y=240`/`y=−239`. A STA permanece gate: qualquer dos 14 endpoints VGA negativo sob os 40 ns mantém TASK-039 BLOCKED; a STA negativa da implementação 1 não é prova nem estimativa do novo predicado.

## Contrato de implementação

O validador existente é a fonte única dos termos usados tanto pela validação quanto pela apresentação. Propagar os termos abaixo de `validador_vertice_f1` por `datapath_f1` e `processador_f1`, e conectar as duas instâncias no top:

| Termo | Largura/representação | Fórmula normalizada |
|---|---|---|
| Numerador de x | signed [8:0] | `−b` para `a>0`; `b` para `a<0` |
| Denominador de x | unsigned [8:0] | `2|a|`, sempre positivo |
| Numerador de y | signed [17:0] | `sign(a) × (4ac−b²)` |
| Denominador de y | unsigned [9:0] | `4|a|`, sempre positivo |

Para `a=0`, os termos podem permanecer sem valor significativo; o caminho de apresentação deve ser desabilitado. F2 nula também deve permanecer desabilitada conforme seu contrato atual. A elegibilidade do marcador depende de `function_valid`/`display_enable`, `processing_done` e enable da função. Não recalcular nem substituir `a1_zero`, `vertice_y_fora`, `function_valid` ou os sinais de erro existentes.

Para x, o numerador normalizado é `−b` se `a>0` e `b` se `a<0`, sobre `2|a|`; isso equivale a `−b/(2a)` com denominador positivo. Para y, exportar `sign(a)×(4ac−b²)` sobre `4|a|`. A apresentação deve ser exatamente equivalente a arredondar cada razão ao inteiro mais próximo com empate afastado de zero, mas, conforme DEC-057, **não deve materializar quociente nem fazer divisão/restauração serial**. Para a coordenada cartesiana inteira atual `k`, `2n` é comparado aos limites multiplicados por `d`:

- centro (`round(n/d)=k`): se `k>0`, `(2k−1)d ≤ 2n < (2k+1)d`; se `k=0`, ambas as desigualdades são estritas; se `k<0`, `(2k−1)d < 2n ≤ (2k+1)d`.
- vizinhança (`round(n/d) ∈ {k−1,k,k+1}`): limite inferior `2n > (2k−3)d`, com igualdade também aceita quando `k≥2`; limite superior `2n < (2k+3)d`, com igualdade também aceita quando `k≤−2`. Em forma lógica: `(2n > L2 || (k≥2 && 2n=L2)) && (2n < U2 || (k≤−2 && 2n=U2))`, onde `L2=(2k−3)d` e `U2=(2k+3)d`. Nos outros valores de `k`, o respectivo limite externo permanece estrito.

Todos os sinais e extensões devem ser explícitos. Nos domínios VGA `x∈[−320,319]`, `y∈[−239,240]`, `d_x≤256`, `d_y≤512`, fatores dos limites cabem signed11 (x) e signed10 (y); produtos completos cabem signed19. `2*x_num` cabe signed10 e `2*y_num` signed19. Portas/comparações não podem truncar nem misturar sem sinal. O centro da cruz é `x_center && y_center`; braços ortogonais são `(x_neighborhood && y_center) || (x_center && y_neighborhood)`. A validação racional e o clipping das curvas permanecem inalterados.

O marcador é o pixel central mais os quatro vizinhos ortogonais (cruz de cinco pixels), cor verde RGB `(0,15,0)`. Clipping de cada braço é natural por `video_on` e pelos limites da área ativa. Prioridade final do compositor: interseção magenta > qualquer marcador verde > curvas existentes (preservar sua ordem atual) > eixos brancos > fundo preto. Nenhum texto, label ou painel é parte desta tarefa.

## Restrições aplicáveis

- Cumprir `docs/regras.md` e DEC-057: RTL estrutural, sem `assign`, FSM/seqüenciador/pipeline novo, operador de divisão/restauração na rota VGA, `always` fora de primitivo FF, `if`/`else`, `begin`/`end`, laços, `generate` ou `buf` no RTL.
- Sem alterar os coeficientes, equações, limites de validade, resultados das curvas, prioridade da interseção ou ports físicos/pinagem.
- Manter `vendor/vga/vga_sync.v` byte a byte intacto.
- Não relaxar o orçamento VGA de 40 ns nem criar false path/multicycle para o caminho de pixel.

## Arquivos permitidos

### RTL e projeto

- `rtl/funcao/validador_vertice_f1.v` — exportar os termos racionais calculados para a validação.
- `rtl/funcao/datapath_f1.v` — propagar os termos.
- `rtl/funcao/processador_f1.v` — propagar os termos até os callers.
- `rtl/top/top_pbl03.v` — conectar termos/eligibilidade de F1 e F2 e enviar hits dos marcadores ao compositor.
- `rtl/video/compositor_rgb.v` — receber coordenadas cartesianas, termos racionais e enables válidos de F1/F2; implementar comparações signed de centro/vizinhança por intervalos de DEC-057 e prioridade magenta > marcador > curvas > eixos > fundo, sem dividir ou formar quociente.

### Verificação

- `sim/tb_f1_function.v` e `sim/f1_function_vpi.c` — observar os termos racionais expostos pelo datapath e conferir valores exatos.
- `sim/tb_f1_processor.v` e `sim/f1_processor_vpi.c` — conferir propagação dos termos através do processador.
- `sim/tb_f1_f2_processors.v`, `sim/f1_f2_processors_vpi.c` e `sim/run_f1_f2_processors_icarus.sh` — conferir os dois processadores instanciados e a propagação independente de F1/F2.
- `sim/tb_video_axes.v` e `sim/video_axes_icarus_vpi.c` — cobrir conversão racional, cruz e prioridades no compositor com referência independente.
- `sim/pbl03_top_verilator.cpp` — atualizar o modelo independente de RGB e cenários completos de F1/F2 para marcadores, colisões e clipping; adicionar F2 válida isolada e casos de clipping de braços em y=240/−239.
- `sim/run_video_axes_icarus.sh` — ajustar somente a interface/stimulus do harness, sem adicionar fonte RTL.
- `sim/run_f1_function_icarus.sh` — sem mudança esperada: compila os módulos atuais envolvidos.
- `sim/run_f1_processor_icarus.sh`, `sim/run_pbl03_top_verilator.sh` — sem mudança esperada: fontes atuais já incluem todos os módulos afetados.
- `sim/run_pbl03_regression.sh` — protegido: deve ser executado, mas não modificado como parte desta tarefa.

## Arquivos protegidos

- Todos os arquivos fora da allowlist acima, salvo ajuste de runner estritamente necessário e explicitado pelo Implementer antes da edição.
- `rtl/funcao/avaliador_quadratico_f1.v`, `rtl/funcao/avaliador_derivada_f1.v`, `rtl/funcao/detector_hits_f1.v` e módulos aritméticos: não fazem parte do caminho de vértice e não devem ser alterados.
- `quartus/pbl03.qsf` e `verification/pbl03_sources.json`: protegidos; DEC-056 determina que a tarefa não altera a lista de fontes/QSF. A implementação fica em módulos já listados.
- `quartus/pbl03.sdc`: manter as restrições atuais e demonstrar o limite existente.
- `vendor/vga/vga_sync.v`, ports do `top_pbl03`, pin assignments e demais arquivos QSF não relacionados à inclusão da fonte.
- Harnesses e expectativas de tarefas anteriores que não estejam explicitamente na allowlist.

## Plano

1. Registrar nas interfaces dos três módulos da cadeia validador → datapath → processador os quatro termos racionais definidos acima, preservando sinais anteriores.
2. Atualizar a interface privada do compositor para receber x/y cartesianos, numeradores/denominadores racionais e elegibilidade F1/F2; implementar predicados de centro/vizinhança da DEC-057 com desigualdades estruturais signed, retirando a cadeia de divisão/restauração do caminho de pixel.
3. Ligar os termos dos dois processadores ao compositor no top e aplicar a prioridade pixel a pixel, preservando blanking e cores existentes.
4. Atualizar testes unitários e integração com referências matemáticas independentes; executar regressão agregada TASK-036.
5. Fazer compilação/síntese completa do Quartus e consultar TimeQuest para os 14 endpoints VGA (`VGA_R[0..3]`, `VGA_G[0..3]`, `VGA_B[0..3]`, `VGA_HS`, `VGA_VS`). Confirmar o caminho coordenada→termos racionais/conversão→detecção→RGB dentro de 40 ns, sem exceções que ocultem o caminho.

## Critérios de aceite

- Os quatro termos racionais exportados por F1 e F2 correspondem exatamente às fórmulas e representações aprovadas, para coeficientes positivos/negativos, numeradores positivos/negativos e casos de numerador zero.
- `a=0`, F2 nula, função inválida e função ainda não habilitada nunca produzem marcador; as flags de erro, `function_valid`, `DONE`, `BUSY`, clipping e pixels das curvas mantêm o comportamento preexistente.
- Predicados de centro/vizinhança são equivalentes à referência matemática de arredondamento para inteiros, frações dos dois sinais, resto abaixo/acima de metade e empate exato afastado de zero, incluindo k negativo e zero para x e y.
- No predicado de vizinhança, incluir os contraexemplos full-frame `n/d=−1/2, k=−2` (igualdade no limite superior aceita) e o simétrico `n/d=+1/2, k=+2` (igualdade no limite inferior aceita); excluir `k=0, n/d=−3/2` e `k=0, n/d=+3/2`, pois os empates ficam fora de `{−1,0,+1}`.
- Limites válidos de y `240` e `−239`, e casos válidos próximos aos limites, marcam apenas os pixels que caem dentro da área ativa; casos racionais inválidos imediatamente externos não desenham marcador.
- Cada vértice válido gera exatamente uma cruz central de cinco pixels verdes, exceto pixels removidos por clipping da área ativa ou cobertos por interseção magenta.
- Em colisão entre interseção e marcador, o pixel permanece magenta. Sem interseção, marcador vence qualquer curva; sem marcador, cores/ordem de curvas e eixos permanecem iguais ao baseline. Blanking continua preto.
- F1 e F2 são exercitadas separadamente e em conjunto, incluindo frame full-frame de F2 válida isolada (sem marcador elegível de F1), cruzes coincidentes ou sobrepostas às curvas/interseção.
- Testar os braços individualmente clipados em `y=240` e `y=−239`, incluindo `video_on=0`, e confirmar que pixels externos à área ativa permanecem pretos.
- O harness Verilator compara RGB pixel a pixel em quadro completo 800×525 e passa tanto em casos dedicados quanto no agregado TASK-036.
- Quartus conclui síntese/fitter; relatório de timing lista e satisfaz o limite de 40 ns para todos os 14 endpoints VGA, incluindo o caminho combinacional de marcador. Registrar pior atraso/slack e endpoint. Qualquer violação bloqueia a aprovação e não autoriza alterar a arquitetura nesta tarefa.
- `verification/check_pbl03_sources.py` passa e a lista QSF/manifesto permanecem byte a byte inalteradas.

## Testes

1. **Datapath exato (Icarus/VPI):** verificar `x_num`, `x_den`, `y_num`, `y_den` contra divisão racional independente em F1, para `a=0`, `a=±1`, `a=±128`, `b=±127/±128`, `c=±128`, numerador zero e ambos os sinais. Repetir casos de validade nas bordas inclusivas e imediatamente externos de y: `(-1,22,119)→240`, `(1,22,-118)→−239`, `(-1,22,120)→241`, `(1,22,-119)→−240`. Verificar que flags antigas não mudam.
2. **Propagação do processador:** confirmar os mesmos termos nas saídas de F1 e F2, inclusive em F2 nula e inválida; verificar gating impede renderização sem modificar flags/handshake.
3. **Predicados/compositor unitário:** comparar o centro/vizinhança com uma referência racional independente para positivos e negativos, inteiro, resto abaixo/acima de metade, empates `±0.5`; incluir `n/d=−1/2,k=−2` e `+1/2,k=+2` (empates de vizinhança aceitos), e `k=0,n/d=±3/2` (empates externos excluídos). Verificar cruz de cinco pixels, diagonais ausentes, clipping individual dos braços em `y=240` e `y=−239`, `video_on=0` e marcadores inelegíveis.
4. **Prioridade do compositor:** pixel de interseção mais marcador = magenta; marcador mais cada cor de curva/eixo = verde; casos sem marcador iguais ao baseline.
5. **Top full-frame Verilator:** ao menos vértice inteiro; vértices `−1/2` com `k=−2` e `+1/2` com `k=+2` (inclusões de vizinhança); `k=0` com `±3/2` (exclusões); frações positivas/negativas; marcador de F2 válida isolada sem F1 elegível; F1/F2 juntas; inválido e F2 nula; colisão marker/intersection e marker/curves; braços clipados nas bordas `y=240` e `y=−239`. Comparar cada pixel de 800×525, sincronismos, 640×480 ativos e blanking contra modelo C++ independente.
6. **Regressão:** `sim/run_pbl03_regression.sh` e `verification/check_pbl03_sources.py` completos após as mudanças.
7. **Quartus/TimeQuest:** compilação completa e relatório explícito de timing para os 14 endpoints VGA sob `quartus/pbl03.sdc`, orçamento 40 ns; registrar pior caminho combinacional e slack.

## Resultado da análise de contexto

As interfaces atuais têm a cadeia `validador_vertice_f1 → datapath_f1 → processador_f1 → top_pbl03`. O processador é instanciado uma vez por função no top e também nos wrappers `tb_f1_processor` e `tb_f1_f2_processors`; o datapath é encapsulado por `tb_f1_function`; o compositor é instanciado no top e em `tb_video_axes`. `sim/pbl03_top_verilator.cpp` fornece a referência C++ independente e varredura completa de quadro. Esses são os callers afetados pela propagação/integração. A conversão/detecção fica no compositor existente, evitando alterar QSF, SDC, manifesto de fontes ou acrescentar RTL à lista Quartus.

As larguras e regras semânticas de apresentação foram fechadas por DEC-056; DEC-057 define a implementação candidata por intervalos, sem quociente. Não há pendência arquitetural para reimplementar. A prova de timing permanece critério de aceite e foi reprovada na iteração anterior; isso não impede READY para a reimplementação, mas nenhum resultado anterior prova o novo caminho. O escopo não exige alteração de ports físicos, SDC ou módulo VGA.

## Resultado histórico da primeira implementação

Implementação RTL, propagação de termos e casos de verificação foram desenvolvidos. A compilação de Quartus e a regressão funcional concluíram, mas a implementação não pode ser aceita porque o caminho VGA coordenada→marcador→RGB excede o limite de temporização. Conforme o contrato da tarefa, a arquitetura fica parada para decisão/revisão; não foram alterados SDC, ports, QSF ou vendor.

## Histórico da primeira fórmula por intervalos

A primeira tentativa da arquitetura DEC-057 usou limites estritos nos dois lados da vizinhança. A regressão full-frame falhou no contraexemplo `x_v=−1/2, k=−2`; a fórmula foi corrigida e aceita na Rodada 2 de DEC-057. O log `verification/results/task-039/interval-regression.log` é evidência histórica dessa falha da fórmula antiga e não valida a fórmula corrigida. O caso simétrico `x_v=+1/2, k=+2` também pertence à cruz; `k=0` com `±3/2` deve ser excluído. Da mesma forma, a STA negativa da implementação com divisão serial (pior `VGA_B[2]` −31.443 ns) não estima nem prova o timing da arquitetura por intervalos. Ambas as evidências devem permanecer identificadas como históricas; a nova RTL requer regressão e STA próprias.

## Resultado das ferramentas da primeira implementação (histórico)

### Arquivos modificados

- `rtl/funcao/validador_vertice_f1.v`
- `rtl/funcao/datapath_f1.v`
- `rtl/funcao/processador_f1.v`
- `rtl/top/top_pbl03.v`
- `rtl/video/compositor_rgb.v`
- `sim/tb_f1_function.v`, `sim/f1_function_vpi.c`
- `sim/tb_f1_f2_processors.v`, `sim/f1_f2_processors_vpi.c`
- `sim/tb_video_axes.v`, `sim/video_axes_icarus_vpi.c`
- `sim/pbl03_top_verilator.cpp`

### Testes executados

- `sim/run_pbl03_regression.sh`: **PASS**, incluindo regressão Icarus e full-frame Verilator (10,080,784 verificações vetoriais; 9,965,603 ciclos de clock de 20 ns).
- `sim/run_video_axes_icarus.sh` com `IVERILOG_ROOT=/tmp/pbl03-iverilog-local/usr`: **PASS**, 275 casos de composição após incluir testes de arredondamento, cruzes, clipping e prioridade magenta.
- `sim/run_f1_function_icarus.sh` com o runtime local: **PASS**, 3,421 casos de datapath e termos racionais.
- `sim/run_f1_processor_icarus.sh` e `sim/run_f1_f2_processors_icarus.sh` com o runtime local: **PASS**, propagação e handshake; termos de F1/F2 comparados às referências.
- `python3 verification/check_pbl03_sources.py`: **PASS**.
- `git diff --check`: **PASS**.
- Quartus Prime 25.1std `quartus_sh --flow compile quartus/pbl03`: map, fitter e TimeQuest executaram sem erros de ferramenta; os relatórios identificam violações de setup nos endpoints RGB.

### STA VGA — orçamento de 40 ns

O TimeQuest detalhado encontrou slack negativo nos doze endpoints RGB, portanto o critério de 40 ns falha. O pior endpoint é `VGA_B[2]` com −31.443 ns. Os sincronismos têm slack positivo: `VGA_HS` 30.732 ns e `VGA_VS` 30.857 ns. A tabela completa e os caminhos estão em `verification/results/task-039/endpoint-slacks.txt` e `vga-paths-full.log`.

Evidências completas estão em `verification/results/task-039/`, incluindo logs de regressão, compilação, map, fitter, STA e relatórios Quartus.

## Resultado histórico da auditoria da primeira implementação

ESCALATE por violação STA. A primeira versão funcional passou a regressão, mas excedeu o orçamento VGA; seu caminho serial foi substituído conforme DEC-057. Esse resultado não se aplica à reimplementação aprovada.

## Estado final

Não há pendência de implementação em TASK-039. O resultado de timing negativo e o contraexemplo da fórmula anterior permanecem registrados como histórico e não se aplicam à reimplementação aprovada.

## Resultado da reimplementação por intervalos

A RTL implementa o predicado de DEC-057 com limites inclusivos condicionais, comparações signed estruturais e sem divisão/quociente. `2n` é ligado diretamente por referência aos bits dos numeradores com extensão de sinal; os quatro somadores identidade foram removidos. Os termos racionais do vértice continuam vindo unicamente do validador existente. A referência C++ foi ajustada para desabilitar hits de funções inválidas, e os checks full-frame consideram seus LEDs de erro retidos sem reduzir a comparação RGB.

- Teste unitário VGA/Icarus: **PASS**, 280 casos, incluindo `n/d=−1/2,k=−2`, `n/d=+1/2,k=+2` e exclusão de `k=0,n/d=±3/2`.
- Regressão agregada TASK-036: **PASS** em `verification/results/task-036/regression-20261122T171858Z.log`; inclui 3.421 casos de datapath, processadores F1/F2, entrada, handshake, status e quadro completo Verilator.
- Top Verilator: **PASS**, 18.481.099 verificações vetoriais e 18.269.638 ciclos; inclui F2 válida isolada, bordas de vizinhança e clipping em `y=240/−239`.
- `verification/check_pbl03_sources.py`: **PASS**; `git diff --check`: **PASS**.
- Quartus Prime 25.1std compile, map, fitter e STA: **PASS**, sem erros; map implementou 5.721 logic cells. A síntese/fitter registrou 33 warnings de ferramenta, principalmente pinos/segmentos constantes e avisos existentes de interface; não houve relaxamento de restrições.
- TimeQuest pós-fit, orçamento `set_max_delay=40 ns`: **14/14 endpoints VGA positivos**. Após remover os somadores identidade apontados pela auditoria, pior slack `VGA_B[0] = +1.421 ns` (38.579 ns de chegada); `VGA_HS=+31.205 ns`, `VGA_VS=+30.237 ns`. Tabela em `verification/results/task-039/interval3-endpoint-slacks.txt`; caminhos completos em `verification/results/task-039/interval3-vga-paths-full.log`.
- Logs: `verification/results/task-039/interval3-video-axes.log`, `interval3-quartus-compile.log`, `interval3-source-check.log`, `interval3-diff-check.log`, `interval3-endpoint-slacks.txt` e `interval3-vga-paths-full.log`.

QSF, manifesto de fontes, SDC, portas físicas e `vendor/vga/vga_sync.v` foram preservados.
Os relatórios Quartus versionados têm somente os espaços em branco finais removidos; valores e mensagens de timing permanecem inalterados.

## Resultado da auditoria final

**APPROVED.** A auditoria confirmou compliance estrutural, a remoção dos somadores usados como identidade, a allowlist e os callers. Não encontrou findings funcionais. A regressão agregada, o checker, o Quartus e a STA final passaram, com os 14 endpoints positivos e pior slack de +1.421 ns em `VGA_B[0]`.

## Histórico

- Context Analysis inicial: BLOCKED porque contrato de exportação/apresentação do vértice não estava definido.
- DEC-056 alcançou CONSENSUS e resolveu representação, arredondamento, marcador, cor, prioridade e ausência de labels/painel.
- Context Analysis final: interfaces/callers e critérios de verificação especificados; estado promovido a READY.
- Implementação 1 bloqueada pela STA; sua primeira fórmula de vizinhança falhou no full-frame. Esses dados são históricos.
- DEC-057 Rodada 2 alcançou CONSENSUS para os predicados racionais condicionais sem quociente e reabriu a TASK-039 para reimplementação.
- Reimplementação passou regressão full-frame, checker, compilação/fitter e STA dos 14 endpoints; auditoria independente APPROVED.
