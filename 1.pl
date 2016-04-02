use strict;
use warnings;
use v5.22;


use Mojo::UserAgent;
use Mojo::DOM;
use DBI;
use JSON;
use Data::Dumper;
my $url = "http://www.sports.ru/fantasy/football/league/84024.html";
#save_league( $league );

my $ua = Mojo::UserAgent->new();
$ua->max_redirects(5);
my $league_page_dom = $ua->get( $url )->res->dom;
my $league_name = $league_page_dom->at( 'h1[class~=titleH1]' )->at( 'b' )->all_text;
my $league_tournament_name = $league_page_dom->at( 'table[class~=profile-table]' )->at( 'tr td a' )->all_text;
my $league_tournament_url = $league_page_dom->at( 'table[class~=profile-table]' )->at( 'tr td a' )->attr( 'href' );


my $dbh = DBI->connect( 'dbi:SQLite:dbname=db/fantasy_stat.db', "", "" ) or die $DBI::errstr;
my ( $external_league_id ) = $url =~ /.*\/(\d+)(?:\.html)?$/;
my $rv = $dbh->do(
    'insert into leagues( name, external_id, url, tournament_name, tournament_url ) values ( ?, ?, ?, ?, ? )' ,
    undef,
    $league_name,
    $external_league_id,
    $url,
    $league_tournament_name,
    $league_tournament_url
) or die $dbh->errstr;

my $league_id;
if ( $rv > 1 ) {
    $league_id = $dbh->last_insert_id( undef, undef, 'leagues', 'id' );
} else {
    $league_id
        = $dbh->selectrow_hashref( "select * from leagues where external_id = ? ", {}, $external_league_id )
        ->{id}
        or die "Couldn't find or create league";
}


my $stat_table = $league_page_dom->at( 'table[class~=stat-table]' );
my @teams = map make_team_from_stat_table_row( $_ ), @{ $stat_table->find( 'tbody tr' ) || [] };


my $users = {};
my $players = {};
for my $team ( @teams ) {
    use Data::Dumper;
    say "TEAM: " . Dumper $team;
    my $team_id = save_team( $team );
    save_team_league_link( $team_id, $league_id );
    next unless $team_id;
    next;
    warn "www.sports.ru" . $team->{url};
    my $res = $ua->get( "http://www.sports.ru" . $team->{url} )->res;
    my $team_page_dom = $res->dom;
    my @tours = $team_page_dom->at( 'select#fan_points_select' )->find( 'option' )->map( 'attr', 'value' )->each;
    for my $tour ( @tours ) {
        warn "TOUR " . Dumper $tour;
        my $lineup = get_line_up( $team, $tour );
        #say "TOUR: " . Dumper $tour;
        say "LINEUP: " . Dumper $lineup;
        #my $order = 0;
        for my $player ( @{ $lineup->{players} } ) {
            $players->{ $player->{id} } ||= $player;
            #save_player( $player );
            #save_player_tour_result( $player, $tour );
            #save_team_tour_player( $team, $player, $tour, $order++ );
        }
    }
}

sub save_team_league_link {
    my ( $team_id, $league_id ) = @_;
    my $rv = $dbh->do(
        'insert into league_team_links values( ?, ? )',
        undef,
        $league_id,
        $team_id
    ) or die $dbh->errstr;
}

sub save_team {
    my $team = shift;
    my $rv = $dbh->do(
        'insert into teams ( name, external_id, url, user_id, user_name ) values ( ?, ?, ?, ?, ? )',
        undef,
        @{ $team }{ 'name', 'id', 'url', 'user_id', 'user_name' }
    );
    my $team_id;
    if ( $rv > 0 ) {
        $team_id = $dbh->last_insert_id( undef, undef, 'teams', 'id' );
    } else {
        $team_id
            = $dbh->selectrow_hashref( 'select * from teams where external_id = ?', {}, $team->{id} )
            ->{id}
            or die "Couldn't find or create team $team->{name}";
    }
    return $team_id;
}

sub make_team_from_stat_table_row {
    my $row = shift;
    my @td = @{ $row->find( 'td' ) || [] };
    my ( $league_id ) = ( $td[2]->at( 'a' )->attr( 'href' ) =~ /\/(\d+).html$/ );
    my ( $user_id ) = $td[3]->at( 'a' )->attr( 'href' ) =~ /profile\/(\d+)\/?$/;

    return {
        id => $league_id,
        name => $td[2]->at( 'a' )->all_text,
        url => $td[2]->at( 'a' )->attr( 'href' ),
        user_name => $td[3]->at( 'a' )->all_text,
        user_id => $user_id || '',
    };
    say "Player " . $td[0]->all_text;
    say "Team name " . Encode::encode_utf8( $td[2]->at( 'a' )->all_text );
    say "User name " . Encode::encode_utf8( $td[3]->at( 'a' )->all_text );
}

sub get_line_up {
    my ( $team, $tour ) = @_;
    $url = "http://www.sports.ru/fantasy/football/team/points/" . $team->{id} . "/" . $tour . ".json";
    my $lineup = $ua->get( $url )->res->json;
    return $lineup;
}


sub save_line_up {
    my $lineup = shift;

}

__END__
my $url = 'http://www.sports.ru/fantasy/football/league/84024.html';







for my $player_row ( @{ $stat_table->find( 'tr' ) || [] } ) {
    my @td = @{ $player_row->find( 'td' ) || [] };
    say "Player " . $td[0]->all_text;
    say "Team name " . Encode::encode_utf8( $td[2]->at( 'a' )->all_text );
    say "User name " . Encode::encode_utf8( $td[3]->at( 'a' )->all_text );

};
