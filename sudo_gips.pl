#!/usr/bin/perl

use strict;
use warnings;

# "sudo police" says:
my $msg = "\n*** You ran a shell with root privileges! Arrested! ***\n";

my $wait = 50 * 1000;
my $secure_log = '/var/log/secure';
my $target_user = $ARGV[0] || 'any';
my $target_tty = $ARGV[1] || 'any';


sub go_go_police
{
    my ( $user, $tty, $cmd ) = @_;
    my @result_str = ( 'kill ', '     ' );
    my $result;
    my @pids;
    system( "usleep $wait" );
    system( "echo \"$msg\" > /dev/$tty" );
    print STDERR "exec> ps\n";
    open( PPS, 'ps ao user,tty,pid,cmd |' );
    while ( <PPS> ) {
        my ( $ps_user, $ps_tty, $pid, $cmd ) = split( /\s+/ );
        if (( $ps_user eq 'root' ) && ( $ps_tty eq $tty )) {
            $result = 0;
            push( @pids, $pid );
        }
        else {
            $result = 1;
        }
        print STDERR $result_str[$result],  $_;
    }
    close( PPS );
    my $kill_cmd = 'kill -KILL ' . join( ' ', @pids );
    print STDERR 'exec>', $kill_cmd, "\n";
    system( $kill_cmd );

    my $now = localtime();
    print "$now: $user ran $cmd. (at $tty)\n";
}

open( PLOG, "tail -n 0 -f $secure_log |" );
while ( <PLOG> ) {
    next if ( index( $_, 'sudo' ) < 0 );
    if ( /sudo:\s+([^\s]+)\s+:\s+TTY=([^\s]+) / ) {
        my $user = $1;
        my $tty = $2;
        if ((( $target_user eq 'any' ) || ( $target_user eq $user ))
            && (( $target_tty eq 'any' ) || ( $target_tty eq $tty )))
        {
            print STDERR "find> sudo: user=$user, tty=$tty\n";
            if ( m{USER=root ; COMMAND=/(usr/)?bin/(su)(\s|$)} ) {
                &go_go_police( $user, $tty, $2 );
            }
            elsif ( m{USER=root ; COMMAND=/(usr/)?bin/(([a-z]{0,2})sh)(\s|$)} ) {
                &go_go_police( $user, $tty, $2 );
            }
        }
    }
}
