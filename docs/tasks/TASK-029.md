# TASK-029 | Reutilizar o processador em F2

## Objetivo

Instanciar o processador validado de F1 para F2 e preservar estados e erros independentes.

## Status

APPROVED | auditoria independente aprovou Compliance, Functional e Integration, sem findings.

## Dependências

- TASK-028 | processador F1 aprovado.
- Contratos de F2 em `REGRAS.md`.

## Planejamento e aceite

- Reutilizar a mesma estrutura de avaliação e validação, com coeficientes de F2.
- Desabilitar F2 sem erro quando `a₂=b₂=c₂=0`.
- Reportar erro quando `a₂=0` e pelo menos um dos outros coeficientes for não nulo.
- Não deixar a função inválida apagar a válida nem manter BUSY preso.
- Cobrir F1 válida com F2 desabilitada, F2 válida e cada combinação independente de erro.

## Arquivos

Ver a allowlist fechada no Implementation Brief. A implementação reutiliza os módulos já listados no QSF; não precisa alterar a lista de fontes Quartus.

## Implementation Brief

### Objetivo

Adicionar um segundo caminho independente do módulo aprovado `processador_f1`, conectando nele os coeficientes F2 e as mesmas coordenadas VGA, START, clock e reset. Interpretar os sinais de saída desse segundo caminho como F2 e F2′. Reconhecer a tripla totalmente nula como F2 desabilitada: deve concluir a validação, não habilitar desenho e não expor erro de coeficiente zero.

### Requisitos

- PDF PBL03 §§4.2, 4.4, 4.9–13 e 5.3–4.
- `REGRAS.md` §§2, 3.6–10, 4, 7.1–6 e 11.1.
- Uma função inválida não impede a exibição da outra função válida.

### Decisões aplicáveis

- DEC-044 | F2 toda nula desabilitada sem erro; F2 com `a₂=0` e `b₂≠0` ou `c₂≠0` é inválida; processadores/FSMs independentes; START/BUSY/DONE.
- DEC-045 | wrapper estrutural e verificação externa com Icarus/VPI.
- DEC-046 | clock e reset lógico sincronizado ativo alto.
- DEC-047 | datapath F1 combinacional aprovado, reutilizado para F2.
- DEC-048 | interface e tabela da FSM F1, reset, retenção de erros/DONE e fronteira de integração.

### Módulos envolvidos

- `rtl/funcao/processador_f1.v` e `rtl/funcao/fsm_funcao_f1.v`: reutilizar sem alteração de portas ou lógica; a segunda instância recebe os coeficientes F2. Cada instância mantém seu estado independente.
- `rtl/top/top_pbl03.v`: adicionar sinais e segunda instância; conectar seus erros a fios internos com política de desabilitação da F2. Manter `processing_done` ligado ao DONE de F1 nesta TASK conforme a fronteira registrada em DEC-048; a TASK-030 será responsável por consolidar os dois processadores na FSM principal/handshake.
- `sim/tb_f1_f2_processors.v`: wrapper estrutural para dois processadores e o mesmo gate de erro da integração do top.
- `sim/f1_f2_processors_vpi.c` e `sim/run_f1_f2_processors_icarus.sh`: estímulo, referência e runner independentes.
- `quartus/pbl03.qsf`: nenhuma edição prevista; conferir que todos os módulos RTL instanciados pelo top atualizado já constam da lista de fontes.

### Interface

Segunda instância existente, sem nova porta ou mudança de interface:

| Porta de `processador_f1` | Conexão para a instância F2 | Semântica |
|---|---|---|
| `clk` | `MAX10_CLK1_50` | Clock do sistema. |
| `system_reset` | `entrada_pbl03.system_reset` | Reset síncrono ativo alto, comum às duas instâncias. |
| `start_pulse` | `entrada_pbl03.start_pulse` | Pulso START comum. |
| `a1`, `b1`, `c1` | `a2`, `b2`, `c2` | Coeficientes signed8 da F2, na ordem a, b, c. |
| `x_cartesiano`, `y_cartesiano` | coordenadas atuais compartilhadas | Signed10, domínio definido em `REGRAS.md` §5. |
| `busy`, `done` | fios internos `busy_f2`, `done_f2` | BUSY de um ciclo de validação; DONE retido até START aceito ou reset. |
| `error_a_zero`, `error_vertex` | fios internos de erro F2 com gate externo | Erros F2 independentes de F1; expor cada erro somente quando F2 está habilitada. |
| `display_enable`, `f1_hit`, `f1_derivada_hit` | fios internos F2/F2′ | `display_enable` e hits naturalmente baixos para a função nula, pois o datapath retorna `function_valid=0`; tratar os hits como F2 e F2′. |

Derivar `f2_enabled` estruturalmente como OR dos 24 bits `{a2,b2,c2}`. Assim, `f2_enabled=0` exatamente para a tripla nula. Aplicar esse sinal como gate às duas saídas de erro da instância F2; manter ambas as saídas de erro de F1 sem gate de F2. Não adicionar porta `enable` nem alterar a interface aprovada de `processador_f1`.

