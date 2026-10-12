# TASK-017 — Auditoria independente de conformidade pré-síntese

Data: 11/10/2026 (America/Bahia). Code Auditor independente dos implementadores. Ciclo 1. **APPROVED**, zero findings abertos.

## Escopo e método

12 fontes RTL `.v` e11 arquivos de testbench; `.save` explicitamente excluído. Revisão manual dos módulos realizada nas auditorias TASK-002–019 e conferência global atual com parser estático estrito específico ao subconjunto usado. O parser remove comentários, rejeita palavras-chave proibidas, aceita somente conexões estáticas em assign, expande a hierarquia top_module e concatenações em bits, contabiliza drivers, percorre dependências combinacionais e corta arestas de armazenamento nos DFFs. Declarações/instâncias fora da gramática esperada interrompem o programa; não ignora construções desconhecidas. Código reproduzível abaixo. Esta elaboração estática auxiliar não é síntese Quartus, nem verificador geral de toda a linguagem Verilog.

## Gate 1 — Compliance PASS

37 definições de módulo;1463 instâncias de módulos na hierarquia integrada (portas primitivas não entram nessa contagem). 31 FF:2 pbl_dff_plain e29 pbl_dff_sync_reset, todos no core de captura, mesmo clock MAX10_CLK1_50. Correspondem24 coeficientes+2 progresso+5 sincronização/histórico. Somente os dois módulos dedicados têm always posedge incondicional; cálculo de D/reset/enable por portas. Nenhum latch, comportamento de controle, if/else, buf, laço/geração, parâmetro ou operador aritmético no DUT. Testbenches sem if/else; laços/case/aritimética de referência restritos ao TB.

Inspeção global:14753 bits dirigidos, zero drivers múltiplos, zero referências não dirigidas, zero ciclos combinacionais após separar armazenamento. Estado limitado ao contador linear autorizado e dados/sincronização; não há controlador FSM adicional. A interpretação acadêmica do contador continua risco explicitado, sem alegar aceite externo. Não houve alteração de RTL/pinos.

## Gate 2 — Functional evidence PASS

Auditorias locais já aceitaram TEST-001 (15 checks), TEST-002 (FA8+37212 vetores), TEST-003 (65536 signed+4194560 mistos+256 quadrados+91 dirigidos), TEST-004 (131072 radicandos), TEST-005 (131072 pares), TEST-006 (12413 vetores), TEST-007 (10030 vetores), TEST-008 (6048 seletor+10032 display+16 BCD/add3), TEST-009 (010:3584+53;018:240;019:16+64) e TEST-010/011 (10 cenários/660 observações). Modelos/referências independentes e limites foram revisados nos pareceres próprios. TASK-005 exaure16.777.216 triplas no software, não no RTL.

Manifesto integrado system-icarus.json e hash de system-icarus.log conferem com os13 fontes atuais, Icarus14.0 devel s20260301-394-g9edaf7b6a, imagem sha256:80bee5d44cb0fe60fa98f020b9c1ea18c857a4a92185158f7cd2d7076f8598d0, retorno0 e PASS10/660. Não reexecutei simulações já aprovadas. Logs unitários antigos do arquivo compartilhado status_flags referem-se às revisões de cada TASK; acréscimos posteriores foram auditados e o conjunto final foi novamente exercitado na integração.

## Gate 3 — Integration PASS

Top instancia core de captura e core y uma vez, sem duplicar wrappers. Rota loaded/carry usa portas ordinárias, nunca acesso hierárquico a sinais ocultos. Portas físicas e mapeamento LEDs/HEX preservados. Soma final de y fornece carry, distinto de OV0. x² não negativo≤16384 satisfaz contrato restrito s8×u15→s22, bit15 eliminado é zero; extensões signed23/18/10 explícitas. abs(-128)=128 unsigned8. Raízes mantêm E/r até arredondamento por paridade/correção, sinais e associação dos ramos; inválidos mascarados. Display conserva magnitude e sete dígitos BCD antes do limite visual. Não há armazenagem nova em aritmética/flags/apresentação.

## Findings e limites

