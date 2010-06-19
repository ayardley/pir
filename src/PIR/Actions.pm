#
# PIR Actions.
#
# I'm not going to implement pure PASM grammar. Only PIR with full sugar
# for PCC, etc.

class PIR::Actions is HLL::Actions;

has $!BLOCK;
has $!MAIN;

INIT {
    pir::load_bytecode("nqp-setting.pbc");
}

method TOP($/) { make $<top>.ast; }

method top($/) {
    my $past := POST::Node.new;
    for $<compilation_unit> {
        my $child := $_.ast;
        $past.push($child) if $child;
    }

    # Remember :main sub.
    $past<main_sub> := $!MAIN;

    make $past;
}

method compilation_unit:sym<.HLL> ($/) {
    our $*HLL := $<quote>.ast<value>;
}

method compilation_unit:sym<.namespace> ($/) {
    our $*NAMESPACE := $<namespace_key>[0] ?? $<namespace_key>[0].ast !! undef;
}

method newpad($/) {
    $!BLOCK := POST::Sub.new(
    );
}

method compilation_unit:sym<sub> ($/) {
    my $name := $<subname>.ast;
    $!BLOCK.name( $name );

    # TODO Handle pragmas.

    # TODO Handle :main pragma
    $!MAIN := $name unless $!MAIN;

    if $<statement> {
        for $<statement> {
            my $past := $_.ast;
            $!BLOCK.push( $past ) if $past;
        }
    }

    make $!BLOCK;
}

method param_decl($/) {
    my $name := ~$<name>;
    my $past := POST::Register.new(
        :name($name),
        :type(pir::substr__SSII(~$<pir_type>, 0, 1)),
        :declared(1),
    );

    if $!BLOCK.symbol($name) {
        $/.CURSOR.panic("Redeclaration of varaible '$name'");
    }

    $!BLOCK.symbol($name, $past);

    make $past;
}

method statement($/) {
    make $<pir_directive> ?? $<pir_directive>.ast !! $<labeled_instruction>.ast;
}

method labeled_instruction($/) {
    # TODO Handle C<label> and _just_ label.
    my $child := $<pir_instruction>[0] // $<op>[0]; # // $/.CURSOR.panic("NYI");
    make $child.ast if $child;
}

method op($/) {
    my $past := POST::Op.new(
        :pirop(~$<name>),
    );

    for $<op_params> {
        $past.push( $_.ast );
    }

    self.validate_registers($/, $past);

    # TODO Validate via OpLib

    make $past;
}

method op_params($/) { make $<value>[0] ?? $<value>[0].ast !! $<pir_key>[0].ast }

method pir_directive:sym<.local>($/) {
    my $type := pir::substr__SSII(~$<pir_type>, 0, 1);
    for $<ident> {
        my $name := ~$_;
        if $!BLOCK.symbol($name) {
            $/.CURSOR.panic("Redeclaration of varaible '$name'");
        }

        my $past := POST::Register.new(
            :name($name),
            :type($type),
            :declared(1),
        );
        $!BLOCK.symbol($name, $past);
    }

}
#rule pir_directive:sym<.lex>        { <sym> <string_constant> ',' <pir_register> }
#rule pir_directive:sym<.file>       { <sym> <string_constant> }
#rule pir_directive:sym<.line>       { <sym> <int_constant> }
#rule pir_directive:sym<.annotate>   { <sym> <string_constant> ',' <constant> }
#rule pir_directive:sym<.include>    { <sym> <quote> }

# PCC
#rule pir_directive:sym<.begin_call>     { <sym> }
#rule pir_directive:sym<.end_call>       { <sym> }
#rule pir_directive:sym<.begin_return>   { <sym> }
#rule pir_directive:sym<.end_return>     { <sym> }
#rule pir_directive:sym<.begin_yield>    { <sym> }
#rule pir_directive:sym<.end_yield>      { <sym> }

#rule pir_directive:sym<.call>       { <sym> <value> [',' <continuation=pir_register> ]? }
#rule pir_directive:sym<.meth_call>  { <sym> <value> [',' <continuation=pir_register> ]? }
#rule pir_directive:sym<.nci_call>   { <sym> <value> [',' <continuation=pir_register> ]? }

