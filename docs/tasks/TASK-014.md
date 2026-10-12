# TASK-014 — Validação física na DE10-Lite

## Objetivo

Implementar/verificar o escopo especificado abaixo segundo as decisões aprovadas.

## Status

BLOCKED

## Requisitos relacionados

REQ-001–010/014/015

## Decisões relacionadas

DEC-001/003/007–019/030/031

## Dependências

TASK-015 aprovada e placa/bitstream disponíveis; dependência física ainda não comprovada.

## Restrições aplicáveis

Aplicar `docs/regras.md` e `docs/agente_workflow.md`. Contratos matemáticos preservados; DUT estrutural, comportamento somente nos FF dedicados; nenhum novo estado sem decisão explícita. Delegação de 11/10/2026 substitui gates anteriores de consulta humana. READY exige brief e confirmação de contexto; APPROVED exige evidência real e auditoria independente.

## Arquivos permitidos

verification/hardware-procedure.md; verification/results/hardware/

## Arquivos protegidos

Requisitos P0, RTL fora do escopo, pinagem oficial e contratos não revisados pelas decisões citadas.

## Plano e contrato fechado

Procedimento fechado em DEC-030: registrar placa, bitstream/versão, reset após energização, três capturas, captura excedente, seleções, sinais/limites, a=0, delta negativo e limpeza de ERR. Registrar observações/fotos reais e comparar com simulação. Operação manual exige SW estável na captura e saídas observadas após acomodação.

## Critérios de aceite e testes

TEST-012/015: setup e evidências físicas. Não substituir ausência de placa por validação simulada.

## Resultado da implementação

Procedimento físico reproduzível criado em `verification/hardware-procedure.md`, com três conjuntos de coeficientes e resultados esperados independentes. Execução na placa não realizada.

## Resultado das ferramentas

Nenhuma execução física registrada. A evidência Quartus da TASK-015 não substitui programação e observação na placa.

## Resultado da revisão

Arquitetura aceita em DEC-030/031 conforme aplicável. Auditoria da implementação permanece futura.

## Pendências de execução

Placa e execução física ainda necessárias para TEST-012/015. A tarefa está BLOCKED por ausência de observações e evidências da DE10-Lite. Nenhuma escolha arquitetural local está em aberto.

## Histórico

- 2026-10-06 — TASK candidata criada na Sprint 0; delimitada à validação física; status DRAFT.
- 2026-10-11 — Contratos, arquivos e critérios fechados sob delegação em DEC-030/031; planejamento reconciliado, sem declarar implementação ou testes.
- 2026-10-11 — Procedimento físico preparado com vetores esperados; execução permanece BLOCKED até haver placa e evidências reais.
