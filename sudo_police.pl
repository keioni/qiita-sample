#!/usr/bin/perl

use strict;
use warnings;

# police says:
my $msg = "\n*** You ran a shell with root privileges! Arrested! ***\n";

my $secure_log = '/var/log/secure';
if ( defined $ARGV[0] ) {
    $secure_log = $ARGV[0];
}

sub go_go_police
{
    my $user = shift;
    my $tty = shift;
    my $cmd = shift;
    system( "usleep 100; echo \"$msg\" > /dev/$tty" );
    open( FPS, "ps au | grep $tty |");
    while ( <FPS> ) {
        if ( /^root\s+([0-9]+)\s+/ ) {
            system( "kill -KILL $1" );
        }
    }
    my $now = localtime();
    print "$now: $user uses $cmd.\n";
}

open(FLOG, "/bin/tail -f $secure_log |");
while ( <FLOG> ) {
    if ( /sudo:\s+([^ ]+) : TTY=([^ ]+) / ) {
        my $user = $1;
        my $tty = $2;
        if ( m{; USER=root ; COMMAND=/bin/su\s*$} ) {
            &go_go_police($user, $tty, 'su');
        }
        elsif ( m{; USER=root ; COMMAND=/(usr/)?bin/((a|k|ba|tc|c|z|)sh)(\s|$)} ) {
            &go_go_police($user, $tty, $2);
        }
    }
}
