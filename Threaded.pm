package Coro::Mysql::Threaded;

use strict qw(vars subs);
no warnings;

use Scalar::Util ();
use Carp qw(croak);

use Guard;
use AnyEvent ();
use Coro ();
use Coro::AnyEvent (); # not necessary with newer Coro versions

BEGIN {
    our $VERSION = 0.1;

    if (AnyEvent::detect ne "AnyEvent::Impl::EV") {
        warn "EV is not detected";
    }

    require DynaLoader;
    require XSLoader;
    XSLoader::load Coro::Mysql::Threaded, $VERSION;

    my $mysql_lib_path = (DynaLoader::dl_findfile("-lmysqlclient"))[0]
        or die "Can't find MySQL client library";

    my $my_lib_path = do {
        my (@dirs, $file);
        my $module = __PACKAGE__;
        my @modparts = split(/::/, $module);
        my $modfname = $modparts[-1];
        my $modpname = join('/', @modparts);
        foreach (@INC) {
            my $dir = "$_/auto/$modpname";
            next unless -d $dir;
            my $try = "$dir/$modfname.$DynaLoader::dl_dlext";
            last if $file = ((-f $try) && $try);
            push @dirs, $dir;
        }
        $file = DynaLoader::dl_findfile(map("-L$_", @dirs, @INC), $modfname) unless $file;

        die("Can't locate loadable object for module $module in \@INC (\@INC contains: @INC)")
            unless $file;   # wording similar to error from 'require'

        $file;
    };

    Coro::Mysql::Threaded::_begin($my_lib_path, $mysql_lib_path);
}

END {
    Coro::Mysql::Threaded::_end();
}

1;
__END__
=head1 NAME

Coro::Mysql::Threaded - Asynchronous MySQL queries on real threads

=begin HTML

<p><a href="https://metacpan.org/pod/Coro::Mysql::Threaded" target="_blank"><img alt="CPAN version" src="https://badge.fury.io/pl/p5-Coro-Mysql-Threaded.svg"></a> <a href="https://travis-ci.org/yoreek/p5-Coro-Mysql-Threaded" target="_blank"><img title="Build Status Images" src="https://travis-ci.org/yoreek/p5-Coro-Mysql-Threaded.svg"></a></p>

=end HTML

=head1 SYNOPSIS

    use DBI;
    use EV;
    use Coro;
    use Coro::Mysql::Threaded;

    async {
        my $dbh = DBI->connect('DBI:mysql:test', '', '')
            or die $DBI::errstr;

        my $sth = $dbh->prepare('SELECT * FROM users');
        $sth->execute();
        my $res = $sth->fetchall_arrayref({});
    } for 1..10

    EV::loop;

=head1 DESCRIPTION

This module is experimental!

=head1 AUTHOR

Yuriy Ustushenko, E<lt>yoreek@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 Yuriy Ustushenko

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
