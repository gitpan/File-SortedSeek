# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "Testing 1..40\n"; }
END {print "1  Module failed to load not ok\n" unless $loaded;}
# use lib '.'; use Seek;
use File::SortedSeek;
$loaded = 1;
print "1  Module loaded ok\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

use strict;
#use warnings;
$|++;
my $file = './test.file';
my ( $test, $ok, $tell, $begin, $finish, $line, $got, $want, @data, @lines, @between );
File::SortedSeek::set_silent; # silence warnings to std err to avoid duplicates
$test++; $ok ++;
#################### numeric ascending tests ####################

@data = ( 0 .. 1000 );
write_file ( @data );
open TEST, "<$file" or die "Can't read from test file $!\n";

# basic seek
printf "%-2d ", ++$test;
$tell = File::SortedSeek::numeric( *TEST, 42 );
chomp ( $line = <TEST> );
if ( $line eq $data[42] ) {
    print  "Numeric (asc) ok 1\n" ;
    $ok++;
}
else {
    print  "Numeric (asc) not ok 1 ".File::SortedSeek::error."\n";;
}

# check default no cuddle
printf "%-2d ", ++$test;
$tell = File::SortedSeek::numeric( *TEST, 41.5 );
chomp ( $line = <TEST> );
if ( $line eq '42' ) {
    print  "Numeric (asc) ok 2\n" ;
    $ok++;
}
else {
    print  "Numeric (asc) not ok 2 ".File::SortedSeek::error."\n";;
}

# cuddle
printf "%-2d ", ++$test;
File::SortedSeek::set_cuddle;
$tell = File::SortedSeek::numeric( *TEST, 41.5 );
chomp ( $line = <TEST> );
if ( $line eq '41' ) {
    print  "Numeric (asc) ok 3\n" ;
    $ok++;
}
else {
    print  "Numeric (asc) not ok 3 ".File::SortedSeek::error."\n";;
}

File::SortedSeek::set_no_cuddle;

# check between
printf "%-2d ", ++$test;
$begin  = File::SortedSeek::numeric( *TEST, 941.5 );
$finish = File::SortedSeek::numeric( *TEST, 943.5 );
@between = File::SortedSeek::get_between( *TEST, $begin, $finish );
$got = join " ", @between;
if ( $got eq '942 943' ) {
    print  "Numeric (asc) ok 4\n" ;
    $ok++;
}
else {
    print  "Numeric (asc) not ok 4 ".File::SortedSeek::error."\n";;

}

# need to close and reopen FH now binmoded.
close TEST; 
open TEST, "<$file" or die "Can't read from test file $!\n";

# should find first line
printf "%-2d ", ++$test;
$tell = File::SortedSeek::numeric( *TEST, -1 );
chomp ( $line = <TEST> );
if ( $line eq '0' ) {
    print  "Numeric (asc) ok 5\n" ;
    $ok++;
}
else {
    print  "Numeric (asc) not ok 5 ".File::SortedSeek::error."\n";;
}

# generate not found error
printf "%-2d ", ++$test;
$tell = File::SortedSeek::numeric( *TEST, 1001 );
if ( !defined $tell ) {
    print  "Numeric (asc) ok 6\n" ;
    $ok++;
}
else {
    print  "Numeric (asc) not ok 6 ".File::SortedSeek::error."\n";;
}

close TEST;

#################### numeric descending tests ####################

@data = reverse ( 1 .. 1000 );
write_file ( @data );
open TEST, "<$file" or die "Can't read from test file $!\n";

File::SortedSeek::set_descending; # set mode to descending

# basic seek
printf "%-2d ", ++$test;
$tell = File::SortedSeek::numeric( *TEST, 42 );
chomp ( $line = <TEST> );
if ( $line eq $data[-42] ) {
    print  "Numeric (desc) ok 1\n" ;
    $ok++;
}
else {
    print  "Numeric (desc) not ok 1 ".File::SortedSeek::error."\n";;
}

# check default no cuddle
printf "%-2d ", ++$test;
$tell = File::SortedSeek::numeric( *TEST, 42.5 );
chomp ( $line = <TEST> );
if ( $line eq '42' ) {
    print  "Numeric (desc) ok 2\n" ;
    $ok++;
}
else {
    print  "Numeric (desc) not ok 2 ".File::SortedSeek::error."\n";;
}

