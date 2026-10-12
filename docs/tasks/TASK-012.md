# TASK-012 — Integração do top-level

## Objetivo

Implementar/verificar o escopo especificado abaixo segundo as decisões aprovadas.

## Status

APPROVED

## Requisitos relacionados

REQ-001–011/013/014

## Decisões relacionadas

DEC-003/008–019/030/031

## Dependências

TASK-002/003/004/006/007/008/009/010/011/018/019 aprovadas antes da aprovação de integração.

## Restrições aplicáveis

Aplicar `docs/regras.md` e `docs/agente_workflow.md`. Contratos matemáticos preservados; DUT estrutural, comportamento somente nos FF dedicados; nenhum novo estado sem decisão explícita. Delegação de 11/10/2026 substitui gates anteriores de consulta humana. READY exige brief e confirmação de contexto; APPROVED exige evidência real e auditoria independente.

## Arquivos permitidos

rtl/modulo_principal.v; testbench/tb_top_module.v

## Arquivos protegidos

Requisitos P0, RTL fora do escopo, pinagem oficial e contratos não revisados pelas decisões citadas.

## Plano e contrato fechado

`top_module(MAX10_CLK1_50,KEY[1:0],SW[9:0] → LEDR[9:0],HEX0..HEX5[6:0])`.
Instanciar coefficient_input_core e polynomial_y_core uma única vez, quadratic_roots, result_select, decimal_display e flag_ov_err/flag_z/flag_c. Wrappers de compatibilidade não são duplicados no top. SW[7:0] alimenta x e captura; SW[9:8] seleciona. LEDR0=OV,1=Z,2=C,3=ERR e LEDR9:4=0. Mascarar apresentação conforme TASK-006. Sem DP, clock derivado ou registradores de saída; 31 FF totais previstos, comprovar na síntese.

## Critérios de aceite e testes

TEST-010/011: reset, carga a→b→c, quatro seleções, resultados e flags, capturas excedentes, reset durante carga; raízes válidas/inválidas e ambos sinais.

## Implementation Brief

### Objetivo

Compor o sistema completo por conexões estruturais, sem duplicar wrappers/cores ou adicionar estado.

### Requisitos

REQ-001–011, REQ-013, REQ-014.

### Decisões aplicáveis

DEC-003, DEC-008–019, DEC-030, DEC-031.

### Módulos envolvidos

top_module; instâncias únicas coefficient_input_core, polynomial_y_core, quadratic_roots, result_select, decimal_display, flag_ov_err, flag_z e flag_c.

### Interface

Entradas: MAX10_CLK1_50(1), KEY[1:0](unsigned2,ativo baixo), SW[9:0](unsigned10). Saídas: LEDR[9:0](unsigned10), HEX0..HEX5(cada unsigned7,segmentos ativos baixos [0..6]=a..g). Sem DP ou pino adicional.

SW[7:0] alimenta entrada sw da captura e x signed8 do polinômio/seletor; SW[9:8] fornece sel00=x,01=y,10=x1,11=x2. Coeficientes signed8 alimentam y e raízes; y signed23 e raízes signed9 chegam ao seletor, cujo value signed23 alimenta display/Z. Conectar loaded/carry_y por portas privadas normais aos módulos de flags, sem acesso hierárquico. flag_ov_err recebe loaded,a,delta signed18; LEDR0=OV,1=Z,2=C,3=ERR,9:4=0. OV do polinômio é constante0 conforme contrato; usar origem de LEDR0 da flag_ov_err definida em DEC-030, sem múltiplo driver. Apresentação invalid=(sel≠00 E NÃO loaded) OU (sel[1] E ERR), por portas. domain_error de quadratic_roots pode ficar em fio privado sem consumidor: ERR é qualificado por loaded em flag_ov_err.

### Clock e reset

Clock único50MHz, borda positiva; KEY1 ativo baixo segue sincronizadores/reset do core aprovado; KEY0 captura única. Nenhum clock derivado ou registrador novo. Exatamente31FF previstos pela composição; confirmar posteriormente em síntese.

### Restrições

Preservar regras.md e contratos DEC-030/031: DUT estrutural por portas/instâncias explícitas; comportamento apenas DFF dedicado, sem if/else/buf/FSM/loops/generate/parâmetros/operadores aritméticos no DUT. assign somente fiação estática. Testbench separado pode usar aritmética de referência, laços e case, nunca if/else. Não alterar contratos, pinagem ou dependências aprovadas. Registrar versão/backend, fontes explícitos sem .save, comandos, cobertura, logs e hashes reais. Nenhum PASS presumido por planejamento.

### Arquivos protegidos

Todo arquivo fora da lista permitida, especialmente requisitos, decisões e RTL dependente aprovado. Ler/compilar dependências não autoriza sua edição.

### Arquivos permitidos

rtl/modulo_principal.v; testbench/tb_top_module.v; resultados/auditoria na própria TASK-012. Logs temporários em /tmp.

### Testes exigidos

