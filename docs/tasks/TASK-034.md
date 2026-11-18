# TASK-034 | Verificar fontes e sintaxe do PBL03

## Objetivo

Adicionar uma verificação repetível da lista de fontes do PBL03, das restrições sintáticas e da integridade do módulo VGA fornecido.

## Status

APPROVED

## Dependências

- TASK-025-032 | estrutura RTL e fontes de vídeo definidos.
- TASK-032 | saídas de status definidas para compilar e verificar a lista completa de fontes.
- Sintaxe e exceções vigentes em `REGRAS.md`.

## Planejamento e aceite

- Verificar que cada arquivo RTL ativo declara somente o módulo esperado.
- Aplicar as regras sintáticas por categoria de módulo, incluindo as exceções aprovadas.
- Confirmar que o QSF não compila arquivos legados do PBL02.
- Comparar o hash do `vendor/vga/vga_sync.v` com o artefato professoral registrado.
- Fazer a verificação falhar com arquivo ou regra identificável quando houver violação.

## Arquivos

Ver Implementation Brief para a lista permitida.

## Implementation Brief

### Objetivo

Criar um verificador Python repetível que compara a lista explícita de fontes PBL03 com `quartus/pbl03.qsf`, valida a regra sintática aplicável a cada categoria e confere a integridade do periférico VGA.

### Requisitos

- `REGRAS.md` §2: categorias e restrições de sintaxe do PBL03.
- `REGRAS.md` §6: manter `vga_sync.v` intacto.
- PDF PBL03 §4.14: integrar o periférico sem alterar sua função básica.
- Critérios desta TASK: fontes explícitas, um módulo por arquivo, nenhuma fonte legada no QSF e falhas identificáveis.

### Decisões aplicáveis

- DEC-043: usar `REGRAS.md` do PBL03 como regra vigente; não transportar restrições do PBL02 sem aprovação.
- DEC-044 e DEC-051: `vga_sync.v` é externo e protegido; a retirada do painel não cria fonte RTL para o VGA.

### Módulos envolvidos

- Fontes RTL ativas listadas no `quartus/pbl03.qsf` e no manifesto PBL03.
- Categorias do manifesto: `structural`, `ff`, `fsm` e `vendor`.
- O verificador trata `vendor` somente pela integridade registrada, sem aplicar regras internas de sintaxe.

### Interface

- Invocação sem argumentos: `python3 verification/check_pbl03_sources.py`.
- Saída: mensagem `PASS` ou uma lista de erros com arquivo e regra identificáveis; código de saída zero no sucesso e diferente de zero na falha.
- Manifesto JSON: lista de objetos com `path`, `module` e `category`. Os caminhos são relativos à raiz do repositório.

### Clock e reset

Não aplicável. O verificador é executado no host.

### Restrições

- Usar somente a biblioteca padrão do Python.
- Não alterar RTL, QSF, SDC ou `vendor/vga/vga_sync.v`.
- Não aplicar regras sintáticas de RTL às fontes `vendor`.
- Para fontes da equipe, aceitar lógica comportamental somente nas categorias `ff` e `fsm`; aplicar as proibições de `REGRAS.md` às demais categorias.
- Validar tokens fora de comentários e strings para evitar falhas causadas por texto explicativo.
- Rejeitar atribuições de fonte além de `VERILOG_FILE` e comandos de inclusão Tcl/QIP que não estejam cobertos pelo manifesto.
- Aceitar índices literais de vetor no alvo `-to` de atribuições QSF permitidas, como `set_location_assignment PIN_C10 -to SW[0]` e `set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SW[0]`.
- Continuar rejeitando substituições Tcl executáveis como `[source ../quartus/legacy.qsf]` e comandos Tcl compostos como `if {1} { source ../quartus/legacy.qsf }`.
- Não declarar que o verificador substitui parser Verilog, compilação, síntese ou auditoria funcional.

### Arquivos permitidos

- `verification/check_pbl03_sources.py`
- `verification/pbl03_sources.json`
- `verification/test_check_pbl03_sources.py`
- `docs/tasks/TASK-034.md`

### Arquivos protegidos

- `quartus/pbl03.qsf` e `quartus/pbl03.sdc`.
- Todos os arquivos em `rtl/`.
- `vendor/vga/vga_sync.v` e `vendor/vga/UPSTREAM.md`.
- Fontes e resultados existentes de simulação, síntese e verificação.

### Testes exigidos

