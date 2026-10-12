# TASK-008 — Raiz quadrada estrutural inteira com resíduo exato

## Objetivo

Raiz quadrada estrutural inteira com resíduo exato, conforme a arquitetura exata aprovada em DEC-031. O candidato F=16 foi substituído; esta TASK não aguarda nova escolha de precisão.

## Status

APPROVED

## Requisitos relacionados

REQ-005, REQ-006, REQ-008, REQ-011

## Decisões relacionadas

DEC-007, DEC-013 (formatos candidatos supersedidos por DEC-031), DEC-016, DEC-020 (estratégia de evidência atualizada por DEC-031), DEC-024/025/026/027, DEC-030, DEC-031.

## Dependências

DEC-031 em CONSENSUS. Unidade autossuficiente com helpers privados; não depende de aprovação de TASK-003/007 nem da execução da evidência de cadeia TASK-005.

## Restrições aplicáveis

Implementação do DUT exclusivamente estrutural: portas, fios, módulos fixos e instâncias explícitas; sem FSM, FF/registradores, `always`, `if`, `else`, `buf`, `for`, `generate`, `genvar` ou `begin/end`. Operadores aritméticos nas fórmulas são especificação matemática, não autorização de operadores no DUT. Testbenches separados podem usar estímulos/comparações comportamentais, laços e blocos conforme DEC-024, mas `if`/`else` continuam proibidos em todo Verilog. Não alterar interfaces públicas ou pinagem.

## Arquivos permitidos

- `rtl/raiz_quadrada_u17.v`
- `testbench/tb_sqrt_u17.v`
- `docs/tasks/TASK-008.md` (resultados e auditoria).

## Arquivos protegidos

Requisitos P0, decisões, regras, pin assignments, top-level e todos os arquivos fora do escopo permitido. Helpers de DUT são privados/fixos e definidos no respectivo arquivo autorizado. Novas decisões não podem ser introduzidas pela implementação.

## Plano

1. Implementar nove estágios restauradores combinacionais explícitos, lendo pares de `{1'b0, radicand}` do mais significativo para o menos significativo; S₀=R₀=0.
2. Em cada estágio, T=4R+pair e trial=4S+1; comparador/subtrator e mux de portas selecionam R'=T−trial/S'=2S+1 ou R'=T/S'=2S.
3. Usar temporários unsigned11 para T/subtração e trial estendido, raiz parcial unsigned9 e resto unsigned10. Antes do último estágio, S≤255, R≤510, T≤2043 e trial≤1021. Podar constantes somente com justificativa de equivalência.
4. Entregar E diretamente da recorrência, sem multiplicador adicional para reconstruir S². Nenhum operador raiz ou aritmético comportamental no DUT.

## Critérios de aceite

Contrato válido em todos os radicandos, nenhum truncamento indevido, zero estado/FF, conformidade estrutural e revisão independente APPROVED com logs reais.

## Testes

TEST-004: simulação de todos os 131.072 radicandos. Referência independente no testbench por raiz inteira matemática/busca em inteiros, verificando S²≤N<(S+1)² e E=N−S²; expressão aritmética permitida somente na referência do testbench. Compilar top `tb_sqrt_u17` com Icarus e executar vvp; registrar comando, versão, total e falhas na TASK. Compliance Gate por inspeção antes do parecer funcional.

## Implementation Brief

### Objetivo

Implementar o plano acima sem reinterpretar as decisões numéricas.

### Requisitos

REQ-005, REQ-006, REQ-008, REQ-011

### Decisões aplicáveis

DEC-031 controla algoritmo/contratos; DEC-007 controla arredondamento; DEC-016 exige preservar informação; regras.md e DEC-024/025/026/027 controlam sintaxe. DEC-030 controla integração/flags externa.

### Módulos envolvidos

`sqrt_u17` e helpers combinacionais fixos privados, com nomes prefixados `sqrt_`, definidos no mesmo arquivo.

### Interface

Entrada `radicand[16:0]` unsigned. Saídas `root[8:0]` unsigned S e `remainder[9:0]` unsigned E. Para TODO unsigned17: radicand=S²+E, 0≤E<2S+1. S≤362, E≤722. Raiz e resto compõem o contrato, sem descartar o resto.

### Clock e reset

Não há clock/reset neste escopo: rede puramente combinacional, zero flip-flops.

### Restrições

Implementação do DUT exclusivamente estrutural: portas, fios, módulos fixos e instâncias explícitas; sem FSM, FF/registradores, `always`, `if`, `else`, `buf`, `for`, `generate`, `genvar` ou `begin/end`. Operadores aritméticos nas fórmulas são especificação matemática, não autorização de operadores no DUT. Testbenches separados podem usar estímulos/comparações comportamentais, laços e blocos conforme DEC-024, mas `if`/`else` continuam proibidos em todo Verilog. Não alterar interfaces públicas ou pinagem.

### Arquivos permitidos

Somente os enumerados na seção homônima desta TASK.

### Arquivos protegidos

Todos os demais arquivos, incluindo contratos matemáticos, pinagem e módulos consumidores.

### Testes exigidos

Executar integralmente o plano da seção Testes, com resultados reais e reproduzíveis.

### Casos de borda

0, 1, 2, 3, quadrados perfeitos e vizinhos, 81408 (máximo do caminho), 130321, 131043 (resto 722), 131071.

### Critérios de aceite

