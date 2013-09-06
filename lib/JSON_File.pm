package JSON_File;
# ABSTRACT: Tie a hash or an array to a JSON

use Moo;
use JSON::MaybeXS;
use Path::Tiny;
use autodie;

has json => (
  is => 'ro',
  lazy => 1,
  default => sub { JSON->new()->utf8(1) },
);

has filename => (
  is => 'ro',
  required => 1,
);

has abs_filename => (
  is => 'ro',
  lazy => 1,
  default => sub { path(shift->filename)->absolute },
);

has tied => (
  is => 'ro',
  required => 1,
);

sub BUILD {
  my ( $self ) = @_;
  $self->abs_filename;
}

sub data {
  my ( $self ) = @_;
  if (-f $self->abs_filename) {
    return $self->load_file;
  } else {
    if ($self->tied eq 'HASH') {
      return {};
    } elsif ($self->tied eq 'ARRAY') {
      return [];
    }
  }
}

sub add_data {
  my ( $self, $key, $value ) = @_;
  my $data = $self->data;
  if ($self->tied eq 'HASH') {
    $data->{$key} = $value;
  } elsif ($self->tied eq 'ARRAY') {
    $data->[$key] = $value;
  }
  $self->save_file($data);
}

sub remove_data {
  my ( $self, $key, $value ) = @_;
  my $data = $self->data;
  if ($self->tied eq 'HASH') {
    delete $data->{$key};
  } elsif ($self->tied eq 'ARRAY') {
    delete $data->[$key];
  }
  $self->save_file($data);
}

sub load_file {
  my ( $self ) = @_;
  local $/;
  open( my $fh, '<', $self->abs_filename );
  my $json_text = <$fh>;
  return $self->json->decode( $json_text );
}

sub save_file {
  my ( $self, $data ) = @_;
  local $/;
  open( my $fh, '>', $self->abs_filename );
  my $json_text = $self->json->encode( $data );
  print $fh $json_text;
  close($fh);
}

sub TIEHASH {shift->new(
  filename => shift,
  tied => 'HASH',
  @_,
)}

sub TIEARRAY {shift->new(
  filename => shift,
  tied => 'ARRAY',
  @_,
)}

sub FETCH {
  my ( $self, $key ) = @_;
  if ($self->tied eq 'HASH') {
    return $self->data->{$key};
  } elsif ($self->tied eq 'ARRAY') {
    return $self->data->[$key];
  }
}

sub STORE {
  my ( $self, $key, $value ) = @_;
  $self->add_data($key,$value);
}

sub FETCHSIZE {
  my ( $self ) = @_;
  return scalar @{$self->data};
}

sub PUSH {
  my ( $self, @values ) = @_;
  my @array = @{$self->data};
  push @array, @values;
  $self->save_file(\@array);
}

sub UNSHIFT {
  my ( $self, @values ) = @_;
  my @array = @{$self->data};
  unshift @array, @values;
  $self->save_file(\@array);
}

sub POP {
  my ( $self ) = @_;
  my @array = @{$self->data};
  my $value = pop @array;
  $self->save_file(\@array);
  return $value;
}

sub SHIFT {
  my ( $self ) = @_;
  my @array = @{$self->data};
  my $value = shift @array;
  $self->save_file(\@array);
  return $value;
}

sub SPLICE {
  my $self = shift;
  return splice(@{$self->data},@_);
}

sub DELETE {
  my ( $self, $key ) = @_;
  $self->remove_data($key)
}

sub EXISTS {
  my ( $self, $key ) = @_;
  if ($self->tied eq 'HASH') {
    return exists $self->data->{$key};
  } elsif ($self->tied eq 'ARRAY') {
    return exists $self->data->[$key];
  }
}

sub SCALAR {
  my ( $self ) = @_;
  return scalar %{$self->data};
}

sub CLEAR {
  my ( $self ) = @_;
  if ($self->tied eq 'HASH') {
    $self->save_file({});
  } elsif ($self->tied eq 'ARRAY') {
    $self->save_file([]);
  }
}

sub EXTEND {}
sub STORESIZE {}

sub FIRSTKEY {
  my ( $self ) = @_;
  if ($self->tied eq 'HASH') {
    my ( $first ) = sort { $a cmp $b } keys %{$self->data};
    return defined $first ? ($first) : ();
  } elsif ($self->tied eq 'ARRAY') {
    return scalar @{$self->data} ? (0) : ();
  }
}

sub NEXTKEY {
  my ( $self, $last ) = @_;
  if ($self->tied eq 'HASH') {
    my @sorted_keys = sort { $a cmp $b } keys %{$self->data};
    my $next;
    while (@sorted_keys) {
      my $key = shift @sorted_keys;
      if ($key eq $last) {
        if (@sorted_keys) {
          return (shift @sorted_keys);
        } else {
          return;
        }
      }
    }
  } elsif ($self->tied eq 'ARRAY') {
    my $last_index = (scalar @{$self->data}) - 1;
    if ($last < $last_index) {
      return $last+1;
    } else {
      return;
    }
  }
}

sub UNTIE {}
sub DESTROY {}

1;
