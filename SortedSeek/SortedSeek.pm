package File::SortedSeek;

use strict;
# use warnings; # you can use warnings if you have 5.6+
use Time::Local;
require Exporter;

use vars qw( @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION );

@ISA         = qw( Exporter );
@EXPORT         = ();
@EXPORT_OK   = qw( alphabetic numeric find_time get_between get_last );
%EXPORT_TAGS = ( 'all' => \@EXPORT_OK );
$VERSION     = '0.01';

my ($count, $exact_match );
my $debug       = 0;  # set true to watch progression of algorithm
my $max_tries   = 42;
my $descending  = 0;
my $cuddle      = 0;
my $line_length = 80;
my $error_msg   = '';
my $stationary  = 0;
my $silent      = 0;
my $NAME        = 'File::SortedSeek';
my $EMAIL       = 'jfreeman@tassie.net.au';
my %months = ( Jan => 0, Feb => 1, Mar => 2, Apr => 3, May => 4,  Jun => 5, 
               Jul => 6, Aug => 7, Sep => 8, Oct => 9, Nov => 10, Dec => 12);
my $default_rec_sep = ($^O =~ m/win32|vms/i) ? "\015\012" : 
                      ( $^O =~ /mac/i ) ? "\015" : "\012";

# some subs to set optional vars OO style
sub set_cuddle      { $cuddle = 1 };
sub set_no_cuddle   { $cuddle = 0 };
sub set_descending  { $descending = 1 };
sub set_ascending   { $descending = 0 };
sub set_max_tries   { $max_tries = shift || 42 };
sub set_line_length { $line_length = shift || 80; $line_length = 80 unless $line_length >= 1 };
sub set_silent      { $silent = 1 };
sub set_verbose     { $silent = 0 };
sub set_debug       { $debug = 1 };
sub no_debug        { $debug = 0 };
sub was_exact       { $exact_match };
sub error           { $error_msg; };

# basic line munge (just chomp it)
sub basic_munge     { local $_ = shift || return undef; chomp; return $_ };

sub alphabetic {
    local *FILE     = shift;
    my $string      = shift;
    my $munge_ref   = shift || \&basic_munge;
    $error_msg   = '';
    $stationary  = 0;
    _find( *FILE, $string, $munge_ref, \&_test_alphabetic );
}

sub numeric {
    local *FILE     = shift;
    my $number      = shift;
    my $munge_ref   = shift || \&basic_munge;
    $error_msg   = '';
    $stationary  = 0;
    _find( *FILE, $number, $munge_ref,  \&_test_numeric ); 
}

sub find_time {
    local *FILE     = shift;
    my $find        = shift;
    my $not_gmtime  = shift;
    $error_msg   = '';
    $stationary  = 0;
    my $munge_ref   = \&get_epoch_seconds;
    my $epoch       = get_epoch_seconds( $find );
    # if $epoch is defined we assume a date string else real epoch secs
    $find = (defined $epoch) ? $epoch : $find;
    _find( *FILE, $find, $munge_ref,  \&_test_numeric ); 
}

sub get_epoch_seconds {
    my $line  = shift;
  return undef unless defined $line;
    # grab a scalar localtime looking like string from the line
    my ($wday,$mon,$mday,$hours,$min,$sec,$year) = 
        $line =~ m/(\w\w\w)\s+(\w\w\w)\s+(\d{1,2})\s+(\d\d):(\d\d):(\d\d)\s+(\d{4})/;
    unless ($year) {
        $error_msg = "Unable to find time like string in line:\n$line";
        warn $error_msg unless $silent;
      return undef;
    }   
    $mon = $months{$mon};   # convert to numerical months 0 - 11
  return timegm($sec,$min,$hours,$mday,$mon,$year);
}

sub get_between {
    local *FILE = shift;
    my $begin   = shift || 0;
    my $finish  = shift || 0;
    my $rec_sep = shift || $default_rec_sep;
    $error_msg   = '';
    binmode FILE;
    ($begin , $finish) =  ($finish, $begin) if $begin > $finish;
    my $bytes   = $finish - $begin;
    seek FILE, $begin, 0;
    my $read = read (FILE, my $buffer, $bytes);
    if ( $read < $bytes ) {
        $error_msg  = "Short read $NAME\nWanted: $bytes Got: $read\n";
        warn $error_msg unless $silent;
      return undef;
    }
    $buffer = substr $buffer, 0, $bytes;
    my @lines = split $rec_sep, $buffer;
  return wantarray ? @lines : [ @lines ];
}

