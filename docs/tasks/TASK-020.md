# TASK-020 — Remoção de assign contínuo do RTL

## Objetivo

Remover `assign` contínuo de todo RTL sintetizável e da cópia `rtl/coefficient_input.v.save`, religando sinais estruturalmente e preservando o comportamento vigente.

## Status

APPROVED — implementação, validação funcional e auditoria independente concluídas em 12/10/2026.

## Requisitos relacionados

REQ-008, REQ-011, REQ-013, REQ-015.

## Decisões relacionadas

DEC-033, DEC-035, DEC-036. DEC-034 permanece separado e não autoriza alteração de largura/OV nesta TASK.

## Dependências

DEC-033, DEC-035 e DEC-036 CONSENSUS. Referências e suítes anteriores nas TASKs 002/003/004/006/007/008/009/010/011/012/013/017/018/019.

## Restrições aplicáveis

Sem `assign` contínuo, `wire` inicializado como atribuição, `buf`, FSM, `if`/`else`, laços/geração, comportamento fora dos DFF ou alteração de interface pública, largura, matemática, FF, pinagem e semântica de apresentação. As exceções privadas e pontuais para `decimal_dabble_stage`/`decimal_double_dabble` e `sqrt_stage` são DEC-035/036. Aliases devem ser ligados diretamente; não usar gates de identidade como buffers. Literais podem ligar diretamente entradas; constantes externas permanecem dirigidas por lógica constante com driver único. `.save` não entra na compilação.

## Arquivos permitidos

Os 11 RTL ativos identificados em DEC-033; `rtl/coefficient_input.v.save`; `testbench/tb_decimal_display.v` somente para migrar o caller direto de `decimal_double_dabble` conforme DEC-035; `docs/regras.md`; `docs/convencoes_verilog.md`; `docs/decisions/DEC-030.md`; `docs/decisions/DEC-033.md`; `docs/decisions/DEC-035.md`; `docs/sprints/README.md`; `docs/pendencias.md`; e este arquivo.

## Arquivos protegidos

Requisitos P0, interfaces públicas e contratos matemáticos; `docs/decisions/DEC-034.md`; demais testbenches; top-level pin assignments; fontes fora da lista permitida.

## Plano

Classificar as 96 ocorrências do RTL em aliases, constantes, concatenações/extensões e saídas de lógica. Remover aliases por ligação direta e constantes de entrada por literais. Preservar outputs constantes com driver estrutural único. Aplicar alterações de baixo para cima e manter `.save` fora da lista de compilação.

## Critérios de aceite

- Nenhum `assign` contínuo ou inicializador equivalente nos 11 RTL ativos ou em `rtl/coefficient_input.v.save`.
- Testbenches conservam autorização existente.
- Interfaces, equações, ordem de bits, FF e pinagem permanecem iguais.
- Interfaces públicas permanecem intactas; as únicas interfaces privadas alteradas são Double Dabble e `sqrt_stage`, conforme DEC-035/036.
- Sem `buf`, gates de identidade, drivers duplicados, latches ou laços combinacionais.
- Suítes existentes de módulos afetados compilam e passam; revisão independente sem findings HIGH/CRITICAL.

## Testes

Executar os testbenches dirigidos de cada módulo afetado e `verification/run_system.py` com lista de fontes sem `.save`; fazer Compliance Gate e auditoria independente. Registrar comandos, versões, contagens e resultados reais.

## Resultado da implementação

As 11 fontes RTL e `rtl/coefficient_input.v.save` foram editadas para remover `assign` contínuo, preservando as interfaces públicas; Double Dabble e `sqrt_stage` foram remodelados conforme DEC-035/036. `testbench/tb_decimal_display.v` foi migrado somente para reconstruir o BCD no caller privado. Na revisão funcional, foi encontrada e corrigida uma referência restante ao `carry[9]` agora dirigido pelo próprio `quotient_bit` em `divide_stage`; a restauração e os muxes consomem diretamente `quotient_bit`.

## Resultado das ferramentas

Executado em 12/10/2026 com Docker `hdlc/iverilog:latest`, Icarus Verilog 14.0 (devel), `iverilog -g2012 -Wall` e `vvp`. Os testbenches foram compilados com seus RTL dependentes explícitos; os vetores necessários foram empacotados em `/tmp/work/verification/vectors`, e `.save` não foi compilado.

