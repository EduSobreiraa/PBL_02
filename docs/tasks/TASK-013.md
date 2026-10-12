# TASK-013 — Verificação do sistema por simulação

## Objetivo

Implementar/verificar o escopo especificado abaixo segundo as decisões aprovadas.

## Status

APPROVED

## Requisitos relacionados

REQ-015

## Decisões relacionadas

DEC-005/020/030/031

## Dependências

TASK-012 implementada/auditável, módulos aprovados e backend acessível.

## Restrições aplicáveis

Aplicar `docs/regras.md` e `docs/agente_workflow.md`. Contratos matemáticos preservados; DUT estrutural, comportamento somente nos FF dedicados; nenhum novo estado sem decisão explícita. Delegação de 11/10/2026 substitui gates anteriores de consulta humana. READY exige brief e confirmação de contexto; APPROVED exige evidência real e auditoria independente.

## Arquivos permitidos

testbench/tb_top_module.v; verification/ (scripts e vetores de sistema); verification/results/ (logs reais)

## Arquivos protegidos

Requisitos P0, RTL fora do escopo, pinagem oficial e contratos não revisados pelas decisões citadas.

## Plano e contrato fechado

Backend automatizado Icarus Verilog/vvp local ou container hdlc/iverilog; Verilator compilado é alternativa para exaustões custosas, conforme adaptação operacional de DEC-030 e ferramentas permitidas no workflow. Registrar versão/digest efetivamente usados, cobertura e resultados separadamente por backend. EDA Playground serve para reprodução visual sem bloquear automação. Compilar fontes explícitos e -s, excluir .save. Registrar comandos, hashes, seed, cobertura e resultados; testbench separado comportamental sem if/else.

## Critérios de aceite e testes

TEST-010/011 com referência independente; nenhum caminho não exercitado ganha PASS. Versão/logs reais são critérios de execução, não escolhas pendentes.

## Implementation Brief

### Objetivo

Consolidar verificação reproduzível do sistema integrado, sem alterar RTL.

### Requisitos

REQ-015.

### Decisões aplicáveis

DEC-005, DEC-020, DEC-030, DEC-031.

### Módulos envolvidos

tb_top_module; scripts/vetores de sistema em verification/ e relatórios/logs em verification/results/.

### Interface

Interface de teste é a interface física de top_module da TASK-012; referência independente valida HEX/LEDR e sequência de entradas. Scripts recebem fontes/casos/seed explícitos e produzem logs/contagens/hash; não acrescentar porta de debug ao DUT.

### Clock e reset

Estímulo50MHz/20ns, reset e capturas respeitam sincronizadores existentes. Aguardar acomodação combinacional antes de observar outputs. Simulação digital não comprova timing físico.

### Restrições

Preservar regras.md e contratos DEC-030/031: DUT estrutural por portas/instâncias explícitas; comportamento apenas DFF dedicado, sem if/else/buf/FSM/loops/generate/parâmetros/operadores aritméticos no DUT. assign somente fiação estática. Testbench separado pode usar aritmética de referência, laços e case, nunca if/else. Não alterar contratos, pinagem ou dependências aprovadas. Registrar versão/backend, fontes explícitos sem .save, comandos, cobertura, logs e hashes reais. Nenhum PASS presumido por planejamento.

### Arquivos protegidos

Todo arquivo fora da lista permitida, especialmente requisitos, decisões e RTL dependente aprovado. Ler/compilar dependências não autoriza sua edição.

### Arquivos permitidos

testbench/tb_top_module.v; verification/ para scripts/vetores de sistema; verification/results/ para logs reais; resultados/auditoria na própria TASK-013.

### Testes exigidos

TEST-010/011 integralmente conforme TASK-012: reset/carga/seletor/resultados/flags/invalidade/bloqueio/reset durante carga e sinais/extremos/empates/limitesvisuais. Comparação independente da cadeia e de codificação decimal. Icarus/vvp local ou Docker hdlc/iverilog, top explícito e fontes explícitos. Verilator só como alternativa registrada para exaustão custosa; separar resultados por backend. Não repetir suites já aprovadas sem mudança/achado que justifique; selecionar regressões impactadas e registrar cobertura.

