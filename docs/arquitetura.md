# Arquitetura lógica aprovada

## Baseline de 11/10/2026

DEC-030 e DEC-031 encerram as escolhas técnicas sob delegação explícita do responsável, com revisão independente ACCEPT. Requisitos P0 permanecem em `requisitos.md`; o texto de REQ-006 exige truncamento, e a exceção autorizada DEC-007 determina arredondamento ao inteiro mais próximo, empate longe de zero.

## Fluxo

1. Clock único MAX10_CLK1_50, borda de subida. KEY1 ativo baixo é sincronizado em duas etapas e produz reset lógico síncrono. Pressionar reset após energizar.
2. KEY0 sincronizado produz evento por pressão. Contador saturante `00→01→10→11` habilita captura de a, b, c, nessa ordem; após c, capturas excedentes são ignoradas até reset. Coeficientes signed8. Não se usa o antigo deslocador de DEC-009.
3. `loaded` é a decodificação estrutural de `11`, sem FF adicional. A retenção dos coeficientes assegura persistência de ERR após carga inválida até reset.
4. SW[7:0] fornece x signed8 após carga; SW[9:8] seleciona 00=x,01=y,10=x1,11=x2. Cálculo e apresentação contínuos, sem EXECUTAR ou registradores de resultado.
5. `y=((a*x²)+(b*x))+c`, saída signed23 exata. Produtos completos no domínio, extensões explícitas e duas somas simultâneas. LEDR0/OV acende quando `y` está selecionado/carregado e excede a faixa decimal dos seis displays, conforme DEC-039; nenhuma soma intermediária é truncada. Carry_y vem exclusivamente da soma final com c.
6. `Δ=b²−4ac` signed18. Raiz quadrada inteira unsigned9 com resíduo unsigned10, divisão unsigned9/unsigned8 com resto e representação signed10/F=1 acompanhada dos resíduos permitem arredondamento final exato em signed9. DEC-031 substitui o candidato F=16; a prova aceita não substitui a exaustão e testes da implementação.
7. x1 é sempre o ramo +sqrt e x2 o ramo −sqrt, mesmo para a negativo. Se a=0 ou Δ<0, domain_error=1 e os dados x1/x2 são zero sem validade. ERR=loaded AND domain_error; não acrescentar latch/FF para ERR.
8. Z detecta zero do valor selecionado, mascarada quando raiz inválida está selecionada. C=carry_y AND loaded AND seleção y. LEDR0=OV,1=Z,2=C,3=ERR,9:4=0.
9. Seleção estrutural com extensão signed23; conversão double-dabble combinacional, displays ativos baixos. Faixa visual 0..999999 e -99999..-1; negativos usam HEX5 para sinal. Excesso, raiz inválida ou resultado selecionado antes de loaded mostram seis traços. x continua visível antes da carga. Z/OV não são flags de capacidade do display.

## Hierarquia aprovada

```text
modulo_principal
 ├─ entrada_coeficientes_nucleo ── a,b,c,loaded
 ├─ polinomio_y_nucleo ── y,OV,carry_y
 │   ├─ multiplica_com_sinal_8_por_8 (x² e bx)
 │   ├─ multiplica_com_sinal_8_por_sem_sinal_15 (a*x², domínio x²<=16384)
 │   └─ somador_23_nucleo (duas somas)
 ├─ raizes_quadraticas ── delta,x1,x2,domain_error
 │   ├─ multiplicadores e subtrator_18
 │   ├─ raiz_quadrada_17 (uma unidade)
 │   └─ divisor_9_por_8 (duas unidades simultâneas)
 ├─ seletor_resultado ── value signed23
 ├─ exibicao_decimal ── HEX0..HEX5
 └─ sinaliza_overflow_erro / sinaliza_zero / sinaliza_carry ── LEDR
```

Wrappers públicos `entrada_coeficientes`, `polinomio_y` e `somador_23` preservam suas portas sem status adicional. Cada wrapper instancia seu core privado. O top usa apenas os cores; não duplica wrappers e cores como circuitos separados. Loaded/carry atravessam portas privadas documentadas, sem referência hierárquica a fios ocultos.

## Mínimo, sintaxe e temporização

31 FF previstos: 24 coeficientes, 2 progresso, 5 sincronização/histórico. Nenhum FF adicional na aritmética, apresentação ou flags. Esse é o mínimo justificado para a arquitetura acordada; custo em LEs e temporização requerem síntese real, sem alegar ótimo global.

DUT estrutural em todos os blocos exceto captura D incondicional dos FF dedicados. FSM, if/else, buf e laços/generate permanecem proibidos; instâncias repetidas são explícitas. Contador local é a interpretação de projeto de DEC-024/027/030; aceite acadêmico não foi inventado.

50MHz/20ns aplica-se aos caminhos registrados. Caminhos combinacionais de saída são medidos separadamente, orçamento de acomodação 1ms; não ocultar falhas por false_path geral. SW é entrada manual que deve estar estável na captura; não há sincronizador multibit adicional. Validação física e análise de timing permanecem obrigatórias.

## Referência PBL1

O código legado é referência de estilo, não contrato de arquitetura ou larguras do PBL02. Não inferir pinagem dele. Contratos completos, algoritmos e alternativas rejeitadas estão em DEC-030/031.
