use strict;
use warnings;
use Test::More;
use File::Temp qw( tempfile );
use JSON::MaybeXS;
use JSON_File;

{
  my ($fh, $filename) = tempfile();
  tie(my %test,'JSON_File',$filename);
  %test = ( a => { ab => 1 }, b => { ba => 1, bc => 1 }, c => { ca => { caa => 1 }} );
  my %copy_test = %test;
  untie(%test);
  open( $fh, '<', $filename );
  my $json_text = <$fh>;
  is_deeply(\%copy_test,decode_json( $json_text ),'HASH is saved');
  tie(my %load_test,'JSON_File',$filename);
  is_deeply(\%copy_test,\%load_test,'HASH is loaded');
}

{
  my ($fh, $filename) = tempfile();
  tie(my @test,'JSON_File',$filename);
  @test = qw( a b c d e f g h );
  my @copy_test = @test;
  untie(@test);
  open( $fh, '<', $filename );
  my $json_text = <$fh>;
  is_deeply(\@copy_test,decode_json( $json_text ),'ARRAY is saved');
  tie(my @load_test,'JSON_File',$filename);
  is_deeply(\@copy_test,\@load_test,'ARRAY is loaded');  
}

{
  my ($fh, $filename) = tempfile();
  tie(my %test,'JSON_File',$filename);
  %test = ( d => { da => { daa => 1 } } );
  $test{d}->{da}->{dab} = 1;
  $test{d}->{da}->{dac} = 1;
  $test{d}->{db} = {};
  $test{d}->{db}->{dba} = 1;
  $test{d}->{db}->{dbb} = 1;
  $test{d}->{db}->{dbc} = 1;
  delete $test{d}->{da}->{dac};
  delete $test{d}->{db}->{dbc};
  my %copy_test = %test;
  untie(%test);
  open( $fh, '<', $filename );
  my $json_text = <$fh>;
  is_deeply(\%copy_test,decode_json( $json_text ),'HASH after operations is saved');
  tie(my %load_test,'JSON_File',$filename);
  is_deeply(\%copy_test,\%load_test,'HASH after operations is loaded');
}

done_testing;