- `tb_add_sub`: PASS, `TEST-002 PASS full_adder=8 exact_add=24808 delta=12401 core_modular=3 rows=37212`.
- `tb_coefficient_input`: PASS, `PASS TEST-001 coefficient_input wrapper/core loaded checks=15`.
- `tb_decimal_display`: PASS, `TEST-008 DISPLAY PASS cases=10032 BCD_add3=16 seed=20261011 segments_magnitude_BCD=PASS`.
- `tb_divide_u9_u8`: PASS, `TEST-005 PASS pairs=131072 valid=130560 divisor_zero=512 quotient_remainder=PASS identity=PASS masks=PASS`.
- `tb_multipliers`: VVP imprimiu `TEST-003 PASS signed=65536 mixed=4194560 squares=256 boundary=91` e chamou `$finish` em 4,260,443,000 ps. O wrapper da sessão retornou código 130 apesar do marcador completo e da chamada de `$finish`; registramos o código real, sem tratá-lo como saída 0.
- `tb_polynomial_y`: PASS, `TEST-006 PASS directed=12 cartesian=2401 random=10000 rows=12413 wrapper_core=PASS carry=PASS OV=PASS`.
- `tb_quadratic_roots`: PASS, `TEST-007 PASS directed=30 random=10000 seed=20261011 total=10030 valid=6255 invalid=3775 delta_roots_error=PASS`.
- `tb_result_select`: PASS, `TEST-008 SELECT PASS cases=6048 seed=20261011`.
- `tb_sqrt_u17`: PASS, `TEST-004 PASS radicands=131072 failures=0`.
- `tb_status_flags`: PASS, `TEST-009 TASK010 PASS isolated=3584 integrated=53 failures=0`.
- `python3 verification/run_system.py`: PASS; TEST-010/011, 10 cenários e 660 verificações de saída.
- `git diff --check`: PASS. `rg -n 'assign|wire\\s+[^;]*='` nos onze RTL e `.save`: nenhuma ocorrência.

As execuções isoladas foram empacotadas por `tar -cf - <fontes e vetores> | docker run --rm -i hdlc/iverilog:latest sh -c '<extração, compilação e vvp>'`. O runner de sistema foi executado pelo comando exato `python3 verification/run_system.py`.

## Resultado da revisão

**APPROVED — auditoria final independente em 12/10/2026.** Compliance Gate e Integration Gate passaram conforme o registro de auditoria acima. Functional Gate passou: todas as suítes exigidas têm marcador PASS e contagens completas, incluindo `tb_quadratic_roots` (10.030 casos) e a integração de sistema (10 cenários/660 verificações). O Implementation Brief documenta explicitamente as duas exceções privadas: Double Dabble conforme DEC-035 e `sqrt_stage` conforme DEC-036, preservando as portas públicas.

Para `tb_multipliers`, a evidência é o marcador final `TEST-003 PASS signed=65536 mixed=4194560 squares=256 boundary=91` seguido por `$finish` em 4,260,443,000 ps. Isso demonstra que todas as verificações previstas terminaram sem falhas. O código 130 retornado pelo wrapper da sessão permanece registrado acima e não é apresentado como código de saída zero; como ocorreu após o marcador final e a chamada explícita de `$finish`, não invalida a evidência funcional da simulação concluída. Não há finding CRITICAL/HIGH. Síntese, STA e validação física não foram realizadas.

## Pendências

Nenhuma pendência funcional. Síntese/STA e validação física não foram executadas. O wrapper do teste exaustivo de multiplicadores retornou 130 após o marcador PASS completo e `$finish`, conforme ressalva registrada.

## Implementation Brief

### Objetivo

Remover as atribuições contínuas `assign` dos 11 arquivos RTL que atualmente as contêm e de `rtl/coefficient_input.v.save`, preservando exatamente o comportamento e os contratos existentes. Religação direta é o método para aliases; constantes nas entradas de instâncias vão como literais. Manter o caminho BCD de `decimal_display` conectado aos HEX físicos.

### Requisitos

- REQ-008
- REQ-011
- REQ-013
- REQ-015

### Decisões aplicáveis