sub get_last {
    local *FILE    = shift;
    my $num_lines  = shift;
    my $rec_sep    = shift || $default_rec_sep;
    $error_msg   = '';
    binmode FILE;
    my $file_size  = -s FILE;
    my $read       = $line_length * $num_lines;
    my @file;
    GET: 
    {        
        $read = $read << 1;  # double our estimate 
        my $position = $file_size - $read;
        if ($position < 0 ) {
            seek FILE, 0, 0;
            $read = read ( FILE, my $buffer, $file_size );
            @file = split "$rec_sep", $buffer;
            chomp (@file);
            if ( $num_lines > @file ) {
                $error_msg  = "$NAME Wanted $num_lines lines but file only ";
                $error_msg .= "contains" . @file . " lines. Whole file returned\n";
                warn $error_msg unless $silent;
              return wantarray ? @file : [ @file ];
            }
            splice @file, 0, (scalar @file - $num_lines); ;
          return wantarray ? @file : \@file;
        } 
        else {
            seek FILE, $position, 0;
            $read = read ( FILE, my $buffer, $read );
            my $count_lines = $buffer;
            my $line_count = $count_lines =~ s/$rec_sep//og;
            my $average_line_length = ($line_count) ? ( $read / $line_count ) : $read;
            if ($average_line_length > $line_length ) {
                $line_length = $average_line_length;
                $read =  $num_lines * $average_line_length;
            }  
          redo GET unless $num_lines < $line_count; # first line will be a partial          
            @file = split "$rec_sep", $buffer;
        }
        splice @file, 0, (scalar @file - $num_lines); ;
      return wantarray ? @file : \@file;
   }
}

# this is the main routine that implements the halve the difference search  
sub _find{

    my ( $partial, $line, $next );
    local *FILE    = shift;
    my $find       = shift;
    my $munge_ref  = shift;
    my $comp_type  = shift;
    my $file_size  = -s FILE;
    my $top        = 0;
    my $bottom     = $file_size;
    $exact_match   = 0;
    $count         = 0;

    # first line is an edge case, so we test it now
    seek FILE, 0, 0;
    $line = &$munge_ref( scalar <FILE> );
    $next = &$munge_ref( scalar <FILE> );
    unless (defined $line and defined $next) {
        $error_msg = "$NAME Unable to munge valid data from first or second lines\n";
        warn $error_msg unless $silent;
      return undef;
    }
    my $ans = &$comp_type($find, $line, $next);
    if ( $ans == 0 or ($descending and $ans == 1) or (not $descending and $ans == -1) ) {
        seek FILE, 0, 0;
        my $gobble = <FILE> if $exact_match == 2;
      return tell FILE;
    }

    # start the halve the difference loop, we count iterations and
    # will abort the loop if we exceed the specified $max_tries
    while ( ++$count ) {
        my $middle = int(($top+$bottom)/2);
        seek FILE, $middle , 0;
        $partial = <FILE>;
        $line = &$munge_ref( scalar <FILE> );
        $next = &$munge_ref( scalar <FILE> );
        $ans = &$comp_type($find, $line, $next);
        print "A:'$ans' C:'$count' T:'$top' B:'$bottom' Find:'$find' L:'$line' N:'$next'\n" if $debug;
        unless (defined $ans) {
            $error_msg  = "\n\n\nArk, $NAME got to EOF\n";
            $error_msg .= &_debug($find, $line, $next, $file_size, $top, $bottom, $descending);
            warn $error_msg unless $silent;
          return undef;    
        }
        if ( $ans ) {
             if ( $descending ) {
                 ( $ans == 1 ) ? $bottom = $middle : $top = $middle; 
             }
             else {
                 ( $ans == 1 ) ? $top = $middle : $bottom = $middle;        
             }
        }
        else  {
            seek FILE, $middle, 0;
            my $partial = <FILE>;
            if ($exact_match) {
                my $gobble = <FILE> if $exact_match == 2;
            }
            else {
                my $gobble = <FILE> unless $cuddle;
            }
            my $pos = tell FILE;
            # end of file is an edge case
          return ( $pos < $file_size ) ? $pos : undef;
        }
        if ( $count >= $max_tries ) {
            $error_msg  = "\n\n\nArk, $NAME baling out of infinite loop after $max_tries tries\n";
            $error_msg .= &_debug($find, $line, $next, $file_size, $top, $bottom, $descending);
            warn $error_msg unless $silent;
          return undef;
        } 
    }
}

