Definitions.

WHITESPACE=[\s\t\r\n]+
INT = [0-9]+
ATOM = [a-zA-Z0-9\._]+

Rules.

{WHITESPACE} : skip_token.

nil : {token, {'nil', TokenLine}}.
fun\( : {token, {'fun(',  TokenLine}}.
\[ : {token, {'[',  TokenLine}}.
\] : {token, {']',  TokenLine}}.
\( : {token, {'(',  TokenLine}}.
\) : {token, {')',  TokenLine}}.
\{ : {token, {'{',  TokenLine}}.
\} : {token, {'}',  TokenLine}}.
_ : {token, {'_',  TokenLine}}.
\# : {token, {'#',  TokenLine}}.
\| : {token, {'|',  TokenLine}}.
\:\= : {token, {':=',  TokenLine}}.
\=\> : {token, {'=>',  TokenLine}}.
\-\> : {token, {'->',  TokenLine}}.
\| : {token, {'|',  TokenLine}}.
\' : {token, {'\'',  TokenLine}}.
, : {token, {',',  TokenLine}}.
\.\. : {token, {'..', TokenLine}}.
{INT} : {token, {int,  TokenLine, list_to_integer(TokenChars)}}.
{ATOM} : {token, {atom, TokenLine, TokenChars}}.

Erlang code.
