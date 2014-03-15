use Test::Most;
use Test::MockModule;
use Plack::Middleware::Debug::Panel;

BEGIN {
    use_ok( 'Plack::Middleware::Debug::Notepad' );
}

test_call();
test_run();
test_save_markdown();

done_testing;


sub get_object {
    return Plack::Middleware::Debug::Notepad->new;
}

sub test_call {
    can_ok 'Plack::Middleware::Debug::Notepad', 'call';
    my $obj = get_object;
    my $mocker = Test::MockModule->new( 'Plack::Middleware::Debug::Notepad' );
    my $save_called = 0;
    my $get_called  = 0;
    $mocker->mock( save_markdown => sub { ++$save_called } );
    $mocker->mock( get_markdown  => sub { ++$get_called  } );

    dies_ok { $obj->call( {} ) } 'dies somewhere in Debug::Base';
    dies_ok { $obj->call( { REQUEST_METHOD => 'POST', QUERY_STRING => 'plack_middleware_debug_notepad' } ) } 'request not captured, wrong query string';

    ok $obj->call( { REQUEST_METHOD => 'POST', QUERY_STRING => 'foo&__plack_middleware_debug_notepad__=bar' } ), 'request captured';
    is $save_called, 1, 'save_markdown would have been called once';

    ok $obj->call( { REQUEST_METHOD => 'GET', QUERY_STRING => 'foo&__plack_middleware_debug_notepad__=bar' } ), 'GET is ok, should return our markdown';
    is $get_called, 1, 'get_markdown would have been called once';
}

sub test_run {
    can_ok 'Plack::Middleware::Debug::Notepad', 'run';
    my $obj = get_object;

    my $panel = Plack::Middleware::Debug::Panel->new;
    $panel->dom_id( 'the-dom_id' );

    my $mocker = Test::MockModule->new( 'Plack::Middleware::Debug::Notepad' );
    $mocker->mock( get_notepad_content => sub { 'generated panel content' } );
    my $result = $obj->run( {}, $panel );
    isa_ok $result, 'CODE';
    ok ! $panel->title, 'title is not yet set';
    ok ! $panel->nav_title, 'nav_title is not yet set';
    ok ! $panel->nav_subtitle, 'nav_subtitle is not yet set';
    ok ! $panel->content, 'content is not yet set';

    $result->();
    is $panel->title, 'Notepad', 'title is correctly set';
    is $panel->nav_title, 'Notepad', 'nav_title is correctly set';
    is $panel->nav_subtitle, 'things to keep in mind', 'nav_subtitle is correctly set';
    is $panel->content, 'generated panel content', 'content is correctly set';
}

sub test_save_markdown {
    can_ok 'Plack::Middleware::Debug::Notepad', 'save_markdown';
    my $obj = get_object;
    my $store = 'notepad_file.tmp';
    $obj->notepad_file( $store );
    my $md = "# this\n## is just\n### a test\n";
    my $env = {
        'plack.request.body' => Hash::MultiValue->new( markdown => $md )
    };
    my $result = $obj->save_markdown( $env );
    is $result->[ 0 ], 200, 'returns status 200';
    is $result->[ 1 ]->[ 1 ], 'text/html', 'content type seems ok';

    my $expected_html = '<h1>this</h1>

<h2>is just</h2>

<h3>a test</h3>
';
    is $result->[ 2 ]->[ 0 ], $expected_html, 'correct html returned';
    ok -e $store, 'store file exists';

    open my $fh, '<', $store;
    local $/;
    my $md_got = <$fh>;
    is $md_got, $md, 'markdown correctly saved';

    $md_got = $obj->get_markdown;
    is $md_got, $md, 'markdown correctly saved and retrieved';

    unlink $store;
}