### Comportamento de F2 nula e handshake

Com `a2=b2=c2=0`, a instância reutilizada percorre a tabela DEC-048 normalmente: START aceito, BUSY alto em `VALIDATE` por um ciclo, então BUSY baixo e DONE alto retido em `COMPLETE`. O datapath reporta `a1_zero=1` internamente e `function_valid=0`; portanto a FSM produz `display_enable=0`, e os hits gated ficam baixos. O top mascara os erros dessa instância com `f2_enabled=0`, de modo que a tripla desabilitada não apresenta `ERR_F2`.

Com `a2=0` e ao menos um entre `b2`,`c2` não nulo, `f2_enabled=1`: o erro `error_a_zero` da instância é exposto; `display_enable` e os hits continuam baixos. Erros F1 e F2 não se mascaram entre si. O DONE/BUSY de F2 usa a FSM existente sem modificação, então a função desabilitada não mantém BUSY preso. Neste estágio os dois processadores compartilham START/reset e a mesma FSM, logo os pulsos de BUSY e DONE ficam alinhados; TASK-030 substituirá a ligação provisória `processing_done=done_f1` pela conclusão consolidada da FSM principal, conforme DEC-048.

### Clock e reset

- Clock: `MAX10_CLK1_50`, borda de subida.
- Reset de ambas as instâncias: `system_reset`, síncrono ativo alto, derivado de KEY1 sincronizada.
- Não ligar KEY físico diretamente ao reset lógico dos processadores. Preservar a ligação invertida de KEY1 ao reset do periférico VGA.

### Restrições

- FSMs são permitidas nos módulos dedicados, conforme `REGRAS.md` §2 e PDF §5.3–4; reutilizar a FSM existente sem editá-la.
- Manter datapaths aritméticos e integração combinacionais estruturais. Sem `assign`, `buf`, `if`/`else` comportamental, loops ou `begin`/`end` fora das exceções explícitas do PBL03.
- Um módulo por arquivo. Não mudar pin assignments, SDC, `vendor/vga/vga_sync.v` ou RTL legado PBL02.
- Não implementar FSM principal, composição RGB, LEDs, displays ou medição de timing nesta TASK.

### Arquivos permitidos

- `rtl/top/top_pbl03.v`.
- `sim/tb_f1_f2_processors.v`.
- `sim/f1_f2_processors_vpi.c`.
- `sim/run_f1_f2_processors_icarus.sh`.
- `docs/tasks/TASK-029.md`.

Os módulos `rtl/funcao/processador_f1.v`, `rtl/funcao/fsm_funcao_f1.v`, datapath e módulos aritméticos são somente leitura nesta TASK. O QSF também é somente leitura: suas fontes atuais já contêm todo o RTL reutilizado. Se a integração exigir qualquer módulo novo de RTL ou inclusão de fonte não listada, interromper e encaminhar a incompatibilidade documental; não alterar a interface/arquitetura por iniciativa própria.

### Arquivos protegidos

- Todos os arquivos em `rtl/funcao/` e `rtl/aritmetica/` aprovados nas TASKs 027–028.
- `rtl/entrada/entrada_pbl03.v`, módulos de entrada e `rtl/video/` exceto que o compositor permanece intocado.
- `quartus/pbl03.qsf`, pin assignments, SDC, `vendor/vga/vga_sync.v`, `REGRAS.md` e DEC-044 a DEC-048.
- `quartus/pbl02.*` e RTL legado do PBL02.

### Testes exigidos

- VPI com referência independente cobrindo reset, START, BUSY de um ciclo, DONE retido, novo START após DONE e estados independentes das duas instâncias.
- Cobrir simultaneamente: F1 válida/F2 nula; F1 nula ou com vértice fora/F2 válida; F1 válida/F2 com `a2=0,b2≠0`; F1 válida/F2 com `a2=0,c2≠0`; F2 válida; e erros de vértice independentes.
- Para F2 nula, verificar explicitamente `done_f2=1`, `busy_f2=0`, `display_enable_f2=0`, hits baixos e os dois erros F2 baixos após conclusão.
- Para F2 `a2=0` não nula, verificar `error_a_zero_f2=1`, sem exibição F2, enquanto hits/display/erros da F1 válida permanecem corretos.
- Verificar reset nos estados `WAIT_START`, `VALIDATE` e `COMPLETE`, além de nova validação pelo START aceito em `COMPLETE`.
- Executar `sim/run_f1_f2_processors_icarus.sh`, regressões `sim/run_f1_processor_icarus.sh` e `sim/run_coefficient_input_pbl03.sh`, elaboração do top com todas as fontes atuais do QSF e `git diff --check`.
- Inspecionar estruturalmente o top: sinais de F2 vêm da segunda instância; só erros F2 recebem gate `f2_enabled`; a rota de reset VGA permanece inalterada; `processing_done` continua conforme a fronteira DEC-048.
- Não afirmar síntese/timing ou validação física; esses gates não pertencem a esta TASK.

### Casos de borda