- Executar a suíte unitária do verificador com `python3 -m unittest verification.test_check_pbl03_sources`.
- Executar `python3 verification/check_pbl03_sources.py` na árvore real.
- Cobrir sucesso e falha por: divergência entre manifesto e QSF, fonte ausente ou legada, quantidade/nome de módulos, token proibido por categoria e hash divergente.
- Cobrir atribuições adicionais como `SYSTEMVERILOG_FILE`, `VHDL_FILE`, `QIP_FILE`, arquivos de inclusão e comandos `source`.
- Cobrir alvos vetoriais em `set_location_assignment` e `set_instance_assignment`, rejeitar colchetes em `SEARCH_PATH` e manter a rejeição de `[source ...]` sem permitir comandos Tcl compostos.

### Casos de borda

- Fonte repetida no QSF ou no manifesto.
- Caminho relativo que escape da raiz do repositório.
- Arquivo Verilog com zero módulos ou mais de um módulo.
- Nome do módulo diferente do manifesto.
- Token proibido presente apenas em comentário ou string, que não deve gerar falso positivo.
- `vga_sync.v` alterado, removido ou com hash diferente do `UPSTREAM.md`.
- Índice de pino vetorial `SW[0]` em um alvo `-to` permitido, que deve ser aceito sem aceitar substituição Tcl ou colchetes em outros campos.

### Critérios de aceite

- O manifesto e o conjunto de fontes Verilog no QSF são iguais, sem duplicatas.
- Cada fonte RTL ativa existe e declara exatamente o módulo registrado.
- A classificação aplica as regras de sintaxe da categoria correta.
- Nenhuma fonte do PBL02 ou arquivo legado aparece no QSF.
- O hash de `vga_sync.v` coincide com o registrado em `vendor/vga/UPSTREAM.md`.
- Toda falha informa arquivo e regra, e retorna código diferente de zero.
- Índices decimais como `SW[0]` passam somente no alvo `-to` de comandos QSF permitidos; `[source ...]`, Tcl composto e colchetes em outros campos falham.
- Os testes e a execução sobre o projeto atual passam.

### Dependências

- TASK-025 a TASK-032: estrutura RTL PBL03 definida.
- `quartus/pbl03.qsf`, `REGRAS.md` e `vendor/vga/UPSTREAM.md`.

### Pendências

Nenhuma pendência impede a implementação. A correção do FIND-034-004 foi registrada; a decisão final do Auditor está pendente.

## Resultado

Arquivos adicionados:

- `verification/check_pbl03_sources.py`
- `verification/pbl03_sources.json`
- `verification/test_check_pbl03_sources.py`

Verificações executadas:

- `python3 -m unittest verification.test_check_pbl03_sources` — 20 testes passaram após a correção do FIND-034-004.
- `python3 verification/check_pbl03_sources.py` — `PBL03 source check: PASS`.

O manifesto contém 41 fontes ativas do QSF: 34 estruturais, 3 módulos de flip-flop, 3 FSMs e o periférico externo. A checagem de sintaxe é lexical e não substitui parser Verilog, compilação, síntese ou auditoria funcional.

## Resultado da revisão

**FIND-034-001 (MEDIUM), corrigido.** O verificador rejeita atribuições de fonte diretas diferentes de `VERILOG_FILE`, como `SYSTEMVERILOG_FILE`, `VHDL_FILE`, `QIP_FILE` e `IP_FILE`.

**FIND-034-002 (MEDIUM), corrigido.** O verificador aceita os comandos QSF de atribuição usados pelo projeto e rejeita outros comandos Tcl. Assim, `if {1} { source ../quartus/legacy.qsf }` falha com linha e comando identificados, sem interpretar blocos Tcl arbitrários. Strings comuns e linhas de comentário não acionam esse erro.

**FIND-034-003 (MEDIUM), corrigido.** O verificador rejeita colchetes em qualquer linha ativa do QSF, inclusive dentro de aspas duplas, porque Tcl avalia substituições `[...]` nesses argumentos. Linhas de comentário completas são ignoradas. Testes cobrem ambas as formas reportadas e uma linha comentada.

**FIND-034-004 (MEDIUM), corrigido.** O verificador aceita índices decimais de bits somente no alvo `-to` de atribuições QSF permitidas. Os testes cobrem `set_location_assignment PIN_C10 -to SW[0]` e `set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SW[0]`; `SEARCH_PATH SW[0]`, `[source ...]` e Tcl composto continuam bloqueados.

**Resultado final: APPROVED.** A revisão confirmou os casos de pinos, rejeição das formas de substituição/inclusão Tcl, comentário completo ignorado e execução sem regressões. TASK-035 pode acrescentar pin assignments nos formatos permitidos. A allowlist permanece limitada aos três arquivos novos de verificação e a esta TASK.
