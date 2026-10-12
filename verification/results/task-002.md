# TASK-002 — Evidência de implementação

Data: 11/10/2026. Estado do Implementer: IMPLEMENTED, aguardando Code Auditor.

## Alterações

`coefficient_input` preserva portas e instancia um único `coefficient_input_core`. O core contém as equações originais e exporta `loaded` por conexão ao decode existente de progresso11. O wrapper termina esse fio privadamente. Não há acesso hierárquico para obter status. Mantidos 31 FF por circuito: 24 coeficientes, 2 progresso, 5 sincronização/histórico. Duplicação wrapper/core ocorre somente no testbench de equivalência. Não foi necessário inicializar registradores hierarquicamente: o teste parte de X e aplica reset físico sincronizado.

## Execução real

TEST-001: PASS, 15 verificações, término em 3391000 ps. Compara coeficientes do wrapper e core e loaded esperado. Cobre reset com KEY0 pressionado, liberação sem captura espúria, captura longa inicial única, três cargas ordenadas 80/01/7F, loaded0 após a/b e loaded1 após c, alteração de SW sem evento, quarta/quinta pressões ignoradas, reset completo/parcial, recarga, prioridade de reset e captura posterior. Cada comparação rejeita X por comparação de desigualdade estrita.

Icarus Verilog 14.0 (devel), s20260301-394-g9edaf7b6a. Imagem efetivamente usada `hdlc/iverilog:latest`, digest `sha256:80bee5d44cb0fe60fa98f020b9c1ea18c857a4a92185158f7cd2d7076f8598d0`. Sem warnings na compilação `-Wall`. Log em `task-002.log`.

Reprodução a partir da raiz do projeto (fontes explícitos; .save excluído):

```sh
mkdir -p /tmp/pbl02-task002
cp rtl/coefficient_input.v testbench/tb_coefficient_input.v /tmp/pbl02-task002/
tar -C /tmp/pbl02-task002 -cf - coefficient_input.v tb_coefficient_input.v | docker run --rm -i hdlc/iverilog@sha256:80bee5d44cb0fe60fa98f020b9c1ea18c857a4a92185158f7cd2d7076f8598d0 sh -c 'mkdir -p /tmp/task002; cd /tmp/task002; tar -xf -; iverilog -g2012 -Wall -s tb_coefficient_input -o /tmp/task002.vvp coefficient_input.v tb_coefficient_input.v && vvp /tmp/task002.vvp'
```

A execução usou a tag local `latest` com o digest acima, consultado por `docker image inspect`; o comando fixa esse mesmo digest para reprodução. Socket exigiu execução escalada. Bind mounts do projeto e de /tmp falharam por permissão de leitura dentro do container; transferência dos mesmos dois fontes pelo stdin resolveu o acesso.

## Inspeção estática do Implementer

Busca lexical sem comentários confirmou ausência de if/else/buf/for/generate/genvar no DUT e ausência de if/else no TB. Todos always/begin/end/reg do DUT estão nos dois módulos dedicados a FF. Contagem das instâncias pbl_dff_plain/pbl_dff_sync_reset: 31. Equações de reset/enable/captura/progresso preservadas. Esta inspeção apoia TEST-013 e não substitui auditoria independente.

SHA256 dos fontes executados:

- `rtl/coefficient_input.v`: b83d645e41ca77f69daecbeb4ddb27e4560cc6a6e9137d26b7f7b077b6f0801c
- `testbench/tb_coefficient_input.v`: 9725529c1292fc8f21963dc0c5aef6695e5f221c78e5424b92878a5c2d85a307

Nenhuma síntese, medição física ou aprovação do tutor é afirmada.

## Code Auditor independente — ciclo 1, 11/10/2026

**APPROVED.** Gate 1 PASS: leitura integral do DUT/testbench e diff confirmou somente fronteira privada nova e conexão estática de loaded; wrapper público preservado, sem operador/construção proibida ou mudança de pinos. Gate 2 PASS: equações originais mantidas; contagem 24+2+5=31 FF; loaded segue progress_done (AND dos bits de progresso). O teste compara resultados esperados e equivalência wrapper/core com rejeição de X, cobre 15 verificações e registra PASS com compilação sem warning. SHA256 atual de ambos os fontes coincide com o registro executado. Gate 3 PASS: acesso normal à porta privada, sem referência hierárquica nem duplicação no circuito integrado; sem efeito no top-level atual.

Nenhum finding. Logs inspecionados; simulação não repetida sem preocupação concreta. Aprovação limitada à extensão TASK-002; síntese/placa seguem pendentes nas tarefas próprias.
