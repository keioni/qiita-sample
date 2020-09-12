#!/usr/bin/perl

use strict;
use warnings;
use Time::HiRes qw(usleep);

# "sudo police" says:
my $msg = "\n*** You ran a shell with root privileges! Arrested! ***\n";

my $wait = 50 * 1000;
my $secure_log = '/var/log/secure';
my $target_user = $ARGV[0] || 'any';
my $target_tty = $ARGV[1] || 'any';

sub arrest
{
    my ( $user, $tty, $cmd ) = @_;
    my $result;
    my @pids;

    # shell が起動する時間を待つ
    # 環境によるので $wait で調整する
    usleep( $wait );

    # 指定の tty にメッセージを送信する
    open( PTTY, '>>', "/dev/$tty" );
    print PTTY $msg;
    close( PTTY );

    # ps コマンドの結果をもとに kill するプロセスを拾う
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
        print STDERR (( 'kill ', '     ' )[$result]),  $_;
    }
    close( PPS );

    # 拾ったプロセスを kill する
    print STDERR 'exec> kill ', join( ' ', @pids ), "\n";
    kill( 'KILL', @pids );

    # 実行結果を標準出力に出力する
    my $now = localtime();
    print "$now: $user ran $cmd. (at $tty)\n";
}

sub inspect_log
{
    my ( $user, $tty ) = @_;

    # 引数で指定したユーザ、tty のものだけを拾い上げる
    # 同じ行から実行するコマンドも拾い上げる
    if ((( $target_user eq 'any' ) || ( $target_user eq $user ))
        && (( $target_tty eq 'any' ) || ( $target_tty eq $tty )))
    {
        print STDERR "find> sudo: user=$user, tty=$tty\n";
        if ( m{USER=root ; COMMAND=/(usr/)?bin/(su)(\s|$)} ) {
            # コマンドが su の場合
            return $2;
        }
        elsif ( m{USER=root ; COMMAND=/(usr/)?bin/(([a-z]{0,2})sh)(\s|$)} ) {
            # コマンドが shell の場合 (sudo -s)
            return $2;
        }
    }
    return;
}

sub watch_logs
{
    open( PLOG, "tail -n 0 -f $secure_log |" );
    while ( <PLOG> ) {
        # /var/log/secure には sudo 以外のログも含まれる
        # sudo のログだけ拾いたいが正規表現は重いので、まず index で選別する
        next if ( index( $_, 'sudo:' ) < 0 );

        # sudo のログを parse する
        if ( /sudo:\s+([^\s]+)\s+:\s+TTY=([^\s]+) / ) {
            my $user = $1;
            my $tty = $2;
            my $cmd = &inspect_log( $user, $tty );
            if ( $cmd ) {
                # コマンドが su または shellの場合 kill する
                &arrest( $user, $tty, $cmd );
            }
        }
    }
    close( PLOG );
}

&watch_logs()