TEST-010/011: simular reset, três capturas a→b→c, carga parcial com resultados mascarados, seleção x antes da carga, quatro seleções após loaded, mudança contínua de x, bloqueio de captura excedente e reset durante/depois da carga. Verificar todos HEX e LEDs contra valores/segmentos de referência independentes, nunca pelo próprio módulo do DUT. Cobrir raízes válidas positivas/negativas, a0,delta negativo, extremos de y/traços, carry final com/sem carry e Z sob raiz inválida. Reutilizar política de empate longe de zero; casos dirigidos podem ter resultados matemáticos calculados explicitamente. Testar KEY mantido pressionado sem recaptura e prioridade reset. Compilar top tb_top_module no Icarus com lista explícita dos fontes aprovados.

### Casos de borda

Reset após energização; três cargas; quarta carga ignorada; a0; delta<0/0; raízes positivas/negativas e empate; extremosa,b,c,x e limites visuais; Z não é mascarado por loaded.

### Critérios de aceite

Conexões/larguras/fontes preservadas, zero FF adicional, nenhum wrapper/core duplicado; TEST-010/011 com evidência real, outputs corretos, auditor independente sem HIGH/CRITICAL.

### Dependências

TASK-002/003/004/006/007/008/009/010/011/018/019 APPROVED conferidas em11/10/2026. READY_FOR_IMPLEMENTATION; integração não depende da execução física da placa.

### Pendências

Nenhuma decisão arquitetural aberta. Permanecem somente dependências e evidências de execução acima.

### Resultado do Context Analyst — 11/10/2026

READY_FOR_IMPLEMENTATION. Nenhum RTL, simulação, síntese ou auditoria final foi executado nesta preparação.

## Resultado da implementação

Implementado top_module com instâncias únicas dos cores privados coefficient_input_core/polynomial_y_core e módulos aprovados roots/seletor/display/flags. loaded e carry_y conectados por portas normais, sem referência hierárquica; LEDR0..3=OV/Z/C/ERR e9:4 constantes0. Máscara de apresentação por portas conforme contrato. Zero FF novo, sem clock derivado;31FF previstos pela hierarquia aprovada, contagem física/síntese ainda não comprovada nesta TASK.

## Resultado das ferramentas

TEST-010/011 PASS:10cenários completos mais resets parcial/final;660 comparações simultâneas de todos LEDs e seis HEX. Docker Icarus14.0, compilação -Wall sem warnings, processo retornou0. Lista explícita de12 fontes RTL mais testbench, sem .save. Evidência/comando/hashes abaixo. Nenhuma síntese/timing/placa executada nesta TASK.

## Resultado da revisão

**APPROVED — Code Auditor independente, ciclo 1, 11/10/2026.** Gate 1 PASS: top usa somente instâncias aprovadas, portas/assign estático, cores únicos sem duplicar wrappers, nenhum FF/clock derivado/construção proibida. Gate 2 PASS: máscara incompleto/raiz inválida, seleção e flags conferidas; teste independente pelas portas físicas modela carga, y/carry, raízes por fronteiras exatas e decimal por divisão/resto. Log final TEST-010/011 PASS10 cenários/660 comparações com rejeição X/Z, incluindo reset parcial/completo, pressão mantida, captura excedente, quatro seleções e ambos erros. Gate 3 PASS: portas físicas e LEDR0..3/9:4 corretos, loaded/carry por portas privadas normais, sem referência hierárquica; 13 hashes atuais coincidem com fontes executados. Hierarquia mantém31 FF por construção, sem alegar contagem física sintetizada. Nenhum finding. Sem repetição desnecessária de simulação; síntese/timing/placa continuam pendentes.

## Clarificação posterior — DEC-039 / TASK-022

DEC-039 revisou a semântica de LEDR0/OV: preserva `y` signed23, mas acende quando `y` está selecionado/carregado e não cabe na faixa decimal dos seis displays; HEX mostra `------`. TASK-022 implementou essa conexão por `overflow_exibicao`. A aprovação anterior de TASK-012 documenta a integração antes dessa mudança e não constitui auditoria da nova lógica; consultar o resultado/auditoria de TASK-022.

## Pendências de execução

Nenhuma pendência desta implementação: dependências, TEST-010/011 e auditoria independente aprovados. Obrigações de síntese/timing/placa permanecem em suas TASKs, sem alegação de conclusão por esta simulação.

## Histórico

- 2026-10-11 — Context Analyst preparou brief completo; estado READY conforme dependências verificadas. Nenhuma implementação/evidência antecipada.

- 2026-10-06 — TASK candidata criada na Sprint 0; status DRAFT.
- 2026-10-11 — Contratos, arquivos e critérios fechados sob delegação em DEC-030/031; planejamento reconciliado, sem declarar implementação ou testes.

## Reprodução e evidências do Code Implementer — 11/10/2026