- A tripla nula é somente `{a2,b2,c2}=0`; valores negativos e `-128` em qualquer coeficiente contam como não nulos.
- `a2=0,b2=0,c2≠0` deve gerar erro, assim como `a2=0,b2≠0,c2=0`.
- F1 sempre é habilitada como contrato de entrada; `a1=0` continua gerando erro mesmo com todos os coeficientes F1 nulos.
- F2 desabilitada deve completar junto da F1 sem prolongar BUSY; DONE de F2 permanece retido conforme DEC-048.

### Critérios de aceite

- F2 usa uma segunda instância sem alterar interfaces ou implementação aprovada de F1.
- F2 toda nula conclui com DONE, sem display, hits ou erro exposto.
- F2 com `a2=0` e outro coeficiente não nulo expõe erro próprio e não apaga resultado válido de F1.
- FSM/estado, reset, erros, BUSY e DONE de cada instância são independentes; nesta integração os pulsos ficam alinhados por clock/reset/START comuns e FSM reutilizada.
- Regressões, elaboração do top/QSF e inspeções listadas passam, com resultados reais documentados na seção Resultado.

### Dependências

- TASK-028 aprovada: interfaces e FSM de `processador_f1`, integração F1 em `top_pbl03` e fontes Quartus.
- TASK-026 aprovada: registradores a1…c2, `start_pulse` e reset síncrono exportado.
- DEC-044 a DEC-048 em consenso/aprovadas, sobretudo contratos de F2 nula e FSM/handshake F1.

### Pendências

Nenhuma decisão nova é necessária: F2 nula, erro de `a2=0`, reutilização paralela e comportamento START/BUSY/DONE estão definidos. A interface atual de `processador_f1` aceita os coeficientes de F2 por conexão posicional/nomeada na instância e permite mascarar apenas os erros da função desabilitada na fronteira do top. A FSM principal e a consolidação final do handshake permanecem na TASK-030.

## Resultado

IMPLEMENTED. O top instancia `processador_f1` uma segunda vez com os coeficientes a₂/b₂/c₂, coordenadas VGA, clock, reset e START compartilhados. `f2_enabled` é a OR estrutural dos 24 bits dos coeficientes; somente `error_a_zero_f2` e `error_vertex_f2` são mascarados por esse sinal. A segunda FSM conclui normalmente para F2 nula; os sinais `display_enable_f2`, `f2_hit` e `f2_derivada_hit` permanecem em fios internos e são baixos para a tripla nula. `processing_done` continua conectado a `done_f1` conforme DEC-048.

### Arquivos modificados

- `rtl/top/top_pbl03.v`
- `sim/tb_f1_f2_processors.v`
- `sim/f1_f2_processors_vpi.c`
- `sim/run_f1_f2_processors_icarus.sh`
- `docs/tasks/TASK-029.md`

### Testes executados

- `IVERILOG_ROOT=/tmp/task028-iverilog/usr sim/run_f1_f2_processors_icarus.sh` — PASS; 25 ciclos VPI cobrindo F2 nula, erros de a₂=0 para b₂ e c₂ não nulos, F2 válida, erro de vértice independente em cada função, DONE/BUSY, START, reset em WAIT_START/VALIDATE/COMPLETE e hits/display. O runner elaborou `top_pbl03` com a lista completa de fontes do QSF atual.
- `IVERILOG_ROOT=/tmp/task028-iverilog/usr sim/run_f1_processor_icarus.sh` — PASS; 92 ciclos VPI da regressão TASK-028 e elaboração de top/QSF.
- `IVERILOG_ROOT=/tmp/task028-iverilog/usr sim/run_coefficient_input_pbl03.sh` — PASS; 187 passos VPI da regressão TASK-026.
- `IVERILOG_ROOT=/tmp/task028-iverilog/usr sim/run_f1_function_icarus.sh` — PASS; 3421 casos da regressão TASK-027.
- `git diff --check` — PASS.

### Inspeções e limitações

- A lista de fontes RTL existente em `quartus/pbl03.qsf` já contém os módulos reutilizados; não foi alterada.
- A integração mantém `processing_done=done_f1` nesta etapa e deixa `done_f2` disponível em fio interno.
- Não foram executados Quartus, síntese, timing nem validação física; esses resultados não são alegados.

### Resultado da revisão

APPROVED. O Code Auditor repetiu os quatro runners e aprovou os três gates. A elaboração conferiu as fontes do QSF atual. Como os arquivos protegidos e o QSF estão sem rastreamento Git nesta workspace, não foi possível demonstrar comparação byte a byte com uma revisão anterior; a auditoria não encontrou alterações fora da allowlist nem sinal de edição do QSF.

### Histórico

- 16/11/2026 | Context Analyst marcou READY após confirmar que a segunda instância reutiliza a interface F1 existente; erro de F2 nula é mascarado somente na fronteira do top.
- 16/11/2026 | Code Implementer adicionou F2, runner e 25 ciclos VPI; regressões TASK-026–028 e TASK-027 passaram.
- 16/11/2026 | Code Auditor repetiu quatro runners e aprovou Compliance, Functional e Integration sem findings. Registrou limitação de rastreamento Git para comparação byte a byte do QSF.
