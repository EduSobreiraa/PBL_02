# TASK-027 | Implementar o datapath combinacional de F1

## Objetivo

Criar módulos combinacionais estruturais independentes do top para avaliar `f₁(x)=a₁x²+b₁x+c₁` e `f₁′(x)=2a₁x+b₁`, validar o vértice racional e detectar hits depois do clipping, sem truncar resultados.

## Status

APPROVED | Code Auditor ciclo 2 passou Compliance, Functional e Integration. VPI PASS: 3421 casos.

## Requisitos relacionados

- PBL03 PDF §3-5 e §4.7, §4.9-13.
- `REGRAS.md` §§2, 5 e 7.

## Decisões relacionadas

- DEC-043 | etapas pequenas com F1 antes de F2.
- DEC-044 | cálculo direto, precisão inteira exata, validação racional do vértice, clipping e larguras.
- DEC-045 | wrapper estrutural e verificação externa via Icarus/VPI.
- DEC-047 | datapath standalone nesta TASK; FSM e integração do top na TASK-028.

## Dependências

- TASK-025 | árvore RTL e interfaces do top-level PBL03.
- TASK-026 | banco de coeficientes signed8 e interface de entrada.
- Portas e larguras do datapath foram fixadas no Implementation Brief abaixo.
- A TASK não inclui FSM, retenção de erro, reset ou habilitação da curva por estado.
- A FSM F1, integração ao top e inclusão das fontes no QSF pertencem à TASK-028.

## Restrições aplicáveis

- x cartesiano signed10 cobre −320…319; o x pixel só é convertido no caminho de coordenadas.
- Usar x² unsigned17, resultado de f(x) signed25 e resultado de f′(x) signed18 conforme DEC-044.
- O coeficiente −128 deve ser incluído na prova de cada intermediário.
- Validar o vértice racional sem arredondar, com limites inclusivos xᵥ∈[−320,319] e yᵥ∈[−239,240]. Tratar a₁=0 antes de qualquer divisão.
- Aplicar clipping antes de transformar y em coordenada de pixel.
- O datapath é combinacional e estrutural; não implementa controle sequencial.
- Não utilizar `assign`, `generate`, `for` ou `buf` nos módulos aritméticos.
- Não implementar comparador das bordas x do vértice. Para `a₁≠0`, `|xᵥ|=|b₁/(2a₁)|≤64`, portanto xᵥ está sempre dentro da tela.
- Não alterar o PBL02 nem o periférico VGA.

## Arquivos permitidos

- Módulos PBL03 em `rtl/aritmetica/` e `rtl/funcao/`.
- `sim/tb_f1_function.v` (wrapper estrutural).
- `sim/f1_function_vpi.c`.
- `sim/run_f1_function_icarus.sh`.
- `docs/tasks/TASK-027.md`

## Arquivos protegidos

- Todos os RTL e projetos Quartus do PBL02 na raiz.
- `rtl/top/top_pbl03.v` e `quartus/pbl03.qsf`; a integração desses módulos fica na TASK-028.
- `vendor/vga/vga_sync.v`, `REGRAS.md`, `TEC498_2026_2_Problema3.pdf`, DEC-043, DEC-044 e DEC-045.
- Arquivos não listados como permitidos.

## Implementation Brief

### Objetivo

Implementar um datapath combinacional independente do top que calcule `f₁(x)`, `f₁′(x)`, valide o vértice racional e produza hits somente para coordenadas cartesianas visíveis. A FSM da TASK-028 combinará validade e hits com o estado de exibição.

### Requisitos

- PDF PBL03 §4, itens 7, 9-13; §5, itens 3-4 e 8.
- `REGRAS.md` §§2, 5, 7 e 10.

### Decisões aplicáveis

- DEC-043 | implementar e validar F1 antes de F2.
- DEC-044 | avaliação direta exata, larguras de saída, vértice racional e clipping.
- DEC-045 | wrapper estrutural e driver externo Icarus/VPI.
- DEC-047 | datapath standalone nesta TASK; FSM e integração ficam na TASK-028.

### Módulos envolvidos

- `rtl/funcao/datapath_f1.v` | unidade pública que conecta cálculo, validação e detecção de hits.
- `rtl/funcao/avaliador_quadratico_f1.v` | calcula `a₁x²+b₁x+c₁`.
- `rtl/funcao/avaliador_derivada_f1.v` | calcula `2a₁x+b₁`.
- `rtl/funcao/validador_vertice_f1.v` | sinaliza `a₁=0`, valida `yᵥ` por comparação racional exata e combina os erros em `function_valid`.
- `rtl/funcao/detector_hits_f1.v` | compara os resultados completos com y, após verificar que y está em `[-239,240]`.
- Criar módulos aritméticos estruturais auxiliares em `rtl/aritmetica/`, um por arquivo. As portas e larguras externas abaixo são fixas; a decomposição interna não deve criar largura menor que os limites indicados.

