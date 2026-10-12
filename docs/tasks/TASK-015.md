# TASK-015 — Síntese e compilação Quartus

## Objetivo

Implementar/verificar o escopo especificado abaixo segundo as decisões aprovadas.

## Status

APPROVED

## Requisitos relacionados

REQ-013/014

## Decisões relacionadas

DEC-018/021/030

## Dependências

TASK-012 e conformidade TASK-017 aprovadas; Quartus disponível.

## Restrições aplicáveis

Aplicar `docs/regras.md` e `docs/agente_workflow.md`. Contratos matemáticos preservados; DUT estrutural, comportamento somente nos FF dedicados; nenhum novo estado sem decisão explícita. Delegação de 11/10/2026 substitui gates anteriores de consulta humana. READY exige brief e confirmação de contexto; APPROVED exige evidência real e auditoria independente.

## Arquivos permitidos

quartus/pbl02.qpf; quartus/pbl02.qsf; quartus/pbl02.sdc; verification/results/quartus/

## Arquivos protegidos

Requisitos P0, RTL fora do escopo, pinagem oficial e contratos não revisados pelas decisões citadas.

## Plano e contrato fechado

Dispositivo 10M50DAF484C7G, top_module; assignments e I/O exclusivamente de docs/hardware.md, confronto independente de cada pino. Quartus DEC-021, versão real nos logs. Clock 50MHz/20ns para caminhos registrados; exceção KEY somente até primeira etapa sincronizadora. Nenhum false_path geral. Dados SW são entrada manual assíncrona com estabilidade exigida; relatar limitações. Caminhos de saída combinacionais têm orçamento de acomodação de 1ms e atraso reportado separadamente, conforme DEC-030 §5. Não inventar fechamento de timing nem pipeline.

## Critérios de aceite e testes

TEST-014: compilação/fitting sem erros, warnings relevantes tratados, pinos corretos, FF/LEs/latches/timing reportados e auditados.

## Implementation Brief

### Objetivo

Criar projeto Quartus da baseline aprovada, compilar e registrar pinagem/recursos/timing reais.

### Requisitos

REQ-013, REQ-014.

### Decisões aplicáveis

DEC-018, DEC-021, DEC-030.

### Módulos envolvidos

quartus/pbl02.qpf, pbl02.qsf, pbl02.sdc; top_module existente e fontes aprovados por referência.

### Interface

Dispositivo10M50DAF484C7G; top_module portas conforme TASK-012. Copiar cada assignment e I/O da baseline docs/hardware.md (SW0..9,KEY0/1,LEDR0..9,HEX0..5 segmentos0..6,MAX10_CLK1_50 P11), sem DP ou remapeamento. KEY usa3.3V Schmitt Trigger; demais pinos conforme tabelas oficiais. Conferência independente pino a pino antes de aprovar.

### Clock e reset

SDC cria clock20ns. Exceção KEY somente até primeira etapa sincronizadora, nunca entre etapas; nenhuma false_path global. SW manual assíncrono requer estabilidade durante captura: documentar ausência de garantia durante comutação em vez de inventar delays síncronos externos. Caminhos combinacionais paraLED/HEX devem ter atraso reportado separadamente contra orçamento1ms DEC-030; não exigir20ns onde não há registrador de saída. Não adicionar pipeline ou mascarar falhas de timing.

### Restrições

Preservar regras.md e contratos DEC-030/031: DUT estrutural por portas/instâncias explícitas; comportamento apenas DFF dedicado, sem if/else/buf/FSM/loops/generate/parâmetros/operadores aritméticos no DUT. assign somente fiação estática. Testbench separado pode usar aritmética de referência, laços e case, nunca if/else. Não alterar contratos, pinagem ou dependências aprovadas. Registrar versão/backend, fontes explícitos sem .save, comandos, cobertura, logs e hashes reais. Nenhum PASS presumido por planejamento.

### Arquivos protegidos

Todo arquivo fora da lista permitida, especialmente requisitos, decisões e RTL dependente aprovado. Ler/compilar dependências não autoriza sua edição.

### Arquivos permitidos

quartus/pbl02.qpf; quartus/pbl02.qsf; quartus/pbl02.sdc; verification/results/quartus/ para artefatos/logs de execução; resultados/auditoria na própria TASK-015. Redirecionar arquivos gerados para esse diretório ou diretório temporário, sem escrever fontes fora de escopo.

### Testes exigidos

TEST-014: verificar versão real quartus_sh e dispositivo, executar compilação/fitting/STA, registrar comando/fontes/hashes/logs completos; relatar erros/warnings, recursosLEs/FF, ausência de latches, clock/constraints e pior atraso de caminhos sequenciais e combinacionais. Comparar cada porta/pino/I/O com docs/hardware.md independentemente. Testar versão no caminho DEC-021 /home/edupires/altera_lite/25.1std/quartus/bin/quartus_sh; evidência histórica25.1std.0 Build1129 não substitui execução atual. Não instalar ou presumir backend ausente.

### Casos de borda

Reset/sincronizadores não devem ter caminhos internos ocultos; nenhum pino duplicado/semassignment; FF31 esperado, qualquer divergência justificada; display maior caminho pode não cumprir orçamento e precisa evidência real.

### Critérios de aceite

