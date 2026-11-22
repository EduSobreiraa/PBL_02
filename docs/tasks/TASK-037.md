# TASK-037 | Destacar interseções inteiras

## Objetivo

Aplicar a quinta cor quando F1 e F2 têm valores completos iguais em uma das 640 colunas inteiras e o ponto passa pelo clipping.

## Status

APPROVED

## Dependências

- TASK-036 | regressão obrigatória aprovada.
- TASK-029 e TASK-031 | resultados de ambas as funções e compositor.
- DEC-052 (CONSENSUS) | esta regressão é a extensão pós-base para interseções e quinta cor.

## Planejamento e aceite

- Comparar f₁(x) e f₂(x) antes de qualquer conversão para coordenada VGA.
- Destacar somente pontos visíveis que satisfaçam a igualdade exata.
- Confirmar funções coincidentes, interseções com x inteiro e ausência de destaque para cruzamento apenas fracionário.
- Estender o runner de integração aprovado na TASK-036 e repetir a captura/checagem de um quadro completo após habilitar a quinta cor.
- Usar `f₁(x)=x²` e `f₂(x)=x²+3x+1` para confirmar que a interseção em x=−1/3 não produz a quinta cor em nenhuma coluna inteira.
- Preservar a prioridade de cores definida em `REGRAS.md`.

## Arquivos

Ver lista autorizada e arquivos protegidos no Implementation Brief. DEC-055 fechou a interface privada dos resultados completos; esta tarefa não altera QSF/SDC nem adiciona fonte ao projeto Quartus.

## Resultado

Brief revisado após DEC-055. Estado anterior BLOCKED preservado no histórico desta análise; nenhuma implementação foi iniciada.

## Implementation Brief

### Objetivo

Adicionar a quinta cor magenta `(15,0,15)` quando, na coluna cartesiana corrente, `f₁(x)` e `f₂(x)` sejam iguais nos valores signed completos de 25 bits, e o ponto comum esteja dentro do clipping vertical e corresponda à linha corrente. A igualdade deve ser determinada antes de clipping/conversão para pixel. A nova cor tem prioridade acima das quatro curvas, dos eixos e do fundo. Executar novamente a regressão integrada e capturar frames completos após a mudança.

### Requisitos

- PBL03 PDF §§4.5–6 e §5.3–4: composição VGA e validação por simulação.
- REQ-015: testes e simulações registrados.
- Contrato de interseções da DEC-044 item 7: comparar resultados completos em cada coluna inteira e colorir igualdade válida/visível com a quinta cor.

### Decisões aplicáveis

- DEC-044 (CONSENSUS): domínio x signed10 −320…319; `f(x)` signed25; f1/f2 exatos; clipping y fechado [−239,240]; igualdade inteira recebe magenta acima das curvas.
- DEC-052 (CONSENSUS): TASK-036 base foi aprovada; TASK-037 estende a mesma regressão e repete o frame. Caso fracionário determinístico aprovado: `f₁=x²`, `f₂=x²+3x+1`, igualdade somente em x=−1/3.
- DEC-055 (CONSENSUS): `processador_f1` exporta internamente `f1_y signed[24:0]`; o comparador usa os resultados completos das duas instâncias. Não duplicar avaliadores nem alterar ports físicos/QSF/SDC.
- DEC-045: estímulo/referência/checks externos ao Verilog são permitidos.
- DEC-053/054: HS/VS públicos ativos baixos, budgets de 40 ns preservados e revisão integrada validada por TASK-042; mudanças desta tarefa não devem afrouxar timing.

### Módulos e interface atuais

- `compositor_rgb` (`rtl/video/compositor_rgb.v`) recebe `video_on`, eixos, `processing_done`, `intersection_hit` e quatro hits de curva (todos 1 bit), e emite `red`, `green`, `blue` (4 bits cada). O port privado `intersection_hit` já está presente na RTL; preservar sua semântica e garantir prioridade magenta acima das demais condições, sem alterar os ports físicos de `top_pbl03`.
- `top_pbl03` (`rtl/top/top_pbl03.v`) instancia `processador_f1` em paralelo para F1 e F2 e liga seus hits ao compositor. Seus ports físicos ficam congelados.
- `avaliador_quadratico_f1` calcula `f1_y signed[24:0]`; `datapath_f1` já expõe esse valor, e DEC-055 autoriza encaminhá-lo pelo novo output privado de `processador_f1` até os fios do top.
- O dado exigido pelo comparador é exatamente `f1_y[24:0]` e `f2_y[24:0]` signed, sem reduzir/truncar larguras. `x` é signed10. A condição de ponto desenhável também exige o valor comum dentro de [−239,240], igual à coordenada vertical atual e ambas as funções habilitadas/validas, `processing_done=1` e `video_on=1`.