### Interface

`datapath_f1` é combinacional e tem esta interface pública:

| Sinal | Direção | Largura e tipo | Semântica |
|---|---|---|---|
| `a1`, `b1`, `c1` | entrada | signed8 | Coeficientes de F1 em complemento de 2, incluindo −128. |
| `x_cartesiano` | entrada | signed10 | Coluna cartesiana corrente, domínio suportado −320…319. |
| `y_cartesiano` | entrada | signed10 | Linha cartesiana corrente. Somente −239…240 pode produzir hit. |
| `f1_y` | saída | signed25 | Valor inteiro completo `a₁x²+b₁x+c₁`. |
| `f1_derivada` | saída | signed18 | Valor inteiro completo `2a₁x+b₁`. |
| `a1_zero` | saída | 1 bit | Alto quando `a₁=0`. |
| `vertice_y_fora` | saída | 1 bit | Alto quando `a₁≠0` e y do vértice está fora de −239…240. Baixo quando `a₁=0`; `a1_zero` identifica esse erro. |
| `function_valid` | saída | 1 bit | Alto quando `a₁≠0` e y do vértice está dentro dos limites inclusivos. Não é retido. |
| `f1_hit` | saída | 1 bit | Alto quando `f1_y` é exatamente igual ao y de entrada e y está dentro da tela. Não é habilitado por `function_valid` ou estado da FSM. |
| `f1_derivada_hit` | saída | 1 bit | Alto quando `f1_derivada` é exatamente igual ao y de entrada e y está dentro da tela. Não é habilitado por `function_valid` ou estado da FSM. |

As portas internas dos módulos auxiliares podem ser privadas ao datapath, mas devem usar sinais explicitamente dimensionados e extensões explícitas. Não expor coordenadas de pixel nesta TASK.

### Larguras e cálculo racional

- `x²` é unsigned17, máximo `102400` no domínio VGA.
- `a₁x²` é signed25. `b₁x` é signed18. Estender esses termos e `c₁` com sinal para signed25 antes das somas.
- `2a₁` é signed9; o produto `2a₁x` e a soma final da derivada são signed18 dentro do domínio `x=−320…319`.
- `4a₁c₁−b₁²` é signed18. O denominador bruto `4a₁` é signed10 e sua magnitude é unsigned10, até `512`.
- Validar `yᵥ=(4a₁c₁−b₁²)/(4a₁)` sem divisão ou arredondamento. Normalize o sinal do denominador antes de comparar os limites. Os produtos-limite `239|4a₁|` e `240|4a₁|` cabem em signed18, até magnitude `122880`.
- Não implementar comparador para os limites x do vértice. Para `a₁≠0`, `|xᵥ|=|b₁/(2a₁)|≤64`, dentro de `[-320,319]`.
- Trate `a₁=0` antes de avaliar a validade do vértice. Não usar o denominador zero para classificar o vértice.
- Para hits, comparar `f1_y` e `f1_derivada` completos com y estendido com sinal. Não reduzir os resultados para 10 bits. Rejeitar y fora de `[-239,240]` antes de indicar hit.

### Clock e reset

Não há clock ou reset nesta unidade combinacional. A retenção dos erros, o START, DONE, reset e habilitação por estado pertencem à FSM da TASK-028.

### Restrições

- Todo cálculo aritmético deve ser estrutural e manter as extensões de sinal explícitas.
- Não usar `assign`, `generate`, `for`, `buf`, `always` ou `initial` nos módulos sintetizáveis desta TASK.
- Manter um módulo por arquivo `.v`.
- O wrapper `sim/tb_f1_function.v` deve ser estrutural. Estímulo e comparação ficam em C/VPI, conforme DEC-045.
- Não alterar nem incluir no escopo de edição os fontes PBL02, o top PBL03, o QSF ou `vendor/vga/vga_sync.v`.

### Arquivos permitidos

- Novos módulos em `rtl/aritmetica/` e `rtl/funcao/`.
- `sim/tb_f1_function.v`.
- `sim/f1_function_vpi.c`.
- `sim/run_f1_function_icarus.sh`.
- `docs/tasks/TASK-027.md`.

### Arquivos protegidos

- `rtl/` do PBL02, incluindo `multiplicadores.v`, `somador_subtrator.v`, `polinomio_y.v` e `somador_completo.v`.
- `rtl/top/top_pbl03.v` e `quartus/pbl03.qsf`.
- `vendor/vga/vga_sync.v`, `REGRAS.md`, `TEC498_2026_2_Problema3.pdf` e DEC-043 até DEC-045.

### Auditoria dos módulos existentes

