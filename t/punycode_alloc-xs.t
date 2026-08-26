use strict;
use warnings;

use Config;

use Test::More;
use Net::IDN::Punycode     ();
use Net::IDN::Punycode::PP ();

BEGIN {
    plan skip_all => 'no XS version' if eval {
        \&Net::IDN::Punycode::decode_punycode ==
          \&Net::IDN::Punycode::PP::decode_punycode;
    }
}

our $LEN;

BEGIN {
    # (len + 1) * sizeof(UV) wraps STRLEN on a 32-bit perl, so only an input
    # past the wrap point reaches the guard in decode_punycode. That is why
    # this test wants 512MB and skips everywhere else.
    plan skip_all => 'needs a 32-bit address space' if $Config{ptrsize} != 4;

    $LEN = int( 2**32 / $Config{uvsize} );

    my $free = 0;
    if ( open my $meminfo, "<", "/proc/meminfo" ) {
        my ($kb) = map /^MemAvailable:\s+(\d+)/, <$meminfo>;
        $free = ( $kb || 0 ) * 1024;
    }

    # a cgroup caps a container, whilst /proc/meminfo shows the host
    for my $cap ( "/sys/fs/cgroup/memory.max",
        "/sys/fs/cgroup/memory/memory.limit_in_bytes" )
    {
        open my $fh, "<", $cap or next;
        chomp( my $bytes = <$fh> );
        $free = $bytes if $bytes && $bytes =~ /^\d+$/ && $bytes < $free;
    }

    plan skip_all => "needs " . int( $LEN / 2**20 ) . "MB of free memory"
      if $free < $LEN * 1.2;
}

use Test::NoWarnings;

plan tests => 3;

my $label = "a" x $LEN;
substr( $label, -1, 1, "-" );    # in place, to hold one buffer only

is( eval { Net::IDN::Punycode::decode_punycode($label) },
    undef, "the code point buffer size wraps STRLEN (dies)" );
like(
    $@,
    qr/input too long/,
    "the code point buffer size wraps STRLEN (message)"
);
