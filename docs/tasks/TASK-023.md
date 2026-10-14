# TASK-023 — Prompt visual para entrada dos coeficientes

## Objetivo

Durante a carga sequencial `a→b→c`, orientar a próxima entrada nos displays: HEX0 mostra `A`, `b` ou `C`, com HEX1–HEX5 apagados. Após a terceira captura, restaurar a apresentação selecionada normal.

## Status

APPROVED — implementação, simulações e auditoria independente concluídas. Síntese, análise de timing/recursos e validação física continuam pendentes.

## Requisitos relacionados

- REQ-002
- REQ-009

## Decisões relacionadas

- DEC-019 — polaridade e ordem dos segmentos.
- DEC-024 — protocolo de captura e contador de progresso.
- DEC-030 — integração e apresentação; regra pré-carga de `x` supersedida somente enquanto `loaded=0`.
- DEC-040 — prompt visual A/b/C.

## Dependências

- `entrada_coeficientes_nucleo` e `modulo_principal` existentes.
- `exibicao_decimal` existente.

## Restrições aplicáveis

- Nenhuma alteração nas portas físicas, pinagem, KEY0/KEY1, SW ou ordem de captura.
- Nenhum FF novo, FSM, `if`, `else`, `buf`, laço ou `assign` contínuo no RTL.
- Preservar o contrato público do wrapper `entrada_coeficientes`.
- Em progresso `00/01/10`, prompt A/b/C independe de `SW[9:8]`; em `11`, seleção e apresentação existentes devem ser idênticas.
- O prompt não confirma o valor capturado nem altera LEDs ou bloqueio após `c`.

## Arquivos permitidos

- `rtl/entrada_coeficientes.v`
- `rtl/modulo_principal.v`
- `testbench/tb_coefficient_input.v`
- `testbench/tb_status_flags.v`
- `testbench/tb_top_module.v`
- `rtl/exibicao_decimal.v` — somente renomear labels de instância BCD duplicados para permitir compilação.
- `docs/interfaces.md`
- `docs/tasks/TASK-023.md`

## Arquivos protegidos

- Pin assignments/QSF.
- `docs/requisitos.md` e requisitos P0.
- Outros módulos aritméticos e de apresentação.

## Plano

1. Expor os bits já existentes do progresso apenas na interface privada de `entrada_coeficientes_nucleo`, mantendo `loaded`.
2. Migrar callers do core: wrapper, top-level e testbenches de entrada/flags.
3. No top-level, decodificar estruturalmente `00/01/10` para `A/b/C`; selecionar esse glifo em HEX0 e apagar HEX1–HEX5 enquanto `loaded=0`.
4. Quando `loaded=1`, passar sem alteração os HEX da apresentação decimal atual.
5. Cobrir a sequência, reset, independência do seletor durante o prompt e restauração após carga completa.

## Critérios de aceite

- Após reset, HEX0 mostra `A`; HEX1–HEX5 estão apagados.
- Após capturas de `a` e `b`, HEX0 mostra `b` e `C`, respectivamente; HEX1–HEX5 permanecem apagados.
- O prompt prevalece para qualquer `SW[9:8]` enquanto `loaded=0`.
- Após captura de `c`, apresentação normal funciona para `x`, `y`, `x₁` e `x₂` conforme contratos atuais.
- Reset durante carga retorna a `A`; capturas após `c` continuam ignoradas.
- Nenhum FF é adicionado; portas públicas e pinagem permanecem inalteradas.

## Testes

- Atualizar teste de `entrada_coeficientes_nucleo` para verificar a saída de progresso nos estados `00/01/10/11`.
- Atualizar instâncias do core nos testbenches afetados.
- No testbench do top-level, verificar glifos ativos baixos A/b/C, HEX1–HEX5 apagados, prompt sob seleções variadas e restauração numérica em `11`, incluindo seleção `x`.
- Testes de entrada, flags e top-level executados e aprovados; auditoria independente concluída.

## Resultado da implementação

