# Procedimento de validação física na DE10-Lite

## Preparação

1. Registre o modelo e número de identificação da placa.
2. Registre a versão do Quartus e o hash do arquivo `.sof` usado. A compilação aprovada está descrita em `verification/results/quartus/README.md`.
3. Com a placa desligada, conecte-a ao computador e abra o projeto Quartus aprovado.
4. Programe a FPGA com o `.sof` gerado pela compilação aprovada.
5. Registre se a programação terminou sem erro e fotografe a placa ligada.

## Casos

Use `KEY1` para reset. Pressione e solte `KEY0` uma vez para cada coeficiente. Mantenha `SW[7:0]` estável antes e durante cada captura. Aguarde a acomodação dos displays antes de registrar o resultado.

| Caso | Ação | Resultado esperado |
|---|---|---|
| Inicialização | Energize a placa e aplique reset | OV=0, C=0 e ERR=0; Z acompanha o resultado selecionado |
| Caso válido 1 | Após reset, capture `a=1`, `b=-3`, `c=2` | Captura termina após `c`; não há pinos públicos para ler coeficientes |
| Captura excedente | Pressione KEY0 novamente | Coeficientes mantidos; nenhuma captura adicional |
| `x` | Selecione `00`, ajuste `x=2` | Displays mostram `2` |
| `y`, caso 1 | Selecione `01` com `x=2` | Displays mostram `0`; LEDR2 mostra carry-out `1` |
| `x₁`, caso 1 | Selecione `10` | Displays mostram `2` |
| `x₂`, caso 1 | Selecione `11` | Displays mostram `1` |
| Caso válido 2 | Após reset, capture `a=1`, `b=0`, `c=-1`; use `x=0` | `y=-1`, `Δ=4`, `x₁=1`, `x₂=-1` |
| Erro de domínio | Após reset, capture `a=0`, `b=1`, `c=0`; selecione uma raiz | LEDR3 indica ERR; displays seguem a política aprovada |
| OV e Z | Nos casos válidos, observe LEDR0 e LEDR1 em `y=0` e `y=-1` | OV=0; Z=1 para zero e Z=0 para `-1` |
| Reset após carga | Aplique reset | Estado de captura e flags retornam ao estado inicial |

Registre cada observação na tabela. Não substitua observações físicas por resultados de simulação.

| Caso | Entradas/ações observadas | Displays | LEDR[3:0] | Passa? | Foto ou nota |
|---|---|---|---|---|---|
| | | | | | |

## Registro da execução

- Placa e identificação:
- Data e operador:
- Quartus e versão:
- Hash do `.sof`:
- Resultado da programação:
- Divergências:
- Correções e retestes:
- Referências às fotos:

Sem uma execução preenchida e evidência observada na placa, TEST-012 e TEST-015 permanecem pendentes.

Use estas codificações signed de 8 bits nos switches: `1=00000001`, `-3=11111101`, `2=00000010`, `0=00000000` e `-1=11111111`.
