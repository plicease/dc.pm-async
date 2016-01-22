use strict;
use warnings;
use 5.020;
use experimental qw( signatures );
use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::Socket;

my $cv = AnyEvent->condvar;
my @cv;

tcp_connect "localhost", 8079, sub ($fh,@) {

  my $handle = AnyEvent::Handle->new(
    fh => $fh,
    on_eof => sub {
      $cv->send;
    },
  );
  
  $handle->push_write("\015\012");

  my $count = 0;;
  
  $handle->on_read(sub {
    $handle->push_read( line => sub ($handle, $line, @) {
      return if $count++ == 0;
      $line =~ s/\015?\012$//;
      if($line =~ /^([a-zA-Z]+)\s/)
      {
        my $name = $1;
        tcp_connect "localhost", 8079, sub ($fh,@) {
       
          my $cv = AnyEvent->condvar;
          push @cv, $cv;
          
          my @lines;
       
          my $handle = AnyEvent::Handle->new(
            fh => $fh,
            on_eof => sub {
              say "\n\n[$name]";
              say $_ for @lines;
              $cv->send;
            }
          );
          
          $handle->push_write("$name\015\012");
          
          $handle->on_read(sub {
            $handle->push_read( line => sub ($handle, $line, @) {
            
              $line =~ s/\015?\012$//;
              push @lines, $line;
            
            });
          });
        
        };
      }
    });
  });

};

$cv->recv;
$_->recv for @cv;