`entrada_coeficientes_nucleo` expõe os dois bits de progresso já armazenados, sem acrescentar FF; o wrapper público segue inalterado. `modulo_principal` prioriza os glifos A/b/C durante a carga, apaga HEX1–HEX5 com nível alto ativo baixo e restaura os HEX normais quando `loaded=1`. Os testbenches de entrada, flags e top verificam o novo contrato e a restauração.

Corrigidos também labels duplicados `selecao_10`/`selecao_11` em `rtl/exibicao_decimal.v` e variáveis de laço `selecao` duplicadas em `tb_status_flags.v`, que impediam a compilação Icarus dos arquivos afetados.

## Resultado das ferramentas

Icarus Verilog 14.0 via Docker `hdlc/iverilog:latest`, compilado com `-g2012 -Wall`:

- `tb_coefficient_input`: PASS, TEST-001, 15 verificações.
- `tb_status_flags`: PASS, TEST-009/TASK-010, 3.584 checks isolados e 53 integrados.
- `tb_top_module`: PASS, TEST-010/011, 10 cenários e 660 checks, incluindo prompt e retorno à exibição normal.
- `git diff --check`: PASS.
- Busca de conformidade no RTL afetado: nenhum `assign`, `buf`, `if`, `else`, `generate` ou `genvar` encontrado.

Não executados: síntese Quartus, análise de timing/recursos e validação física em DE10-Lite.

## Resultado da revisão

**Rodada 1 — REWORK.** Foram registrados FIND-023-001 (glifo C incorreto e expectativa correlacionada) e FIND-023-002 (porta identidade proibida).

**Rodada 2 — APPROVED.** Os dois findings foram corrigidos: a rede estrutural agora produz `7'b1000110` para C, conforme DEC-019, e a expectativa de `tb_top_module` confere esse vetor; o enable usa `loaded` diretamente, sem porta identidade. A revisão não encontrou findings CRITICAL/HIGH ou violações obrigatórias remanescentes.

Testes reproduzidos na segunda rodada com Icarus Verilog via Docker (`-g2012 -Wall`):

- `tb_coefficient_input`: PASS, TEST-001, 15 verificações.
- `tb_status_flags`: PASS, TEST-009/TASK-010, 3.584 checks isolados e 53 integrados.
- `tb_top_module`: PASS, TEST-010/011, 10 cenários e 660 checks.
- `git diff --check`: PASS.

O caso C usa agora o padrão definido pela correspondência de segmentos DEC-019, e não o padrão defeituoso encontrado na rodada anterior. Compliance e integração: sem FSM, `buf`, `assign` contínuo, construções comportamentais proibidas ou laços no DUT; progresso usa os FF existentes, wrapper público preservado e portas/pinagem inalteradas. Síntese, timing/recursos e validação física continuam pendentes.

## Pendências

Nenhuma decisão técnica bloqueadora. Síntese e validação física seguem os gates do projeto.

## Histórico

- 2026-10-13 — criada após DEC-040 CONSENSUS; primeira tentativa exploratória falhou e foi revertida.
- 2026-10-13 — implementação estrutural concluída e validada por TEST-001, TEST-009 e TEST-010/011; status TESTED. Síntese, auditoria independente e validação física pendentes.
- 2026-10-13 — auditoria Code Auditor: REWORK por padrão incorreto de C (FIND-023-001) e porta identidade proibida (FIND-023-002). Testes reproduzidos passaram, mas o oráculo do glifo C repete o padrão do RTL; síntese e placa não verificadas.
- 2026-10-13 — auditoria Code Auditor, rodada 2: APPROVED. FIND-023-001 fechado com padrão C `1000110` e expectativa conferida contra DEC-019; FIND-023-002 fechado removendo a porta identidade. TEST-001, TEST-009, TEST-010/011 e `git diff --check` reproduzidos com PASS. Síntese e validação física continuam pendentes.
- 2026-10-13 — TASK-023 marcada APPROVED após auditoria independente; síntese e validação física não executadas.
