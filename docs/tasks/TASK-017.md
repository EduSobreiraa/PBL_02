# TASK-017 — Auditoria estática independente do HDL

## Objetivo

Implementar/verificar o escopo especificado abaixo segundo as decisões aprovadas.

## Status

APPROVED

## Requisitos relacionados

REQ-008/011/013

## Decisões relacionadas

DEC-014/025/026/030/031

## Dependências

Arquivos implementados, briefs e logs disponíveis. Auditor distinto do implementador.

## Restrições aplicáveis

Aplicar `docs/regras.md` e `docs/agente_workflow.md`. Contratos matemáticos preservados; DUT estrutural, comportamento somente nos FF dedicados; nenhum novo estado sem decisão explícita. Delegação de 11/10/2026 substitui gates anteriores de consulta humana. READY exige brief e confirmação de contexto; APPROVED exige evidência real e auditoria independente.

## Arquivos permitidos

verification/results/compliance.md; seções de revisão das TASKs auditadas

## Arquivos protegidos

Requisitos P0, RTL fora do escopo, pinagem oficial e contratos não revisados pelas decisões citadas.

## Plano e contrato fechado

Aplicar Compliance Gate antes do funcional/integração. Inspecionar léxico e estrutura elaborada: FF dedicados, ausência de FSM/if/else/buf/loops/generate/comportamento ou operadores proibidos, domínio multiplicador restrito, extensões, restos exatos, drivers, latches/loops e portas públicas preservadas. Não modificar RTL. Findings voltam ao Implementer; máximo três ciclos conforme workflow.

## Critérios de aceite e testes

TEST-013: nenhum HIGH/CRITICAL aberto para liberar o conjunto; arquivos e regras associados a cada finding.

## Implementation Brief

### Objetivo

Auditar independentemente o conjunto HDL final, sem corrigir ou implementar funcionalidade.

### Requisitos

REQ-008, REQ-011, REQ-013.

### Decisões aplicáveis

DEC-014, DEC-025, DEC-026, DEC-030, DEC-031.

### Módulos envolvidos

Todos módulos sintetizáveis e testbenches executados, top integrado, declarações/instâncias/larguras e evidências das TASKs.

### Interface

Sem portas novas. Produto é verification/results/compliance.md com arquivos/hashes auditados, gates, achados por severidade/local/regra e parecer; seções de revisão das TASKs auditadas.

### Clock e reset

Conferir31FF somente no core de captura e sincronização, DFF exclusivamente posedge/incondicional; reset/enable calculados estruturalmente, clock único, ausência de estado novo.

### Restrições

Preservar regras.md e contratos DEC-030/031: DUT estrutural por portas/instâncias explícitas; comportamento apenas DFF dedicado, sem if/else/buf/FSM/loops/generate/parâmetros/operadores aritméticos no DUT. assign somente fiação estática. Testbench separado pode usar aritmética de referência, laços e case, nunca if/else. Não alterar contratos, pinagem ou dependências aprovadas. Registrar versão/backend, fontes explícitos sem .save, comandos, cobertura, logs e hashes reais. Nenhum PASS presumido por planejamento.

### Arquivos protegidos

Todo arquivo fora da lista permitida, especialmente requisitos, decisões e RTL dependente aprovado. Ler/compilar dependências não autoriza sua edição.

### Arquivos permitidos

verification/results/compliance.md; seções de revisão das TASKs auditadas; resultados/auditoria na própria TASK-017.

### Testes exigidos

TEST-013: inspeção léxica e estrutural elaborada, fontes explícitos, comportamento só DFF; zero FSM/if/else/buf/loops/geração/aritmética proibida; assign estático; sem drivers duplicados/latches/loops combinacionais/referências hierárquicas. Conferir s8×u15 rhs≤16384, extensão/sinal/Δ, resíduosS/E eQ/r até arredondamento, top/flags/display e interfaces públicas. Conferir logs, contagens e hashes contra fontes atuais. Excluir .save. Gate estrutural precede funcional; achados retornam ao implementador, no máximo3 ciclos.

### Casos de borda

Bits removidos comprovadamente zero/sinal, -128, Δ extremo, r/E zero, associação x1/x2 para a negativo, carries diferentes de OV e rota loaded/carry sem duplicação.

### Critérios de aceite

Nenhum HIGH/CRITICAL aberto; parecer rastreável por gate e arquivo; auditor distinto do implementador. Não alegar síntese/timing/placa com inspeção estática.

### Dependências

Brief completo. PLANNED até RTL final TASK-012 implementado e evidências disponíveis; auditorias locais já existem. TASK-017 libera conformidade pré-síntese para TASK-015, portanto não depende da futura compilação Quartus, evitando ciclo. Conferência posterior do Quartus pertence015.

### Pendências

Nenhuma decisão arquitetural aberta. Permanecem somente dependências e evidências de execução acima.

### Resultado do Context Analyst — 11/10/2026

BRIEF_COMPLETO; mantém PLANNED até as dependências de execução. Não é bloqueio por decisão arquitetural. Nenhum RTL, simulação, síntese ou auditoria final foi executado nesta preparação.

## Resultado da implementação

Auditoria independente concluída; relatório reproduzível em verification/results/compliance.md. Nenhum RTL alterado.

## Resultado das ferramentas

TEST-013 PASS: parser estático estrito e revisão manual dos12RTL/11TB;37 módulos definidos,1463 instâncias elaboradas,31FF no clock único, zero drivers múltiplos, zero referências não dirigidas e zero ciclos combinacionais. Manifest integrado e hashes/log conferidos; sem repetição de simulação. Código auxiliar, resultados e hashes persistidos no relatório.

## Resultado da revisão

**APPROVED — Code Auditor independente, ciclo1.** Gate1 Compliance PASS; Gate2 evidências funcionais PASS; Gate3 integração PASS. Nenhum finding aberto. Relatório verification/results/compliance.md discrimina método, hashes, contratos, limites e evidências. Libera conformidade pré-síntese, sem alegar resultado Quartus/timing/placa.

## Pendências de execução

Nenhuma pendência de conformidade pré-síntese. TASK-015 deverá conferir elaboração/fitting/timing reais no Quartus; validação física continua posterior.

## Histórico

- 2026-10-11 — READY → REVIEW → APPROVED: auditoria global independente executada, três gates PASS e relatório/hashes registrados; nenhum RTL modificado.

- 2026-10-11 — TASK-012/013 APPROVED e módulos predecessores APPROVED; conjunto HDL final e evidências disponíveis. Orchestrator promove a READY para auditoria estática pré-síntese, sem criar dependência circular com Quartus/TASK-015.
- 2026-10-11 — Context Analyst preparou brief completo; estado PLANNED conforme dependências verificadas. Nenhuma implementação/evidência antecipada.

- 2026-10-06 — TASK candidata criada na Sprint 0 para separar TEST-013 da simulação; status DRAFT.
- 2026-10-11 — Contratos, arquivos e critérios fechados sob delegação em DEC-030/031; planejamento reconciliado, sem declarar implementação ou testes.
