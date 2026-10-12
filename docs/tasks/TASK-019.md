# TASK-019 — Flag C da soma final de y

## Objetivo

Implementar/verificar o escopo especificado abaixo segundo as decisões aprovadas.

## Status

APPROVED

## Requisitos relacionados

REQ-010

## Decisões relacionadas

DEC-028/029/030

## Dependências

Contratos privados carry_y e loaded decididos em DEC-030; integração depende TASK-002/004.

## Restrições aplicáveis

Aplicar `docs/regras.md` e `docs/agente_workflow.md`. Contratos matemáticos preservados; DUT estrutural, comportamento somente nos FF dedicados; nenhum novo estado sem decisão explícita. Delegação de 11/10/2026 substitui gates anteriores de consulta humana. READY exige brief e confirmação de contexto; APPROVED exige evidência real e auditoria independente.

## Arquivos permitidos

rtl/sinalizadores_status.v (módulo flag_c); testbench/tb_status_flags.v

## Arquivos protegidos

Requisitos P0, RTL fora do escopo, pinagem oficial e contratos não revisados pelas decisões citadas.

## Plano e contrato fechado

`flag_c(carry_y,loaded,sel[1:0] → C)`: AND de carry_y, loaded, sel[0] e NOT sel[1]. Carry provém da segunda soma23, subtotal+c, em polynomial_y_core; top conecta fios ordinários do core ao módulo de flag. Wrappers públicos continuam sem porta carry. Nenhum acesso hierárquico, recomputação duplicada ou armazenamento. Carry binário é independente de OV.

## Critérios de aceite e testes

TEST-009: produto cartesiano carry0/1 × loaded0/1 × todas seleções; integração confirma origem na última soma.

## Implementation Brief

### Objetivo

Implementar C com carry binário da última soma23 do caminho y, qualificado por loaded e seleção y.

### Requisitos

REQ-010.

### Decisões aplicáveis

DEC-028, DEC-029, DEC-030.

### Módulos envolvidos

flag_c no arquivo compartilhado sinalizadores_status.v.

### Interface

| Sinal | Direção/largura | Semântica |
|---|---|---|
| carry_y | entrada1 | carry-out privado da soma subtotal+c de polynomial_y_core |
| loaded | entrada1 | coeficientes completamente capturados |
| sel | entrada unsigned2 | 00=x,01=y,10=x1,11=x2 |
| C | saída1 | carry_y E loaded E sel[0] E NÃO sel[1] |

Usar porta normal e fio estrutural do core ao módulo; sem referência hierárquica, recomputação de carry ou registrador. Wrappers públicos permanecem sem porta carry. C não é overflow signed nem OV.

### Clock e reset

Puramente combinacional, sem clock/reset, FF, latch ou armazenamento. Sinais de controle são entradas combinacionais.

### Restrições

DUT somente portas e instâncias explícitas de módulos fixos, fios/constantes/concatenações/seleções estáticas por assign. Sem FSM, always/initial, if/else, buf, for/generate/genvar, parâmetros, operadores aritméticos/condicionais ou begin/end. Testbenches separados podem usar referência aritmética, laços, case e estímulos, nunca if/else. Nenhuma alteração silenciosa de contratos ou pinagem. Comparar com referência independente, tratar X/Z como falha, registrar comandos, fontes explícitos, versões, contagens e hashes reais na própria TASK; logs temporários em /tmp, sem criar artefatos fora da lista autorizada.

### Arquivos protegidos

Todos os arquivos fora da lista permitida; incluindo RTL dependente já aprovado, decisões, requisitos, pinagem e top-level. Reutilização/leitura/compilação de dependências aprovadas não autoriza edição.

### Arquivos permitidos

rtl/sinalizadores_status.v, somente flag_c e helpers privados necessários; testbench/tb_status_flags.v; resultados/auditoria na própria docs/tasks/TASK-019.md.

### Testes exigidos

TEST-009: enumerar integralmente carry0/1 × loaded0/1 × sel00/01/10/11 (16 casos); integrar polynomial_y_core aprovado e flag_c por portas e verificar carry originado da soma com c, usando referência unsigned dos padrões23. Nenhuma alteração em consumidores aprovados. Referência/testbench pode usar aritmética, sem if/else.

### Casos de borda

carry1 com loaded0 ou seleção diferente de01 sempre C0; carry1/loaded1/sel01 C1; carry0 sempre C0. Vetores do core com soma final negativa+positiva e carry0/1 devem preservar y e OV0.

### Critérios de aceite

16 combinações e origem integrada do carry verificadas, interfaces públicas preservadas, zero armazenamento/duplicação; TEST-009 PASS e auditor independente sem HIGH/CRITICAL.

### Dependências

TASK-002 APPROVED e TASK-004 APPROVED, incluindo interfaces privadas loaded/carry_y; estados confirmados em11/10/2026.

### Pendências

Nenhuma escolha arquitetural aberta. Implementação, testes reais e auditoria de código permanecem obrigatórios.

### Resultado do Context Analyst — 11/10/2026

READY_FOR_IMPLEMENTATION. Brief derivado dos contratos em CONSENSUS e requisitos citados; interfaces, larguras, arquivos, testes e dependências conferidos. Nenhum RTL ou teste produzido nesta análise.

