#!/usr/bin/perl
print "$_=$ENV{$_}\n" foreach ( sort keys %ENV );