Nenhum HIGH/CRITICAL/MEDIUM/LOW aberto nesta auditoria global. A correção documental anterior sobre Δ=-1 já foi resolvida em TASK-003. Aprovação pré-síntese libera TASK-015; não certifica fitting, área mínima global, timing, pinos efetivamente compilados, bounce/metastabilidade na placa ou funcionamento físico. Tais evidências permanecem nas tarefas próprias.

## Hashes dos arquivos auditados

```text
fad812f3d306bc60b327a464946f96a2915c28f0dbb44b01a782d212dc75da3a  rtl/add_sub.v
0e9e393098a238cf0e5992a187834922fea4506eea13d4cdc635debf7376098e  rtl/arithmetic_cells.v
b83d645e41ca77f69daecbeb4ddb27e4560cc6a6e9137d26b7f7b077b6f0801c  rtl/coefficient_input.v
34a3a9a4be300d8f0f4ffc8074dc7c0c11b0909ca67a8e9469ff39a2ff891d8b  rtl/decimal_display.v
3c78a3f6df23183f9e395cde079e9e2e074fad85cd5ae5e1643d10a2690783cb  rtl/divide_u9_u8.v
95d8de13e7cab690e72544c5b4c89efe7c956f46eadcc714a112f80123ddc371  rtl/multipliers.v
b3d2788521b3e646eb585813e0a3a50390eaa8b71c7edb07f5b3392369477fb7  rtl/polynomial_y.v
4a3ea3a69479a724da17adf1f26c99397d6f7ff8d5e3d9844bba25993392c03e  rtl/quadratic_roots.v
1c0966845e4d864e72ea9f1aa0ac4ff627eb61ab614a2573457e48a1ab593f23  rtl/result_select.v
9c2dd06c7db0ec74226f4911130739cc8862c1efa46ddad6965b507858aeb2c9  rtl/sqrt_u17.v
33a97de7f69a9cf42a6cd0ae5977471cf68376742efe2be5750cd2ab29076339  rtl/status_flags.v
3a0b6453f43c831966d2ed18359bb1d1c76f854c6d9280ee2e7ea4d38803c40c  rtl/top_module.v
05126be5fb41a069deb696076f90a9505518a253e9caa186a671edc4b0564831  testbench/tb_add_sub.v
9725529c1292fc8f21963dc0c5aef6695e5f221c78e5424b92878a5c2d85a307  testbench/tb_coefficient_input.v
83b0790681d588bf57978b3fcfbdbe8d9894e64c78c162c27d7574b5587038c0  testbench/tb_decimal_display.v
b7a5b32d0b0144481dd1f84d80f7144e9fa95eb18d263118da099b97f0c91e56  testbench/tb_divide_u9_u8.v
5d7104d9eb16c5a4f95fb89d85907d3b2e58bf442d02a9f87535265e2fd298f6  testbench/tb_multipliers.v
1144d2c35051acfd64267259db899a6192107a4a3fd24d744c50506aa95310e9  testbench/tb_polynomial_y.v
48cecc3eb8153562e3b8e101d8f1694bf7327b9757731f127c8dd9f5229f6354  testbench/tb_quadratic_roots.v
153e73394d7d591114966f061f04b13ffe54da4f5f40e9e84f3544403ec68e06  testbench/tb_result_select.v
17f18c4ac27f96dbddb1cba7a8a40aa7e150d2d84d4d5bd8a40883d9b55a3a98  testbench/tb_sqrt_u17.v
9c64c0d140dcd50f28887b814102076505145a8f4c0c9ebe4cec0b2a3c136839  testbench/tb_status_flags.v
7c3a5db50256cf0ef2179b472477173d80ff44f5704c0e3e3363d7992a59865b  testbench/tb_top_module.v
```

## Resultado estrutural reproduzível

