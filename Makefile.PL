use 5.014002;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Mojolicious::Plugin::MailException',
    VERSION_FROM      => 'lib/Mojolicious/Plugin/MailException.pm',
    PREREQ_PM         => {
        'Mojolicious'   => 0,
        'MIME::Words'   => 0,
        'MIME::Lite'    => 0,
    },
    ($] >= 5.005 ? 
      (ABSTRACT_FROM  => 'lib/Mojolicious/Plugin/MailException.pm',
       AUTHOR         => 'Dmitry E. Oboukhov <unera@debian.org>') : ()),
       LICENSE        => 'Perl',
);
