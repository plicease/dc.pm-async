use strict;
use warnings;
use 5.010;
use threads;

my $t1 = threads->create(sub {
  for(1..10)
  {
    sleep 1;
    say "t1: $_";
  }
});

my $t2 = threads->create(sub {

  for(1..10)
  {
    sleep 2;
    say "t2: $_";
  }

});


$t1->join;
$t2->join;
