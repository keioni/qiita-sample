#!/usr/bin/perl

if ( $ENV{DOCUMENT_ROOT} =~ m|^(/home/([^/]+))/| ) {
    $ENV{HOME} = $1;
    $ENV{USER} = $2;
}
my $qs = $ENV{QUERY_STRING} if ( $ENV{QUERY_STRING} =~ m|^[a-zA-Z0-9\._-]+$| );

open(FIN, '<', '.htaccess');
while ( <FIN> ) {
    chomp;
    s/^\s*//;
    my @items = split(/\s+/);
    if ( $items[0] eq 'SetEnv' ) {
        $ENV{$items[1]} = $items[2];
    }
}
close(FIN);
print "Content-Type: text/plain\n\n";

exec("./$qs")
