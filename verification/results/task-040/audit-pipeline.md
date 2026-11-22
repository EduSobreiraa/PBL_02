# Auditoria independente — TASK-040

**Resultado: APPROVED**
**Gates:** Compliance PASS · Functional PASS · Integration PASS
**Findings CRITICAL/HIGH:** nenhum.

Auditoria realizada contra `REGRAS.md` PBL03, TASK-040 e seu Implementation Brief, DEC-031/058/059/060/062/063/064, RTL atual, testes e evidências. Não houve alteração de RTL.

## Gate 1 — Compliance

- `quadratic_roots` é estrutural: os 23 estágios e payloads usam módulos DFF dedicados, e não há `always`, `initial`, `assign`, `generate`, `for`, `buf` ou FSM nova no pipeline. A única alteração comportamental está na FSM principal previamente autorizada, agora com a guarda `roots_ready`.
- O projeto mantém um módulo por arquivo. `python3 verification/check_pbl03_sources.py` passou.
- `git diff` confirma que `quartus/pbl03.qsf`, `verification/pbl03_sources.json`, `quartus/pbl03.sdc` e `vendor/vga/vga_sync.v` não foram alterados. O manifesto de fontes inclui a closure utilizada, sem dependência nova.
- Ports físicos, clock de 20 ns, constraints de 40 ns, periférico VGA e prioridade/cores do compositor foram preservados.

## Gate 2 — Functional

Reexecutei `sim/run_pbl03_regression.sh`; terminou com `PBL03 TASK-036 AGGREGATE PASS`. O fingerprint do RTL/testes/configuração foi `f77d7b02b7864da7cf4a4de6ea6e16d4714b1da77ef77dc95b78b774b934b227`, registrado em `pipeline/rtl-source-fingerprint.sha256`. A saída da reexecução está em `pipeline/aggregate-regression-audited.log`.

- **Aritmética e pipeline:** a suíte de raízes passou 30 vetores dirigidos e 256 vetores determinísticos contra referência inteira independente. Confirma N→N+22, pulso `result_valid` de um ciclo, retenção das saídas, flush por START/reset, F2 inativa sem token e alinhamento token/payload. Inclui casos de discriminante negativo/zero/positivo, coeficientes negativos e divisor zero; para `A_original=0`, a máscara impede raiz fictícia e mantém o erro de domínio.
- **Estado/handshake:** `root_domain_valid` é apagado em reset/START e só é setado por token válido sem erro. `roots_ready` é sticky, limpa em reset/START e aguarda F1 mais F2 habilitada; F2 nula é dispensada. A FSM principal só aceita START em REVIEW/DISPLAY e espera `done_f1 && done_f2 && roots_ready`; testes confirmam que START em WAIT não interrompe o pipeline e que DONE não antecipa os tokens.
- **Exibição:** as suítes de renderer/compositor passam gating, clipping e prioridade. O compositor implementa interseção > marcador raiz > rótulo raiz > vértice > F1 > F1′ > F2 > F2′ > eixos > fundo. O frame completo Verilator passou com 20.161.162 verificações vetoriais, incluindo F2 inativa, delta negativo sem suprimir a parábola, interseções coincidentes/fracionárias, vértices de borda e rótulos/marcadores.
- Não houve ensaio em placa física; a regressão não é evidência de validação elétrica ou de monitor VGA.

## Gate 3 — Integration e STA

Reexecutei `quartus_sh --flow compile quartus/pbl03` no estado auditado: compilação e fitter completos, **0 erros e 33 avisos**. Reexecutei STA pós-fit usando o SDC do projeto e o modelo de pior corner slow 1200 mV/85 °C. Os resultados atuais passam os limites da TASK:

| Caminho | Pior slack pós-fit | Limite | Resultado |
|---|---:|---:|---|
| FF→FF setup | +0.873 ns | abaixo de 20 ns | PASS |
| FF→FF hold | +0.247 ns | sem violação | PASS |
| 12 saídas RGB | +2.587 ns (`VGA_G[0]`) | 40 ns | PASS |
| `VGA_HS` | +31.472 ns | 40 ns | PASS |
| `VGA_VS` | +31.342 ns | 40 ns | PASS |

Os 14 endpoints RGB/HS/VS foram relatados individualmente; todos têm slack positivo. A conclusão não depende de relaxamento de constraints.

### Proveniência dos slacks

- A recompilação está registrada em `pipeline/quartus-compile-audited.log`, Quartus Prime Lite 25.1std.0, iniciada em 2026-11-22 17:59:44 e concluída em 18:02:10, horário local do ambiente. Compilação e fitter: 0 erros; STA: 0 erros, 0 avisos.
- `pipeline/pbl03-sta-audited.rpt` é o relatório STA pós-fit gerado por essa recompilação. No corner slow 1200 mV/85 °C, o pior setup FF→FF é +0.873 ns e hold é +0.247 ns. Os resultados +2.196/+0.248 correspondem ao corner slow 1200 mV/0 °C, não ao pior corner.
- `pipeline/vga-paths-audited.log` registra os endpoints pós-fit individuais no modelo slow 1200 mV/85 °C, executados às 18:07:35–18:07:37. O pior RGB é VGA_G[0] +2.587 ns; VGA_HS +31.472 ns; VGA_VS +31.342 ns.
- O relatório temporário de +5.612 ns/+32.216 ns/+32.084 ns era do modelo slow 0 °C e não é usado como resultado do gate de pior corner; esses arquivos temporários não foram copiados.

### Avisos Quartus observados

Os 33 avisos não contêm erro de compilação nem violação dos gates de temporização. A classificação observada é:

- Atribuições constantes de largura maior truncadas em duas linhas do `vendor/vga/vga_sync.v`; fonte fornecida pelo professor, mantida intacta.
- Saídas LED/HEX constantes devido a bits não usados pelo contrato atual.
- Recurso LogicLock indisponível na edição/licença instalada.
- Assignments de drive strength ausentes nas saídas físicas, reportados como I/O incompleto; o fitter também lista 12 interfaces 3.3-V. Pinagem e QSF foram preservados conforme DEC-059. Isso deve permanecer registrado para a validação física, mas não constitui falha funcional ou de STA desta TASK.
- O relatório indica projeto globalmente não totalmente constrained, mas as saídas VGA contratadas foram analisadas explicitamente com o limite de 40 ns e passaram; FF→FF foi analisado sob o clock de 20 ns.

## Findings

Nenhum finding CRITICAL ou HIGH. As advertências de I/O foram registradas sem mudar assignments protegidos ou inferir validação física.

## Parecer

**APPROVED.** Compliance passou; regressão obrigatória e source checker passaram no fingerprint do RTL atual; a integração mantém as interfaces e arquivos protegidos; o pipeline, handshake, reset/flush, gating/renderização e STA pós-fit cumprem os contratos aplicáveis. A ausência de teste físico permanece explicitamente fora da evidência disponível.
