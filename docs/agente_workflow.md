# Agent Workflow — PBL02

Este arquivo contém o workflow operacional do projeto. Instruções específicas de resolução de decisões técnicas também estão em `AGENTS.md` e `agents/`.

## 1. Objetivo

Este documento define o fluxo de atuação dos agentes utilizados no desenvolvimento do PBL02.

O objetivo do workflow é garantir que:

- requisitos do projeto sejam respeitados;
- decisões arquiteturais não sejam alteradas sem autorização;
- código Verilog permaneça compatível com as restrições do enunciado e de `regras.md`;
- implementação e verificação sejam separadas;
- cada etapa produza evidências rastreáveis;
- o estado do projeto permaneça persistido no repositório;
- o processo possa ser auditado posteriormente.

Este fluxo não substitui a revisão humana.

A aprovação final de decisões arquiteturais, exceções e mudanças de escopo permanece sob responsabilidade do desenvolvedor.

---

# 2. Fontes de verdade

Os agentes devem consultar a documentação existente no projeto conforme sua responsabilidade.

A hierarquia factual definida para o projeto é:

1. enunciado oficial do PBL;
2. documentação oficial da DE10-Lite;
3. documentação oficial do Quartus;
4. demais fontes técnicas oficiais;
5. decisões explicitamente aprovadas pelo desenvolvedor;
6. documentação interna presente em `docs/`;
7. planejamento produzido pelos agentes;
8. conhecimento ou inferência do modelo.

`regras.md` possui autoridade comportamental e normativa sobre a atuação dos agentes.

Nenhum agente pode sobrescrever uma restrição explícita presente no enunciado ou em `regras.md`.

---

# 3. Restrições globais confirmadas

As seguintes restrições devem ser consideradas invariantes do projeto enquanto não forem explicitamente revisadas:

- operações aritméticas exigidas pelo PBL devem utilizar implementação estrutural;
- FSM é proibida;
- `buf` é proibido;
- construções comportamentais explicitamente proibidas em `regras.md` não podem ser utilizadas;
- laços e blocos explicitamente proibidos em `regras.md` não podem ser utilizados;
- interfaces aprovadas não podem ser modificadas silenciosamente;
- pin assignments não podem ser alterados sem autorização;
- hipóteses não podem ser transformadas em fatos;
- pendências de hardware não podem ser resolvidas por inferência.

A polaridade elétrica dos botões está confirmada pelo manual da DE10-Lite: KEY é ativo baixo. Sincronização e evento único de captura estão registrados em DEC-019; a validação física permanece futura.

---

# 4. Estrutura do workflow

O fluxo inicial possui três papéis principais:

```text
             Documentação canônica
                     |
                     v
                +---------+
                | Planner |
                +----+----+
                     |
                     v
               TASK planejada
                     |
                     v
             +---------------+
             |  Implementer  |
             +-------+-------+
                     |
                     v
             RTL + testbench
                     |
                     v
          Ferramentas de verificação
                     |
                     v
               +----------+
               | Reviewer |
               +----+-----+
                    |
                    v
               PASS / FAIL
                    |
                    v
              Revisão humana
```

Cada agente possui escopo, entradas e permissões diferentes.

Um agente não deve assumir responsabilidades pertencentes a outro papel sem instrução explícita.

---

# 5. Unidade de trabalho

Toda implementação relevante deve ser representada por uma tarefa persistida no repositório.

Formato:

```text
docs/tasks/TASK-XXX.md
```

Exemplo:

```text
docs/tasks/TASK-001.md
```

Cada tarefa representa uma unidade pequena e verificável de trabalho.

Uma TASK deve possuir escopo suficientemente restrito para permitir:

- planejamento objetivo;
- implementação isolada;
- teste;
- revisão;
- eventual rollback.

Evitar tarefas genéricas como:

> implementar o projeto inteiro

Preferir:

> implementar o somador estrutural utilizado pelo módulo X

---

# 6. Ciclo de vida de uma TASK

Estados permitidos:

```text
DRAFT
PLANNED
READY
IMPLEMENTING
IMPLEMENTED
TESTING
TESTED
REVIEW
APPROVED
REJECTED
BLOCKED
```

Fluxo esperado:

```text
DRAFT
  |
  v
PLANNED
  |
  v
READY
  |
  v
IMPLEMENTING
  |
  v
IMPLEMENTED
  |
  v
TESTING
  |
  v
TESTED
  |
  v
REVIEW
  |
  +------> APPROVED
  |
  +------> REJECTED
```

`BLOCKED` pode ocorrer em qualquer momento quando uma informação necessária estiver ausente.

Uma tarefa rejeitada deve voltar para implementação somente depois que o motivo da rejeição estiver documentado.

---

# 7. Estrutura de uma TASK