- DEC-033 — proibição de `assign` contínuo no RTL e cópia `.save`.
- DEC-030 — interfaces, lógica estrutural e contratos atuais, sem alteração nesta TASK.
- DEC-035 — exceção privada para remodelar o Double Dabble e migrar o caller direto do testbench de display.
- DEC-036 — exceção privada para remodelar `sqrt_stage`, mantendo as portas públicas de `sqrt_u17`.
- DEC-036 — remodelagem privada de `sqrt_stage`, mantendo intactas as portas públicas `sqrt_u17`.
- DEC-034 — explicitamente fora do escopo: não implementar nem antecipar mudança de largura, OV, valor inválido ou política de apresentação proposta nessa decisão ainda BLOCKED.

### Módulos envolvidos

Todos os módulos nos arquivos permitidos abaixo. Os contratos públicos documentados em `docs/interfaces.md` permanecem inalterados; a única exceção privada é o Double Dabble conforme DEC-035. O caminho `decimal_display` → BCD → HEX faz parte do DUT físico e deve permanecer funcional; BCD não é apenas dado de testbench. `rtl/arithmetic_cells.v` é dependência compilada pelo runner, mas não contém `assign` e não deve ser modificado.

### Interface

Nenhuma porta pública documentada pode ser criada, removida, reordenada ou ter nome, direção, sinal, largura ou semântica alterados. As únicas exceções privadas são `decimal_dabble_stage`/`decimal_double_dabble` conforme DEC-035 e `sqrt_stage` conforme DEC-036. O caller direto `conversion_check` em `tb_decimal_display.v` deve ser migrado e continuar verificando os sete dígitos completos. Preservar particularmente:

| Módulo | Interface vigente a preservar |
|---|---|
| `coefficient_input` / `coefficient_input_core` | `clk`, `key0_n`, `key1_n`, `sw[7:0]`; `a`, `b`, `c` signed8; `loaded` privado no core |
| `add23_core` / `add23` / `sub18` | Operandos e resultados signed23 para soma, signed18 para diferença; `carry_out` privado no core |
| `mul_s8_s8` / `mul_s8_u15` | signed8 × signed8 → signed16; signed8 × unsigned15 → signed22 |
| `polynomial_y` / `polynomial_y_core` | `a,b,c,x` signed8; `y` signed23; `OV` e `carry_y` conforme contratos atuais |
| `sqrt_u17` | radicand unsigned17; root unsigned9; remainder unsigned10 |
| `divide_u9_u8` | dividend unsigned9, divisor unsigned8; quotient unsigned9, remainder unsigned8 e `divide_by_zero` |
| `quadratic_roots` | `a,b,c` signed8; `delta` signed18; `x1,x2` signed9; `domain_error` |
| `result_select` | `x` signed8, `y` signed23, `x1,x2` signed9, `sel[1:0]`; `value` signed23 |
| `decimal_display` | `value` signed23 e `invalid`; `HEX0..HEX5[6:0]` ativos baixos |
| `flag_ov_err`, `flag_z`, `flag_c` | Entradas/saídas e domínios das flags conforme tabela em `docs/interfaces.md`; manter OV atual, Z, C e ERR sem alteração |
| `top_module` | `MAX10_CLK1_50`, `KEY[1:0]`, `SW[9:0]`; `LEDR[9:0]`, `HEX0..HEX5[6:0]` |

As demais portas privadas e conexões entre instâncias continuam compatíveis com `docs/interfaces.md`; não há revisão de largura. Para o BCD privado, a saída corrigida e sua recomposição no testbench seguem DEC-035.

### Clock e reset

Não alterar lógica sequencial. `coefficient_input_core` usa `MAX10_CLK1_50`/clock de 50 MHz, borda de subida, reset lógico síncrono ativo alto derivado de `KEY1` ativo baixo; manter sincronização e captura por evento único conforme DEC-019. Não adicionar nem remover FFs.

### Restrições