#rule pir_directive:sym<.invocant>   { <sym> <value> }
#rule pir_directive:sym<.set_arg>    { <sym> <value> <arg_flag>* }
#rule pir_directive:sym<.set_return> { <sym> <value> <arg_flag>* }
#rule pir_directive:sym<.set_yield>  { <sym> <value> <arg_flag>* }
#rule pir_directive:sym<.get_result> { <sym> <value> <result_flag>* }

#rule pir_directive:sym<.return>     { <sym> '(' <args>? ')' }
#rule pir_directive:sym<.yield>      { <sym> '(' <args>? ')' }

#rule pir_directive:sym<.tailcall>   { <sym> <call> }

method pir_directive:sym<.const>($/) {
    my $past := $<const_declaration>.ast;
    my $name := $past.name;
    if $!BLOCK.symbol($name) {
        $/.CURSOR.panic("Redeclaration of varaible '$name'");
    }
    $!BLOCK.symbol($name, $past);
}

#rule pir_directive:sym<.globalconst> { <sym> <const_declaration> }

method const_declaration:sym<int>($/) {
    my $past := $<int_constant>.ast;
    $past.name(~$<ident>);
    make $past;
}

method const_declaration:sym<num>($/) {
    my $past := $<float_constant>.ast;
    $past.name(~$<ident>);
    make $past;
}

method const_declaration:sym<string>($/) {
    my $past := $<string_constant>.ast;
    $past.name(~$<ident>);
    make $past;
}



#rule pir_instruction:sym<call>
method pir_instruction:sym<call>($/) {
    make $<call>.ast;
}

#rule pir_instruction:sym<call_assign>
#rule pir_instruction:sym<call_assign_many>


# Short PCC call.
#proto regex call { <...> }
#rule call:sym<pmc>     { <variable> '(' <args>? ')' }
#rule call:sym<sub>     { <quote> '(' <args>? ')' }
method call:sym<sub>($/) {
    my $past := POST::Call.new(
        :name($<quote>.ast),
    );

    make $past;
}

#rule call:sym<dynamic> { <value> '.' <variable> '(' <args>? ')' }
#rule call:sym<method>  { <value> '.' <quote> '(' <args>? ')' }


#rule args { <arg> ** ',' }

#rule arg {
#    | <quote> '=>' <value>
#    | <value> <arg_flag>*
#}

method arg($/) {
    # TODO Handle flags
    make $<value>.ast;
}

method value($/) { make $<constant> ?? $<constant>.ast !! $<variable>.ast }

method constant($/) {
    my $past;
    if $<int_constant> {
        $past := $<int_constant>.ast;
    }
    elsif $<float_constant> {
        $past := $<float_constant>.ast;
    }
    else {
        $past := $<string_constant>.ast;
    }
    make $past;
}

method int_constant($/) {
    make POST::Constant.new(
        :type<ic>,
        :value(~$/),
    );
}

method float_constant($/) {
    make POST::Constant.new(
        :type<nc>,
        :value(~$/),
    );
}

method string_constant($/) {
    make POST::Constant.new(
        :type<sc>,
        :value($<quote>.ast<value>),
    );
}

method variable($/) {
    my $past;
    if $<ident> {
        # Named register
        $past := POST::Value.new(
            :name(~$<ident>),
        );
    }
    else {
        # Numbered register
        my $type := ~$<pir_register><INSP>;
        my $name := '$' ~ $type ~ ~$<pir_register><reg_number>;
        $past := POST::Value.new(
            :name($name),
            :type(pir::downcase__SS($type)),
        );
    }

    make $past;
}

method subname($/) {
    make $<ident> ?? ~$<ident> !! ~($<quote>.ast<value>);
}

method quote:sym<apos>($/) { make $<quote_EXPR>.ast; }
method quote:sym<dblq>($/) { make $<quote_EXPR>.ast; }

method validate_registers($/, $node) {
    for @($node) -> $arg {
        my $name;
        try {
            # XXX Constants doesn't have names. But pir::isa__IPP doesn't wor either
            $name := $arg.name;
        };
        if $name {
            if pir::substr__SSII($name, 0, 1) eq '$' {
                $!BLOCK.symbol($name, POST::Register.new(
                        :name($name),
                        :type($arg.type),
                    ));
            }
            elsif !$!BLOCK.symbol($name) {
                $/.CURSOR.panic("Register '" ~ $name ~ "' not predeclared");
            }
        }
    }
}

# vim: ft=perl6
