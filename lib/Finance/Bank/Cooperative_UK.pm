package Finance::Bank::Cooperative_UK;
use warnings;
use strict;
use Moose;
use WWW::Mechanize;
use WWW::Mechanize::TreeBuilder;

our $VERSION = '0.001';

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

=item account

The account number of your bank account, an eight-character string of
digits.  (Careful to quote this, or it will loose leading zeros.)

=item number

Your four-digit PIN code.  There is no mechinisim for providing only
the needed characters.

=item name

Your memorable name.

=item birth

Your place of birth.

=item first

Your first school attended.

=item last

Your last school attended.

=item date

Your memorable date.  (FIXME: describe how this should be formatted.)

=cut

has 'sortcode', is => 'rw', required => 1;
has 'accountnum', is => 'rw', required => 1;
has 'pin', is => 'rw', required => 1;
has 'name', is => 'rw', required => 1;
has 'place', is => 'rw', required => 1;
has 'first', is => 'rw', required => 1;
has 'last', is => 'rw', required => 1;
has 'date', is => 'rw', required => 1;

sub login {
  my ($self) = @_;

  # the commented URL just does a meta-tag based redirect to the uncommnted one.  Lazyness.
  # $self->mech->get('http://www.co-operativebank.co.uk/star/pibs/index.html');
  # First screen: sort code / account number
  $self->mech->get('https://welcome27.co-operativebank.co.uk/CBIBSWeb/start.do');

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
    my $n = $_->attr('id');
  }


  $self->mech->dump;

  exit;
}

'Is the pope Catholic?';
