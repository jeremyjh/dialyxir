Definitions.

WHITESPACE=[\s\t\r\n]+
INT = -?[0-9]+
NUMBERED = _@[0-9]+::
REST = \.\.\.
RANGE = \.\.
ATOM = [a-zA-Z_\?@][a-zA-Z\._0-9\?@]*

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
_ : {token, {'_',  TokenLine}}.
\# : {token, {'#',  TokenLine}}.
\| : {token, {'|',  TokenLine}}.
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
{RANGE} : {token, {'..', TokenLine}}.
{INT} : {token, {int,  TokenLine, list_to_integer(TokenChars)}}.
{ATOM} : {token, {atom, TokenLine, TokenChars}}.

Erlang code.
