use v6;

use Test;

plan(2);

unless (try { EVAL("1", :lang<perl5>) }) {
    skip_rest;
    exit;
}

{
    lives_ok {
        EVAL q|
            use Digest::MD5:from<Perl5>;
            my $d = Digest::MD5.new;
            is $d.isa(Digest::MD5), 1, "Correct isa";
            $d.add('foo'.encode('UTF-8'));
            is $d.hexdigest, 'acbd18db4cc2f85cedef654fccc4a4d8';
        |
        or die $!;
    }, "CLASS:from<Perl5>.new";
}

# vim: ft=perl6