### Contrato aprovado para igualdade e apresentação

- Comparar estruturalmente os 25 bits de `f1_y` e `f2_y` antes de clipping/conversão. Qualificar a igualdade com `f1_hit`, `f2_hit`, `f2_enabled` e `processing_done`.
- `f1_hit`/`f2_hit` já representam função válida, resultado dentro de [−239,240] e coincidência com a coordenada vertical corrente. O compositor aplica `video_on`, impedindo interseções fora da área ativa.
- A extensão `f1_y` da interface privada de `processador_f1` é a única mudança de porta permitida por DEC-055. A interface física do top permanece congelada.
- Implementar igualdade estrutural na integração existente de `top_pbl03` (XNOR bit a bit e redução AND estrutural). Não criar novo arquivo fonte; QSF/SDC ficam inalterados.
- Adicionar a condição privada `intersection_hit` à interface de `compositor_rgb`. Magenta `(15,0,15)` tem prioridade sobre F1, F1′, F2, F2′, eixos e fundo.

### Arquivos permitidos

- `rtl/funcao/processador_f1.v` | adicionar output `f1_y signed[24:0]` ligado diretamente a `datapath_f1.f1_y`.
- `rtl/top/top_pbl03.v` | conectar os dois resultados, igualdade estrutural completa, qualificação e fio privado para o compositor; preservar ports físicos.
- `rtl/video/compositor_rgb.v` | receber `intersection_hit` privado e dar prioridade máxima a magenta.
- `sim/pbl03_top_verilator.cpp` | referência signed-wide e cenários públicos com frame completo: coincidência, cruzamento inteiro, caso fracionário e F2 inválida/desabilitada.
- `sim/tb_f1_processor.v` | adaptar os dois callers nomeados; conectar `f1_y` a checks/wires ou deixar a porta explicitamente aberta.
- `sim/tb_f1_f2_processors.v` | adaptar os dois callers nomeados; conectar `f1_y` a checks/wires ou deixar a porta explicitamente aberta.
- `sim/tb_video_axes.v` | caller de `compositor_rgb` usado pela regressão base; conectar `.intersection_hit(1'b0)` para que os testes de eixos/composição mantenham o comportamento sem interseção.
- `docs/interfaces.md` e `docs/tasks/TASK-029.md` | somente se houver divergência com o contrato de DEC-055, que já foi registrado.
- `docs/tasks/TASK-037.md` e `verification/results/task-037/**` | brief, logs, resultados, hashes e relatórios da TASK-037.

Os scripts `sim/run_pbl03_top_verilator.sh` e `sim/run_pbl03_regression.sh` podem ser executados, mas não precisam ser alterados: compilam as fontes QSF e incluem o top harness no agregado.

### Arquivos protegidos

`vendor/vga/**`, QSF/SDC e pin assignments, ports físicos de `top_pbl03`, `vga_sync.v`, módulos de entrada/controle/reset, datapath e módulos aritméticos, contratos matemáticos/larguras/clipping, scripts de regressão, fontes PBL02 e relatórios/evidências aprovados (exceto novos resultados TASK-037).

### Clock, reset e restrições

- O comparador/compositor são combinacionais; não adicionar clock, reset, pipeline ou estado.
- Manter clock/raster de 50 MHz/25 MHz e fase atuais. Os ports `VGA_HS`/`VGA_VS` permanecem ativos baixos.
- Sem `assign`, `buf`, FSM, `if`/`else`, loops, `generate` ou `begin`/`end` em RTL estrutural, conforme `docs/regras.md`.
- Não editar `vendor/vga/vga_sync.v`, relaxar SDC 40 ns nem ocultar paths RGB/HS/VS.

### Testes exigidos

1. Executar o runner agregado aprovado `sim/run_pbl03_regression.sh`, preservando os sete gates Icarus e a regressão top Verilator; manter log/fingerprint e falha propagada.
   O runner Icarus `sim/run_video_axes_icarus.sh` deve continuar passando com `sim/tb_video_axes.v` fixando `intersection_hit` em zero; isso preserva a regressão base isolada do recurso novo.
