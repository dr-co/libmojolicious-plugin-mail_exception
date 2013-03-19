#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More tests    => 20;
use Encode qw(decode encode decode_utf8);

my @elist;
my @mails;


BEGIN {
    # Подготовка объекта тестирования для работы с utf8
    my $builder = Test::More->builder;
    binmode $builder->output,         ":utf8";
    binmode $builder->failure_output, ":utf8";
    binmode $builder->todo_output,    ":utf8";

    use_ok 'Test::Mojo';
    require_ok 'Mojolicious';
    require_ok 'MIME::Lite';
    require_ok 'MIME::Words';
    require_ok 'Mojolicious::Plugin::MailException';
}


my $t = Test::Mojo->new('MpemTest');
$t  -> get_ok('/')
    -> status_is(200)
    -> content_is('Hello')
;


$t  -> get_ok('/crash')
    -> status_is(500)
    -> element_exists('div#showcase > pre')
    -> content_like(qr{<pre>превед, медвед})
    -> content_like(qr{
        <tr[^>]+class="important"[^>]*>
        \s*
        <td.*?/td>
        \s*
        <td[^>]+class="value"[^>]*>
        \s*
        <pre[^>]+class="prettyprint"[^>]*>
        \s*
        [^>]*
        die\s+marker
    }x
    )
;



is  scalar @elist, 1, 'one caugth exception';
my $e = shift @elist;



like $e->message, qr{превед, медвед}, 'text of message';
like $e->line->[1], qr{die "превед, медвед"}, 'line';

is scalar @mails, 1, 'one prepared mail';
my $m = shift @mails;


# note decode_utf8 $t->tx->res->to_string;
# note decode_utf8 $m->as_string;


$m->send if $ENV{SEND};
isa_ok $m => 'MIME::Lite';
$m = $m->as_string;
like $m, qr{^Stack}m, 'Stack';
like $m, qr{^Content-Disposition:\s*inline}m, 'Content-Disposition';


package MpemTest::Ctl;
use Mojo::Base 'Mojolicious::Controller';

sub hello {
     $_[0]->render_text('Hello');
}

sub crash {
    eval {
        die "медвед, превед";
    };
    die "превед, медвед"; ### die marker
}

package MpemTest;
use utf8;
use strict;
use warnings;

use Mojo::Base 'Mojolicious';


sub startup {
    my ($self) = @_;

    $self->secret('my secret phrase');
    $self->mode('development');

    $self->plugin('MailException',
        send => sub {
            my ($m, $e) = @_;
            push @elist => $e;
            push @mails => $m;
        },
        $ENV{FROM}  ? ( from => $ENV{FROM} ) : (),
        $ENV{TO}    ? ( to   => $ENV{TO} ) : (),
        subject => 'Случилось страшное (тест)!',
        headers => {},
    );
    for my $r ($self->routes) {
        $r  -> get('/')
            -> to('ctl#hello');

        $r  -> get('/crash')
            -> to('ctl#crash')
        ;

    }
}

1;