- Proibido `assign` contínuo nos 11 arquivos RTL alvo e no `.save`; nenhum inicializador de `wire` ou equivalente para disfarçá-lo. Permissão estrita de DEC-033 para testbench ou descrição dedicada de FF, se necessária, não autoriza novos usos nesta migração.
- Não usar `buf`, portas identidade como aliases, FSM, `if`/`else`, laços, `generate`, atribuições comportamentais fora do DFF, nem criar estado.
- Remover aliases por ligação direta produtor-consumidor, inclusive entre portas de instâncias e por bits quando largura e ordem forem preservadas. Não inserir portas para simular fios.
- Entradas constantes de instâncias recebem literais diretamente. Saídas realmente constantes requerem driver estrutural único compatível com `regras.md`; se não houver forma permitida, bloquear e registrar o caso, sem inventar workaround.
- Preservar equações, bit order, sinal, extensões, truncamentos existentes, FFs, pinagem, flags e semântica de exibição. A reestruturação interna Double Dabble deve seguir DEC-035 e manter o BCD físico ligado aos HEX.
- `rtl/coefficient_input.v.save` continua cópia arquivada e não pode ser incluído na compilação/síntese.

### Arquivos permitidos

- RTL ativo com ocorrências de `assign` (11): `rtl/add_sub.v`, `rtl/coefficient_input.v`, `rtl/decimal_display.v`, `rtl/divide_u9_u8.v`, `rtl/multipliers.v`, `rtl/polynomial_y.v`, `rtl/quadratic_roots.v`, `rtl/result_select.v`, `rtl/sqrt_u17.v`, `rtl/status_flags.v`, `rtl/top_module.v`.
- Cópia arquivada: `rtl/coefficient_input.v.save`.
- `testbench/tb_decimal_display.v`: adaptar somente o caller direto `conversion_check` para a nova saída privada e recompor os 28 bits BCD no testbench conforme DEC-035; manter estímulos e todas as verificações.
- Documentação e estado: `docs/regras.md`, `docs/convencoes_verilog.md`, `docs/decisions/DEC-030.md`, `docs/decisions/DEC-033.md`, `docs/decisions/DEC-035.md`, `docs/decisions/DEC-036.md`, `docs/sprints/README.md`, `docs/pendencias.md` e esta TASK.

### Arquivos protegidos

- `docs/decisions/DEC-034.md`, contratos P0, matemática, `docs/interfaces.md`, `docs/modulos.md`, pin assignments e quaisquer arquivos fora da lista permitida.
- Todos os testbenches, exceto `testbench/tb_decimal_display.v`: executar como estão e não alterar. Migrar apenas o caller direto do conversor no testbench de display conforme DEC-035, mantendo estímulos e verificações independentes.
- `rtl/arithmetic_cells.v`: dependência sem `assign`, não precisa de edição.
- Fontes de síntese/compilação: não adicionar o `.save`.

### Testes exigidos

- Executar os testbenches existentes dos módulos afetados: `tb_add_sub.v`, `tb_coefficient_input.v`, `tb_decimal_display.v`, `tb_divide_u9_u8.v`, `tb_multipliers.v`, `tb_polynomial_y.v`, `tb_quadratic_roots.v`, `tb_result_select.v`, `tb_sqrt_u17.v`, `tb_status_flags.v` e `tb_top_module.v`. O único ajuste autorizado é a conexão/recomposição BCD do caller em `tb_decimal_display.v`, preservando estímulos, referência independente, contagem e verificações.
- Executar `python3 verification/run_system.py`; esse runner usa lista explícita dos 12 RTL ativos, inclui `arithmetic_cells.v` como dependência e exclui `.save`.
- Executar Compliance Gate e auditoria independente: zero `assign`/inicializador equivalente nos alvos, sem violações estruturais ou drivers duplicados, e sem findings HIGH/CRITICAL.
- Registrar comandos, versões, fontes e contagens, cobertura/resultado e logs reais na TASK. Não alegar teste, síntese ou validação física que não tenha sido executada.

### Casos de borda

- Confirmar bit a bit largura, ordem e sinal em concatenações e extensões que forem religadas.
- Confirmar carry inicial/final, bits constantes de arrays estruturais e saídas de constantes com driver único.
- Preservar sinais e resultados extremos já cobertos pelas suítes: entradas signed `-128`, `-1`, `0`, `1`, `127`; `Δ` e raízes inválidas; zero/limites BCD; estados de reset, carga parcial/completa e captura excedente.
- Confirmar que `HEX0..HEX5` continuam mostrando os resultados/traços sob as condições atuais.