# numeric test routine
{
    my $last_line  = 0;
    my $last_next  = 0;
    sub _test_numeric {
        my ($find, $line, $next) = @_;
        # EOF if $line is not defined
      return undef unless defined $line;
        # check for movement - if repeatedly none we have reached EOF.
        if ($line eq $last_line and defined $next and defined $last_next and $next eq $last_next) {
            $stationary++;
            if ($stationary > 2) {
                $stationary = 0;
              return undef;
            }
        }
        ($last_line, $last_next) = ($line, $next);
        # check for an exact match
        $exact_match = 2 if defined $next and $find == $next;
        $exact_match = 1 if $find == $line; # line must be defined
      return 0 if $exact_match;
        # check for between-ness depending on sort order
      return 0  if !$descending and defined $next and $line < $find and $find < $next;
      return 0  if $descending  and defined $next and $line > $find and $find > $next;
        # otherwise indicate which way to jump
      return +1 if $line < $find;
      return -1 if $line > $find;
    }
}

# alphabetic test routine
{
    my $last_line = '';
    my $last_next = '';
    sub _test_alphabetic {
        my ($find, $line, $next) = @_;
      return undef unless defined $line;
        # check for movement - if repeatedly none we have reached EOF. 
        if ($line eq $last_line and defined $next and defined $last_next and $next eq $last_next) {
            $stationary++;
            if ($stationary > 2) {
                $stationary = 0;
              return undef;
            }
        }
        ($last_line, $last_next) = ($line, $next);
        # check for an exact match
        $exact_match = 2 if defined $next and $find eq $next;
        $exact_match = 1 if $find eq $line;
        return 0 if $exact_match;
        # check for between-ness depending on sort order
      return 0  if !$descending and defined $next and $line lt $find and $find lt $next; 
      return 0  if $descending  and defined $next and $line gt $find and $find gt $next;
        # otherwise indicate which way to jump
      return +1 if $line lt $find;
      return -1 if $line gt $find;
    }
}

sub _debug {
    my ($find, $line, $next, $file_size, $top, $bottom, $mode) = @_;
    $line = 'undef' unless defined $line;
    $next = 'undef' unless defined $next;
    $line = sprintf "0x%x", ord $line unless $line;
    $next = sprintf "0x%x", ord $next unless $next;
    $mode = ($mode)? "Descending" : "Ascending";
    my $message = "Failed to find: '$find'\n";
    $message   .= "The search mode for the file was '$mode order'\n";
    $message   .= "\$line:\t$line\n";
    $message   .= "\$next:\t$next\n";
    $message   .= sprintf "File size: %12d Bytes\n", $file_size;
    $message   .= sprintf "\$top:      %12d Bytes\n", $top;
    $message   .= sprintf "\$bottom:   %12d Bytes\n", $bottom;
    $message   .= "Perhaps try reversing the search mode\n";
    $message   .= "Are you using the correct method - alhpabetic or numeric?\n\n";
    $message   .= "If you think it is a bug please send a bug report to:\n";
    $message   .= "$EMAIL\n";
    $message   .= "A sample of the file, the call to this module and\n";
    $message   .= "this error message will help to fix the problem\n";
  return $message;
}

"tachyon";

__END__

=head2 NAME

File::SortedSeek -  A Perl module providing fast access to large files

=head2 SYNOPSIS

  use File::Seek ':all';
  open BIG, $file or die $!;

  # find a number or the first number greater in a file (ascending order)
  $tell = numeric( *BIG, $number );
  # read a line in from where we matched in the file
  $line = <BIG>;
  print "Found exact match as $line" if File::Seek:was_exact();

  # find a string or the first string greater in a file (alphabetical order)
  $tell = alphabetic( *BIG, $string );
  $line = <BIG>;

  # find a date in a logfile supplying a scalar localtime type string
  $tell = find_time( *BIG, "Thu Aug 23 22:59:16 2001" );
  # or supplying GMT epoch time
  $tell = find_time( *BIG, 998571554 );
  # get all the lines after our date
  @lines = <BIG>;

  # get the lines between two logfile dates
  $begin  = find_time( *LOG, $start );
  $end    = find_time( *LOG, $finish );
  # get lines as an array
  @lines = get_between( *LOG, $begin, $end );
  # get lines as an array reference
  $lines = get_between( *LOG, $begin, $end );

  # use you own sub to munge the file line data before comparison
  $tell = numeric( *BIG, $number, \&epoch );
  $tell = alphabetic( *BIG, $string, \&munge_line );

  # use methods on files in reverse alphabetic or descending numerical order
  File::Seek::set_descending();

  # for inexact matches set FH so first value read is before and second after
  File::Seek::set_cuddle();

  # get last $n lines of any file as an array
  @lines = get_last( *BIG, $n )
  # or an array reference
  $lines = get_last( *BIG, $n )
  # change the input record separator from the OS default
  @lines = get_last( *BIG, $n, $rec_sep )

