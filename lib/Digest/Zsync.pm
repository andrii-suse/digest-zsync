package Digest::Zsync;

use strict;
use Digest::MD4;
use bytes;

use Digest::Zsync::XS;

BEGIN { our $VERSION = 0.01 }

my $BLOCK_SIZE  = 2048;
my $SEQ_MATCHES = 1;
my $RSUM_LEN    = 2;
my $CHECKSUM_LEN = 3;

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my $self = {};
    bless $self, $class;
    $self->{block_size}   = $BLOCK_SIZE;
    $self->{seq_matches}  = $SEQ_MATCHES;
    $self->{rsym_len}     = $RSUM_LEN;
    $self->{checksum_len} = $CHECKSUM_LEN;
    return $self;
}

sub digest {
    my $self = shift;
    my $arr = $self->{hashes};
    my @arr = @$arr;
    join '', @arr;
}

sub init {
    my ($self, $size) = @_;
    $self->{block_size}   //= $BLOCK_SIZE;
    $self->{seq_matches}  //= $SEQ_MATCHES;
    $self->{rsym_len}     //= $RSUM_LEN;
    $self->{checksum_len} //= $CHECKSUM_LEN;

    $self->{block_size} = 4096   if $size > 100000000; # default behavior of zsyncmake
    $self->{block_size} = 2*4096 if $size > 1024*1024*1024;
    $self->{block_size} = 4*4096 if $size > 1024*1024*1024*16;

    $self->{seq_matches} = 2 if $size >= $self->{block_size};
    my $rsum_len = int(0.99 + ((log($size // 1) + log($self->{block_size})) / log(2) - 8.6) / $self->{seq_matches} / 8);
    $rsum_len = 4 if $rsum_len > 4;
    $rsum_len = 2 if $rsum_len < 2;
    $self->{rsum_len} = $rsum_len;
    my $checksum_len = int(0.99 +
                (20 + (log($size // 1) + log(1 + $size / $self->{block_size})) / log(2))
                / $self->{seq_matches} / 8);

    my $checksum_len2 = int((7.9 + (20 + log(1 + $size / $self->{block_size}) / log(2))) / 8);
    $checksum_len = $checksum_len2 if $checksum_len < $checksum_len2;
    $self->{checksum_len} = $checksum_len;

    my @hashes;
    $self->{hashes} = \@hashes;

    return $self;
}

sub add {
    my ($self, $data) = @_;
    my $zhashes = $self->{hashes};
    my $block_size = $self->{block_size};
    use bytes;
    while (length($data)) {
        (my $block, $data) = unpack("a${block_size}a*", $data);
        my $diff = $block_size - length($block);
        $block .= (chr(0) x $diff) if $diff;
        push @$zhashes, Digest::Zsync::XS::rsum06($block, $block_size, $self->{rsum_len});
        push @$zhashes, substr(Digest::MD4::md4($block),0,$self->{checksum_len});
    }
    no bytes;
    return $self;
}

sub lengths {
    my $self = shift;
    return $self->{seq_matches} . ',' . $self->{rsum_len} . ',' . $self->{checksum_len};
}

1;
