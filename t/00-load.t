
use strict;
use warnings;

use Test::More tests => 1;
BEGIN { use_ok('Coro::Mysql::Threaded') };

diag( "Testing Coro::Mysql::Threaded $Coro::Mysql::Threaded::VERSION, Perl $], $^X" );

eval { require Coro };
unless ($@) {
    diag("Coro $Coro::VERSION");
}

eval { require EV };
unless ($@) {
    diag("EV $EV::VERSION");
}
