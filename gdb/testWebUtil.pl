use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::Const -compile => qw(OK);
use Apache2::Request;

sub handler {
    my $r = shift;

    $r->content_type('text/plain');
    print "Mod_perl 2.0 handler\n";

    $req = Apache2::Request->new($r);

    return Apache2::Const::OK;
}
1;