Coordenar edição de sinalizadores_status.v/tb_status_flags.v entre TASK-010/018/019: um implementer pode executar os três briefs aprovados em conjunto, mantendo evidência por módulo/TASK. Não sobrescrever módulos das outras tarefas nem realizar edições concorrentes do mesmo arquivo.

## Resultado da implementação

Adicionado flag_c por uma inversão e uma porta AND de quatro entradas; zero FF. Módulos flag_ov_err/flag_z e tops anteriores preservados textualmente. Novo top tb_flag_c conecta polynomial_y_core diretamente por sua porta privada carry_y e verifica origem da última soma.

## Resultado das ferramentas

TEST-009 subset TASK019 PASS:16 combinações isoladas e64 verificações integradas, failures0, código0. Icarus14.0 (devel) s20260301-394-g9edaf7b6a via Docker hdlc/iverilog:latest; -Wall sem warnings. Tag mutável; versão/hashes identificam artefatos executados. Log bruto/tmp/task019.log; nenhuma síntese ou placa.

Isolado cobre integralmente carry0/1 × loaded0/1 × quatro seleções. Integrado cobre oito quádruplas a,b,c,x × loaded0/1 × quatro seleções, verificando y exato,OV0,carry binário final eC. Referência independente usa inteiros para subtotal=ax²+bx e soma unsigned dos padrões23 de subtotal e c. Casos distinguem primeira/última soma: (a,b,c,x)=(0,-1,1,1) gera primeiro carry0/final1; (1,-1,0,1) gera primeiro carry1/final0. Inclui y mínimo/máximo e sinais mistos. Sem acesso hierárquico ou recomputação no DUT.

```sh
tar -cf - rtl/sinalizadores_status.v rtl/polinomio_y.v rtl/multiplicadores.v rtl/somador_subtrator.v rtl/somador_completo.v testbench/tb_status_flags.v | docker run --rm -i hdlc/iverilog:latest sh -c 'mkdir -p /tmp/work; cd /tmp/work; tar -xf -; iverilog -V; iverilog -g2012 -Wall -s tb_flag_c -o /tmp/task019.vvp rtl/sinalizadores_status.v rtl/polinomio_y.v rtl/multiplicadores.v rtl/somador_subtrator.v rtl/somador_completo.v testbench/tb_status_flags.v && vvp /tmp/task019.vvp' > /tmp/task019.log 2>&1
```

```text
TEST-009 TASK019 PASS isolated=16 integrated=64 failures=0
testbench/tb_status_flags.v:205: $finish called at 80000 (1ps)
```

SHA-256 dos artefatos executados:

```text
33a97de7f69a9cf42a6cd0ae5977471cf68376742efe2be5750cd2ab29076339  rtl/sinalizadores_status.v
b3d2788521b3e646eb585813e0a3a50390eaa8b71c7edb07f5b3392369477fb7  rtl/polinomio_y.v
95d8de13e7cab690e72544c5b4c89efe7c956f46eadcc714a112f80123ddc371  rtl/multiplicadores.v
fad812f3d306bc60b327a464946f96a2915c28f0dbb44b01a782d212dc75da3a  rtl/somador_subtrator.v
0e9e393098a238cf0e5992a187834922fea4506eea13d4cdc635debf7376098e  rtl/somador_completo.v
9c64c0d140dcd50f28887b814102076505145a8f4c0c9ebe4cec0b2a3c136839  testbench/tb_status_flags.v
226a25a0e3ffe26be57bf39d3200d682c4792a2b39ffeb0cb0e67a861093674b  /tmp/task019.log
```

## Resultado da revisão

**APPROVED — Code Auditor independente, ciclo 1, 11/10/2026.** Gate 1 PASS: flag_c contém somente NOT/AND, sem estado, comportamento ou alteração pública; módulos010/018 preservados. Gate 2 PASS: equação carry_y AND loaded AND sel0 AND NOT sel1 atende DEC-029/030. Teste isolado cobre16 combinações completas; integração cobre64 verificações por portas normais com referência independente de soma unsigned23, incluindo casos que distinguem o carry da primeira e da última soma, extremos e sinais. Log final PASS16/64 e hashes atuais DUT/TB conferidos. Gate 3 PASS: carry_y vem do polynomial_y_core aprovado, sem referência hierárquica, duplicação aritmética no DUT ou confusão com OV; cores/contratos preservados. Nenhum finding. Simulação não repetida; síntese/placa futuras.

## Pendências de execução

Nenhuma pendência desta implementação: TEST-009 subset019 e auditoria independente aprovados. Integração top-level, síntese e validação física permanecem nas tarefas próprias.

## Histórico

- 2026-10-11 — READY → IMPLEMENTING → IMPLEMENTED → TESTING → TESTED → REVIEW; TEST-009 subset019 PASS16 isolados+64 integrados. Fontes congelados para auditoria;010/018 preservados.

- 2026-10-11 — Context Analyst conferiu contratos/dependências e registrou Implementation Brief completo; PLANNED → READY. Nenhuma implementação/teste antecipado.

- 2026-10-06 — TASK candidata criada na Sprint 0; status BLOCKED por PEN-004.
- 2026-10-09 — DEC-029 resolveu a semântica de C; TASK passou a PLANNED. Implementação aguarda detalhamento/auditoria da rota interna estrutural.
- 2026-10-11 — Contratos, arquivos e critérios fechados sob delegação em DEC-030/031; planejamento reconciliado, sem declarar implementação ou testes.
