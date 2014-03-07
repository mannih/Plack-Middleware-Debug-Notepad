package Plack::Middleware::Debug::Notepad;
use strict;
use warnings;

use Text::Markdown;
use Text::MicroTemplate qw/ encoded_string /;
use Plack::Request;
use JSON;

use parent 'Plack::Middleware::Debug::Base';

sub call {
    my ( $self, $env ) = @_;

    if ( $env->{ REQUEST_METHOD } eq 'POST' && $env->{ QUERY_STRING } =~ m/__plack_middleware_debug_notepad__/ ) {
        return $self->save_markdown( $env );
    }
    else {
        return $self->SUPER::call( $env );
    }
}

sub run {
    my ( $self, $env, $panel ) = @_;

    $panel->title( 'Notepad' );
    $panel->nav_title( 'Notepad' );
    $panel->nav_subtitle( 'things to keep in mind' );

    return sub {
        $panel->content( $self->get_notepad_content( $panel->dom_id ) );
    }
}

sub get_notepad_content {
    my $self = shift;
    my $id   = shift;

    my $md = $self->get_markdown;
    my $vars = {
        markdown => $md,
        id       => $id,
        rendered => encoded_string( Text::Markdown->new->markdown( $md ) ),
    };

    return Text::MicroTemplate->new( template => $self->the_template )->build->( $vars );
}

sub get_markdown {
    my $self = shift;

    if ( open my $fh, '<', '/tmp/plack-middleware-debug-notepad.md' ) {
        local $/;
        return <$fh>;
    }

    return 'Replace this with whatever you need to keep track of.';
}

sub the_template {
    <<'EOTMPL' }
? my $stash = $_[0];
<div id="debug_<?= $stash->{ id } ?>">
    <script>
        jQuery( function( $j ) {
            $j( '#edit_button_<?= $stash->{ id } ?>' ).click( function() {
                $j('#debug_<?= $stash->{ id } ?>_markdown').toggle();
                $j('#debug_<?= $stash->{ id } ?>_html').toggle();
                $j('#edit_button_<?= $stash->{ id } ?>').toggle();
            });
            $j( '#save_button_<?= $stash->{ id } ?>' ).click( function() {
                var data = { "markdown": $j( '#debug_<?= $stash->{ id } ?>_markdown_edited' ).val() }; 
                $j.post( "?__plack_middleware_debug_notepad__", data, function( response ) {
                    $j('#debug_<?= $stash->{ id } ?>_html').html( response.html );
                    $j('#debug_<?= $stash->{ id } ?>_markdown').toggle();
                    $j('#debug_<?= $stash->{ id } ?>_html').toggle();
                    $j('#edit_button_<?= $stash->{ id } ?>').toggle();
                }, 'json' );
            });
        })
    </script>
    <div id="debug_<?= $stash->{ id } ?>_markdown" style="display: none">
        <form>
            <textarea name="markdown" id="debug_<?= $stash->{ id } ?>_markdown_edited"><?= $stash->{ markdown } ?></textarea>
            <input type="button" value="save" id="save_button_<?= $stash->{ id } ?>">
        </form>
    </div>
    <div id="debug_<?= $stash->{ id } ?>_html" class="scroll">
?=      $stash->{ rendered }
    <input type="button" value="edit" id="edit_button_<?= $stash->{ id } ?>">
</div>
EOTMPL

sub save_markdown {
    my $self = shift;
    my $env  = shift;

    my $md = Plack::Request->new( $env )->param( 'markdown' );

    if ( open my $fh, '>', '/tmp/plack-middleware-debug-notepad.md' ) {
        print $fh $md;
    }

    my $response = {
        OK   => 1,
        html => Text::Markdown->new->markdown( $md ),
    };

    return [ 200, [ 'Content-Type', 'application/json' ], [ encode_json( $response ) ] ];
}

1;

__END__

=head1 NAME

Plack::Middleware::Debug::Notepad - Abuse the plack debug panel and keep your todo list in it.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=cut

