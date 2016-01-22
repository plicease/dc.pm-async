use strict;
use warnings;
use 5.020;
use experimental qw( postderef signatures );
use Mojo::UserAgent;
use Path::Class qw( dir );

my $ua = Mojo::UserAgent->new;
$ua->max_redirects(1);

my $tx       = $ua->get('http://ftp.gnu.org/gnu/aspell');
my $res      = $tx->res;

# $tx is the second (redirected) transaction, so
# this URL will have the trailing /
my $base_url = $tx->req->url;

# fetch all a href attributes in the document that
# look like an aspell tarball
my @links = $res->dom->find('a')
                     ->map(sub { $_->attr('href') })
                     ->grep(sub { /^aspell-.*\.tar\.gz$/ })
                     ->map(sub { Mojo::URL->new($_)->to_abs($base_url) })
                     ->to_array
                     ->@*;

# pick an output directory.
my $out_dir = dir('aspell')->absolute;
mkdir $out_dir unless -d $out_dir;

foreach my $link (@links)
{
  # fetch each link in parallel in a single thread
  Mojo::IOLoop->delay(
    sub ($delay) {
      $ua->get($link, $delay->begin);
    },
    sub ($delay, $tx) {
      my $url = $tx->req->url;
      my $file = $out_dir->file($url->path->parts->[-1]);
      say "$url => $file";
      $file->spew($tx->res->body);
    },
  );
}

# enter the mojo even loop until all events
# clear out.
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
