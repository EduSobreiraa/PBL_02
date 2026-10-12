# TASK-006 — Seletor e apresentação decimal

## Objetivo

Implementar/verificar o escopo especificado abaixo segundo as decisões aprovadas.

## Status

APPROVED

## Requisitos relacionados

REQ-004/009/011

## Decisões relacionadas

DEC-011/017/019/030

## Dependências

Contratos de saída decididos; implementação independente com entradas controladas. Integração requer TASK-004/011 aprovadas.

## Restrições aplicáveis

Aplicar `docs/regras.md` e `docs/agente_workflow.md`. Contratos matemáticos preservados; DUT estrutural, comportamento somente nos FF dedicados; nenhum novo estado sem decisão explícita. Delegação de 11/10/2026 substitui gates anteriores de consulta humana. READY exige brief e confirmação de contexto; APPROVED exige evidência real e auditoria independente.

## Arquivos permitidos

rtl/seletor_resultado.v; rtl/exibicao_decimal.v; testbench/tb_result_select.v; testbench/tb_decimal_display.v

## Arquivos protegidos

Requisitos P0, RTL fora do escopo, pinagem oficial e contratos não revisados pelas decisões citadas.

## Plano e contrato fechado

`result_select(x signed8,y signed23,x1,x2 signed9,sel[1:0] → value signed23)` estende sinal e seleciona por portas na ordem x/y/x1/x2.
`decimal_display(value signed23,invalid → HEX0..HEX5[6:0])`: magnitude unsigned23, double-dabble combinacional de 23 estágios explícitos para sete dígitos BCD. Faixa visual: 0..999999 e -99999..-1; zero em unidades, zeros iniciais apagados, sinal negativo em HEX5. Fora da faixa ou invalid, seis traços; BCD10..15 apaga. Índices a..g, ativos baixos. Algoritmo e mintermos descritos em DEC-030 §4.
Na integração, invalid=(seleção diferente de x e não loaded) OU (raiz selecionada e ERR).

## Critérios de aceite e testes

TEST-008: quatro seleções; 0, ±1, 99999,100000,999999,1000000,-99999,-100000; polaridade, branco, traço, inválido e limites. Referência decimal independente.

## Implementation Brief

### Objetivo

Implementar mux estrutural de visualização e apresentação decimal signed em seis displays, conforme DEC-030 §4.

### Requisitos

REQ-004, REQ-009, REQ-011.

### Decisões aplicáveis

DEC-011, DEC-017, DEC-019, DEC-030; larguras das raízes conforme DEC-031.

### Módulos envolvidos

result_select e decimal_display; helpers combinacionais fixos privados nos respectivos arquivos.

### Interface

| Módulo | Entrada | Saída | Semântica |
|---|---|---|---|
| result_select | x signed8; y signed23; x1/x2 signed9; sel unsigned2 | value signed23 | sel00=x,01=y,10=x1,11=x2; extensões de sinal explícitas |
| decimal_display | value signed23; invalid1 | HEX0,HEX1,HEX2,HEX3,HEX4,HEX5, cada unsigned7 | HEX0 unidades, HEX5 posição mais significativa; [0..6]=a..g ativos baixos |

Magnitude unsigned23 preservada, inclusive -4194304; complemento de dois estrutural condicionado ao sinal. Double-dabble de23 estágios espaciais explícitos gera sete dígitos BCD28 antes de verificar faixa. Células add3 e decodificação BCD por portas/mintermos conforme DEC-030, sem divisão comportamental. Valores0..999999 e -99999..-1 são exibidos; fora dessas faixas ou invalid1 mostrar seis traços. Zero mantém apenas unidade0; zeros iniciais apagados; negativo fixa sinal em HEX5, deixando posições vazias até a magnitude. Códigos BCD10..15 apagam; traço acende só g. Nenhum novo arredondamento. A integração futura fornece invalid=(sel≠00 E não loaded) OU (sel[1] E ERR); esse cálculo externo não altera portas destes módulos.

### Clock e reset

Puramente combinacional, sem clock/reset, FF, latch ou armazenamento. Sinais de controle são entradas combinacionais.

### Restrições