# cuddle
printf "%-2d ", ++$test;
File::SortedSeek::set_cuddle;
$tell = File::SortedSeek::numeric( *TEST, 41.5 );
chomp ( $line = <TEST> );
if ( $line eq '42' ) {
    print  "Numeric (desc) ok 3\n" ;
    $ok++;
}
else {
    print  "Numeric (desc) not ok 3 ".File::SortedSeek::error."\n";;
}

File::SortedSeek::set_no_cuddle;

# get range
printf "%-2d ", ++$test;
$begin  = File::SortedSeek::numeric( *TEST, 943.5 );
$finish = File::SortedSeek::numeric( *TEST, 941.5 );
@between = File::SortedSeek::get_between( *TEST, $begin, $finish );
$got = join " ", @between;
if ( $got eq '943 942' ) {
    print  "Numeric (desc) ok 4\n" ;
    $ok++;
}
else {
    print  "Numeric (desc) not ok 4 ".File::SortedSeek::error."\n";;
}

# need to close and reopen FH now binmoded.
close TEST; 
open TEST, "<$file" or die "Can't read from test file $!\n";

# should find first line
printf "%-2d ", ++$test;
$tell = File::SortedSeek::numeric( *TEST, 1001 );
chomp ( $line = <TEST> );
if ( $line eq '1000' ) {
    print  "Numeric (desc) ok 5\n" ;
    $ok++;
}
else {
    print  "Numeric (desc) not ok 5 ".File::SortedSeek::error."\n";;
}

# generate not found error
printf "%-2d ", ++$test;
$tell = File::SortedSeek::numeric( *TEST, -1 );
if ( !defined $tell ) {
    print  "Numeric (desc) ok 6\n" ;
    $ok++;
}
else {
    print  "Numeric (desc) not ok 6 ".File::SortedSeek::error."\n";;
}

File::SortedSeek::set_ascending; # reset mode to ascending
close TEST;

#################### alphabetic ascending tests ####################

@data =  ( 'AAA' .. 'ZZZ' );
write_file ( @data );
open TEST, "<$file" or die "Can't read from test file $!\n";

# basic SortedSeek
printf "%-2d ", ++$test;
$tell = File::SortedSeek::alphabetic( *TEST, 'BBB' );
chomp ( $line = <TEST> );
if ( $line eq 'BBB' ) {
    print  "Alphabetic (asc) ok 1\n" ;
    $ok++;
}
else {
    print  "Alphabetic (asc) not ok 1 ".File::SortedSeek::error."\n";
}

# check default no cuddle
printf "%-2d ", ++$test;
$tell = File::SortedSeek::alphabetic( *TEST, 'TTTTest' );
chomp ( $line = <TEST> );
if ( $line eq 'TTU' ) {
    print  "Alphabetic (asc) ok 2\n" ;
    $ok++;
}
else {
    print  "Alphabetic (asc) not ok 2 ".File::SortedSeek::error."\n";
}

# cuddle
printf "%-2d ", ++$test;
File::SortedSeek::set_cuddle;
$tell = File::SortedSeek::alphabetic( *TEST, 'TTTTest' );
chomp ( $line = <TEST> );
if ( $line eq 'TTT' ) {
    print  "Alphabetic (asc) ok 3\n" ;
    $ok++;
}
else {
    print  "Alphabetic (asc) not ok 3 ".File::SortedSeek::error."\n";
}

File::SortedSeek::set_no_cuddle;

# check between
printf "%-2d ", ++$test;
$begin  = File::SortedSeek::alphabetic( *TEST, 'ABA' );
$finish = File::SortedSeek::alphabetic( *TEST, 'ABBA' );
@between = File::SortedSeek::get_between( *TEST, $begin, $finish );
$got = join " ", @between;
if ( $got eq 'ABA ABB' ) {
    print  "Alphabetic (asc) ok 4\n" ;
    $ok++;
}
else {
    print  "Alphabetic (asc) not ok 4 ".File::SortedSeek::error."\n";
}

# need to close and reopen FH now binmoded.
close TEST; 
open TEST, "<$file" or die "Can't read from test file $!\n";