### Casos de borda

KEY prolongado/simultâneo, carga parcial/completa/excedente, reset, mudançaSW/sel, a0/Δ<0, limites de display, Z/C/OV/ERR e empate dos dois sinais.

### Critérios de aceite

Suites exigidas concluídas com logs reais, zero divergências e cobertura rastreável; nenhum caminho não exercitado ganha PASS. Auditoria independente antes de APPROVED.

### Dependências

Brief completo. PLANNED até TASK-012 implementada/auditável e backend acessível; módulos estão APPROVED. Orchestrator pode promover READY quando houver evidência dessas dependências sem nova decisão.

### Pendências

Nenhuma decisão arquitetural aberta. Permanecem somente dependências e evidências de execução acima.

### Resultado do Context Analyst — 11/10/2026

BRIEF_COMPLETO; mantém PLANNED até as dependências de execução. Não é bloqueio por decisão arquitetural. Nenhum RTL, simulação, síntese ou auditoria final foi executado nesta preparação.

## Resultado da implementação

Criado `verification/run_system.py` com Python stdlib, lista explícita de12RTL+TB, empacotamento tar/stdin, execução Docker por ID imutável e captura de log/manifest. TB e RTL aprovados da TASK-012 preservados sem alteração. Resultados em `verification/results/system-icarus.log`, `system-icarus.json` e `task-013.md`.

## Resultado das ferramentas

Runner executado integralmente:TEST-010/011 PASS10cenários/660observações, código0, Icarus14.0 devel s20260301-394-g9edaf7b6a, compilação -Wall sem warnings. Imagem/digest, comando, hashes e log real registrados nos artefatos; conferência independente via Python confirmou hashes de todos fontes/log. Seed não aplicável, suite dirigida determinística. Reexecução do teste integrado justificada pela validação do runner novo; suites unitárias/exaustivas não repetidas.

## Resultado da revisão

**APPROVED — Code Auditor independente, ciclo 1, 11/10/2026.** Gate 1 PASS: runner Python stdlib no escopo, sem alterações HDL, lista fixa de12RTL+TB exclui .save, argumentos Docker estruturados e imagem executada pelo ID inspecionado. Gate 2 PASS: invalida sucesso antigo antes da execução, encadeia compilação/simulação e só registra PASS com retorno0 e exatamente um marcador completo TEST-010/011; saída de falha retorna não zero. Manifest/log reais confirmam10 cenários/660 observações; conferência independente dos13 hashes e hash do log passou, com um marcador esperado. Gate 3 PASS: contratos e fontes TASK-012 preservados, versões/comando/digest/log rastreáveis, seed corretamente não aplicável à suite dirigida. Nenhum finding. Sem reexecução desnecessária; evidência limitada à simulação funcional, sem síntese/timing/placa.

## Pendências de execução

Nenhuma pendência desta implementação: TASK-012, execução do runner e auditoria independente aprovados. Validação física/timing/síntese permanecem fora desta evidência.

## Histórico

- 2026-10-11 — TASK-012 APPROVED; dependência de integração satisfeita. Orchestrator promove a READY conforme o gate definido no brief, sem mudança arquitetural.
- 2026-10-11 — Context Analyst preparou brief completo; estado PLANNED conforme dependências verificadas. Nenhuma implementação/evidência antecipada.

- 2026-10-06 — TASK candidata criada na Sprint 0; delimitada à simulação; status DRAFT.
- 2026-10-11 — Contratos, arquivos e critérios fechados sob delegação em DEC-030/031; planejamento reconciliado, sem declarar implementação ou testes.

- 2026-10-11 — READY → IMPLEMENTING → IMPLEMENTED → TESTING → TESTED → REVIEW; runner validado por TEST-010/011 integral, fontes preservados, logs/hashes/digest registrados.
