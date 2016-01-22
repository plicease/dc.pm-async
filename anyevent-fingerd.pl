# to test with a regular finger client where you can't configure the port:
# sudo iptables -t nat -I OUTPUT -p tcp -d 127.0.0.1 --dport 79 -j REDIRECT --to-port 8079
# sudo iptables -t nat -A PREROUTING -p tcp --dport 79 -j REDIRECT --to-port 8079

use strict;
use warnings;
use 5.020;
use experimentals;
use AnyEvent;
use AnyEvent::Open3::Simple;
use AnyEvent::Finger::Server;

my $server = AnyEvent::Finger::Server->new(port => 8079);

$server->start(sub ($tx) {

  my $ipc = AnyEvent::Open3::Simple->new(
    on_stdout => sub ($proc, $line) {
      $tx->res->say($line);
    },
    on_exit => sub ($proc, $exit, $signal) {
      $tx->res->done;
    },
  );

  if($tx->req->listing_request)
  {
    $ipc->run('finger');
  }
  else
  {
    $ipc->run('finger', $tx->req->username);
  }
});

AnyEvent->condvar->recv;
