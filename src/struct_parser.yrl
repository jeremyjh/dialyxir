Nonterminals

document
assignment
rest
values value
list
map map_items map_entry
tuple
binary binary_items binary_part
pattern
value_items
byte_list byte_items
byte
range
atom sub_atom
contract
type
integer
pipe_list
function.

Terminals

atom_part atom_full
int
'(' ')'
'[' ']'
'_'
'\''
','
'#' '{' '}'
':=' '=>'
'fun(' '->'
'|'
'..'
'::'
':'
'...'
'<<' '>>'
'<' '>'
'*'
'='.

Rootsymbol document.

document -> values : '$1'.

values -> value : ['$1'].
values -> value values : ['$1'] ++ '$2'.

value -> assignment : '$1'.
value -> atom : {atom, '$1'}.
value -> binary : '$1'.
value -> byte_list : '$1'.
value -> contract : '$1'.
value -> function : '$1'.
value -> integer : '$1'.
value -> list : '$1'.
value -> map : '$1'.
value -> pattern : '$1'.
value -> pipe_list : '$1'.
value -> range : '$1'.
value -> rest : '$1'.
value -> tuple : '$1'.
value -> type : '$1'.

binary -> '<<' binary_items '>>' : {binary, '$2'}.

pattern -> '<' value_items '>' : {pattern, '$2'}.

tuple -> '{' value_items '}' : {tuple, '$2'}.

byte_list -> '#' '{' '}' '#' : {byte_list, []}.
byte_list -> '#' '{' byte_items '}' '#' : {byte_list, '$3'}.

list -> '(' ')' : {empty_list, paren}.
list -> '(' value_items ')' : {list, paren, '$2'}.
list -> '[' ']' : {empty_list, square}.
list -> '[' value_items ']' : {list, square, '$2'}.

map -> '#' '{' '}' : {empty_map}.
map -> '#' '{' map_items '}' : {map, '$3'}.

pipe_list -> value '|' value : {pipe_list, '$1', '$3'}.
pipe_list -> pipe_list '|' value : {pipe_list, '$1', '$3'}.
pipe_list -> '\'' pipe_list '\'' : '$2'.

map_entry -> value ':=' value : {map_entry, '$1', '$3'}.
map_entry -> value '=>' value : {map_entry, '$1', '$3'}.

function -> 'fun(' ')' : {any_function}.
function -> 'fun(' contract ')' : {function, '$2'}.

binary_part -> '_' ':' value : {binary_part, {any}, '$3'}.
binary_part -> '_' ':' '_' '*' value : {binary_part, {any}, {any}, {size, '$5'}}.

assignment -> value '=' value : {assignment, '$1', '$3'}.

byte -> '#' '<' int '>' '(' int ',' int ',' atom ',' '[' atom ',' atom ']' ')' : unwrap('$3').

contract -> list '->' value : {contract, {args, '$1'}, {return, '$3'}}.

range -> int '..' int : {range, unwrap('$1'), unwrap('$3')}.
range -> '\'' range '\'' : '$2'.

rest -> '...' : {rest}.

integer -> '\'' int '\'' : {int, unwrap('$2')}.
integer -> int : {int, unwrap('$1')}.

atom -> '\'' atom '\'' : '$2'.
atom -> atom_full : unwrap('$1').
atom -> sub_atom : ['$1'].
atom -> sub_atom integer : ['$1'] ++ ['$2'].
atom -> atom atom : '$1' ++ '$2'.

sub_atom -> atom_part : unwrap('$1').
sub_atom -> '_' : '_'.

type -> atom ':' type : {type, {atom, '$1'}, '$3'}.
type -> atom '::' binary : {named_type, {atom, '$1'}, '$3'}.
type -> atom '::' integer : {named_type, {atom, '$1'}, '$3'}.
type -> atom '::' list : {named_type, {atom, '$1'}, '$3'}.
type -> atom '::' map : {named_type, {atom, '$1'}, '$3'}.
type -> atom '::' tuple : {named_type, {atom, '$1'}, '$3'}.
type -> atom '::' type : {named_type, {atom, '$1'}, '$3'}.
type -> atom list : {type_list, '$1', '$2'}.

byte_items -> byte : ['$1'].
byte_items -> byte ',' byte_items : ['$1'] ++ '$3'.

binary_items -> binary_part : ['$1'].
binary_items -> binary_part  ',' binary_items : ['$1'] ++ '$3'.

map_items -> map_entry : ['$1'].
map_items -> map_entry ',' map_items : ['$1'] ++ '$3'.

value_items -> value : ['$1'].
value_items -> value ',' value_items : ['$1'] ++ '$3'.

Erlang code.

unwrap({_,_,V}) -> V.
