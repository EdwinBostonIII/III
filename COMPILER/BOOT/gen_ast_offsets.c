#include "ast.h"
#include <stdio.h>
#include <stddef.h>
int main(void){
#define NODE(f) printf("%-34s %zu\n", #f, offsetof(iii_ast_node_t, f))
  NODE(kind); NODE(flags);
  NODE(u.module_.name.offset);   NODE(u.module_.name.length);
  NODE(u.module_.decls.offset);  NODE(u.module_.decls.count);
  NODE(u.cycle_decl.name.offset);     NODE(u.cycle_decl.name.length);
  NODE(u.fn_decl.name.offset);        NODE(u.fn_decl.name.length);
  NODE(u.type_decl.name.offset);      NODE(u.type_decl.name.length);
  NODE(u.const_decl.name.offset);     NODE(u.const_decl.name.length);
  NODE(u.extern_decl.name.offset);    NODE(u.extern_decl.name.length);
  NODE(u.mobius_candidate.name.offset); NODE(u.mobius_candidate.name.length);
  NODE(u.schema_decl.name.offset);    NODE(u.schema_decl.name.length);
  NODE(u.sealed_call.name.offset);    NODE(u.sealed_call.name.length);
  NODE(u.forward_block.stmts.offset); NODE(u.forward_block.stmts.count);
  NODE(u.block.stmts.offset);         NODE(u.block.stmts.count);
  printf("sizeof_node                        %zu\n", sizeof(iii_ast_node_t));
  return 0;
}
