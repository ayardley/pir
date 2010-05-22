#
# PIR Grammar.
#
# I'm not going to implement pure PASM grammar. Only PIR with full sugar
# for PCC, etc.

class PIR::Grammar is HLL::Grammar;

# Top-level rules.
rule TOP {
    <compilation_unit>*
    [ $ || <panic: "Confused"> ]
}

proto token compilation_unit { <...> }

token compilation_unit:sym<sub> {
    <.newpad>
    '.sub' <.ws> <subname> [ <.ws> <sub_pragma> ]* <.nl>
    <statement_list>
    '.end' <.terminator>
}

token compilation_unit:sym<namespace> {
    '.namespace' <.ws> '[' <pir_key>? ']' <.terminator>
}

token compilation_unit:sym<loadlib> {
    '.loadlib' <.ws> <quote> <.terminator>
}

token compilation_unit:sym<HLL> {
    '.HLL' <.ws> <quote> <.terminator>
}

#token compilation_unit:sym<pragma> { }

proto regex sub_pragma { <...> }
token sub_pragma:sym<main>       { ':' <sym> }
token sub_pragma:sym<init>       { ':' <sym> }
token sub_pragma:sym<load>       { ':' <sym> }
token sub_pragma:sym<immediate>  { ':' <sym> }
token sub_pragma:sym<postcomp>   { ':' <sym> }
token sub_pragma:sym<anon>       { ':' <sym> }
token sub_pragma:sym<method>     { ':' <sym> }
token sub_pragma:sym<nsentry>    { ':' <sym> }

token sub_pragma:sym<vtable>     { ':' <sym> '(' <string_constant> ')' }
token sub_pragma:sym<outer>      { ':' <sym> '(' <string_constant> ')' }
token sub_pragma:sym<subid>      { ':' <sym> '(' <string_constant> ')' }

token sub_pragma:sym<multi>      { ':' <sym> '(' [<.ws><multi_type><.ws>] ** ',' ')' }

# TODO Do more strict parsing.
token multi_type {
    | '_'               # any
    | <quote>           # "Foo"
    | '[' <pir_key> ']' # ["Foo";"Bar"]
    | <ident>           # Integer
}

rule statement_list {
    | $
    | <statement>*
}

# Don't put newline here.
rule statement {
    | <pir_directive>
    | <labeled_instruction>
}

# Various .local, .lex, etc
proto regex pir_directive { <...> }
rule pir_directive:sym<local> {
    '.local' <pir_type> [<.ws><ident><.ws>] ** ',' <.nl>
}

rule pir_directive:sym<lex> {
    '.lex' <string_constant> ',' <pir_register> <.nl>
}

rule pir_directive:sym<const> {
    '.const' <const_declaration> <.nl>
}

rule pir_directive:sym<globalconst> {
    '.globalconst' <const_declaration> <.nl>
}

proto regex const_declaration { <...> }
rule const_declaration:sym<int> {
    <sym> <variable> '=' <int_constant>
}
rule const_declaration:sym<num> {
    <sym> <variable> '=' <float_constant>
}
rule const_declaration:sym<string> {
    <sym> <variable> '=' <string_constant>
}
# .const "Sub" foo = "sub_id"
rule const_declaration:sym<pmc> {
    <string_constant> <variable> '=' <string_constant>
}

rule pir_directive:sym<file> {
    '.file' <string_constant> <.nl>
}
rule pir_directive:sym<line> {
    '.line' <int_constant> <.nl>
}
rule pir_directive:sym<annotate> {
    '.annotate' <string_constant> ',' <constant> <.nl>
}

token labeled_instruction {
    <.ws> [ <label=ident> ':' <.ws>]? <op>? <.nl>
}

# raw pasm ops.
rule op {
    <op> [ <value> ** ',']?
}

token op {
    <ident> # TODO Check in OpLib
}

token value {
    | <constant>
    | <pir_register>
    | <variable>
}

token variable {
    <ident>  # TODO Check it in lexicals
}

token pir_type {
    | int
    | num
    | pmc
    | string
}

# Up to 100 registers
token pir_register {
    '$' <type=INSP> <digit>+
}

token INSP {
     I | N | S | P
}

token variable {
    | <pir_register>
    | <ident>
}

token subname {
    | <string_constant>
    | <ident>
}

token pod_comment {
    ^^ '=' <pod_directive>
    .* \n
    ^^ '=cut'
}

token terminator { $ | <.nl> }

rule pir_key { <quote> ** ';' }

token constant {
    | <int_constant>
    | <float_constant>
    | <string_constant>
}

token int_constant {
    | '0b' \d+
    | '0x' \d+
    | ['-']? \d+
}

token float_constant {
    ['-']? \d+\.\d+
}

# There is no iterpolation of strings in PIR
# TODO charset/encoding handling.
token string_constant { <quote> }

proto token quote { <...> }
token quote:sym<apos> { <?[']> <quote_EXPR: ':q'>  }
token quote:sym<dblq> { <?["]> <quote_EXPR: ':q'> }

# Don't be very strict on pod comments (for now?)
token pod_directive { <ident> }

token nl { \v+ }

# Any "whitespace" including pod comments
token ws {
    <!ww>
        [
        | ^^ \v+ # newlines accepted only by themselfs
        | '#' \N*
        | ^^ <.pod_comment>
        | \h+
        ]*
}

# Special rule to push new Lexpad.
token newpad { <?> } # always match.

# vim: ft=perl6

