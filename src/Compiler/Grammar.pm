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

#token sub_pragma:sym<multi>      { ':' <sym> '(' <key> ')' }


rule statement_list {
    | $
    | <statement>*
}

# Don't put newline here.
rule statement {
    | <pir_directive>
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
proto token string_constant { <...> }
token string_constant:sym<apos> { <?[']> <quote_EXPR: ':q'>  }
token string_constant:sym<dblq> { <?["]> <quote_EXPR: ':q'> }

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

