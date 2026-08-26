use strict;
use utf8;
use warnings;

use Test::More;
use Net::IDN::Punycode::PP ();

use Test::NoWarnings;

our @encode_dies = (
    [
        "a" . chr(0xFFFFFFFF),
        qr/exceeds punycode limit/,
        "encoding overflows the delta accumulator"
    ],
    [
        ( "a" x 4368 ) . chr(983183),
        qr/exceeds punycode limit/,
        "the skipped basic code points overflow the delta accumulator"
    ],
    [
        ( "a" x 3855 ) . chr(0x10FFFF),
        qr/exceeds punycode limit/,
        "a long basic prefix overflows the delta accumulator"
    ],
);

our @decode_dies = (
  ["NMzZNlL6SU", qr/incomplete encoded code point/,
    "truncated label without a delimiter"],
  ["abc-td", qr/incomplete encoded code point/,
    "truncated label after base characters"],
  ["z", qr/incomplete encoded code point/,
    "single digit ending mid code point"],
  ["a-99999999999999999999", qr/exceeds punycode limit/,
    "digit weight overflows"],
  ["a-kk503321e", qr/exceeds punycode limit/,
    "delta accumulator overflows"],
  ["a-j023p", qr/invalid code point/,
    "decodes just above U+10FFFF"],
  [("a" x 3900)."-2x485856a", qr/exceeds punycode limit/,
    "a label only an unguarded encoder could produce"],
);

plan tests => 1
  + 2 * (scalar @encode_dies)
  + 2 * (scalar @decode_dies);

foreach my $test (@encode_dies) {
    my ( $input, $message, $comment ) = @{$test};

    is( eval { Net::IDN::Punycode::PP::encode_punycode($input) },
        undef, $comment . ' (encode_punycode dies)' );
    like( $@, $message, $comment . ' (encode_punycode message)' );
}

foreach my $test (@decode_dies)
{
  my ($label, $message, $comment) = @{$test};

  is(eval { Net::IDN::Punycode::PP::decode_punycode($label) }, undef,
    $comment.' (decode_punycode dies)');
  like($@, $message, $comment.' (decode_punycode message)');
}