DUT somente portas e instâncias explícitas de módulos fixos, fios/constantes/concatenações/seleções estáticas por assign. Sem FSM, always/initial, if/else, buf, for/generate/genvar, parâmetros, operadores aritméticos/condicionais ou begin/end. Testbenches separados podem usar referência aritmética, laços, case e estímulos, nunca if/else. Nenhuma alteração silenciosa de contratos ou pinagem. Comparar com referência independente, tratar X/Z como falha, registrar comandos, fontes explícitos, versões, contagens e hashes reais na própria TASK; logs temporários em /tmp, sem criar artefatos fora da lista autorizada.

### Arquivos protegidos

Todos os arquivos fora da lista permitida; incluindo RTL dependente já aprovado, decisões, requisitos, pinagem e top-level. Reutilização/leitura/compilação de dependências aprovadas não autoriza edição.

### Arquivos permitidos

rtl/seletor_resultado.v; rtl/exibicao_decimal.v; testbench/tb_result_select.v; testbench/tb_decimal_display.v; resultados/auditoria na própria docs/tasks/TASK-006.md.

### Testes exigidos

TEST-008: verificar seleção e extensão signed nas quatro opções com sinais/extremos de cada entrada; comparar display com referência decimal independente de divisão/resto no testbench. Cobrir todos dígitos, branco/traço e polaridade, invalid0/1, limites e supressão de zeros. Testar mintermos BCD0..15 dos helpers, incluindo códigos inválidos10..15, se houver módulo helper de decodificação. Compilar tops tb_result_select e tb_decimal_display explicitamente no Icarus e executar vvp, com fontes limitados aos módulos envolvidos.

### Casos de borda

0, ±1, 99999,100000,999999,1000000,-99999,-100000; signed23 mínimo -4194304 e máximo4194303; entradas x -128/127 e raízes signed9 -256/255 para extensão do contrato local. inválido força seis traços em qualquer sinal/faixa.

### Critérios de aceite

Mapeamento e extensão exatos; apresentação decimal completa dentro da faixa, traços fora/inválido, sinal/zeros/polaridade corretos. Zero FF e sintaxe permitida. TEST-008 PASS e auditor independente sem HIGH/CRITICAL antes de APPROVED.

### Dependências

TASK-004 APPROVED e TASK-011 APPROVED confirmadas em11/10/2026; contratos disponíveis. Teste dos módulos usa entradas controladas; integração posterior é TASK-012.

### Pendências

Nenhuma escolha arquitetural aberta. Implementação, testes reais e auditoria de código permanecem obrigatórios.

### Resultado do Context Analyst — 11/10/2026

READY_FOR_IMPLEMENTATION. Brief derivado dos contratos em CONSENSUS e requisitos citados; interfaces, larguras, arquivos, testes e dependências conferidos. Nenhum RTL ou teste produzido nesta análise.

## Resultado da implementação

Implementados seletor mux4 com extensões signed explícitas e decimal_display combinacional. Magnitude signed23 por negação condicionada estrutural;23 estágios double-dabble espaciais com7 células add3 por estágio, sete dígitos BCD preservados antes da detecção de faixa. Add3 e segmentos por mintermos/portas; zeros iniciais, sinal em HEX5 e traços por lógica combinacional. Zero FF, sem dependências RTL externas ou modificações fora do escopo.

## Resultado das ferramentas

TEST-008 PASS: seletor6048 casos; display10032 casos e16 códigos BCD/add3. Docker Icarus14.0, compilação -Wall sem warnings, processo retornou0. Evidência e reprodução abaixo; nenhuma síntese/timing/placa executada.

## Resultado da revisão

**APPROVED — Code Auditor independente, ciclo 1, 11/10/2026.** Gate 1 PASS: módulos usam portas e conexões estáticas, 23 estágios explícitos double-dabble, sem FF/comportamento/construções proibidas. Gate 2 PASS: extensões signed do seletor, magnitude do extremo -4194304, mintermos add3/segmentos e preservação BCD7 conferidos; detecção de faixa ocorre após conversão completa, negativos mostram sinal em HEX5, invalid/excesso produz seis traços e zero preserva unidade. Referência independente por divisão/resto decimal e tabela de segmentos; logs TEST-008 SELECT6048/DISPLAY10032 e16 códigos completos PASS, rejeitando X/Z. Gate 3 PASS: portas, ordem x/y/x1/x2, polaridade ativa baixa e faixas correspondem DEC-030; quatro hashes atuais conferem com execução. Nenhum finding. Não repeti simulação; integração da máscara invalid, síntese/timing e placa continuam nas tarefas posteriores.

