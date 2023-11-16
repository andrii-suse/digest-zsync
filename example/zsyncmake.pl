use strict;
use warnings;

use Digest::Zsync;

use File::stat;

my $f = shift || '~/example.iso';

open my $fh, "<", $f or die "Unable to open $f!";

my $stat = stat($fh);
my $size = $stat->size;
my $mtime = $stat->mtime;
my $zsync = Digest::Zsync->new->init($size);

my $buffer_size = $zsync->{block_size};
my $buffer;

while (read $fh, $buffer, $buffer_size) {
        $zsync->add($buffer);
}
close $fh;

my $zlengths = $zsync->lengths;

my $header = <<"EOT";
zsync: 0.6.2-perl-digest-zsync
Filename: $f
MTime: $mtime
Blocksize: $buffer_size
Length: $size
Hash-Lengths: $zlengths
EOT

print $header;
print "\n";
print $zsync->digest;
