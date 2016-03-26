# test for recommendations from "Perl Best Practices"

use strict;
use warnings;
use Test::More;
use Coro::Mysql::Threaded;

eval { use Test::CPAN::Changes };
plan skip_all => 'Test::CPAN::Changes required for this test' if $@;
plan tests => 6;
changes_file_ok(undef, { version => $Coro::Mysql::Threaded::VERSION });