- `somador_completo.v` contém uma célula estrutural compatível e um módulo, mas está em fonte PBL02 protegido; esta TASK não depende dela nem altera o arquivo.
- `somador_subtrator.v` contém três módulos no mesmo arquivo, somadores de 23 bits e subtrator de 18 bits. Não atende diretamente a saída signed25 e não cumpre isoladamente a regra de um módulo por arquivo.
- `multiplicadores.v` contém módulos signed8×signed8 e signed8×unsigned15 no mesmo arquivo. As larguras não cobrem x signed10 nem x² unsigned17; não reutilizar diretamente.
- `polinomio_y.v` contém dois módulos, usa x signed8 e saída signed23. É insuficiente para o domínio e largura PBL03.
- Criar ou portar somente as células necessárias para os novos módulos PBL03 e manter todos os arquivos acima intactos.

### Testes exigidos

- O VPI deve comparar os resultados com uma referência independente em casos direcionados e nos extremos do domínio. A referência deve usar aritmética signed64 inteira/racional do driver, não as mesmas redes RTL.
- Testar `f₁(x)` e `f₁′(x)` com coeficientes positivos, negativos, zero, −128 e 127; x=−320, −1, 0, 1 e 319.
- Testar `a₁=0`, validade do vértice e `function_valid`.
- Testar limites de y do vértice: `(-1,22,119)` produz 240 e `(1,22,-118)` produz −239, ambos válidos; `(-1,22,120)` produz 241 e `(1,22,-119)` produz −240, ambos inválidos.
- Verificar que y VGA fora de −239…240 nunca produz `f1_hit` nem `f1_derivada_hit`, mesmo quando um resultado matemático coincide com esse y.
- Testar hits exatos nos limites de y visíveis, hits negativos e positivos, além de valores próximos que não coincidem. Varrer todas as 480 linhas y para conferir igualdade e clipping em casos dirigidos.
- Compilar somente módulos PBL03 autorizados, wrapper estrutural e driver VPI pelo runner Icarus. Registrar os casos e resultado real na TASK.
- Fazer inspeção estrutural e `git diff --check`. Não alegar timing; a medição pertence à tarefa de síntese posterior.

### Critérios de aceite

- Resultados f e f′ corretos e completos para todos os casos de teste e coeficientes extremos.
- `a1_zero`, `vertice_y_fora` e `function_valid` seguem as semânticas da tabela.
- A validação racional aceita as duas bordas inclusivas e rejeita os dois casos imediatamente externos.
- Nenhum hit ocorre para y fora da tela; igualdade é avaliada sem truncamento.
- O VPI passa com referência independente e o código sintetizável cumpre as restrições estruturais.
- Nenhum arquivo PBL02, top, QSF ou periférico VGA é alterado.

### Dependências

- TASK-025 fornece coordenadas cartesianas signed10 e a estrutura de arquivos PBL03.
- TASK-026 fornece coeficientes signed8 retidos; este datapath recebe os valores por portas e não instancia a entrada.
- TASK-028 fará integração ao top, FSM, retenção dos erros e habilitação por estado.

### Pendências

Nenhuma pendência técnica bloqueia a implementação combinacional descrita neste brief. A arquitetura interna das células estruturais pode ser escolhida pelo Implementer dentro das larguras e restrições fixadas aqui. FSM, top, QSF e temporização permanecem fora do escopo.

## Plano

1. Auditar os somadores e multiplicadores candidatos do PBL02 antes de reutilizá-los.
2. Definir módulos separados para quadrática, derivada, vértice e clipping, mantendo cada declaração em arquivo próprio.
3. Provar larguras dos produtos e somas com coeficientes −128…127 e x −320…319.
4. Comparar resultados completos com y VGA e rejeitar valores fora de −239…240 antes de formar qualquer coordenada/pixel.
5. Expor validade e erro combinacionais separados dos hits; a TASK-028 fará a habilitação por estado.

## Critérios de aceite

- `f₁(x)` e `f₁′(x)` correspondem aos resultados matemáticos exatos em todo o domínio.
- Uma saída combinacional indica `a₁=0`; outra indica vértice racional fora da área visível. A retenção desses erros fica na TASK-028.
- Um resultado y fora de −239…240 não gera ponto nem coordenada VGA inválida.
- Nenhuma operação aritmética usa largura insuficiente ou truncamento implícito.
- O datapath recebe coeficientes F1 e coordenadas x/y signed10 por portas explícitas; não modifica o top-level.
- Os módulos respeitam a sintaxe PBL03 e não alteram os arquivos PBL02.

## Testes

