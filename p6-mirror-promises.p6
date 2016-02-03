#!/usr/bin/env perl6

use v6.c;
use HTTP::UserAgent;
use Mojo::DOM:from<Perl5>;
use Mojo::URL:from<Perl5>;

my $ua = HTTP::UserAgent.new;
my $response = $ua.get('http://ftp.gnu.org/gnu/aspell');

my $dom = Mojo::DOM.new($response.content);
my @links = $dom
  .find('a')
  .to_array()
  .map({ $_.attr('href') })
  .grep(/^ 'aspell-' .* '.tar.gz' $/);

my $out_dir = 'aspell'.IO(:d);
mkdir $out_dir;

say "Downloading {@links.elems} files...";

my @promises;
for @links -> $link {
  push @promises, start {
    say "Downloading $link";
    my $response = $ua.get("http://ftp.gnu.org/gnu/aspell/$link");
    "$out_dir/$link".IO.spurt($response.content);
  };
}
await Promise.allof(@promises);

say "Done!";

