use Test::More;
use Test::Spelling;
set_spell_cmd("C:\\usr\\Aspell\\bin\\aspell.exe -l");
add_stopwords(<DATA>);
all_pod_files_spelling_ok('../lib');
__DATA__
CGI
CPAN
GPL
STDIN
STDOUT
DWIM
OO
Stig
James
Freeman
refactored
behaviour
ta
da
hh
mm
ss
dd
mm
yyyy
