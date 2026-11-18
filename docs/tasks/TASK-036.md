# TASK-036 | Verificar a integração completa do PBL03

## Objetivo

Executar uma regressão reproduzível do caminho entrada→controle→validação→RGB, displays e LEDs antes dos extras.

## Status

PLANNED

## Dependências

- TASK-025-032 e TASK-034-035 | base obrigatória integrada e compilável.
- DEC-045 | simulação estrutural com estímulo e checagem externos.

## Planejamento e aceite

- Cobrir seis coeficientes, START, BUSY/DONE, reset e reexecução.
- Cobrir F1 e F2 válidas, F2 desabilitada, cada erro, função válida junto de função inválida e clipping.
- Verificar RGB para eixos, quatro curvas, blanking e prioridades aprovadas.
- Comparar cálculos com uma referência independente e conferir pelo menos um frame completo.
- Repetir compilação e regressão com um comando documentado e registrar logs vinculados à revisão.

## Arquivos

Definir a lista permitida na análise de contexto. Incluir runner, wrapper estrutural, referência independente e casos de regressão.

## Resultado

Pendente. Não há implementação nem evidência nesta TASK.
