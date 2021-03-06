# Copyright (C) 2007-2008, Parrot Foundation.

#.HLL 'parrot'
.loadlib 'pirate_ops'

.namespace ['PackfileBytecodeSegment']
.sub 'push' :method
    .param pmc value
    push self, value
.end

.sub 'at' :method
    .param int key
    $I0 = self[key]
    .return ($I0)
.end

.namespace ['PackfileConstantTable']
.sub 'push' :method
    .param pmc value
    $I0 = self.'pmc_count'()
    push self, value
    .return($I0)
.end

.namespace ['StringBuilder']
.sub 'push' :method
    .param string value
    push self, value
.end


.namespace ['PackfileConstantTable']
.sub 'get_or_create_string' :method
    .param string str
    $I0 = self.'get_or_create_constant'(str)
    .return ($I0)
.end

.sub 'get_or_create_number' :method
    .param num n
    $I0 = self.'get_or_create_constant'(n)
    .return ($I0)
.end

.sub 'get_or_create_pmc' :method
    .param pmc p
    $I0 = self.'get_or_create_constant'(p)
    .return ($I0)
.end


.namespace ['FixedIntegerArray']
.sub 'elements' :vtable('get_number') :method
    $I0 = self
    .return ($I0)
.end

.namespace ['Key']
.sub 'set_str' :method
    .param string s
    self = s
    .return ()
.end

.sub 'set_int' :method
    .param int i
    self = i
    .return ()
.end

.sub 'push' :method
    .param pmc p
    push self, p
    .return()
.end

.namespace ['Opcode']
.sub 'length' :vtable('get_number') :method
    $I0 = elements self
    .return ($I0)
.end

# We can't use NQP for dynamically loaded stuff... It's broken somehow.
.namespace []


.sub "register_hll_lib"
    .param string lib
    register_hll_lib lib
.end

.sub "defined"
    .param pmc arg
    $I0 = defined arg
    .return ($I0)
.end

.sub "new" :multi(_)
    .param string what
    $P0 = new what
    .return ($P0)
.end

.sub "new" :multi(_,_)
    .param string what
    .param pmc    how
    $P0 = new what, how
    .return ($P0)
.end


=head1 LICENSE

Copyright (C) 2011, Parrot Foundation.

This is free software; you may redistribute it and/or modify
it under the same terms as Parrot.

=cut

# Local Variables:
#   mode: pir
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4 ft=pir:
