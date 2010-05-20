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
    '.sub' <.ws> <subname> <.nl>
    '.end' <.terminator>
}

#token compilation_unit:sym<pragma> { }

rule statement_list {
    | $
    | <statement>*
}

# Don't put newline here.
rule statement {
    <EXPR>
}

token terminator {
    | $
    | \n
}

token subname {
    [
    | <string_constant>
    | <ident>
    ]
}


token pod_comment {
    ^^ '=' <pod_directive>
    .* \n
    ^^ '=cut'
}

# There is no iterpolation of strings in PIR
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
