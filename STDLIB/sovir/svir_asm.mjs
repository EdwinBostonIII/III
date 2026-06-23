// svir_asm.mjs -- a tiny SVIR assembler (dev tool): readable instruction lists -> SVIR v1 module bytes,
// formatted as a III u8 array.  Used to author svir_fact.iii reliably (the committed .iii holds the literal
// bytes; this is reproducible documentation, not a build dependency).
//   run: node svir_asm.mjs           (prints the byte array + the readable program)
const C=v=>[0x01,...(()=>{let b=[],x=BigInt.asUintN(64,BigInt(v));for(let i=0;i<8;i++){b.push(Number(x&0xffn));x>>=8n}return b})()];
const G=s=>[0x10,s], S=s=>[0x11,s], CALL=(f,a)=>[0x70,f,a], BR=d=>[0x50,d], BRIF=d=>[0x51,d];
const ADD=[0x20],SUB=[0x21],MUL=[0x22],SDIV=[0x23],SREM=[0x24],EQ=[0x30],LT=[0x32],GE=[0x33];
const BLOCK=[0x40],LOOP=[0x41],IF=[0x42],ELSE=[0x43],END=[0x44],RET=[0x60],PRINTC=[0x71],DROP=[0x72];
const flat=a=>a.flat(Infinity);
const GOLD=2432902008176640000n;  // 20!

// func 0 = main, 1 = fact_rec, 2 = fact_iter, 3 = print_dec
const funcs=[
 {name:'main',params:0,code:flat([            // locals: 0=r 1=s
   C(20),CALL(1,1),S(0),                        // r = fact_rec(20)
   C(20),CALL(2,1),S(1),                        // s = fact_iter(20)
   G(0),G(1),EQ,IF,ELSE,C(1),RET,END,           // if r!=s return 1
   G(0),C(GOLD),EQ,IF,ELSE,C(2),RET,END,        // if r!=golden return 2
   G(0),CALL(3,1),DROP,                          // print_dec(r)
   C(10),PRINTC,                                 // newline
   C(99),RET,
 ])},
 {name:'fact_rec',params:1,code:flat([          // n = local 0
   G(0),C(2),LT,IF,C(1),RET,END,                 // if n<2 return 1
   G(0),G(0),C(1),SUB,CALL(1,1),MUL,RET,         // return n * fact_rec(n-1)
 ])},
 {name:'fact_iter',params:1,code:flat([         // n=0 acc=1 i=2
   C(1),S(1), C(2),S(2),
   BLOCK,LOOP,
     G(2),G(0),C(1),ADD,GE,BRIF(1),              // if i >= n+1 break
     G(1),G(2),MUL,S(1),                          // acc *= i
     G(2),C(1),ADD,S(2),                          // i += 1
     BR(0),
   END,END,
   G(1),RET,
 ])},
 {name:'print_dec',params:1,code:flat([         // n = local 0
   G(0),C(10),GE,IF,                             // if n>=10:
     G(0),C(10),SDIV,CALL(3,1),DROP,             //   print_dec(n/10)
   END,
   C(48),G(0),C(10),SREM,ADD,PRINTC,             // print_char('0' + n%10)
   C(0),RET,
 ])},
];

function assemble(fl){ let m=[fl.length]; for(const f of fl){ const b=f.code; m.push(f.params,1,b.length&0xff,(b.length>>8)&0xff,...b); } return m; }
function iiiarr(m){ return `var SVIR : [u8; ${m.length}] = [\n    `+m.map(x=>x+'u8').join(',')+`\n]`; }

const M=assemble(funcs);
console.log(iiiarr(M));
console.log('\n// total bytes =',M.length,' golden 20! =',GOLD.toString());
for(const f of funcs) console.log('//  func',funcs.indexOf(f),f.name,'params',f.params,'body',f.code.length);

// ---- debug isolation programs (main returns fact_X(5); expect exit 120) ----
if(process.argv[2]==='dbg'){
  const fr=funcs[1], fi=funcs[2];
  const mr=[{name:'main',params:0,code:flat([C(5),CALL(1,1),RET])}, fr];
  const mi=[{name:'main',params:0,code:flat([C(5),CALL(1,1),RET])}, fi];
  console.error('\n--- DBGR (fact_rec(5)) ---\n'+iiiarr(assemble(mr)));
  console.error('\n--- DBGI (fact_iter(5)) ---\n'+iiiarr(assemble(mi)));
}
