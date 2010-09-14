package Finance::Bank::Cooperative_UK;
use warnings;
use strict;
use Moose;
use WWW::Mechanize;
use WWW::Mechanize::TreeBuilder;

our $VERSION = '0.001';

=head2 Other attributes

=over 4

=item start_url

The URL of the first page of the login procedure (sort code & account
number).  This is mostly for testing purposes, but perhaps you can
think of another use.  The defualt is reasonable, so you shouldn't
have to worry about it.

=item mech

The L<WWW::Mechanize> instance used.  Feel free to, say, change the
user-agent string.  Defaults reasonably.

=cut

has 'start_url', (
                  is => 'rw',
                  lazy => 1,
                  default => 'https://welcome27.co-operativebank.co.uk/CBIBSWeb/start.do',
                 );
has 'mech', (
             is => 'rw',
             lazy => 1,
             default => sub {
               my $mech = WWW::Mechanize->new;
               WWW::Mechanize::TreeBuilder->meta->apply($mech);

               $mech->agent("Finance::Bank::Cooperative_UK/$VERSION (".$mech->agent.")");

               return $mech;
             }
);

=head2 Login information

These are the pieces of login information that the Co-Op bank requests.
Each may be either a string or a coderef returning a string.  (The
coderef option is intended to allow an interactive program to only
prompt for the pieces of "memorable information".)  There is currently
no support for loging in with a Visa card number instead of a sort
code / account number.

=over 4

=item sortcode

The sortcode of your bank account, a six-character string of digits.

=item accountnum

The account number of your bank account, an eight-character string of
digits.  (Careful to quote this, or it will loose leading zeros.)

=item pin

Your four-digit PIN code.  There is no mechinisim for providing only
the needed characters.

=item name

Your memorable name.

=item place_of_birth

Your place of birth.

=item first_school

Your first school attended.

=item last_school

Your last school attended.

=item date

Your memorable date.  (FIXME: describe how this should be formatted.)

=cut

has 'sortcode', is => 'rw', required => 1;
has 'accountnum', is => 'rw', required => 1;
has 'pin', is => 'rw', required => 1;
has 'name', is => 'rw', required => 1;
has 'place_of_birth', is => 'rw', required => 1;
has 'first_school', is => 'rw', required => 1;
has 'last_school', is => 'rw', required => 1;
has 'date', is => 'rw', required => 1;

sub login {
  my ($self) = @_;

  # the commented URL just does a meta-tag based redirect to the uncommnted one.  Lazyness.
  # $self->mech->get('http://www.co-operativebank.co.uk/star/pibs/index.html');
  # First screen: sort code / account number
  $self->mech->get($self->start_url);

  $self->sortcode($self->sortcode->()) if ref $self->sortcode;
  $self->accountnum($self->accountnum->()) if ref $self->accountnum;

  $self->mech->submit_form(with_fields => {
                                           sortCode => $self->sortcode,
                                           accountNumber => $self->accountnum,
                                          });

  # Second login screen: PIN code digits.
  $self->pin($self->pin->()) if ref $self->pin;
  my %form_data;
  for ($self->mech->look_down(_tag => 'select', id => qr/^[a-z]+PassCodeDigit$/)) {
    my ($n_en) = $_->attr('id') =~ m/^([a-z]+)PassCodeDigit$/;
    my $n = {first => 1,
             second => 2,
             third => 3,
             fourth => 4,
            }->{$n_en};
    $form_data{$_->id} = substr($self->pin, $n, 1);
  }

  $self->mech->submit_form(with_fields => \%form_data);

  $self->mech->dump;

  exit;
}

'Is the pope Catholic?';