2. Estender o harness Verilator com frames completos 800×525 dirigidos só por ports públicos, entrada de seis coeficientes e START reais.
3. Casos de frames completos 800×525, iniciados pelos ports públicos, com sequência real de entrada e START:
   - `f₁=f₂=x²`: cada ponto comum visível é magenta, inclusive sobre curva/eixos; valores fora do clipping não aparecem magenta.
   - `f₁=x²`, `f₂=x²+x`: interseção inteira em x=0, y=0; verificar magenta sobre as curvas/eixos nesse pixel.
   - `f₁=x²`, `f₂=x²+3x+1`: igualdade só em x=−1/3; afirmar ausência da quinta cor em toda a área ativa de todas as 640 colunas, não apenas em pixels amostrados.
   - F2 toda nula/inválida ou função fora de validade: não gerar quinta cor. Verificar que pontos sem igualdade completa não são destacados mesmo que ambos os resultados extrapolem/clippem fora da tela.
4. A referência independente deve calcular f1/f2 em signed wide integer, comparar igualdade nos resultados completos antes do clipping, depois validar y corrente/limites e cor esperada.
5. Reexecutar `python3 verification/check_pbl03_sources.py`; novos RTL devem estar corretamente incluídos na fonte de projeto se houver novo arquivo, sem incluir C++/testes no QSF.

### Critérios de aceite

- Igualdade completa signed25 é comparada antes de qualquer clipping/truncamento e só pinta o pixel comum visível/valido.
- Magenta `(15,0,15)` precede F1, F1′, F2, F2′, eixos e fundo; RGB preto e sync active-low são preservados.
- Os três casos inteiros/coincidentes/fracionários acima passam com um frame completo por caso; o caso fracionário demonstra ausência de cor em todas as colunas inteiras.
- A regressão base TASK-036 continua passando junto da extensão; logs do agregado incluem oito markers de runner e todos os novos casos de frame.
- Fonte structural checker passa, ports públicos, pinout, QSF/SDC e vendor permanecem conforme decisões.
- A única alteração da interface privada de `processador_f1` é o output signed25 `f1_y` autorizado por DEC-055; todos os callers enumerados permanecem compiláveis. Nenhuma porta física do top muda.
- QSF e SDC permanecem byte a byte inalterados; `verification/check_pbl03_sources.py` passa.
- Quartus Analysis & Synthesis/Fitter/TimeQuest são executados na mesma revisão RTL: os 12 endpoints RGB e dois endpoints HS/VS mantêm orçamento máximo de 40 ns sem slack negativo. Arquivar resultados reais em `verification/results/task-037/**`; qualquer slack negativo bloqueia o aceite e exige Decision Workflow, sem afrouxar constraints.

### Dependências

- TASK-036 está `APPROVED`; `verification/results/task-036/regression-20261118T165634Z.log` comprova os sete testes unitários e frame de base.
- TASK-029 e TASK-031 estão `APPROVED`; compositor/top e interfaces vigentes estão documentados.
- DEC-044 e DEC-052 estão `CONSENSUS`.

### Pendências

Não há pendência arquitetural ou de timing aberta. O relatório novo dos 14 endpoints VGA passa em 40 ns, com slack mínimo positivo de 2.703 ns (`VGA_G[1]`). A validação em placa/monitor continua futura.

### Resultado do Context Analyst

**READY_FOR_IMPLEMENTATION.** DEC-044/052 fixam matemática, precisão, clipping, cor, prioridade e cenários de frame; DEC-055 resolve a interface e revisa expressamente a exceção de TASK-029; TASK-036 aprovada fornece a regressão base. A allowlist identifica `processador_f1`, top, compositor e todos os callers dos testbenches. A igualdade estrutural será integrada em `top_pbl03`, evitando novo source file/QSF. Critérios incluem regressão full-frame, fonte estrutural e novo STA dos 14 endpoints; nenhuma evidência dessa implementação foi produzida nesta análise. Nenhum RTL foi alterado.

### Implementação e evidências

Arquivos RTL alterados:

- `rtl/funcao/processador_f1.v`: exporta o resultado signed25 já calculado pelo datapath.
- `rtl/top/top_pbl03.v`: compara os 25 bits via XNOR/AND estrutural e qualifica igualdade por hits F1/F2, `f2_enabled` e `processing_done`.
- `rtl/video/compositor_rgb.v`: adiciona `intersection_hit` e dá prioridade magenta `(15,0,15)` acima de todas as curvas/eixos.
- `sim/tb_f1_processor.v`, `sim/tb_f1_f2_processors.v`: conectam explicitamente a porta não usada; `sim/tb_video_axes.v` mantém teste de composição base com interseção zero.
- `sim/pbl03_top_verilator.cpp`: referência signed64 e quatro quadros públicos de 800×525.

