# Arquitetura lógica

## Autoridade e estado

- **Requisitos P0:** `docs/requisitos.md` transcreve o enunciado sem alterar seu sentido. Em particular, REQ-006 publica “truncar”.
- **Decisões de equipe:** DEC-007 a DEC-014 definem os critérios de implementação listados abaixo. São decisões de projeto, não alterações ao PDF.
- **Escopo deste documento:** arquitetura lógica acordada para orientar futura especificação e implementação; não descreve RTL existente nem fecha os itens ainda abertos em `docs/pendencias.md`.

## Fluxo funcional acordado

1. KEY1 solicita reset lógico síncrono ativo alto, amostrado na borda de subida de `MAX10_CLK1_50`. O botão é eletricamente ativo baixo; DEC-019 aprova sincronização em duas etapas e exige pressionar KEY1 após energizar antes de iniciar.
2. Após o reset, o usuário apresenta `a`, `b` e `c` em `SW[7:0]` e pressiona KEY0 exatamente três vezes, nessa ordem. O armazenamento acordado é um deslocador de três estágios. Não há detecção de carga incompleta ou captura excedente (DEC-009).
3. Depois da carga, `SW[7:0]` representa `x`; `SW[9:8]` seleciona a visualização: `00=x`, `01=y`, `10=x₁`, `11=x₂` (DEC-011). Não há botão EXECUTAR nem seletor HEX/DEC.
4. Os resultados e a seleção ficam continuamente disponíveis por lógica combinacional após a carga (DEC-010). Os coeficientes ficam armazenados; não há captura de resultados.
5. `y` é signed de 23 bits. OV indica não representabilidade aritmética nessa faixa; para entradas válidas signed de 8 bits, OV é sempre 0. Overflow de apresentação é distinto e usa `------` quando o valor não cabe (DEC-012/017).
6. As raízes são apresentadas arredondadas ao inteiro mais próximo, com empate para longe de zero, como exceção de implementação autorizada pelo professor (DEC-007). O texto literal do REQ-006/PDF continua dizendo truncar. As raízes intermediárias signed de 25 bits com F=16 são uma escolha candidata acordada, ainda sujeita à validação PEN-019 (DEC-013).
7. A saída prioriza decimal com sinal. LEDs devem apresentar OV, Z, C e ERR; os significados/origens de Z e C seguem PEN-004. Em `a=0` ou `Δ<0`, ERR é ativado e permanece até reset; não se exige mensagem ERR nos displays (DEC-001).

## Diagrama funcional

```text
SW[7:0] ──> captura KEY0 / deslocador ──> a,b,c armazenados
    │                                        │
    └── x após a carga ──> cálculo de y <────┤
                                             └──> cálculo de Δ e raízes
SW[9:8] ──> seletor x/y/x₁/x₂ ──> conversão decimal com sinal ──> HEX0–HEX5
                                     └──> apresentação de OV/Z/C/ERR em LEDs
MAX10_CLK1_50 + KEY1 ──> registradores (reset lógico síncrono)
```

Os nomes são agrupamentos conceituais; não determinam quantidade de módulos nem compartilhamento de unidades.

## Decisões e limites atuais

| Aspecto | Estado acordado | Ainda aberto |
|---|---|---|
| Entrada e carga | SW[7:0], KEY0, três capturas a→b→c por deslocador; um evento por pressão sincronizada | Validar na placa; não há detecção de sequência incorreta |
| Seleção e execução | SW[9:8] seleciona x/y/x₁/x₂; cálculo contínuo após carga | Nenhum comando separado de execução |
| Clock e reset | MAX10_CLK1_50, borda de subida; KEY1 ativo baixo sincronizado e convertido em reset lógico síncrono ativo alto; reset após energizar | Validar na placa e conferir QSF contra top-level |
| Aritmética | y signed 23-bit; raízes intermediárias signed 25-bit, F=16 candidato | Evidência numérica da suficiência de F=16 (PEN-019) |
| Arredondamento | Arredondar ao mais próximo, empate longe de zero, somente quando houver redução necessária de precisão; preservar bits enquanto possível (DEC-016) | Validar a cadeia numérica em PEN-019 |
| Raízes finais | Arredondamento ao mais próximo; empate longe de zero, autorizado como exceção | Registrar a exceção no relatório futuro |
| Flags | OV aritmético de y; ERR para domínio inválido e reset para limpar; Z é zero do valor selecionado | Origem/semântica de C (PEN-004) |
| Apresentação | Decimal signed; `------` se valor completo exceder capacidade dos seis dígitos (DEC-017) | Validação da conversão na implementação |
| Implementação | Circuitos aritméticos estruturais; DFF com always apenas no próprio FF, sem FSM | Detalhes RTL aguardam baseline e demais decisões |

## Referência PBL1

O pacote `Pbl1felipe.7z` contém HDL estrutural para o topo antigo, somadores, multiplexadores, flags, conversão BCD e displays. Implementa a equação fixa do PBL1, sem captura dos coeficientes do PBL2 nem unidades completas de raiz/divisão. Serve como referência técnica, não como arquitetura aprovada. O pacote não inclui `.qsf` ou `.qpf`; consulte `docs/fontes.md` e `docs/modulos.md`.