=head2 DESCRIPTION

File::OrderedSeek provides fast access to data from large files. Three 
methods numeric() alphabetic() and find_time() depend on the file data 
being sorted in some way. Logfiles are a typical example of big files that 
are sorted (by date stamp). The get_between() method can be used to get 
a chunk of lines efficiently from anywhere in the file. The required postion(s) 
for the get_between() method are supplied by the previous methods. The 
get_last() method will efficiently get the last N lines of any file, sorted 
or not.

With sorted data a linear search is not required. Here is a typical linear 
search

    while (<FILE>) {
        next unless /$some_cond/
        # found cond, do stuff
    }

Remember that old game where you try to guess a number between lets say 0 
and say 128? Let's choose 101 and now try to guess it. 

Using a linear search is the same as going 1 higher 2 higher 3 higher ... 
100 higher 101 correct! Consider the geometric approach: 64 higher 96 higher 
112 lower 104 lower 100 higher 102 lower - ta da must be 101! This is the 
halving the difference search method and can be applied to any data set where 
we can logically say higher or lower. In other words any sorted data set can 
be searched like this. It is a far more efficient method - see the SPEED 
section for a quick analysis.

=head3 ABSTRACT

Fiel::OrderedSeek provides fast access to data from large files. Three 
methods numeric() alphabetic() and find_time() depend on the file data 
being sorted in some way. Logfiles are a typical example of big files that 
are sorted (by date stamp). The get_between() method can be used to get 
a chunk of lines efficiently from anywhere in the file. The required postion(s) 
for the get_between() method are supplied by the previous methods. The 
get_last() method will efficiently get the last N lines of any file, sorted 
or not.

=head3 The two basic methods - numeric() and alphabetic()

There are two basic methods - numeric() to do numeric searches and 
alphabetic() that does alphabetic searches. 

You call the functions like this:

    $tell = numeric( *BIG, $find );
    $tell = alphabetic( *BIG, $find );

These methods take two required arguments. *BIG is a FILEHANDE to read from. 
$find is the item you wish to find. $find must be appropriate to the function 
as the numeric method will make numeric comparisons ( == < > ). Similarly the 
alphabetic method makes string comparisons ( eq lt gt ). You will get strange 
results if you use the wrong method just as you do if you say use == when 
you actually meant eq

=head3 Return values with search success and failure

The return value from the numeric() and alphabetic() methods depend on the 
result of the search. If the search fails the return value is undefined. 
A search can succeed in two ways. If an exact match is found then the 
current file position pointer is set to the beginning of the matching line. 
The return value is the corresponding response from tell(). This means that 
the next read from <FILEHANDLE> will return the matching line. 
Subsequent reads return the following lines as expected.

Alternatively a search will succeed if a point in the file can be found such 
that $find is cuddled between two adjacent lines. For example consider 
searching for the number 42 in a file like this:

    ..
    36
    40  <- Before
    44  <- After
    48
    .. 

The number 42 is not actually there but the search will still succeed as it 
is between 40 and 44. By default the file postion pointer is set to the 
beginning of the line '44' so the next read from <FILEHANDLE> will return 
this line. If the File::Seek::set_cuddle() function is called then the file 
position pointer will be set to the beginning of line '40' so that the 
first two reads from <FILEHANDLE> will cuddle the in-between value in $find.

=head3 Adding line munging to make the basic methods more useful

Both the numeric and alphabetic subs take an optional third argument. 
This optional argument is a reference to a subroutine to munge the 
file lines so that suitable values are extracted for comparison to $find.

    $tell = numeric( *BIG, $find, \&munge_line );
    $tell = alphabetic( *BIG, $find, \&munge_line );