```json
{
  "rtl_files": 12,
  "testbenches": 11,
  "module_definitions": 37,
  "elaborated_instances": 1463,
  "primitive_driver_bits": 14753,
  "ff": 31,
  "multiple_drivers": 0,
  "undriven_references": 0,
  "combinational_cycles": 0,
  "hierarchy_counts": {
    "top_module": 1,
    "coefficient_input_core": 1,
    "pbl_dff_plain": 2,
    "pbl_dff_sync_reset": 29,
    "polynomial_y_core": 1,
    "mul_s8_s8": 4,
    "full_adder": 914,
    "mul_s8_u15": 1,
    "add23_core": 2,
    "quadratic_roots": 1,
    "sub18": 1,
    "sqrt_u17": 1,
    "sqrt_stage": 9,
    "sqrt_full_adder": 99,
    "roots_condneg10": 3,
    "roots_addsub10": 2,
    "roots_condneg8": 1,
    "roots_branch": 2,
    "divide_u9_u8": 2,
    "divide_stage": 18,
    "divide_full_adder": 162,
    "roots_increment9": 2,
    "roots_condneg9": 2,
    "result_select": 1,
    "flag_ov_err": 1,
    "flag_z": 1,
    "flag_c": 1,
    "decimal_display": 1,
    "decimal_magnitude": 1,
    "decimal_double_dabble": 1,
    "decimal_dabble_stage": 23,
    "decimal_add3": 161,
    "decimal_position": 6,
    "decimal_bcd_segments": 6
  }
}
```

## Procedimento auxiliar executado

Executado `python3 /tmp/pbl017_audit.py` desde a raiz, retorno0. Para reproduzir, salvar o código abaixo em /tmp/pbl017_audit.py e executar o mesmo comando; saída JSON auxiliar em /tmp/pbl017_audit.json. Apenas leitura dos fontes.