```sh
tar -cf - rtl/entrada_coeficientes.v rtl/somador_completo.v rtl/somador_subtrator.v rtl/multiplicadores.v rtl/polinomio_y.v rtl/raiz_quadrada_u17.v rtl/divisor_9_por_8.v rtl/raizes_quadraticas.v rtl/seletor_resultado.v rtl/exibicao_decimal.v rtl/sinalizadores_status.v rtl/modulo_principal.v testbench/tb_top_module.v | docker run --rm -i hdlc/iverilog:latest sh -c 'mkdir -p /tmp/work; cd /tmp/work; tar -xf -; iverilog -V; iverilog -g2012 -Wall -s tb_top_module -o /tmp/task012.vvp rtl/entrada_coeficientes.v rtl/somador_completo.v rtl/somador_subtrator.v rtl/multiplicadores.v rtl/polinomio_y.v rtl/raiz_quadrada_u17.v rtl/divisor_9_por_8.v rtl/raizes_quadraticas.v rtl/seletor_resultado.v rtl/exibicao_decimal.v rtl/sinalizadores_status.v rtl/modulo_principal.v testbench/tb_top_module.v && vvp /tmp/task012.vvp' > /tmp/task-012.log 2>&1
```

Backend Docker hdlc/iverilog:latest, tag mutável; versão executada registrada abaixo. Primeira tentativa negada no socket Docker; reexecução escalada via tar/stdin. Log bruto temporário em /tmp/task-012.log, trecho funcional preservado nesta TASK. Nenhum módulo dependente foi alterado.

```text
Icarus Verilog version 14.0 (devel) (s20260301-394-g9edaf7b6a)
TEST-010/011 PASS scenarios=10 output_checks=660 reset_partial_full=PASS held_key=PASS extra_capture=PASS flags_displays=PASS
testbench/tb_top_module.v:191: $finish called at 33202000 (1ps)
process exit code: 0
```

Compilação -Wall sem warnings. Cada observação compara os10LEDs e42segmentos, rejeitando X/Z; não lê sinais internos do DUT. Modelo independente acompanha coeficientes/carga a partir dos estímulos esperados, calcula y/carry com inteiros, raízes por comparação exata com fronteiras meio-inteiro e displays por divisão/resto10. Nenhum módulo DUT serve de oracle. Dez conjuntos incluem raízes positivas/negativas, empates positivos/negativos, a negativo sem troca de ramos, a0,delta negativo/zero, extremos de y, sinal e traços. Cada conjunto verifica carga parcial, x visível antes de loaded, quatro seleções, alterações de SW com KEY0 ainda pressionado, quarta captura ignorada, valores x -128/-1/0/1/99/127/-3 e reset com as duas teclas ativas para prioridade. Sequência adicional reinicia carga parcial e completa nova carga após reset. Z anterior a loaded segue valor, sem máscara extra; C somente y/loaded; ERR permanece sob alterações de SW/seleção e limpa com reset. Nenhuma conclusão sobre bounce físico ou timing pós-fitter é derivada deste teste funcional.

### SHA-256 dos fontes executados

```text
b83d645e41ca77f69daecbeb4ddb27e4560cc6a6e9137d26b7f7b077b6f0801c  rtl/entrada_coeficientes.v
0e9e393098a238cf0e5992a187834922fea4506eea13d4cdc635debf7376098e  rtl/somador_completo.v
fad812f3d306bc60b327a464946f96a2915c28f0dbb44b01a782d212dc75da3a  rtl/somador_subtrator.v
95d8de13e7cab690e72544c5b4c89efe7c956f46eadcc714a112f80123ddc371  rtl/multiplicadores.v
b3d2788521b3e646eb585813e0a3a50390eaa8b71c7edb07f5b3392369477fb7  rtl/polinomio_y.v
9c2dd06c7db0ec74226f4911130739cc8862c1efa46ddad6965b507858aeb2c9  rtl/raiz_quadrada_u17.v
3c78a3f6df23183f9e395cde079e9e2e074fad85cd5ae5e1643d10a2690783cb  rtl/divisor_9_por_8.v
4a3ea3a69479a724da17adf1f26c99397d6f7ff8d5e3d9844bba25993392c03e  rtl/raizes_quadraticas.v
1c0966845e4d864e72ea9f1aa0ac4ff627eb61ab614a2573457e48a1ab593f23  rtl/seletor_resultado.v
34a3a9a4be300d8f0f4ffc8074dc7c0c11b0909ca67a8e9469ff39a2ff891d8b  rtl/exibicao_decimal.v
33a97de7f69a9cf42a6cd0ae5977471cf68376742efe2be5750cd2ab29076339  rtl/sinalizadores_status.v
3a0b6453f43c831966d2ed18359bb1d1c76f854c6d9280ee2e7ea4d38803c40c  rtl/modulo_principal.v
7c3a5db50256cf0ef2179b472477173d80ff44f5704c0e3e3363d7992a59865b  testbench/tb_top_module.v
```

- 2026-10-11 — READY → IMPLEMENTING → IMPLEMENTED → TESTING → TESTED → REVIEW; TEST-010/011 PASS660 observações, saída0, sem warnings; evidências entregues ao Code Auditor.
