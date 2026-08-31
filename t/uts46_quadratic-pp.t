use strict;
use warnings;

use Test::More;

BEGIN { $Net::IDN::Punycode::_NO_XS = 1 }

use Net::IDN::Punycode     ();
use Net::IDN::Punycode::PP ();

BEGIN {
    plan skip_all => 'XS version loaded despite $_NO_XS' if !eval {
        \&Net::IDN::Punycode::encode_punycode ==
          \&Net::IDN::Punycode::PP::encode_punycode;
    }
}

use Test::NoWarnings;
use Net::IDN::UTS46 ();

plan tests => 1 + 1;

## every code point assigned in Unicode 10.0 and valid under UTS #46
our $label =
  join( '', map chr, 0x3400 .. 0x4DB5, 0x4E00 .. 0x9FEA, 0x20000 .. 0x2A6D6 ) x
  3;

SKIP: {
    my $pid = fork;
    skip 'cannot fork', 1 if !defined $pid;

    if ( !$pid ) {
        close STDERR;
        $SIG{__WARN__} =
          sub { };    # Test::NoWarnings keeps a backtrace per warning
        alarm 10;
        eval { Net::IDN::UTS46::uts46_to_ascii($label) };
        exit 0;
    }

    waitpid( $pid, 0 );
    is(
        $? & 127,
        0,
        'an overlong label of distinct code points'
          . ' (to_ascii rejects it before encoding)'
    );
}