Contrato válido em todos os radicandos, nenhum truncamento indevido, zero estado/FF, conformidade estrutural e revisão independente APPROVED com logs reais.

### Dependências

DEC-031 em CONSENSUS. Unidade autossuficiente com helpers privados; não depende de aprovação de TASK-003/007 nem da execução da evidência de cadeia TASK-005.

### Pendências

Nenhuma decisão aberta. Implementação e TEST-004 concluídos; auditoria independente pendente.

### Resultado do Context Analyst — 11/10/2026

READY_FOR_IMPLEMENTATION. Contratos, formatos, arquivos, testes e critérios definidos por decisão em CONSENSUS; sem dependência crítica de implementação externa.

## Resultado da implementação

Implementados sqrt_u17, sqrt_stage e sqrt_full_adder privados em rtl/raiz_quadrada_u17.v. Nove estágios espaciais explícitos, cada um com subtração11 por 11 full adders de portas, carry final como comparação unsigned e muxes de portas. Zero FF, sem comportamento/geração/parâmetros no DUT. O resto é produzido diretamente pela recorrência.

Antes de cada estágio, S≤255 e R≤510: os bits S[8] e R[9] não contêm informação nesse ponto; T={R[8:0],pair} e S'={S[7:0],take} preservam magnitude. Se a subtração for aceita, resto≤722; se rejeitada, T<trial≤1021. Ambos cabem10 bits; o bit11 do carry informa ausência de borrow, sem contaminar a magnitude. Contrato total confirmado pela exaustão.

## Resultado das ferramentas

2026-10-11 — TEST-004 PASS, todos os131072 radicandos, zero divergências. Icarus Verilog14.0 (devel), s20260301-394-g9edaf7b6a via Docker hdlc/iverilog:latest; comando retornou0, compilação -Wall sem warnings. A tag é mutável; a versão executada e hashes abaixo identificam esta evidência. Log bruto da sessão em /tmp/task008.log; trecho final preservado abaixo para persistência. Nenhuma síntese, timing ou placa executados.

```sh
tar -cf - rtl/raiz_quadrada_u17.v testbench/tb_sqrt_u17.v | docker run --rm -i hdlc/iverilog:latest sh -c 'mkdir -p /tmp/work; cd /tmp/work; tar -xf -; iverilog -V; iverilog -g2012 -Wall -s tb_sqrt_u17 -o /tmp/task008.vvp rtl/raiz_quadrada_u17.v testbench/tb_sqrt_u17.v && vvp /tmp/task008.vvp' > /tmp/task008.log 2>&1
```

Referência independente no testbench: busca inteira de quadrados consecutivos; compara S/E e verifica S²≤N<(S+1)², N=S²+E e E<2S+1. Inclui todos os casos dirigidos por exaustão; comparações de quatro estados rejeitam X/Z, falha termina com $fatal e contagem131072 é obrigatória.

```text
TEST-004 progress checked=16384
TEST-004 progress checked=32768
TEST-004 progress checked=49152
TEST-004 progress checked=65536
TEST-004 progress checked=81920
TEST-004 progress checked=98304
TEST-004 progress checked=114688
TEST-004 progress checked=131072
TEST-004 PASS radicands=131072 failures=0
testbench/tb_sqrt_u17.v:43: $finish called at 131072000 (1ps)
```



SHA-256 dos arquivos executados:

```text
9c2dd06c7db0ec74226f4911130739cc8862c1efa46ddad6965b507858aeb2c9  rtl/raiz_quadrada_u17.v
17f18c4ac27f96dbddb1cba7a8a40aa7e150d2d84d4d5bd8a40883d9b55a3a98  testbench/tb_sqrt_u17.v
108f642658b9e3e1d6cd24e2a227ed8b764856551e17646e06e622e3bd76bb9b  /tmp/task008.log
```

## Resultado da revisão

**APPROVED — Code Auditor independente, ciclo 1, 11/10/2026.** Gate 1 PASS: leitura integral dos módulos confirma nove estágios explícitos de portas, zero FF/comportamento/laços/parâmetros, helpers privados e contratos preservados. Gate 2 PASS: subtração unsigned11 usa carry11 corretamente como ausência de borrow; mux e atualização de raiz correspondem à recorrência. Limites S≤255/R≤510 antes do estágio e resto selecionado≤1021 justificam slices sem perda; domínio final é conferido por TEST-004 exaustivo PASS131072, referência independente de quadrados consecutivos e identidades com rejeição X/Z. Gate 3 PASS: root9/remainder10 e radicand17 conformes DEC-031; hashes atuais dos dois fontes conferem com registro executado e log final foi inspecionado. Nenhum finding. Não repeti simulação; aprovação de RTL/simulação desta unidade não inclui síntese/timing/placa.

## Pendências

Nenhuma pendência desta implementação: TEST-004 e auditoria independente aprovados. Integração das raízes e síntese/placa seguem nas tarefas correspondentes.

## Histórico

- 2026-10-11 — READY → IMPLEMENTING → IMPLEMENTED → TESTING → TESTED → REVIEW; TEST-004 PASS131072 radicandos, zero falhas, evidências/hashes registrados. Aguarda Code Auditor.

- 2026-10-06 — TASK candidata criada na Sprint 0; status BLOCKED.
- 2026-10-11 — DEC-031 em CONSENSUS substitui F16 por arquitetura exata com resíduos; contratos e Implementation Brief atualizados. Estado READY, sem execução de código/testes.
