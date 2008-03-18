# --
# scripts/test/Performance.t - a performance testscript
# Copyright (C) 2001-2008 OTRS AG, http://otrs.org/
# --
# $Id: Performance.t,v 1.1.2.1 2008-03-18 15:57:24 tr Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see http://www.gnu.org/licenses/gpl-2.0.txt.
# --

use strict;
use warnings;

# declare externally defined variables to avoid errors under 'use strict'
use vars qw( $Self %Param );
use Time::HiRes qw(gettimeofday tv_interval);

#----------------------------------#
# use - load classes
#----------------------------------#
my $StartUse = [gettimeofday];

use Kernel::System::AuthSession;
use Kernel::System::Web::Request;
use Kernel::System::Group;
use Kernel::System::Queue;
use Kernel::System::User;
use Kernel::System::Ticket;
use Kernel::Output::HTML::Layout;
use Kernel::Modules::AgentTicketQueue;

my $DiffTime = tv_interval($StartUse);
$Self->True(
    1,
    "$DiffTime seconds - for all 'use' calls." ,
);

#-----------------------------------#
# generate new objects - first part
#-----------------------------------#
#my $StartNew = [gettimeofday];

$Self->{SessionObject} = Kernel::System::AuthSession->new(
    ConfigObject   => $Self->{ConfigObject},
    LogObject      => $Self->{LogObject},
    DBObject       => $Self->{DBObject},
    MainObject     => $Self->{MainObject},
    TimeObject     => $Self->{TimeObject},
);

$Self->{ParamObject} = Kernel::System::Web::Request->new(
    %{$Self},
    WebRequest => $Param{WebRequest} || 0,
);

$Self->{GroupObject} = Kernel::System::Group->new(
    ConfigObject   => $Self->{ConfigObject},
    LogObject      => $Self->{LogObject},
    DBObject       => $Self->{DBObject},
);
$Self->{UserObject} = Kernel::System::User->new(
    ConfigObject   => $Self->{ConfigObject},
    LogObject      => $Self->{LogObject},
    TimeObject     => $Self->{TimeObject},
    MainObject     => $Self->{MainObject},
    DBObject       => $Self->{DBObject},
);

#-----------------------------------------#
# find the user with the most privileges
#-----------------------------------------#

my $StartMostImportantUser = [gettimeofday];
my %UserList = $Self->{UserObject}->UserList(
    Type  => 'Short',
    Valid => 1,
);

my $GroupsCount = 0;
for my $UserID (keys %UserList) {
    my %Groups = $Self->{GroupObject}->GroupMemberList(
        UserID => $UserID,
        Type   => 'rw',
        Result => 'HASH',
    );
    if ($GroupsCount < scalar keys  %Groups ) {
        $GroupsCount = scalar keys  %Groups;
        $Self->{UserID} = $UserID;
    }
}
$DiffTime = tv_interval($StartMostImportantUser);
$Self->True(
    1,
    "$DiffTime seconds - find the user with the most privileges ($UserList{$Self->{UserID}}). To get an useful user for the following tests." ,
);

#-----------------------------------#
# generate new objects - second part
#-----------------------------------#

$Self->{TicketObject} = Kernel::System::Ticket->new(
    ConfigObject   => $Self->{ConfigObject},
    LogObject      => $Self->{LogObject},
    TimeObject     => $Self->{TimeObject},
    MainObject     => $Self->{MainObject},
    DBObject       => $Self->{DBObject},
);

$Self->{LayoutObject} = Kernel::Output::HTML::Layout->new(
    ConfigObject   => $Self->{ConfigObject},
    LogObject      => $Self->{LogObject},
    TimeObject     => $Self->{TimeObject},
    MainObject     => $Self->{MainObject},
    EncodeObject   => $Self->{EncodeObject},
    SessionObject  => $Self->{SessionObject},
    DBObject       => $Self->{DBObject},
    ParamObject    => $Self->{ParamObject},
    TicketObject   => $Self->{TicketObject},
    GroupObject    => $Self->{GroupObject},
    Action         => 'AgentTicketQueue',
    UserID         => 2,
    Lang => 'de',
);

$Self->{QueueObject} = Kernel::System::Queue->new( %{$Self} );
$Self->{AgentTicketQueueObject} = Kernel::Modules::AgentTicketQueue->new( %{$Self} );

#$DiffTime = tv_interval($StartNew);
#$Self->True(
#    1,
#    "$DiffTime seconds - to handle all new() calls." ,
#);

#----------------------------------#
# GetOverTimeTickets
#----------------------------------#
my $StartGetOverTimeTickets = [gettimeofday];
my @EscalationTickets = $Self->{TicketObject}->GetOverTimeTickets( UserID => 1 );

# this check is only to display how long it had take
$DiffTime = tv_interval($StartGetOverTimeTickets);
$Self->True(
    1,
    "$DiffTime seconds - to handle GetOverTimeTickets." ,
);

#----------------------------------#
# NavigationBar
#----------------------------------#
my $StartNavigationBar = [gettimeofday];
my $Output = $Self->{LayoutObject}->NavigationBar();
$DiffTime = tv_interval($StartNavigationBar);
$Self->True(
    1,
    "$DiffTime seconds - to handle NavigationBar." ,
);

#-----------------------------------------------------#
# ShowTicket - especially to test the pre module time
#-----------------------------------------------------#
my @TicketIDs = $Self->{TicketObject}->TicketSearch(
    Result    => 'ARRAY',
    Limit     => 15,
    StateType => 'Open',
    UserID    => 1,
);
my $StartShowTicket = [gettimeofday];

for my $TicketID (@TicketIDs) {
    $Self->{AgentTicketQueueObject}->ShowTicket(TicketID => $TicketID);
}

$DiffTime = tv_interval($StartShowTicket);

$Self->True(
    1,
    "$DiffTime seconds - to handle ShowTicket." ,
);

#----------------------------------#
# All tests
#----------------------------------#
$DiffTime = tv_interval($StartUse);
$Self->True(
    1,
    "$DiffTime seconds - to handle all functions." ,
);

1;
