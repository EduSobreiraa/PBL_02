# TASK-015 — Síntese e compilação Quartus

## Objetivo

Configurar e compilar no Quartus o top-level aprovado para a DE10-Lite e registrar os resultados de síntese.

## Status

DRAFT

## Requisitos relacionados

- REQ-013, REQ-014

## Decisões relacionadas

- DEC-018, DEC-021

## Dependências

- TASK-012 aprovada; interfaces e top-level finais.
- Baseline de pinagem consultada em `docs/hardware.md` e conferida contra a documentação da placa.
- Quartus Prime Standard Lite 25.1std.0 Build 1129.

## Restrições aplicáveis

- Não alterar pin assignments sem autorização.
- Preservar os módulos/interfaces aprovados; registrar warnings e limitações.

## Arquivos permitidos

- A definir no planejamento para arquivos de projeto Quartus e relatórios gerados.

## Arquivos protegidos

- Requisitos, decisões, pinagem oficial e RTL fora de mudança autorizada.

## Plano

- Configurar dispositivo, top-level, I/O e restrições conforme baseline aprovada.
- Compilar/sintetizar e registrar logs, warnings e contagem de LEs.

## Critérios de aceite

- Compilação sem erros; warnings relevantes analisados.
- Dispositivo, I/O e restrições conferidos e registrados.
- Evidência de síntese inclui recursos/LEs para o relatório.

## Testes

- TEST-014.

## Resultado da implementação

Não iniciado.

## Resultado das ferramentas

Não executado.

## Resultado da revisão

Pendente.

## Pendências

- Projeto QSF/QPF do PBL02 ainda não foi produzido.
- Baseline de pinagem depende do top-level final.

## Histórico

- 2026-10-06 — TASK candidata criada na Sprint 0; status DRAFT.