Validação em 2026-11-18:

- `python3 verification/check_pbl03_sources.py`: PASS. O agregado repetiu o checker antes/depois; `git diff --check`: PASS.
- `./sim/run_pbl03_regression.sh`: PASS em `verification/results/task-036/regression-20261118T172118Z.log`; 8 markers `RUN PASS`, sete regressões Icarus e a extensão Verilator. O manifest fonte/config tem 283 entradas, fingerprint `7997c064264d0d8e6f6e5e6ae52031ad19f727e57c0debca19334b552b42c0e8`; as entradas foram verificadas com `sha256sum -c`.
- Quatro quadros completos, dirigidos somente por entradas públicas e START: interseção inteira em `(0,0)` produziu exatamente 1 pixel magenta; funções coincidentes produziram 31 pontos visíveis magenta e clipping preservado; `x²`/`x²+3x+1` produziu zero pontos magenta (igualdade apenas em `x=−1/3`); F2 nula produziu zero interseções.
- Harness: 6.720.658 checks e 6.643.989 ciclos de clock. Cada quadro verificou fase/sync active-low, 525 pulsos HS, 50.400 amostras HS baixas, 1.600 amostras VS baixas, blanking, RGB, curvas e eixos.
- Quartus Prime Lite 25.1std.0 Build 1129: A&S PASS (0 erros/31 avisos); Fitter PASS (0/3); TimeQuest PASS (0/0). Todos os 14 outputs estão detalhados sob max-delay 40 ns, sem slack negativo. Slack RGB R=`3.335/3.358/3.333/3.081 ns`, G=`2.721/2.703/2.734/2.724 ns`, B=`2.753/2.763/3.112/3.103 ns`; HS=`30.010 ns`, VS=`29.822 ns`. Slack mínimo positivo: `2.703 ns` em `VGA_G[1]`.
- Hash de `vendor/vga/vga_sync.v` segue igual a `UPSTREAM.md`; QSF e SDC não foram alterados nesta TASK. Evidências, relatórios completos, fingerprint, hashes e comando TimeQuest estão em `verification/results/task-037/`.
- O Quartus ainda sinaliza que setup/hold não estão globalmente totalmente constrained; os endpoints VGA exigidos estão individualmente constrained e passam. Não houve teste físico.

### Resultado do Implementer

**IMPLEMENTED.** O output signed25 e a quinta cor estão integrados sem alterar portas físicas/QSF/SDC/vendor. Regressão agregada, quatro frames completos, checker, Fitter e TimeQuest passaram. A auditoria independente ainda está pendente.

### Auditoria independente

**APPROVED — 2026-11-18.**

- **Compliance Gate:** `processador_f1` exporta o valor signed25 existente; o top compara os 25 bits com XNORs e redução AND estrutural. Não foram encontrados `assign`, `buf`, FSM, `always` novo, laços ou blocos comportamentais nos módulos RTL alterados. Todos os callers de `processador_f1` e `compositor_rgb` foram atualizados. Ports físicos do top, QSF, SDC e `vendor/vga/vga_sync.v` permanecem inalterados; hash do VGA confere com `UPSTREAM.md`.
- **Functional Gate:** a referência C++ independente usa aritmética signed64 e compara os valores completos antes do clipping. Os quatro frames públicos passam: interseção inteira em `(0,0)` = 1 pixel magenta; funções coincidentes = 31 pontos magenta visíveis, com clipping; caso `x²` / `x²+3x+1` = zero pontos magenta em todas as colunas inteiras; F2 nula = zero interseções. O frame também cobre prioridade sobre curvas/eixos, blanking e sincronismos active-low. O agregado executou sete suítes Icarus e 6.720.658 checks Verilator.
- **Timing/Integration Gates:** Quartus A&S/Fitter/TimeQuest concluíram com 0 erros (31/3/0 avisos); todos os 14 endpoints estão individualmente limitados a 40 ns e têm slack positivo. Menor slack: +2.703 ns em `VGA_G[1]`; HS +30.010 ns; VS +29.822 ns. O checker de fontes passou e os hashes protegidos conferem.
- **Findings HIGH/CRITICAL:** nenhum.
- **Limitações registradas:** TimeQuest ainda informa que setup/hold não estão globalmente totalmente constrained; os endpoints VGA desta tarefa passam. Não houve validação em placa ou monitor físico.

Evidências da auditoria: `verification/results/task-037/aggregate-regression.log`, `aggregate-inputs.sha256`, `vga-paths-full.log`, relatórios Quartus e arquivos de hash em `verification/results/task-037/`.
