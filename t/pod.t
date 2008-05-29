use Test;

eval "use Test::Pod 1.00";

if ($@) {
    skip("Test::Pod 1.00 required for testing POD");
}
else {
    my @poddirs = qw(lib ../lib);  # depends on calling
    all_pod_files_ok(all_pod_files( @poddirs ));
}