## Pendências de execução

Nenhuma pendência desta implementação: dependências, TEST-008 e auditoria independente aprovados. Integração top-level e obrigações externas de placa/modelo/timing permanecem nas tarefas próprias.

## Histórico

- 2026-10-11 — Context Analyst conferiu contratos/dependências e registrou Implementation Brief completo; PLANNED → READY. Nenhuma implementação/teste antecipado.

- 2026-10-06 — TASK candidata criada na Sprint 0; status PLANNED.
- 2026-10-11 — Contratos, arquivos e critérios fechados sob delegação em DEC-030/031; planejamento reconciliado, sem declarar implementação ou testes.

## Reprodução e evidências — Code Implementer, 11/10/2026

```sh
tar -cf - rtl/seletor_resultado.v rtl/exibicao_decimal.v testbench/tb_result_select.v testbench/tb_decimal_display.v | docker run --rm -i hdlc/iverilog:latest sh -c 'mkdir -p /tmp/work; cd /tmp/work; tar -xf -; iverilog -V; iverilog -g2012 -Wall -s tb_result_select -o /tmp/select.vvp rtl/seletor_resultado.v testbench/tb_result_select.v && vvp /tmp/select.vvp && iverilog -g2012 -Wall -s tb_decimal_display -o /tmp/display.vvp rtl/exibicao_decimal.v testbench/tb_decimal_display.v && vvp /tmp/display.vvp' > /tmp/task-006.log 2>&1
```

Backend Docker hdlc/iverilog:latest, Icarus14.0 devel s20260301-394-g9edaf7b6a. Tag mutável; comparar versão registrada. Primeira tentativa sem escalonamento negada no socket Docker; reexecução escalada via tar/stdin. Log temporário em /tmp/task-006.log; resultado final real persistido abaixo.

### Cobertura e independência

Seletor:6048 casos; todas quatro seleções, varredura completa de entradas x signed8 e x1/x2 signed9, y mínimo/máximo, mais1000 quádruplas pseudoaleatórias. Display:10032 casos (invalid0/1,16 casos dirigidos por polaridade incluindo fronteiras e extremos,0..999 e negativos, amostras aleatórias signed23 e amostras nas duas faixas visuais). Semente inicial20261011 por $random(seed) em cada testbench. Referência decimal divide magnitude por10 e usa resto10; compara seis segmentos, magnitude23 e BCD de sete dígitos; independe da rede double-dabble. Teste adicional exaustivo dos16 códigos do decoder e add3, incluindo códigos BCD inválidos que apagam segmentos. X/Z, divergência e contagem incompleta causam fatal. Não se afirma exaustão de todo signed23 ou validação física de displays.

### SHA-256 dos fontes executados

```text
1c0966845e4d864e72ea9f1aa0ac4ff627eb61ab614a2573457e48a1ab593f23  rtl/seletor_resultado.v
34a3a9a4be300d8f0f4ffc8074dc7c0c11b0909ca67a8e9469ff39a2ff891d8b  rtl/exibicao_decimal.v
153e73394d7d591114966f061f04b13ffe54da4f5f40e9e84f3544403ec68e06  testbench/tb_result_select.v
83b0790681d588bf57978b3fcfbdbe8d9894e64c78c162c27d7574b5587038c0  testbench/tb_decimal_display.v
```

### Log funcional e conclusão real

```text
Icarus Verilog version 14.0 (devel) (s20260301-394-g9edaf7b6a)
TEST-008 SELECT PASS cases=6048 seed=20261011
testbench/tb_result_select.v:45: $finish called at 6048000 (1ps)
TEST-008 DISPLAY PASS cases=10032 BCD_add3=16 seed=20261011 segments_magnitude_BCD=PASS
testbench/tb_decimal_display.v:106: $finish called at 10048000 (1ps)
process exit code: 0
```

Compilação -Wall sem warnings. Fontes permaneceram congelados durante a execução. O bit mais significativo descartado em cada deslocamento BCD é zero no domínio reachable, pois prefixos da magnitude23 nunca excedem4194304 e sete dígitos comportam o domínio integral. Faixa visual verificada depois da conversão completa; nenhuma alteração de OV aritmético.

- 2026-10-11 — READY → IMPLEMENTING → IMPLEMENTED → TESTING → TESTED → REVIEW; TEST-008 completo PASS, saída0, sem warnings; auditoria independente solicitada.