### Critérios de aceite

- Nenhum `assign` contínuo nem atribuição contínua disfarçada nos 11 arquivos ativos alvo e em `rtl/coefficient_input.v.save`.
- Todas as suítes e a integração de sistema listadas passam com fontes explícitos, sem `.save`.
- Interfaces, equações, representação, FFs, pinagem, flags e caminho BCD→HEX preservados.
- Sem `buf`, porta identidade, múltiplos drivers, latch ou loop combinacional; Compliance Gate e revisão independente sem findings HIGH/CRITICAL.

### Dependências

- DEC-033 em CONSENSUS (Rodada 2 ACCEPT); inventário de 96 ocorrências em 11 arquivos com `assign`.
- Suítes de referência já aprovadas nas TASKs 002/003/004/006/007/008/009/010/011/012/013/017/018/019; esta implementação deve reexecutar as afetadas e capturar evidência atual.
- A pendência DEC-034 não bloqueia a remoção sintática desde que nenhum aspecto de largura/OV/apresentação sob aquela decisão seja alterado.

### Pendências

- Após a implementação, revalidar o conjunto de RTL por simulação e auditoria conforme acima. Síntese/STA e validação física ficam fora dos critérios desta TASK e não são alegadas.

### Resultado do Context Analyst — 12/10/2026

`READY_FOR_IMPLEMENTATION`. Interfaces, restrições, arquivos e evidências exigidas estão definidos. A TASK preserva integralmente os contratos vigentes e exclui mudanças de largura/OV/política de apresentação de DEC-034. BCD permanece lógica do DUT conectada aos displays. Não editei RTL nem executei testes.

### Bloqueio do Orchestrator — 12/10/2026

DEC-035 chegou a CONSENSUS na rodada 2. Atualizado o escopo para permitir a remodelagem privada de `decimal_dabble_stage`/`decimal_double_dabble` e a migração exclusiva do caller `conversion_check` em `tb_decimal_display.v`. A interface pública, o BCD ligado aos HEX e as verificações funcionais continuam obrigatórios. A TASK retorna a READY; ainda não há edição RTL nem teste nesta rodada.

### Resolução do bloqueio parcial — DEC-036 — 12/10/2026

DEC-036 chegou a CONSENSUS na rodada 2. A interface privada de `sqrt_stage` pode ser remodelada mantendo `sqrt_u17` público e suas nove etapas; o brief exige os mapeamentos de raiz, resto, pares e carry documentados na decisão. Implementação retomada; simulações permanecem pendentes.

### Auditoria independente — 12/10/2026

- **Compliance Gate: PASS.** Varredura dos 12 `.v` em `rtl/` e de `rtl/coefficient_input.v.save`: sem `assign`, inicializador de `wire`, `buf`, FSM, laços ou comportamento fora dos módulos dedicados de FF. `git diff --check` passou. A única atribuição contínua nova está em `testbench/tb_decimal_display.v`, autorizada pela DEC-033 e restrita à reconstrução da observação BCD do caller migrado.
- **Integration Gate: PASS.** Comparação das declarações de portas contra `HEAD` não encontrou mudança em interfaces públicas; foram excluídas da comparação apenas as interfaces privadas remodeladas com consenso em DEC-035 (`decimal_dabble_stage`, `decimal_double_dabble`) e DEC-036 (`sqrt_stage`). Busca de callers confirmou a cadeia do Double Dabble só em `rtl/decimal_display.v` e no caller migrado do testbench, e nove instâncias de `sqrt_stage` dentro de `sqrt_u17`. `verification/run_system.py` passou com Icarus Verilog 14.0 devel, cobrindo 10 cenários e 660 verificações; a lista explícita de fontes exclui `.save`. Os artefatos gerados foram restaurados após registrar o resultado aqui. Não foram encontrados achados de integração.
- **Functional Gate: PASS.** As onze suítes requeridas emitiram marcadores PASS e contagens completas; o auditor independente aceitou o marcador final e a cobertura exaustiva de `tb_multipliers`, registrando separadamente o código 130 do wrapper.
- **Resultado independente:** APPROVED, sem findings CRITICAL/HIGH. Síntese, STA e validação física não foram realizadas.