```python
from pathlib import Path
import re,collections,hashlib,json
root=Path.cwd(); files=sorted(Path('rtl').glob('*.v')); tbs=sorted(Path('testbench').glob('*.v'))
mods={}; problems=[]
def clean(s): return re.sub(r'//[^\n]*|/\*.*?\*/','',s,flags=re.S)
for p in files:
 s=clean(p.read_text())
 assert not re.search(r'\b(if|else|buf|for|while|generate|genvar|initial|case|parameter|defparam)\b',s),p
 for n,ports,body in re.findall(r'module\s+(\w+)\s*\((.*?)\);(.*?)endmodule',s,re.S):
  assert n not in mods,n
  widths={}; directions={}; direction=None;width=1
  for item in ports.split(','):
   item=item.strip();m=re.match(r'(input|output)\s+(?:wire|reg)\s*(?:signed\s*)?(?:\[(\d+):(\d+)\]\s*)?(\w+)$',item)
   if m:
    direction,hi,lo,name=m.groups();width=int(hi)-int(lo)+1 if hi else 1
   else: name=item;assert re.fullmatch(r'\w+',name),item
   widths[name]=width;directions[name]=direction
  for hi,lo,names in re.findall(r'wire\s+(?:signed\s*)?(?:\[(\d+):(\d+)\]\s*)?([^;]+);',body):
   for name in names.split(','): widths[name.strip()]=int(hi)-int(lo)+1 if hi else 1
  always=re.findall(r'always\s*@\(posedge clk\)\s*begin\s*(\w+)\s*<=\s*(\w+)\s*;\s*end',body)
  if re.search(r'\b(always|reg|begin|end)\b',body):
   assert n in ('pbl_dff_plain','pbl_dff_sync_reset') and len(always)==1,n
  body=re.sub(r'always\s*@\(posedge clk\)\s*begin\s*\w+\s*<=\s*\w+\s*;\s*end','',body)
  body=re.sub(r'wire\s+(?:signed\s*)?(?:\[\d+:\d+\]\s*)?[^;]+;','',body)
  mods[n]=(widths,directions,body,always)
for p in tbs: assert not re.search(r'\b(if|else)\b',clean(p.read_text())),p

def split(s):
 out=[];start=level=0
 for i,c in enumerate(s):
  level+=c=='{';level-=c=='}'
  if c==',' and level==0:out.append(s[start:i]);start=i+1
 return out+[s[start:]]
def bits(e,ns,widths):
 e=e.strip()
 if e.startswith('{'):
  inner=e[1:-1];m=re.fullmatch(r'(\d+)\{(.*)\}',inner,re.S)
  if m:return bits('{'+m[2]+'}',ns,widths)*int(m[1])
  return sum((bits(x,ns,widths) for x in split(inner)),[])
 m=re.fullmatch(r"(\d+)'b([01]+)",e)
 if m:return ['CONST']*int(m[1])
 m=re.fullmatch(r'(\w+)(?:\[(\d+)(?::(\d+))?\])?',e);assert m,e
 name,hi,lo=m.groups();assert name in widths,(ns,name)
 indexes=range(widths[name]-1,-1,-1) if hi is None else range(int(hi),int(lo if lo else hi)-1,-1)
 assert all(0<=i<widths[name] for i in indexes),(name,e)
 return [ns[name][i] for i in indexes]
drivers=collections.Counter(); edges=collections.defaultdict(set);count=collections.Counter();clocks=[]
def drive(outs,ins):
 for x in outs:
  assert x!='CONST'
  drivers[x]+=1;edges[x].update(v for v in ins if v!='CONST')
def visit(name,path,connections=None):
 widths,directions,body,always=mods[name];count[name]+=1
 ns={k:[path+'.'+k+'['+str(i)+']' for i in range(w)] for k,w in widths.items()}
 if connections:
  for k,v in connections.items():assert len(v)==widths[k],(name,k,len(v),widths[k]);ns[k]=list(reversed(v))
 else:
  for k,d in directions.items():
   if d=='input':
    for node in ns[k]:drivers[node]+=1
 for q,d in always:
  drive(bits(q,ns,widths),[]);clocks.extend(bits('clk',ns,widths))
 for statement in body.split(';'):
  st=statement.strip()
  if not st:continue
  m=re.fullmatch(r'assign\s+(.+?)\s*=\s*(.+)',st,re.S)
  if m:
   a,b=bits(m[1],ns,widths),bits(m[2],ns,widths);assert len(a)==len(b),(name,m.groups())
   for x,y in zip(a,b):drive([x],[y])
   continue
  m=re.fullmatch(r'(\w+)\s*(\w+)?\s*\((.*)\)',st,re.S);assert m,(name,st)
  typ,inst,args=m.groups()
  if typ in ('and','or','not','xor','nor','nand','xnor'):
   refs=[bits(a,ns,widths) for a in args.split(',')];assert all(len(v)==1 for v in refs),(name,st)
   drive(refs[0],sum(refs[1:],[]))
  else:
   ports={p:bits(e,ns,widths) for p,e in re.findall(r'\.(\w+)\(([^()]*)\)',args)}
   assert typ in mods and set(ports)==set(mods[typ][1]),(name,typ,set(ports))
   visit(typ,path+'.'+inst,ports)
visit('top_module','top')
assert len(clocks)==31 and set(clocks)=={'top.MAX10_CLK1_50[0]'},clocks
multi=[n for n,c in drivers.items() if c>1];undriven={i for inputs in edges.values() for i in inputs if i not in drivers}
assert not multi,multi[:8]
assert not undriven,list(undriven)[:8]
state={}
def dfs(n):
 if state.get(n)==1:raise AssertionError(('combinational_cycle',n))
 if state.get(n)==2:return
 state[n]=1
 for i in edges[n]:dfs(i)
 state[n]=2
import sys
sys.setrecursionlimit(100000)
for n in list(edges):dfs(n)
summary={'rtl_files':len(files),'testbenches':len(tbs),'module_definitions':len(mods),'elaborated_instances':sum(count.values()),'primitive_driver_bits':len(drivers),'ff':len(clocks),'multiple_drivers':len(multi),'undriven_references':len(undriven),'combinational_cycles':0,'hierarchy_counts':dict(count),'hashes':{str(p):hashlib.sha256(p.read_bytes()).hexdigest() for p in files+tbs}}
Path('/tmp/pbl017_audit.json').write_text(json.dumps(summary,indent=2))
print(json.dumps({k:v for k,v in summary.items() if k!='hashes'},indent=2))
```
