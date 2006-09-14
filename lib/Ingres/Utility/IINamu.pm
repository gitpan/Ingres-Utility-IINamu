package Ingres::Utility::IINamu;

use warnings;
use strict;
use Expect::Simple;
use Data::Dump qw(dump);

=head1 NAME

Ingres::Utility::IINamu -  API to IINamu Ingres utility for (un)registering services with IIGCN

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

List registered INGRES (IIDBMS) services:

    use Ingres::Utility::IINamu;

    my $foo = Ingres::Utility::IINamu->new();
    
    # list all INGRES-type servers (iidbms)
    print $foo->show('INGRES');
    
    # process each server separately
    while (my @server = $foo->getServer()) {
    	
	print "Server type: $server[0]\tname:$server[1]\tid:$server[2]";

	if (defined($server[3])) {

		print "\t$server[3]";

	}

	print "\n";

    }
    
    # stop IIGCN server (no more connections to all of Ingres)
    $ret = $foo->stop();
    
    ...


=head1 DESCRIPTION

=for author to fill in:
    Write a full description of the module and its features here.
    Use subsections (=head2, =head3) as appropriate.
This module provides an API to the iinamu utility for Ingres RDBMS,
which provides local interaction and control of IIGCN server,
in charge of registering all Ingres services.

Through this interface, it is possible to obtain a list of all
registered services, for later processing (eg. iimonitor), and
also stopping the IIGCN server (extreme caution!).


=head1 FUNCTIONS

=head2 new

Create a new instance, checking environment prerequisites
and preparing for interfacing with iinamu utility.

=cut

sub new {
	my $class = shift;
	my $this = {};
	$class = ref($class) || $class;
	bless $this, $class;
	if (! defined($ENV{'II_SYSTEM'})) {
		die $class . ": Ingres environment variable II_SYSTEM not set";
	}
	my $iigcn_file = $ENV{'II_SYSTEM'} . '/ingres/bin/iinamu';
	
	if (! -x $iigcn_file) {
		die $class . ": Ingres utility cannot be executed: $iigcn_file";
	}
	$this->{cmd} = $iigcn_file;
	$this->{xpct} = new Expect::Simple {
				Cmd => $iigcn_file,
				Prompt => [ -re => 'IINAMU>\s+' ],
				DisconnectCmd => 'QUIT',
				Verbose => 0,
				Debug => 0,
				Timeout => 10
        } or die $this . ": Module Expect::Simple cannot be instanciated.";
	return $this;
}

=head2 show($serverType)

Returns the output of SHOW command, and prepares for
parsing the servers sequentially with getServer().

Takes one optional argument for the service: 'INGRES'(IIDBS, default), 'COMSVR' (IIGCC), etc.

=cut

sub show {
	my $this = shift;
	my $server_type = uc (@_ ? shift : 'INGRES');
	#print $this . ": cmd = $cmd";
	my $obj = $this->{xpct};
	my $cmd = 'SHOW ' . $server_type;
	$obj->send($cmd);
	my $before = $obj->before;
	while ($before =~ /\ \ /) {
		$before =~ s/\ \ /\ /g;
	}
	my @antes = split(/\r\n/,$before);
	if ($#antes > 0) {
		if ($antes[0] eq $cmd) {
			shift @antes;
		}
	}
	$this->{stream} = join($RS,@antes);
	$this->{svrtype} = $server_type;
	return $this->{stream};
}

=head2 getServer

Returns sequentially (call-after-call) each server reported by show() as an array of
3~4 elements.

=cut

sub getServer {
	my $this = shift;
	if (! $this->{stream}) {
		return ();
	}
	if (! $this->{streamPtr}) {
		$this->{streamPtr} = 0;
	}
	my @antes = split($RS,$this->{stream});
	if ($#antes <= $this->{IINAMU_STREAM_PTR}) {
		$this->{streamPtr} = 0;
		return ();
	}
	my $line = $antes[$this->{streamPtr}++];
	return split(/\ /, $line);
}

=head2 stop

Shuts down the IIGCN daemon, making it no longer possible to
stablish new connections to any Ingres service.
After this, a total restart of Ingres will most probably be necessary.

=cut

sub stop {
	my $this = shift;
	my $obj = $this->{IINAMU_XPCT};
	$obj->send( 'STOP');
	my $before = $obj->before;
	while ($before =~ /\ \ /) {
		$before =~ s/\ \ /\ /g;
	}
	my @antes = split(/\r\n/,$before);
	return;
	
}


=head1 DIAGNOSTICS

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

=over

=item C<< Ingres environment variable II_SYSTEM not set >>

Ingres environment variables should be set on the user session running
this module.
II_SYSTEM provides the root install dir (the one before 'ingres' dir).
LD_LIBRARY_PATH also. See Ingres RDBMS docs.

=item C<< Ingres utility cannot be executed: _COMMAND_FULL_PATH_ >>

The IINAMU command could not be found or does not permits execution for
the current user.

=back


=head1 CONFIGURATION AND ENVIRONMENT

=for author to fill in:
    A full explanation of any configuration system(s) used by the
    module, including the names and locations of any configuration
    files, and the meaning of any environment variables or properties
    that can be set. These descriptions must also include details of any
    configuration language used.
  
Requires Ingres environment variables, such as II_SYSTEM and LD_LIBRARY_PATH.

See Ingres RDBMS documentation.


=head1 DEPENDENCIES

=for author to fill in:
    A list of all the other modules that this module relies upon,
    including any restrictions on versions, and an indication whether
    the module is part of the standard Perl distribution, part of the
    module's distribution, or must be installed separately. ]

L<Expect::Simple>


=head1 INCOMPATIBILITIES

=for author to fill in:
    A list of any modules that this module cannot be used in conjunction
    with. This may be due to name conflicts in the interface, or
    competition for system or program resources, or due to internal
    limitations of Perl (for example, many modules that use source code
    filters are mutually incompatible).

None reported.


=head1 BUGS AND LIMITATIONS

=for author to fill in:
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.

No bugs have been reported.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Ingres::Utility::IINamu

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Ingres-Utility-IINamu>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Ingres-Utility-IINamu>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Ingres-Utility-IINamu>

=item * Search CPAN

L<http://search.cpan.org/dist/Ingres-Utility-IINamu>

=back


=head1 ACKNOWLEDGEMENTS

Thanks to Computer Associates (CA) for licensing Ingres as
open source, and let us hope for Ingres Corp to keep it that way.


=head1 AUTHOR

Joner Cyrre Worm  C<< <FAJCNLXLLXIH at spammotel.com> >>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006, Joner Cyrre Worm C<< <FAJCNLXLLXIH at spammotel.com> >>. All rights reserved.


Ingres is a registered brand of Ingres Corporation.


This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

1; # End of Ingres::Utility::IINamu
_END_
