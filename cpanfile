requires 'Plack';
requires 'Plack::Middleware::Debug';
requires 'Text::Markdown';
requires 'Text::MicroTemplate';

on build => sub {
    requires 'ExtUtils::MakeMaker', '6.36';
    requires 'Test::MockModule';
    requires 'Test::Most';
};
