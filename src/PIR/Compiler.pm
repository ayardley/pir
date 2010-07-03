class PIR::Compiler is HLL::Compiler;

INIT {
    PIR::Compiler.language('PIRATE');
    PIR::Compiler.parsegrammar(PIR::Grammar);
    PIR::Compiler.parseactions(PIR::Actions);
}

=begin
Emit PBC file.

Long explanation about it:
Currently there is no way in Parrot to generate Packfile and attach it
to Interp via existing API. This function is partially hack to generate
serialized PBC, load it back and execute it (modulus fix for TT#1685).

Best way to deal with such issues is:
1. Switch Interp to use Packfile* PMC internally.
2. Add API calls to attach freshly generated Packfile to current Interp.

Quick "fix" can be:
1. Add "PackFile_unpack_string" function which will accept STRING.
2. Expose this function via Interp (or Packfile PMC method).

Kind of wishful thinking, but we can fix it.

=end

our method pbc($post, *%adverbs) {
    #pir::trace(4);
    my $packfile := POST::Compiler.pbc($post, %adverbs);

    my $main_sub := $post<main_sub>;

    my $unlink;
    my $filename := ~%adverbs<output>;
    if !$filename {
        # TODO Add mkstemp into OS PMC.
        $filename := "/tmp/temp.pbc";
        $unlink   := 1;
    }

    my $handle := pir::new__Ps('FileHandle');
    $handle.open($filename, 'w');
    $handle.print(~$packfile);
    $handle.close();

    return sub() {
        #pir::trace(1);
        pir::load_bytecode($filename);

        #if $unlink {
        #    my $os := pir::new__PS("OS");
        #    $os.rm($filename);
        #}

        Q:PIR<
            %r = find_lex '$main_sub'
            $S99 = %r
            %r = find_sub_not_null $S99
            %r()
        >;
    };
}

our method post($source, *%adverbs) {
    $source.ast;
}

sub hash (*%result) { %result; }

our method eliminate_constant_conditional ($post, *%adverbs) {
    my $conditional_ops :=
        / [ eq | ne | lt | le | gt | ge ] /;
    my $nonpmc := / ic | nc | sc /;
    my $pattern :=
       POST::Pattern::Op.new(:pirop($conditional_ops),
                             POST::Pattern::Constant.new(:type($nonpmc)),
                             POST::Pattern::Constant.new(:type($nonpmc)),
                             POST::Pattern::Label.new);
    my %op_funcs := hash(:eq(sub ($l, $r) { pir::iseq__IPP($l, $r) }),
                         :ne(sub ($l, $r) { pir::isne__IPP($l, $r) }),
                         :lt(sub ($l, $r) { pir::islt__IPP($l, $r) }),
                         :le(sub ($l, $r) { pir::isle__IPP($l, $r) }),
                         :gt(sub ($l, $r) { pir::isgt__IPP($l, $r) }),
                         :ge(sub ($l, $r) { pir::isge__IPP($l, $r) }));
    my &eliminate := sub ($/) {
       my $condition := %op_funcs{$<pirop>.orig}($/[0].orig.value,
                                                 $/[1].orig.value);
       if $condition {
           return POST::Op.new(:pirop<branch>, $/[2].orig);
       }
       else {
           return POST::Op.new(:pirop<noop>);
       }
       $/.orig;
    };

    $pattern.transform($post, &eliminate);
}

method fold_arithmetic($post) {
    my $foldable_binary := / add | sub | mul | div | fdiv | mod /;
    my $non_pmc := / ic | nc /;
    my $binary_pattern :=
        POST::Pattern::Op.new(:pirop($foldable_binary),
                              POST::Pattern::Value.new,
                              POST::Pattern::Constant.new(:type($non_pmc)),
                              POST::Pattern::Constant.new(:type($non_pmc)));
    my %binary_funcs := 
        hash(:add(sub ($l, $r, $result_type) {
                    pir::add__PPP($l, $r);
                  }),
             :sub(sub ($l, $r, $result_type) {
                    pir::sub__PPP($l, $r);
                  }),
             :mul(sub ($l, $r, $result_type) {
                    pir::mul__PPP($l, $r);
                  }),
             :div(sub ($l, $r, $result_type) {
                    $result_type eq 'nc' ??
                    pir::div__NNN($l, $r) !!
                    pir::div__III($l, $r);
                  }),
             :fdiv(sub ($l, $r, $result_type) {
                    $result_type eq 'ic' ??
                    pir::fdiv__III($l, $r) !!
                    pir::fdiv__NNN($l, $r);
                  }),
             :mod(sub ($l, $r, $result_type) {
                    pir::mod__NNN($l, $r);
                  }));
    my &binary_fold := sub ($/) {
        my $op := $/.orig.pirop;
        my $result_type := 
            ($/[1].orig.type eq 'nc' || $/[2].orig.type eq 'nc'
             ?? 'nc'
             !! 'ic');
        my $val := %binary_funcs{$op}($/[1].orig.value,
                                      $/[2].orig.value,
                                      $result_type);
        POST::Op.new(:pirop<set>,
                     $/[0].orig,
                     POST::Constant.new(:value($val),
                                        :type($result_type)));
    };
    
    $post := $binary_pattern.transform($post, &binary_fold);

    my $foldable_unary := / abs /;
    my $unary_pattern :=
        POST::Pattern::Op.new(:pirop($foldable_unary),
                              POST::Pattern::Value.new,
                              POST::Pattern::Constant.new(:type($non_pmc)));

    my %unary_funcs :=
        hash(:abs(sub ($n) {
                      pir::abs__NN($n);
                 }));

    my &unary_fold := sub ($/) {
       my $op := $/.orig.pirop;
       my $val := %unary_funcs{$/.orig.pirop}($/[1].orig.value);
       POST::Op.new(:pirop<set>,
                    $/[0].orig,
                    POST::Constant.new(:type($/[1].orig.type),
                                       :value($val)));
    };

    $unary_pattern.transform($post, &unary_fold);
}

# vim: filetype=perl6:
