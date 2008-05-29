use Test;

eval "use Test::Pod::Coverage 1.00";

if ($@) {
    skip("Test::Pod::Coverage 1.00 required for testing POD");
}
else {
    all_pod_coverage_ok( { also_private => [ 'set_max_tries', 'set_line_length' ] });
}