# should get first line
printf "%-2d ", ++$test;
$tell = File::SortedSeek::alphabetic( *TEST, 'A' );
chomp ( $line = <TEST> );
if ( $line eq 'AAA' ) {
    print  "Alphabetic (asc) ok 5\n" ;
    $ok++;
}
else {
    print  "Alphabetic (asc) not ok 5 ".File::SortedSeek::error."\n";
}

# past EOF, should return undef
printf "%-2d ", ++$test;
$tell = File::SortedSeek::alphabetic( *TEST, 'ZZZZ' );
if ( !defined $tell ) {
    print  "Alphabetic (asc) ok 6\n" ;
    $ok++;
}
else {
    print  "Alphabetic (asc) not ok 6 ".File::SortedSeek::error."\n";
}

close TEST;

#################### alphabetic descending tests ####################

@data =  reverse ( 'AAA' .. 'ZZZ' );
write_file ( @data );
open TEST, "<$file" or die "Can't read from test file $!\n";

File::SortedSeek::set_descending; # set mode to descending

# basic seek
printf "%-2d ", ++$test;
$tell = File::SortedSeek::alphabetic( *TEST, 'BBB' );
chomp ( $line = <TEST> );
if ( $line eq 'BBB' ) {
    print  "Alphabetic (desc) ok 1\n" ;
    $ok++;
}
else {
    print  "Alphabetic (desc) not ok 1 ".File::SortedSeek::error."\n";
}

# check default no cuddle
printf "%-2d ", ++$test;
$tell = File::SortedSeek::alphabetic( *TEST, 'TTTTest' );
chomp ( $line = <TEST> );
if ( $line eq 'TTT' ) {
    print  "Alphabetic (desc) ok 2\n" ;
    $ok++;
}
else {
    print  "Alphabetic (desc) not ok 2 ".File::SortedSeek::error."\n";
}

# cuddle
printf "%-2d ", ++$test;
File::SortedSeek::set_cuddle;
$tell = File::SortedSeek::alphabetic( *TEST, 'TTTTest' );
chomp ( $line = <TEST> );
if ( $line eq 'TTU' ) {
    print  "Alphabetic (desc) ok 3\n" ;
    $ok++;
}
else {
    print  "Alphabetic (desc) not ok 3 ".File::SortedSeek::error."\n";
}

File::SortedSeek::set_no_cuddle;

# check between
printf "%-2d ", ++$test;
$begin  = File::SortedSeek::alphabetic( *TEST, 'ABD' );
$finish = File::SortedSeek::alphabetic( *TEST, 'ABA' );
@between = File::SortedSeek::get_between( *TEST, $begin, $finish );
$got = join " ", @between;
if ( $got eq 'ABD ABC ABB' ) {
    print  "Alphabetic (desc) ok 4\n" ;
    $ok++;
}
else {
    print  "Alphabetic (desc) not ok 4 ".File::SortedSeek::error."\n";
}

# need to close and reopen FH now binmoded.
close TEST; 
open TEST, "<$file" or die "Can't read from test file $!\n";

# should retrun first line
printf "%-2d ", ++$test;
$tell = File::SortedSeek::alphabetic( *TEST, 'ZZZZ' );
chomp ( $line = <TEST> );
if ( $line eq 'ZZZ' ) {
    print  "Alphabetic (desc) ok 5\n" ;
    $ok++;
}
else {
    print  "Alphabetic (desc) not ok 5 ".File::SortedSeek::error."\n";
}

# past EOF, should return undefined
printf "%-2d ", ++$test;
$tell = File::SortedSeek::alphabetic( *TEST, 'A' );
if ( !defined $tell ) {
    print  "Alphabetic (desc) ok 6\n" ;
    $ok++;
}
else {
    print  "Alphabetic (desc) not ok 6 ".File::SortedSeek::error."\n";
}

File::SortedSeek::set_ascending; # reset mode to ascending
close TEST;

#################### find_time tests ####################

@data = ();
my $time;
for ( 0..3000 ) {
   # change time every 10 entries so we have 10 identical times
   $time = scalar gmtime($_) unless $_ % 10;
   push @data, $time;
}

write_file ( @data );
open TEST, "<$file" or die "Can't read from test file $!\n";

# basic seek on time string (exact match)
printf "%-2d ", ++$test;
$tell = File::SortedSeek::find_time( *TEST, 'Thu Jan  1 00:42:00 1970' );
chomp ( $line = <TEST> );
if ( $line eq 'Thu Jan  1 00:42:00 1970' ) {
    print  "Find_time (asc) ok 1\n" ;
    $ok++;
}
else {
    print  "Alphabetic (asc) not ok 1 ".File::SortedSeek::error."\n";
}

