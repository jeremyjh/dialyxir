Definitions.

WHITESPACE=[\s\t\r\n]+
INT = -?[0-9]+
NUMBERED = _@[0-9]+::
REST = \.\.\.
RANGE = \.\.
ALIAS = V.+@[0-9]+
ATOM = \'[^']+\'

Rules.

{WHITESPACE} : skip_token.
{NUMBERED} : skip_token.

{REST} : {token, {'...', TokenLine}}.
nil : {token, {'nil', TokenLine}}.
fun\( : {token, {'fun(',  TokenLine}}.
\* : {token, {'*',  TokenLine}}.
\[ : {token, {'[',  TokenLine}}.
\] : {token, {']',  TokenLine}}.
\( : {token, {'(',  TokenLine}}.
\) : {token, {')',  TokenLine}}.
\{ : {token, {'{',  TokenLine}}.
\} : {token, {'}',  TokenLine}}.
\# : {token, {'#',  TokenLine}}.
\| : {token, {'|',  TokenLine}}.
_ : {token, {'_',  TokenLine}}.
\:\: : {token, {'::',  TokenLine}}.
\: : {token, {':',  TokenLine}}.
\:\= : {token, {':=',  TokenLine}}.
\=\> : {token, {'=>',  TokenLine}}.
\-\> : {token, {'->',  TokenLine}}.
\| : {token, {'|',  TokenLine}}.
\<\< : {token, {'<<', TokenLine}}.
\< : {token, {'<', TokenLine}}.
\>\> : {token, {'>>', TokenLine}}.
\> : {token, {'>', TokenLine}}.
\' : {token, {'\'',  TokenLine}}.
, : {token, {',',  TokenLine}}.
\= : {token, {'=',  TokenLine}}.
{RANGE} : {token, {'..', TokenLine}}.
{INT} : {token, {int,  TokenLine, list_to_integer(TokenChars)}}.
{ALIAS} : {token, {variable_alias, TokenLine, TokenChars}}.
{ATOM} : {token, {atom_full, TokenLine, TokenChars}}.
. : {token, {atom_part, TokenLine, TokenChars}}.

Erlang code.
