package Mojolicious::Plugin::ExceptionMail;

our $VERSION = '0.01';
use 5.008008;
use strict;
use warnings;

use Mojo::Base 'Mojolicious::Plugin';
use Data::Dumper;
use Mojo::Exception;
use Carp;
use MIME::Lite;
# use MIME::Base64;
use MIME::Words ':all';


my $mail_prepare = sub {
    my ($e, $conf, $self, $from, $to, $headers) = @_;
    my $subject = $conf->{subject} || 'Caught exception';
    $subject .= ' (' . $self->req->method . ': ' .
        $self->req->url->to_abs->to_string . ')';
    utf8::encode($subject) if utf8::is_utf8 $subject;
    $subject = encode_mimeword $subject, 'B', 'utf-8';


    my $text = '';
    $text .= "Exception\n";
    $text .= "~~~~~~~~~\n";
    

    $text .= $e->message;
    $text .= "\n";

    my $maxl = length $e->lines_after->[-1][0];
    $maxl ||= 5;
    $text .= sprintf "   %*d %s\n", $maxl, @{$_}[0,1] for @{ $e->lines_before };
    $text .= sprintf " * %*d %s\n", $maxl, @{ $e->line }[0,1];
    $text .= sprintf "   %*d %s\n", $maxl, @{$_}[0,1] for @{ $e->lines_after };

    if (@{ $e->frames }) {
        $text .= "\n";
        $text .= "Stack\n";
        $text .= "~~~~~\n";
        for (@{ $e->frames }) {
            $text .= sprintf "    %s: %d\n", @{$_}[1,2];
        }
    }


    eval { utf8::encode($text) if utf8::is_utf8 $text };


    my $mail = MIME::Lite->new(
        From    => $from,
        To      => $to,
        Subject => $subject,
        Type    => 'multipart/mixed',
    );


    $mail->attach(
        Type    => 'text/plain; charset=utf-8',
        Data    => $text
    );
    
    $text  = "Request\n";
    $text .= "~~~~~~~\n";
    my $req = $self->req->to_string;
    $req =~ s/^/    /gm;
    $text .= $req;

    $mail->attach(
        Type        => 'text/plain; charset=utf-8',
        Filename    => 'request.txt',
        Disposition => 'inline',
        Data        => $text
    );

    $mail->add($_ => $headers->{$_}) for keys %$headers;
    return $mail;
};


my $send_cb = sub {
    my ($mail, $e) = @_;
    $mail->send;
};

sub register {
    my ($self, $app, $conf) = @_;

    my $cb = $conf->{send} || $send_cb;
    croak "Usage: app->plugin('ExceptionMail'[, send => sub { ... })'"
        unless 'CODE' eq ref $cb;

    my $headers = $conf->{headers} || {};
    my $from = $conf->{from} || 'root@localhost';
    my $to   = $conf->{to} || 'webmaster@localhost';



    croak "headers must be a HASHREF" unless 'HASH' eq ref $headers;

    $app->hook(around_dispatch => sub {
        my ($next, $c) = @_;


        local $SIG{__DIE__} = sub {
            my ($e) = @_;
            my @caller = caller;
            $e = Mojo::Exception->new($e, @caller[1, 2]) unless ref $e;
            my @frames;
            for (my $i = 1; caller($i); $i++) {
                push @frames => [ caller $i ];
            }
            $e->frames(\@frames);

            my $mail = $mail_prepare->( $e, $conf, $c, $from, $to, $headers );

            eval {
                $cb->($mail, $e);
                1;
            } or warn $@;

            die $e;
        };
        $next->()
    });
}


1;