Cada arquivo `TASK-XXX.md` deve seguir, no mínimo, a seguinte estrutura:

```markdown
# TASK-XXX — Nome

## Objetivo

Descrição objetiva da tarefa.

## Status

DRAFT

## Requisitos relacionados

- REQ-XXX
- REQ-YYY

## Decisões relacionadas

- DEC-XXX

## Dependências

- módulos;
- interfaces;
- outras TASKs.

## Restrições aplicáveis

- implementação estrutural;
- FSM proibida;
- construções proibidas relevantes;
- restrições específicas desta tarefa.

## Arquivos permitidos

Arquivos que podem ser criados ou modificados.

## Arquivos protegidos

Arquivos que não devem ser modificados.

## Plano

Preenchido pelo Planner.

## Critérios de aceite

Condições objetivas necessárias para aprovação.

## Testes

Testes necessários ou relacionados.

## Resultado da implementação

Preenchido pelo Implementer.

## Resultado das ferramentas

Compilação, simulação, lint ou outras evidências.

## Resultado da revisão

Preenchido pelo Reviewer.

## Pendências

Questões ainda não resolvidas.

## Histórico

Registro resumido das principais alterações de estado.
```

---

# 8. Planner

## 8.1 Responsabilidade

O Planner transforma uma intenção de implementação em uma tarefa suficientemente especificada para que outro agente possa executá-la.

O Planner não implementa RTL.

Seu objetivo é reduzir ambiguidade antes da geração de código.

---

## 8.2 Entradas

O Planner deve consultar apenas o contexto necessário, incluindo quando aplicável:

- `regras.md`;
- `docs/requisitos.md`;
- `docs/arquitetura.md`;
- `docs/modulos.md`;
- `docs/interfaces.md`;
- `docs/hardware.md`;
- `docs/verificacao.md`;
- `docs/decisoes.md`;
- `docs/pendencias.md`;
- tarefas relacionadas.

---

## 8.3 Responsabilidades do Planner

O Planner deve identificar:

- objetivo da tarefa;
- requisitos envolvidos;
- restrições;
- dependências;
- módulos afetados;
- interfaces envolvidas;
- arquivos permitidos;
- arquivos protegidos;
- abordagem estrutural proposta;
- casos de teste necessários;
- critérios objetivos de aceite;
- riscos;
- pendências.

---

## 8.4 Proibições do Planner

O Planner não deve:

- escrever Verilog;
- editar RTL;
- modificar arquitetura aprovada;
- alterar interfaces aprovadas;
- inventar comportamento ausente nos requisitos;
- resolver uma pendência sem evidência;
- sugerir FSM;
- sugerir implementação comportamental proibida;
- contornar restrições de `regras.md`.

---

## 8.5 Saída

A principal saída do Planner é uma TASK em estado:

```text
PLANNED
```

A tarefa só deve ser movida para `READY` quando não houver pendência crítica impedindo sua implementação.

---

# 9. Implementer

## 9.1 Responsabilidade

O Implementer transforma uma TASK `READY` em código e testes compatíveis com a documentação canônica.

O Implementer executa a tarefa; ele não redefine a tarefa.

---

## 9.2 Entradas

O contexto principal do Implementer deve ser:

- `regras.md`;
- TASK atual;
- requisitos explicitamente associados à TASK;
- interfaces envolvidas;
- módulos envolvidos;
- convenções Verilog;
- documentação técnica necessária.

Evitar carregar documentos não relacionados à tarefa.

---

## 9.3 Permissões

O Implementer pode:

- criar RTL dentro do escopo da tarefa;
- modificar RTL listado em "Arquivos permitidos";
- criar testbenches;
- corrigir defeitos diretamente relacionados à tarefa;
- executar ferramentas permitidas;
- registrar resultados no arquivo da TASK.

---

## 9.4 Proibições

O Implementer não pode:

- modificar requisitos;
- mudar arquitetura por iniciativa própria;
- modificar interfaces aprovadas fora do escopo;
- alterar pin assignments sem autorização;
- implementar FSM;
- utilizar `buf`;
- utilizar construções proibidas;
- substituir implementação estrutural por operador comportamental proibido;
- resolver pendências de hardware por suposição;
- ampliar silenciosamente o escopo da TASK.

Se perceber que a tarefa exige uma mudança arquitetural, deve marcar:

```text
BLOCKED
```

e registrar o motivo.

---

# 10. Ferramentas

A implementação pode utilizar ferramentas externas de validação conforme forem integradas ao projeto.

Exemplos futuros:

- simulador Verilog;
- lint;
- Verilator;
- Icarus Verilog;
- ferramentas de linha de comando do Quartus;
- análise de logs;
- síntese;
- Timing Analyzer.

O resultado de uma ferramenta é considerado evidência, não verdade absoluta.

