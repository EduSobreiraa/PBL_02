# Pacote técnico reproduzível PBL03

## Proveniência

- Git HEAD no início: `ec19269f6c3b71ca9ead50ee6c89d6df0dbadcc9`
- Estado inicial do worktree: registrado em `worktree-status-start.txt` (`clean` significa limpo; texto Git indica alterações locais).
- Fingerprint SHA-256 dos inputs: `548358e29a6907935c81b94068018179dcac7c1bb4e95769f945bcf064cb7787` (`input-sha256.txt`, calculado antes das verificações).
- Início UTC: `2026-11-22T22:10:13Z`
- Fim UTC: `2026-11-22T22:16:01.803170+00:00`
- Quartus: `Quartus Prime Shell
Version 25.1std.0 Build 1129 10/21/2025 SC Lite Edition
Copyright (C) 2025  Altera Corporation. All rights reserved.`
- Quartus compile reported 6 top-level warning messages; see `quartus-compile.log` for details.
- Fontes Quartus ativas: `57` caminhos em `active-sources.txt`, conferidos contra QSF e manifesto.
- Periférico VGA professor: `vga-upstream.sha256` confere com `vendor/vga/UPSTREAM.md`.
- Slacks pós-fit: ver `timing-results.txt`; todos os 14 endpoints VGA e o pior caminho FF→FF precisam ter slack não negativo sob as constraints existentes.

## Comandos e resultados

1. `python3 verification/check_pbl03_sources.py` — PASS; log `source-check.log`.
2. `./sim/run_pbl03_regression.sh` — PASS; log agregado `regression.log`; log próprio do runner `regression-runner.log`.
   Marcadores PASS observados: 10; ver log para Icarus/VPI e Verilator.
3. `quartus_sh --flow compile quartus/pbl03` — PASS; `quartus-compile.log` e relatórios atuais em `quartus/`.
4. TimeQuest detalhado: 14 endpoints VGA e consulta FF→FF; `quartus-paths.log`.
5. `git diff --check` — PASS; log `diff-check.log`.
6. `artifact-sha256.txt` valida as evidências finais com `sha256sum -c`.

## Limitações e entregas externas

- Não foi realizado teste físico da DE10-Lite nem do monitor VGA nesta execução.
- O modelo oficial de relatório do tutor não estava disponível no repositório e não está incluído.
- Compilação e TimeQuest são evidências de ferramenta; não demonstram operação física.
- O estado/fingerprint descreve o snapshot verificado. Para repetir, execute `./verification/package_pbl03_release.sh` na raiz do repositório.

Package end UTC: 2026-11-22T22:16:01Z
Input fingerprint: 548358e29a6907935c81b94068018179dcac7c1bb4e95769f945bcf064cb7787
