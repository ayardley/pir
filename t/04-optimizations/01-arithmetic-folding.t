#! /usr/bin/env parrot-nqp

pir::load_bytecode('t/common.pbc');

run_post_tests_from_datafile('t/optimizations/arithmetic-folding.txt');