# basic seek on time string (in between match)
printf "%-2d ", ++$test;
$tell = File::SortedSeek::find_time( *TEST, 'Thu Jan  1 00:42:42 1970' );
chomp ( $line = <TEST> );
if ( $line eq 'Thu Jan  1 00:42:50 1970' ) {
    print  "Find_time (asc) ok 2\n" ;
    $ok++;
}
else {
    print  "Alphabetic (asc) not ok 2 ".File::SortedSeek::error."\n";
}

# basic seek on epoch time (exact match)
printf "%-2d ", ++$test;
$tell = File::SortedSeek::find_time( *TEST, 40 );
chomp ( $line = <TEST> );
if ( $line eq 'Thu Jan  1 00:00:40 1970' ) {
    print  "Find_time (asc) ok 3\n" ;
    $ok++;
}
else {
    print  "Alphabetic (asc) not ok 3 ".File::SortedSeek::error."\n";
}

# basic seek on epoch time (in between match)
printf "%-2d ", ++$test;
$tell = File::SortedSeek::find_time( *TEST, 42 );
chomp ( $line = <TEST> );
if ( $line eq 'Thu Jan  1 00:00:50 1970' ) {
    print  "Find_time (asc) ok 4\n" ;
    $ok++;
}
else {
    print  "Alphabetic (asc) not ok 4 ".File::SortedSeek::error."\n";
}

close TEST;

# write a new test file for between to keep data set returned small
@data = ();
for ( 0..1000 ) {
   push @data, scalar gmtime($_)
}

write_file ( @data );
open TEST, "<$file" or die "Can't read from test file $!\n";

# check between two inexact epoch times (not in file)
printf "%-2d ", ++$test;
$begin  = $tell = File::SortedSeek::find_time( *TEST, 41.5 );
$finish = $tell = File::SortedSeek::find_time( *TEST, 52.5 );
@between = File::SortedSeek::get_between( *TEST, $begin, $finish );
$got = join "\n", @between;
$want = join "\n", @data[42..52];
if ( $got eq $want ) {
    print  "Find_time (asc) ok 5\n" ;
    $ok++;
}
else {
    print  "Alphabetic (asc) not ok 5 ".File::SortedSeek::error."\n";
}

# need to close and reopen FH now binmoded.
close TEST;
open TEST, "<$file" or die "Can't read from test file $!\n";

# look for date past EOF
printf "%-2d ", ++$test;
$tell = File::SortedSeek::find_time( *TEST, 'Thu Jan  1 00:00:00 1971' );
if ( !defined $tell ) {
    print  "Find_time (asc) ok 6\n" ;
    $ok++;
}
else {
    print  "Alphabetic (asc) not ok 6 ".File::SortedSeek::error."\n";
}

close TEST;

#################### tests get_between ####################

# we have already tested it several times, now lets do edge cases
open TEST, "<$file" or die "Can't read from test file $!\n";

# get data at begining of file
printf "%-2d ", ++$test;
$finish  = $tell = File::SortedSeek::find_time( *TEST, 10 );
@between = File::SortedSeek::get_between( *TEST, 0, $finish);
$got = join "\n", @between;
$want = join "\n", @data[0..9];
if ( $got eq $want ) {
    print  "get_between ok 1\n" ;
    $ok++;
}
else {
    print  "get_between not ok 1 ".File::SortedSeek::error."\n";
}

# get data at end of file
printf "%-2d ", ++$test;
$begin = $tell = File::SortedSeek::find_time( *TEST, 990 );
@between = File::SortedSeek::get_between( *TEST, $begin, -s TEST );
$got = join "\n", @between;
$want = join "\n", @data[990..1000];
if ( $got eq $want ) {
    print  "get_between ok 2\n" ;
    $ok++;
}
else {
    print  "get_between not ok 2 ".File::SortedSeek::error."\n";
}

close TEST;

#################### tests for get_last ####################

# continue to use or date file
open TEST, "<$file" or die "Can't read from test file $!\n";

