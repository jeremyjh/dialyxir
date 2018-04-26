Nonterminals

empty_list_paren
document
values value
list list_items
struct struct_items
tuple tuple_items
pattern pattern_items
range
contract
function.

Terminals
nil int atom '(' ')' '\'' ',' '#' '{' '}' '[' ']' 'fun(' '->' ':=' '=>' '|' '..' '_' ':' '...' '<<' '>>' '<' '>'.

Rootsymbol document.

document -> values : '$1'.

values -> value : ['$1'].
values -> value values : ['$1'] ++ '$2'.

value -> '<<' value ':' value '>>' : {binary, '$2', '$4'}.
value -> struct : '$1'.
value -> atom ':' ':' atom '(' ')' : {type, unwrap('$1'), unwrap('$4')}.
value -> '\'' atom '\'' ':' atom '(' ')' : {type, unwrap('$2'), unwrap('$5')}.
value -> atom ':' atom '(' ')' : {type, unwrap('$1'), unwrap('$3')}.
value -> '_' : {any}.
value -> '...' : {rest}.
value -> atom empty_list_paren : {type, unwrap('$1')}.
value -> atom '(' value ')' : {type, unwrap('$1'), '$3'}.
value -> atom list : {type_list, unwrap('$1'), '$2'}.
value -> '\'' int '..' int '\'' : {range, unwrap('$2'), unwrap('$4')}.
value -> int : {int, unwrap('$1')}.
value -> '\'' int '\'' : {int, unwrap('$2')}.
value -> '\'' atom '\'' : {atom, unwrap('$2')}.
value -> '\'' nil '\''  : {nil}.
value -> atom : {atom, unwrap('$1')}.
value -> list : '$1'.
value -> tuple : '$1'.
value -> pattern : '$1'.
value -> function : '$1'.
value -> contract : '$1'.
value -> range : '$1'.

value -> '\'' value '|' value '\'' : {pipe_list, '$2', '$4'}.
value -> value '|' value : {pipe_list, '$1', '$3'}.

list -> '(' list_items ')' : {list, paren, '$2'}.
list -> '[' ']' : {empty_list, square}.
list -> '[' list_items ']' : {list, square, '$2'}.
list_items -> value : ['$1'].
list_items -> value ',' list_items : ['$1'] ++ '$3'.

empty_list_paren -> '(' ')' : {empty_list, paren}.

tuple -> '{' tuple_items '}' : {tuple, '$2'}.
tuple_items -> value : ['$1'].
tuple_items -> value ',' tuple_items : ['$1'] ++ '$3'.

pattern -> '<' pattern_items '>' : {pattern, '$2'}.
pattern_items -> value : ['$1'].
pattern_items -> value ',' pattern_items : ['$1'] ++ '$3'.

struct -> '#' '{' '}' : {empty_map}.
struct -> '#' '{' struct_items '}' : {map, '$3'}.
struct_items -> value ':=' value : [{map_entry, '$1', '$3'}].
struct_items -> value ':=' value ',' struct_items : [{map_entry, '$1', '$3'}] ++ '$5'.
struct_items -> value '=>' value : [{map_entry, '$1', '$3'}].
struct_items -> value '=>' value ',' struct_items : [{map_entry, '$1', '$3'}] ++ '$5'.

range -> int '..' int : {range, unwrap('$1'), unwrap('$3')}.

function -> 'fun(' empty_list_paren '->' value ')' : {function, {args, '$2'}, {return, '$4'}}.
function -> 'fun(' list '->' value ')' : {function, {args, '$2'}, {return, '$4'}}.

contract -> list '->' value : {contract, {args, '$1'}, {return, '$3'}}.

Erlang code.

unwrap({_,_,V}) -> V.