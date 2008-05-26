use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'File::SortedSeek',
    'VERSION_FROM'  => 'lib/File/SortedSeek.pm',
    'PREREQ_PM'     => {'Search::Dict' => 1},
);