Erros, warnings e resultados relevantes devem ser registrados na TASK.

---

# 11. Reviewer

## 11.1 Responsabilidade

O Reviewer deve avaliar uma implementação sem assumir o papel de autor original.

Seu objetivo é encontrar:

- violações de requisitos;
- violações estruturais;
- violações de `regras.md`;
- inconsistências arquiteturais;
- falhas funcionais;
- testes insuficientes;
- hipóteses não autorizadas;
- alterações de escopo.

---

# 12. Compliance Gate

Antes da avaliação funcional, o Reviewer deve realizar uma verificação de conformidade.

Checklist mínimo:

```text
[ ] Existe FSM?
[ ] Existe uso de buf?
[ ] Existe construção comportamental proibida?
[ ] Existe laço proibido?
[ ] Existe bloco proibido?
[ ] Foi utilizado operador aritmético incompatível com a exigência estrutural?
[ ] Alguma interface aprovada foi alterada?
[ ] Algum pin assignment foi alterado?
[ ] Alguma hipótese foi tratada como fato?
[ ] O escopo da TASK foi excedido?
[ ] Alguma regra de regras.md foi violada?
```

Se qualquer violação obrigatória for encontrada, o resultado deve ser:

```text
REJECTED
```

mesmo que a simulação funcional tenha sido aprovada.

---

# 13. Verificação funcional

Somente após o Compliance Gate ser aprovado devem ser avaliados:

- comportamento funcional;
- casos normais;
- casos de borda;
- reset;
- propagação de sinais;
- integração;
- testbench;
- resultados de simulação;
- warnings relevantes;
- síntese.

Sempre que possível:

```text
REQ
 |
 v
TEST
 |
 v
RESULTADO
```

---

# 14. Resultado do Reviewer

O Reviewer deve produzir uma das três classificações:

## APPROVED

A tarefa atende aos requisitos, restrições e testes.

## REJECTED

Existe uma falha concreta que exige correção.

Cada rejeição deve incluir:

- arquivo;
- localização;
- requisito ou regra violada;
- descrição objetiva;
- severidade.

## BLOCKED

Não é possível concluir a revisão por ausência de informação ou evidência.

---

# 15. Critérios de severidade

## CRITICAL

Viola requisito ou restrição fundamental.

Exemplos:

- FSM;
- implementação aritmética incompatível com o enunciado;
- alteração indevida de interface;
- comportamento funcional incorreto.

Impede aprovação.

## HIGH

Falha importante que pode comprometer funcionamento ou síntese.

Impede aprovação.

## MEDIUM

Problema técnico relevante, mas não necessariamente impeditivo.

Deve ser avaliado antes da aprovação.

## LOW

Melhoria ou questão não crítica.

Não precisa necessariamente bloquear a TASK.

---

# 16. Separação entre geração e avaliação

Sempre que possível, o mesmo contexto/agente que produziu a implementação não deve ser responsável pela avaliação final.

Fluxo preferido:

```text
Planner
   |
   v
Implementer
   |
   v
Reviewer independente
```

A intenção é reduzir viés de autocorreção e aumentar a probabilidade de encontrar defeitos.

---

# 17. Human-in-the-loop

As seguintes situações exigem aprovação humana:

- mudança arquitetural;
- alteração de interface previamente aprovada;
- mudança de requisito;
- interpretação ambígua do enunciado;
- exceção às regras;
- escolha entre alternativas arquiteturais com impacto relevante;
- alteração de pinagem;
- resolução de conflito entre fontes;
- decisão baseada em informação de hardware ainda pendente.

Nesses casos, o agente deve interromper o fluxo e registrar a pendência.

---

# 18. Tratamento de pendências

Um agente nunca deve esconder incerteza.

Quando houver falta de informação:

```text
1. identificar a informação necessária;
2. identificar por que ela é necessária;
3. procurar nas fontes permitidas;
4. se não encontrada, registrar pendência;
5. definir impacto;
6. bloquear somente as tarefas dependentes dela.
```

Pendências locais não devem bloquear partes independentes do projeto.

Exemplo:

A polaridade dos botões não precisa impedir a implementação de um somador estrutural que não utilize os botões.

---

# 19. Princípio de menor contexto

Cada agente deve receber apenas o contexto necessário para sua tarefa.

Evitar:

```text
todos os PDFs
+
todos os documentos
+
todo o código
+
todo o histórico
```

quando a tarefa depende apenas de poucos elementos.

Fluxo desejado:

```text
TASK
  |
  +-- requisitos relacionados
  +-- interfaces relacionadas
  +-- regras relevantes
  +-- arquivos relacionados
```

Isso reduz:

- ruído;
- conflitos;
- custo de contexto;
- inferências desnecessárias;
- risco de utilizar informação obsoleta.