Compilação/fitting sem erros, pinagem correta, warnings relevantes tratados, zero latches inesperados, recursos e timing auditados; não declarar fechamento de timing sem relatório. Falta de ferramenta é dependência de execução, não decisão técnica aberta.

### Dependências

Brief completo. PLANNED até TASK-012 e TASK-017 APPROVED e Quartus acessível confirmado. Nenhuma compilação/fitting executada nesta análise; disponibilidade histórica DEC-021 não equivale a confirmação atual.

### Pendências

Nenhuma decisão arquitetural aberta. Permanecem somente dependências e evidências de execução acima.

### Resultado do Context Analyst — 11/10/2026

BRIEF_COMPLETO; mantém PLANNED até as dependências de execução. Não é bloqueio por decisão arquitetural. Nenhum RTL, simulação, síntese ou auditoria final foi executado nesta preparação.

## Resultado da implementação

Criados QPF/QSF/SDC autorizados e runner/relatórios em `verification/results/quartus/`. Pinagem de65portas transcrita da baseline e conferida pós-fit; fontes explícitos sem .save. SDC20ns, duas exceções KEY→primeiroFF, orçamento output1ms separado. Nenhuma alteraçãoRTL.

## Resultado das ferramentas

TEST-014 executado no Quartus25.1std.0 Build1129 SC Lite: compilação/fitting/STA exit0,2187LE/31FF/0latches/65pinos,0memória/0DSP/0PLL. Pior setupregistrado15.669ns e hold0.153ns; maior atrasooutput160.472ns; orçamento1ms atendido nas três condições.0errors/11warnings/0critical, todos descritos em verification/results/quartus/README.md. Manifest/logs/relatórios completos/fontes-snapshot/hashes preservados. Primeira tentativa com serializaçãoQSF inválida segregada e rejeitada; segunda é a válida. LimitaçõesSWassíncrono/holdexterno/drive8mA/AN447/MTBF/placa registradas; não afirmar fechamento total de interfaces assíncronas.

## Resultado da revisão

### Code Auditor — rodada 1 — 11/10/2026

**APPROVED.** Nenhum finding aberto.

- **Gate 1 — Compliance: PASS.** QPF/QSF/SDC respeitam o dispositivo, top e escopo autorizados. Conferência independente extraindo a baseline de `docs/hardware.md`, sem usar `pins-audit.json` como oracle: 65/65 sinais, pinos e I/O coincidem entre baseline, QSF e `.pin` pós-fit; 65 pinos únicos. Doze fontes RTL explícitos, sem `.save`; hashes dos 15 fontes atuais e snapshots conferidos com o manifest. RTL previamente aprovado na TASK-017 preservado.
- **Gate 2 — Functional: PASS.** TEST-014 real: compilação/fitting/STA exit 0, Quartus 25.1std.0 Build1129, 2187 LEs, 31 FF, zero latches/memória/DSP/PLL. Oito hashes de evidências do manifest conferidos. Relatórios dos três corners confirmam mínimo slack de setup registrado +15.669 ns, hold +0.153 ns e máximo atraso até saídas 160.472 ns, dentro do orçamento de 1 ms. Os 11 warnings foram cotejados no log e estão tratados no README; nenhuma tentativa inválida foi usada para aprovação.
- **Gate 3 — Integration: PASS.** Clock de 20 ns, duas exceções KEY somente aos primeiros estágios; consultas STA retornam um registro por destino. Ambos os caminhos primeiro→segundo estágio aparecem no relatório de hold, sem ocultação por exceção global. Constraints efetivamente carregadas conferem com o SDC. Saídas sem registradores mantêm orçamento separado. UCP explicita SW assíncrono e hold externo não especificado; não se declara fechamento temporal dessas interfaces. Drive padrão de 8 mA, aviso AN447 e ausência de MTBF/validação física permanecem limites documentados.

Auditoria feita por leitura dos fontes, relatórios reais e comparação independente de pinagem/hashes; nenhuma compilação repetida, nenhum RTL ou arquivo Quartus alterado.

## Pendências de execução

Implementação, compilação/STA e auditoria independente concluídas. Obrigações elétricas/placa permanecem externas, com warnings/limitações descritos no relatório. Não há mudança arquitetural pendente introduzida por esta execução.

## Histórico

- 2026-10-11 — TASK-012 e TASK-017 APPROVED; Quartus Prime 25.1std.0 Build1129 confirmado disponível no ambiente. Orchestrator promove a READY para execução real do TEST-014.
- 2026-10-11 — Context Analyst preparou brief completo; estado PLANNED conforme dependências verificadas. Nenhuma implementação/evidência antecipada.

- 2026-10-06 — TASK candidata criada na Sprint 0; status DRAFT.
- 2026-10-11 — Contratos, arquivos e critérios fechados sob delegação em DEC-030/031; planejamento reconciliado, sem declarar implementação ou testes.

- 2026-10-11 — READY → IMPLEMENTING → IMPLEMENTED → TESTING → TESTED → REVIEW; compilação/fitting/STA reais, pinagem65/65,31FF/0latches e timing modelado documentados, sem execução em placa.

- 2026-10-11 — Code Auditor: REVIEW → APPROVED, três gates PASS; pinagem e hashes conferidos independentemente. Validação física permanece externa.
