# Sprint 4 — Seleção, displays e flags

## Estado

CONCLUÍDA — TASK-006, TASK-010, TASK-018 e TASK-019 estão APPROVED. As alterações do arquivo rtl/sinalizadores_status.v foram serializadas e auditadas.

## Escopo e sequência

TASK-006 implementa result_select e decimal_display (double-dabble espacial); TASK-010/018/019 implementam flag_ov_err/flag_z/flag_c em arquivo compartilhado, sequencialmente para evitar conflito. Podem testar com entradas controladas antes da integração das Sprints1–3.

## Contratos

Seleção x/y/x1/x2, value signed23; faixa decimal0..999999 e -99999..-1; zeros iniciais apagados, sinal em HEX5, inválido/excesso em seis traços. Z segue valor e máscara raiz inválida; C carry final de y AND loaded AND seleção y; ERR carregado e persistente pelos coeficientes congelados, nenhum FF novo. Interfaces completas em docs/interfaces.md e DEC-030.

## Critérios de conclusão

TEST-008/009 com limites, polaridade, máscaras, seleções e flags; todas TASKs aprovadas pelo Auditor. A integração das raízes depende de TASK-011 aprovada. Nenhuma decisão de origem C ou F16 permanece em aberto.

## Resultado — 11/10/2026

- TASK-006 APPROVED: seletor 6.048 casos; display 10.032 casos e 16 padrões BCD/add3; sem warnings.
- TASK-010 APPROVED: OV/ERR 3.584 casos isolados e 53 integrados; sem warnings.
- TASK-018 APPROVED: Z 240 casos; sem warnings.
- TASK-019 APPROVED: C 16 casos isolados e 64 integrados, incluindo distinção entre carry intermediário e carry da soma final; sem warnings.

Icarus14, exit0. Cada TASK contém os comandos, hashes e evidências; todas passaram pelos três gates do Code Auditor no primeiro ciclo. Nenhum FF foi adicionado. Sprint5 pode iniciar com integração do sistema.
