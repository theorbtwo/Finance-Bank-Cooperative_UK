package Finance::Bank::Cooperative_UK;
use warnings;
use strict;
use Moose;
use WWW::Mechanize;
use WWW::Mechanize::TreeBuilder;
use Data::Dump::Streamer 'Dump';
use HTML::TreeBuilder;
use charnames ':full';
use Time::ParseDate;

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

  my $form_field = $self->mech->look_down(_tag => 'input', type => 'password');
  if (!$form_field) {
    $self->mech->dump;
    die "Can't find form field for personal information";
  }
  # The name of the attribute on this object that holds the piece of
  # information we need.
  my $attr = {
              birthplace => 'place_of_birth',
              firstschool => 'first_school',
              lastschool => 'last_school',
              memorablename => 'name',
             }->{$form_field->attr('id')};
  if (!$attr) {
    die "Don't know attribute for form field ".$form_field->attr('id');
  }
  my $val = $self->$attr;
  $val = $val->() if ref $val;

  my $form = {$form_field->attr('name') => $val};
  Dump $form;
  $self->mech->submit_form(with_fields => $form);

  open my $fh, ">", "debug.out";
  print $fh $self->mech->content;

  $self->mech->dump;

  exit;
}

sub parse_number {
  my ($num) = @_;
  if ($num eq "\xA0") {
    return 0;
  } else {
    $num =~ s/\N{POUND SIGN}//;
    return 0+$num;
  }
}

sub parse_recent_items {
  my ($self, $html) = @_;
  my $tree = HTML::TreeBuilder->new_from_content($html) or die "Couldn't parse HTML at all";
  
  my @data;
  
  # FIXME: Parse the metadata too?
  
  for my $datarowl ($tree->look_down(_tag => 'td', class => 'dataRowL')) {
    my $row = $datarowl->parent;
    my ($date) = $row->address('.0')->as_text;
    $date = parsedate($date, ZONE => 'Europe/London', UK => 1, FUZZY => 0);
    my $thirdparty = $row->address('.1')->as_text;
    my $credit = parse_number($row->address('.2')->as_text);
    my $debit = parse_number($row->address('.3')->as_text);

    if ($thirdparty =~ m/\*Last Statement\*/) {
      next;
    }

    # If I feel like it, parse out ATMs, stick original text in "origtext", date from thirdparty in date.

    push @data, {debit => $debit,
                 credit => $credit,
                 date => $date,
                 _date_readable => scalar localtime $date,
                 party => $thirdparty
                };
  }

  $tree->delete;
  return \@data;
}

'Is the pope Catholic?';