A good example of this is the find_time() function. This is just an 
implementation of the basic numeric algorithm similar to this.

    $tell = numeric ( *BIG, $epoch_seconds, \&get_epoch_seconds );

    sub get_epoch_seconds {
        use Time::Local;
        my $line  = shift;
      return undef unless defined $line;
        my %months = 
            ( Jan => 0, Feb => 1, Mar => 2, Apr => 3, May => 4,  Jun => 5, 
              Jul => 6, Aug => 7, Sep => 8, Oct => 9, Nov => 10, Dec => 12);
        # grab a scalar localtime looking like string from the line
        my ($wday,$mon,$mday,$hours,$min,$sec,$year) = 
            $line =~ m/(\w\w\w)\s+(\w\w\w)\s+(\d{1,2})\s+(\d\d):(\d\d):(\d\d)\s+(\d{4})/;
        unless ($year) {
            $error_msg = "Unable to find time like string in line:\n$line";
            warn $error_msg unless $silent;
          return undef;
        }   
        $mon = $months{$mon};   # convert to numerical months 0 - 11
      return timegm($sec,$min,$hours,$mday,$mon,$year);
    }

As the search is made the test lines are passed to the munging sub. This sub 
needs to return a string or number that we can perform comparison on. In this 
case the sub looks for something that looks like a scalar localtime() string, 
and assuming this is a date passes it to timegm() for conversion to 
epoch seconds and returns this number.

You can see further examples of this in the test suite test.pl

=head3 find_time()

The find_time() function is an implementation of the basic numeric method as 
discussed briefly above. You call it like:

    $tell = find_time( *LOG, 'Thu Jan  1 00:42:00 1970' );
    $tell = find_time( *LOG, $epoch_seconds );

You may use either a scalar localtime() like string or epoch seconds. If you 
use epoch seconds it assumes gmtime. If in doubt use the string as although 
it works internally with gmtime the offsets cancel out and the correct result 
is returned.

=head3 Getting lines from the middle of a file  - get_between()

Say you have a logfile and you want to get the log between one date and 
another. You can simply use two calls to the find_time() to get the beginning 
and end positions and then use get_between() to get the lines.

    # get the lines between two logfile dates
    $begin  = find_time( *LOG, $start );
    $end    = find_time( *LOG, $finish );
    # get lines as an array
    @lines = get_between( *LOG, $begin, $end );
    # get lines as an array reference
    $lines = get_between( *LOG, $begin, $end );

The get_between() method returns an array in list context as above and a 
reference to an array in scalar context.

This function needs to apply binmode so it splits the lines based on a system 
specific default record separator. This is derived as below:

    my $default_rec_sep = ($^O =~ m/win32|vms/i) ? "\015\012" : 
                          ( $^O =~ /mac/i ) ? "\015" : "\012"; 

You can override this on a per file basis by passing the record separator 
to the get_between() function.

    @lines = get_between( *LOG, $begin, $end, $rec_sep );

Modifying $/ has no effect. Note that *the record separator is not returned* 
in the array. As a result the returned array has effectively had every 
element chomped.

Warning - this method will apply binmode to the FH so line endings 
will possibly not be converted properly if you try to continue to read from 
it. As there is no unbinmode() close the FH afterwards and reopen it if you 
want to read from it. You can seek FH, 0, $end if say you want to read more 
lines after $end.

=head3 Getting the lines from the beginning of a file - get_between()

Using the get_between() method you can efficiently get the lines at the 
beginning of a file. Although you can just read in lines sequentially with 
a while loop this requires that you test each line. If you can find the 
end point using the find_time() numeric() or alphabetic() methods you 
can the just get what you need. For large files many thousands of 
unnecessary tests are avoided saving time. Using the example above 
you simply set $begin to 0

    $begin  = 0;
    $end    = find_time( *LOG, $finish );
    @lines  = get_between( *LOG, $begin, $end );

=head3 Getting lines from the end of a file - get_between()

You can similarly use get between to get all the lines from a specific point 
up to the end of the file. The end is just the size of the file so:

    $begin = find_time( *LOG, $start );
    $end   = -s LOG;
    @lines = get_between( *LOG, $begin, $end );

=head3 Getting lines from the end of a file - get_last()

This method does not depend on the file being sorted to work.
When you use the get_last() method the module estimates how many bytes at 
the end of the file to read in. To make the estimate the module  multiplies 
the default line length (80 chars) by the number of lines required and then 
doubles it. 

If it does not get sufficient lines on its first attempt it re-estimates 
the line length from the actual data read in, re-calculates 
the read, doubles it and then tries again. This algorithm is unlikely to 
take more than 2 reads but if you have unusually long of short lines you may 
get a small speed benefit by using the set_line_length() method to set the 
average line length. The default is 80 chars per line. Setting the line length 
close to the actual will also avoid reading a excessive quantity of data into 
memory.

    # get last $n lines of any file as an array
    @lines = get_last( *BIG, $n )
    # or an array reference
    $lines = get_last( *BIG, $n )
    # change the input record separator from the default
    @lines = get_last( *BIG, $n, $rec_sep )

