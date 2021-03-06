package Parse::Method::Signatures::Sig;

use Moose;
use MooseX::Types::Moose qw/HashRef/;
use Parse::Method::Signatures::Types qw/Param ParamCollection NamedParam/;
use List::MoreUtils qw/part/;

use namespace::clean -except => 'meta';

has invocant => (
    is        => 'ro',
    does      => Param,
    predicate => 'has_invocant',
);

has _positional_params => (
    is        => 'ro',
    isa       => ParamCollection,
    init_arg  => 'positional_params',
    predicate => 'has_positional_params',
    coerce    => 1,
    handles   => {
        positional_params => 'params',
    },
);

has _named_params => (
    is        => 'ro',
    isa       => ParamCollection,
    init_arg  => 'named_params',
    predicate => 'has_named_params',
    coerce    => 1,
    handles   => {
        named_params => 'params',
    },
);

has _named_map => (
    is         => 'ro',
    isa        => HashRef[Param],
    lazy_build => 1,
);

override BUILDARGS => sub {
    my $args = super();

    if (my $params = delete $args->{params}) {
        my ($positional, $named) = part { NamedParam->check($_) ? 1 : 0 } @{ $params };
        $args->{positional_params} = $positional if $positional;
        $args->{named_params} = $named if $named;
    }

    return $args;
};

sub _build__named_map {
    my ($self) = @_;
    return {} unless $self->has_named_params;
    return { map { $_->label => $_ } @{ $self->named_params } };
}

sub named_param {
    my ($self, $name) = @_;
    return $self->_named_map->{$name};
}

around has_positional_params => sub {
    my $orig = shift;
    my $ret = $orig->(@_);
    return unless $ret;

    my ($self) = @_;
    return scalar @{ $self->positional_params };
};

around has_named_params => sub {
    my $orig = shift;
    my $ret = $orig->(@_);
    return unless $ret;

    my ($self) = @_;
    return scalar @{ $self->named_params };
};

sub to_string {
    my ($self) = @_;
    my $ret = q{(};

    if ($self->has_invocant) {
        $ret .= $self->invocant->to_string;
        $ret .= q{:};

        if ($self->has_positional_params || $self->has_named_params) {
            $ret .= q{ };
        }
    }

    $ret .= $self->_positional_params->to_string if $self->has_positional_params;
    $ret .= q{, } if $self->has_positional_params && $self->has_named_params;
    $ret .= $self->_named_params->to_string if $self->has_named_params;

    $ret .= q{)};
    return $ret;
}

__PACKAGE__->meta->make_immutable;

1;