# get a chunk of lines as array
printf "%-2d ", ++$test;
@lines =  File::SortedSeek::get_last( *TEST, 101 );
$got = join "\n", @lines;
$want = join "\n", @data[900..1000];
if ( $got eq $want ) {
    print  "get_last ok 1\n" ;
    $ok++;
}
else {
    print  "get_last not ok 1 ".File::SortedSeek::error."\n";
}

# get a chunk of lines as reference
printf "%-2d ", ++$test;
$line =  File::SortedSeek::get_last( *TEST, 101 );
$got = join "\n", @$line;
$want = join "\n", @data[900..1000];
if ( $got eq $want ) {
    print  "get_last ok 2\n" ;
    $ok++;
}
else {
    print  "get_last not ok 2 ".File::SortedSeek::error."\n";
}

# ask for more than entire file as array
printf "%-2d ", ++$test;
@lines =  File::SortedSeek::get_last( *TEST, 1111 );
$got = join "\n", @lines;
$want = join "\n", @data[0..1000];
if ( $got eq $want ) {
    print  "get_last ok 3\n" ;
    $ok++;
}
else {
    print  "get_last not ok 3 ".File::SortedSeek::error."\n";
}

# ask for more than entire file as reference
printf "%-2d ", ++$test;
$line =  File::SortedSeek::get_last( *TEST, 1111 );
$got = join "\n", @$line;
$want = join "\n", @data[0..1000];
if ( $got eq $want ) {
    print  "get_last ok 4\n" ;
    $ok++;
}
else {
    print  "get_last not ok 4 ".File::SortedSeek::error."\n";
}

close TEST;

#################### test passing munge subrefs ####################

# write a test file that will need munging
open TEST, ">$file" or die "Can't write test file $!\n";
$line = 'AAAA';
for ( 0 .. 1000 ) {
    print TEST "Just|Another|Perl|Hacker|$_|$line\n";
    $line++;
}
close TEST;

open TEST, "<$file" or die "Can't open test file $!\n";

# munge the number out of the file and find that record
sub munge_num {
    my $line = shift || return undef;
  return ($line =~ m/(\d+)\|\w+$/) ? $1 : undef;
}

printf "%-2d ", ++$test;
$tell = File::SortedSeek::numeric( *TEST, 42, \&munge_num );
chomp ( $line = <TEST> );
if ($line eq 'Just|Another|Perl|Hacker|42|AABQ') {
    print "Subref numeric ok 1\n";
    $ok++;
}
else {
    print "Subref numeric not ok 1 ".File::SortedSeek::error."\n";
}

# munge a string out of the file and find that record
sub munge_string {
    my $line = shift || return undef;
  return ($line =~ m/\|(\w+)$/) ? $1 : undef;
}

printf "%-2d ", ++$test;
$tell = File::SortedSeek::alphabetic( *TEST, 'ABBA', \&munge_string );
chomp ( $line = <TEST> );
if ( $line eq 'Just|Another|Perl|Hacker|702|ABBA' ) {
    print "Subref aphabetic ok 1\n";
    $ok++;
}
else {
    print "Subref alphabetic not ok 1 ".File::SortedSeek::error."\n";
}

close TEST;

#################### speed test just for the hell of it ####################

# write a million line file
print "Writing a million line test file, may take a few seconds....\n";
open TEST, ">$file" or die "Can't write test file $!\n";
print TEST "$_\n" for ( 0 .. 1000000 );
close TEST;

open TEST, "<$file" or die "Can't open test file $!\n";

print "Starting seek on million line file\n";
printf "%-2d ", ++$test;
$begin = time();
$tell = File::SortedSeek::numeric( *TEST, 999999 );
$finish = time();
chomp ( $line = <TEST> );
if ( $line == 999999 ) {
    print  "Seek ok 1 " ;
    $ok++;
}
else {
    print  "Seek not ok 1 ".File::SortedSeek::error;
}

printf "- total seek time %d seconds\n", ($finish - $begin);

close TEST;

if ( unlink $file ) {
    print "Test file unlinked ok\n";
}
else {
    warn "Can't unlink test file: $file\n";
}

printf "\nCompleted %d tests %d/%d (%d%%) ok\n\n", $test, $ok, $test, $ok*100/$test;

exit;

# write the test file with the data supplied in an array
# we use the default system line ending.
sub write_file {
    open TEST, ">$file" or die "Can't write test file $!\n";
    print TEST "$_\n" for @_;
    close TEST;
}

1;
