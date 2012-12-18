use 5.014002;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Mojolicious::Plugin::ExceptionMail',
    VERSION_FROM      => 'lib/Mojolicious/Plugin/ExceptionMail.pm',
    PREREQ_PM         => {
        'Mojolicious'   => 0,
        'MIME::Words'   => 0,
        'MIME::Lite'    => 0,
    },
    ($] >= 5.005 ? 
      (ABSTRACT_FROM  => 'lib/Mojolicious/Plugin/ExceptionMail.pm',
       AUTHOR         => 'Dmitry E. Oboukhov <unera@>') : ()),
       LICENSE        => 'Perl',
);
