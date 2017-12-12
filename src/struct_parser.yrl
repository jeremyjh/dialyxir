Nonterminals
document
values value
list list_items
struct struct_items
tuple tuple_items
function.

Terminals
nil int atom '(' ')' '\'' ',' '#' '{' '}' '[' ']' 'fun(' '->' ':=' '=>' '|' '..' '_'.

Rootsymbol document.

document -> values : '$1'.

values -> value : ['$1'].
values -> value values : ['$1'] ++ '$2'.

value -> '_' : {any}.
value -> atom '(' ')' : {type, unwrap('$1')}.
value -> atom '(' value ')' : {type, unwrap('$1'), '$3'}.
value -> '\'' int '..' int '\'' : {range, unwrap('$2'), unwrap('$4')}.
value -> '\'' int '\'' : {int, unwrap('$2')}.
value -> '\'' atom '\'' : {atom, unwrap('$2')}.
value -> '\'' nil '\''  : {nil}.
value -> atom : {atom, unwrap('$1')}.
value -> struct : '$1'.
value -> list : '$1'.
value -> tuple : '$1'.
value -> function : '$1'.
value -> value '|' value : {pipe_list, '$1', '$3'}.

list -> '(' list_items ')' : {list, paren, '$2'}.
list -> '[' list_items ']' : {list, square, '$2'}.
list_items -> value : ['$1'].
list_items -> value ',' list_items : ['$1'] ++ '$3'.

tuple -> '{' tuple_items '}' : {tuple, '$2'}.
tuple_items -> value : ['$1'].
tuple_items -> value ',' tuple_items : ['$1'] ++ '$3'.

struct -> '#' '{' '}' : {empty_map}.
struct -> '#' '{' struct_items '}' : {map, '$3'}.
struct_items -> value ':=' value : [{map_entry, '$1', '$3'}].
struct_items -> value ':=' value ',' struct_items : [{map_entry, '$1', '$3'}] ++ '$5'.
struct_items -> value '=>' value : [{map_entry, '$1', '$3'}].
struct_items -> value '=>' value ',' struct_items : [{map_entry, '$1', '$3'}] ++ '$5'.

function -> 'fun(' list '->' value ')' : {function, {args, '$2'}, {return, '$4'}}.

Erlang code.

unwrap({_,_,V}) -> V.