This function needs to apply binmode so it splits the lines based on a system 
specific default record separator. This is derived as below:

    my $default_rec_sep = ($^O =~ m/win32|vms/i) ? "\015\012" : 
                          ( $^O =~ /mac/i ) ? "\015" : "\012"; 

You can override this on a per file basis by passing the record separator 
$rec_sep to the get_last() function as shown. Modifying $/ has no effect.
Note that *the record separator is not returned* in the array. As a 
result the returned array has effectively had every element chomped.

Warning - this method will apply binmode to the FH so line endings 
will possibly not be converted properly if you try to continue to read from 
it. As there is no unbinmode() close the FH afterwards and reopen it if you 
want to read from it. You can seek FH, 0, $end if say you want to read more 
lines after $end.

=head2 EXPORT

Nothing is exported by default. The following 5 methods are available for 
import:

    alphabetic() 
    numeric() 
    find_time()
    get_between()
    get_last()

You can import just the method you want with a:

    use File::Seek 'numeric';

or all 5  methods using the ':all' tag.

    use File::Seek ':all';

=head2 OPTIONS

There are some options available via non exported function
calls. You will need to fully specify the name if you want to use these.

=head3 File::Seek::error()

If a function returns undefined there has been an error. error() will 
contain the text of the last error message or a null string if there 
was no error.

=head3 File::Seek::was_exact()

was_exact() will return true if an exact match was found. It will be 
false if the match was in between or failed.

=head3 File::Seek::set_cuddle()  File::Seek::set_no_cuddle()

set_cuddle() changes the default line returned for in between matches  as 
discussed above and set_no_cuddle() restores default behaviour

=head3 File::Seek::set_descending() File::Seek::set_ascending()

By default ascending numerical order and alphabetical order are assumed. 
This assumption can be reversed by calling set_descending() and reset 
by calling set_ascending() We need to know the order to seek within the 
file in the correct direction.

=head3 File::Seek::set_max_tries($max)

This sets the maximum times that the module will try the halve the 
difference search before it decides there is a problem and bails out. 
The default value is 42 which allows files with up to 2**42 or a bit more 
than 10**12 lines to be processed. A seek in a million line file will take a 
mere 20 tries to find the required value.

=head3 File::Seek::set_line_length($integer)

When you use the get_last() method the module uses its default 
line length to estimate how many bytes at the end of the file to read in. 
You can improve speed slightly and decrease memory usage by setting an 
accurate line length. The default is 80 chars per line. The function will
work fine regardless of what the line length is, this is just an efficiency 
tweak.

=head3 File::Seek::set_silent()  File::Seek::set_verbose()

You can silence or activate error messages by calling these two subs. The 
default is verbose.

=head3 File::Seek::set_debug()  File::Seek::no_debug()

Sets debug on or off. Default is of course off.

=head2 SPEED

Here is a table that demonstrates the advantage of using the halve the 
difference algorithm.

    Num items   Lin avg  Geom avg  Lin:Geom
            2         1         1         1
            4         2         2         1
            8         4         3         1
           16         8         4         2
           32        16         5         3
           64        32         6         5
          128        64         7         9
          256       128         8        16
          512       256         9        28
         1024       512        10        51
         2048      1024        11        93
         4096      2048        12       170
         8192      4096        13       315
        16384      8192        14       585
        32768     16384        15      1092
        65536     32768        16      2048
       131072     65536        17      3855
       262144    131072        18      7281
       524288    262144        19     13797
      1048576    524288        20     26214

Even though there is an overhead involved with this search this is minor 
as the number of tests required is so much less. Speed increases of 100-1000 
of times are typical.

An OO interface slows things down by > 50% so is not used.

=head2 BUGS

Bound to be some. The binmoding of the FH by get_between() and get_last() can 
not be easily avoided.

=head2 AUTHOR

(c) Dr James Freeman 2000-01 E<lt>jfreeman@tassie.net.auE<gt> 
All rights reserved.

This package is free software and is provided ``as is'' without express or 
implied warranty. It may be used, redistributed and/or modified under the terms 
of the Perl Artistic License (see http://www.perl.com/perl/misc/Artistic.html)

=head2 SEE ALSO

For details about the mystical significance of the number 42 and how it can 
be applied to Life the Universe and everything see The Hitch Hiker's Guide 
to the Galaxy 'trilogy' by the recently departed Douglas Adams.