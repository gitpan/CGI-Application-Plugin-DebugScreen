use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'CGI::Application::Plugin::DebugScreen',
    VERSION_FROM      => 'lib/CGI/Application/Plugin/DebugScreen.pm',
    PREREQ_PM         => {
        HTML::Template    => 0,
        Devel::StackTrace => 0,
        IO::File          => 0,
    },
);
