# TASK-007 — implementação e TEST-003

Data: 2026-10-11. Code Implementer. TEST-003 concluído PASS; revisão independente pendente.

## Implementação

`rtl/multipliers.v` contém somente os dois módulos aprovados. Cada linha parcial seleciona os oito bits de lhs por AND; extensão do sinal reutiliza o fio do bit7 selecionado e deslocamentos são concatenações fixas. Cadeias explícitas locais reutilizam full_adder de TASK-003: 112 instâncias para s8×s8 (seis somas positivas e uma subtração do peso do sinal), 308 para s8×u15 (14 somas), total420. Nenhum FF. `rtl/arithmetic_cells.v` permanece intocado.

O contrato s8×u15 exige rhs0..16384. Prefixos das linhas selecionadas nunca superam rhs; produtos parciais e resultado cabem signed22. O multiplicador signed8 usa bits0..6 positivos e subtrai o termo do bit7. Carries finais são bits binários descartados nos domínios aprovados, sem perda do valor signed representável. Síntese ainda não mediu área; nenhuma alegação de mínimo global de portas.

## Referência e cobertura executada

91 vetores dirigidos de inteiros Python em `verification/vectors/multipliers.txt`, produzidos por `verification/reference_multipliers.py`. O testbench enumera todos os65536 pares signed8, todos os4194560 pares signed8×unsigned15 dentro de0..16384 e256 quadrados. A referência exaustiva é multiplicação de inteiros no testbench, independente das linhas/portas do DUT. Quadrados verificam bit15=0 e conversão exata dos bits14:0; contagens finais são exigidas, arquivo ausente/malformado, X/Z ou divergência causam $fatal. Operadores/laços/comportamento de referência permanecem exclusivamente fora do DUT, sem if/else no testbench.

## Comando executado

```sh
python3 verification/reference_multipliers.py
tar -cf - rtl/arithmetic_cells.v rtl/multipliers.v testbench/tb_multipliers.v verification/vectors/multipliers.txt | docker run --rm -i hdlc/iverilog:latest sh -c 'mkdir -p /tmp/work; cd /tmp/work; tar -xf -; iverilog -V; iverilog -g2012 -Wall -s tb_multipliers -o /tmp/task007.vvp rtl/arithmetic_cells.v rtl/multipliers.v testbench/tb_multipliers.v && vvp /tmp/task007.vvp' > verification/results/task-007.log 2>&1
```

Backend: Docker hdlc/iverilog:latest, Icarus14.0(devel) s20260301-394-g9edaf7b6a. Tag mutável; comparar versão e hashes para reprodução. Log completo em task-007.log. Resultado: `TEST-003 PASS signed=65536 mixed=4194560 squares=256 boundary=91`, processo retornou código0. Compilação Icarus -Wall sem warnings. Revisão independente pendente. Não executados síntese, timing ou placa.

## SHA-256 dos artefatos executados

```text
0e9e393098a238cf0e5992a187834922fea4506eea13d4cdc635debf7376098e  rtl/arithmetic_cells.v
95d8de13e7cab690e72544c5b4c89efe7c956f46eadcc714a112f80123ddc371  rtl/multipliers.v
5d7104d9eb16c5a4f95fb89d85907d3b2e58bf442d02a9f87535265e2fd298f6  testbench/tb_multipliers.v
3d4c8db4707055ae68265a161982fa897a1fba17021493ec648ab00802e3d7c0  verification/reference_multipliers.py
953e8be5665844d57f089475033de7db0851ba1d129791a662b7315fdb9148dd  verification/vectors/multipliers.txt
```

## Execução e tentativas de aceleração

A simulação Icarus executou a exaustão integral e concluiu com código0; não foi interrompida nem houve redução da cobertura. Durante execução, diagnóstico Docker top registrou elapsed29:47, CPU29:45 e99,8% para vvp; stdout estava retido por buffering. Uma alternativa Verilator foi preparada enquanto Icarus continuava: imagem hdlc/verilator digest sha256:f244b8f1d56eeef74686663118ed6e9f9f6c27f22c1bfbdde70d725936fba1bc, versão5.053 devel v5.052-343-gdc7ef9bdb. Compilação C++ padrão clang falhou em coroutine final_suspend noexcept; tentativa g++ falhou porque não instalado. Nenhuma delas produziu resultado funcional; não são evidência PASS. Casts explícitos introduzidos temporariamente no testbench para avisos do Verilator foram revertidos ao conteúdo original efetivamente executado no Icarus, com SHA-256 confirmado igual ao registro anterior à execução. RTL nunca foi alterado nessas tentativas. Não se repetiu a exaustão desnecessariamente após PASS.

## Code Auditor independente — ciclo 1, 11/10/2026

**APPROVED.** Gate 1 PASS: conferência de todas as conexões das 420 células full_adder, das 23 concatenações de linha e respectivas portas AND; extensão signed, deslocamentos estáticos e subtração da linha7 corretos. Zero FF e nenhuma palavra-chave proibida no DUT; helper compartilhado preservado. Gate 2 PASS: testbench usa referência inteira independente e exige cobertura completa e comparação estrita; log Icarus concluído confirma signed65536/mixed4194560/squares256/boundary91. Gate 3 PASS: portas/domínio restrito conformes DEC-030, integração das células aprovada e nenhum consumidor/pino alterado. Todos os cinco hashes publicados foram recalculados e conferem, incluindo TB restaurado ao conteúdo executado.

Nenhum finding. Tentativas de acelerar com Verilator são compatíveis com o workflow, mas falharam na ferramenta e não são evidência funcional. A aprovação usa exclusivamente a exaustão Icarus concluída; não houve nova execução pelo Auditor. Síntese/timing/placa continuam fora desta aprovação.
