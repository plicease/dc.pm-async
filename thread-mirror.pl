use if $ENV{FORKS}, 'forks';
use threads;
use strict;
use warnings;
use 5.020;
use experimentals;
use HTTP::Tiny;
use Path::Class qw( dir foreign_file );
use URI;
use HTML::Parser;

my $http = HTTP::Tiny->new;

my $res = $http->get('http://ftp.gnu.org/gnu/aspell');

# This is the response URL, which will have the trailing /
# since the original request was redirected
my $base_url = URI->new($res->{url});

my @threads;

# pick an output directory.
my $out_dir = dir('aspell')->absolute;
mkdir $out_dir unless -d $out_dir;

HTML::Parser->new(
  api_version => 3,
  start_h => [ sub ($tagname, $attr) { 

    # skip all tags that aren't an a with
    # the href pointing to an aspell tarball
    return unless $tagname eq 'a'
           && $attr->{href}
           && $attr->{href} =~ /^aspell-.*\.tar\.gz$/;

    # convert href into an absolute URL
    my $url = URI->new_abs( $attr->{href}, $base_url );
    
    push @threads, threads->create(sub {

      my $res = $http->get($url);
      # response URL might actually be different from
      # the original request URL (but probably isn't)
      my $url = URI->new($res->{url});

      my $file = $out_dir->file(foreign_file('Unix', $url->path)->basename);
      $file->spew($res->{content});

      # return a description of the xfer as a string
      "$url => $file";
    });
    
  }, "tagname, attr" ],
)->parse($res->{content})
 ->eof;

# this will print in order of where the links were
# found in the HTML, even though the actual
# transactions will probably complete in a different
# order
say $_->join for @threads;