---

# 20. Princípio de menor privilégio

Cada papel deve possuir apenas as permissões necessárias.

Exemplo:

```text
Planner
READ docs
WRITE TASK
NO RTL WRITE

Implementer
READ relevant docs
WRITE allowed RTL/TB
NO architecture changes

Reviewer
READ implementation
READ evidence
WRITE review
NO feature implementation
```

Caso a plataforma não permita enforcement técnico dessas permissões, elas devem ser aplicadas como regras explícitas de atuação.

---

# 21. Evidências

Uma TASK não deve ser considerada concluída apenas porque o agente afirma que está correta.

Devem ser priorizadas evidências verificáveis:

```text
código
+
testbench
+
resultado de simulação
+
resultado de síntese
+
review
```

Conforme as ferramentas forem adicionadas ao fluxo, os resultados devem ser registrados ou referenciados pela TASK.

---

# 22. Baseline documental

A documentação canônica deve possuir uma baseline aprovada antes de tarefas de implementação dependentes dela.

Uma atualização relevante na baseline pode exigir revisão de TASKs já planejadas.

O agente deve verificar se sua tarefa ainda está consistente com a documentação atual antes de iniciar a implementação.

---

# 23. Critério de conclusão de uma TASK

Uma tarefa somente é considerada concluída quando:

```text
[ ] objetivo implementado;
[ ] requisitos relacionados atendidos;
[ ] restrições respeitadas;
[ ] testes previstos executados;
[ ] evidências registradas;
[ ] Compliance Gate aprovado;
[ ] revisão funcional aprovada;
[ ] nenhuma pendência crítica permanece;
[ ] status = APPROVED.
```

---

# 24. Evolução futura

O workflow inicial deve permanecer simples.

Agentes adicionais somente devem ser introduzidos quando houver uma necessidade concreta.

Possíveis extensões futuras:

```text
Simulation Agent
Synthesis Agent
Hardware Validation Agent
Documentation Agent
Integration Reviewer
```

Esses papéis não devem ser criados apenas para aumentar o número de agentes.

A especialização deve resolver um problema observado no workflow atual.

---

# 25. Fluxo operacional resumido

```text
1. Desenvolvedor define objetivo.

2. Planner:
   objetivo
      ↓
   documentação
      ↓
   TASK planejada

3. Desenvolvedor resolve/aprova decisões necessárias.

4. TASK → READY.

5. Implementer:
   TASK
      ↓
   RTL/testbench
      ↓
   ferramentas
      ↓
   evidências

6. TASK → REVIEW.

7. Reviewer:
   Compliance Gate
      ↓
   análise funcional
      ↓
   APPROVED / REJECTED / BLOCKED

8. Em caso de REJECTED:
   correção específica
      ↓
   novo teste
      ↓
   nova revisão

9. Em caso de APPROVED:
   TASK encerrada.
```

---

# 26. Regra final

Os agentes existem para executar e verificar decisões do projeto, não para substituir silenciosamente o processo de engenharia.

Quando houver conflito entre:

- cumprir rapidamente uma tarefa;
- e preservar os requisitos, restrições e rastreabilidade;

a prioridade é preservar os requisitos, restrições e rastreabilidade.

# 27. Resolução de decisões técnicas

Para resolver pendências técnicas, aplicar o fluxo específico de `AGENTS.md`:

1. Orchestrator lê `agents/orchestrator.md` e o registro em `docs/pendencias.md`.
2. Decision Architect propõe e atualiza apenas `docs/decisions/DEC-XXX.md`.
3. Decision Reviewer faz revisão independente e registra parecer no mesmo DEC.
4. Limite de três rodadas Architect → Reviewer por decisão. Encerrar ao atingir CONSENSUS, BLOCKED ou ESCALATE, conforme instruções do Orchestrator e do usuário.
5. Não implementar Verilog durante o fluxo de decisão. Atualizações dos documentos canônicos após consenso são coordenadas pelo Orchestrator, mantendo requisitos P0 inalterados.


# Pipeline de implementação

Após a conclusão das decisões necessárias, uma TASK de implementação utiliza o seguinte pipeline:

Implementation Orchestrator
        |
        v
Context Analyst
        |
        v
Implementation Brief
        |
        v
Code Implementer
        |
        v
Code Auditor
        |
        +---- APPROVED
        |
        +---- REWORK ----> Code Implementer
        |
        +---- BLOCKED
        |
        +---- ESCALATE

O pipeline de decisão responde:

> O que deve ser feito?

O pipeline de implementação responde:

> Como transformar uma decisão aprovada em uma implementação verificável?

Os dois pipelines não devem ser misturados.

Uma Implementation TASK não pode criar silenciosamente uma nova decisão arquitetural.