- Testar `f₁(x)` e `f₁′(x)` com sinais, extremos −128/127 e x=−320/319.
- Testar vértice y nas bordas: `(-1,22,119)` produz 240 e `(1,22,-118)` produz -239. Casos externos: `(-1,22,120)` produz 241 e `(1,22,-119)` produz -240. Para xᵥ, provar `|xᵥ|≤64`; as bordas VGA são inalcançáveis.
- Cobrir `a₁=0`, clipping e detecção de hit para cada linha y.
- Comparação com referência independente para f(x), f′(x) e vértice racional.
- Wrapper Verilog estrutural e driver VPI/runner externo, conforme DEC-045.
- Inspeção estrutural e `git diff --check`.
- A temporização do caminho deve ser medida em TASK própria de síntese; não aprovar timing por inferência.

## Resultado da implementação

APPROVED | datapath F1 combinacional standalone aprovado conforme DEC-047. Não inclui FSM nem integração ao top.

### Arquivos criados

- `rtl/aritmetica/`: célula full-adder, somadores/subtratores estruturais, negadores condicionais, multiplicadores unsigned e comparadores signed.
- `rtl/funcao/`: avaliadores da quadrática e derivada, validador racional do vértice, detector de hits e `datapath_f1`.
- `sim/tb_f1_function.v`, `sim/f1_function_vpi.c` e `sim/run_f1_function_icarus.sh`.

### Verificações e resultados

- `IVERILOG_ROOT=/tmp/task027-iverilog/usr sim/run_f1_function_icarus.sh` — `VPI PASS: 3421 datapath cases passed` após o rework.
- A referência independente em C usa inteiros de 64 bits e compara f, f′, a=0, limites racionais do vértice, hits e clipping.
- Casos cobrem os 640 valores de x em três conjuntos de coeficientes, as 480 linhas visíveis em três funções e os quatro vértices y em 240, -239, 241 e -240.
- Icarus Verilog 13.0 foi extraído em `/tmp` dos RPMs Fedora 44 x86_64 `iverilog-13.0-7.fc44` e `iverilog-devel-13.0-7.fc44`. `rpm -K` reportou `digests signatures OK` para ambos; não houve instalação no sistema.
- Inspeção estrutural dos 22 arquivos Verilog: um módulo por arquivo; nenhum `assign`, `generate`, `for`, `buf`, `always`, `initial` ou operador aritmético no RTL PBL03 criado.
- `git diff --check` e inspeção de espaços finais/linhas finais — sem problemas.
- O driver VPI verifica `bval` em todos os bits de cada saída multibit e em cada saída de um bit, e falha explicitamente se encontrar X/Z.
- Casos dirigidos confirmam hits f=240 e f=-239, clipping de f=-240 fora da tela, hits da derivada em 240 e -239, e ausência de hit para coincidência em y=241.

### Limites desta implementação

- Os hits são combinacionais e não são mascarados por `function_valid`; a FSM posterior deve aplicar validade e habilitação de exibição conforme DEC-047.
- Nenhuma conexão com top, QSF ou VGA foi feita, conforme a fronteira da TASK.
- Síntese, temporização e teste físico não foram executados nesta TASK.

## Resultado das ferramentas

Icarus Verilog 13.0: compilação estrutural e simulação VPI passaram no comando registrado acima. Nenhuma ferramenta Quartus foi executada.

## Resultado da revisão

APPROVED | Code Auditor ciclo 2 aprovou os três gates, sem findings abertos.

- Compliance: 22 arquivos Verilog revisados, um módulo por arquivo, sem construções ou operadores proibidos.
- Functional: runner repetido com 3421 casos; o VPI rejeita X/Z e cobre hits nas bordas e igualdade fora da tela.
- Integration: interface e arquivos conferem com o brief; top, QSF e VGA permanecem intactos.

## Pendências

- Nenhuma pendência técnica aberta para o escopo combinacional definido. A FSM e o timing do caminho VGA ficam em TASKs posteriores.

## Histórico

- 15/11/2026 | TASK criada como PLANNED para iniciar pelo caminho de F1, antes de replicar o processador para F2.
- 16/11/2026 | Context Analyst marcou BLOCKED por mistura de datapath, FSM, reset e arquivos de teste não autorizados. DEC-047 fechou o escopo standalone combinacional; top, FSM e QSF seguem na TASK-028.
- 16/11/2026 | Context Analyst adicionou Implementation Brief e marcou READY após DEC-047.
- 16/11/2026 | Code Implementer concluiu datapath e runner; Icarus/VPI passou 3416 casos. Aguardando auditoria independente antes de APPROVED.
- 16/11/2026 | Code Auditor ciclo 1 repetiu 3416 casos e aprovou Compliance/Integration. Functional Gate REWORK por dois gaps MEDIUM em unknowns do VPI e hits nos limites de y.
- 16/11/2026 | Code Implementer corrigiu ambos os findings; o VPI passou 3421 casos e a TASK voltou a IMPLEMENTED, aguardando auditoria ciclo 2.
- 16/11/2026 | Code Auditor ciclo 2 repetiu 3421 casos e aprovou Compliance, Functional e Integration, sem findings abertos.
