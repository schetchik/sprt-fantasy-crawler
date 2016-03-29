use strict;
use warnings;
use v5.22;


use Mojo::UserAgent;
use Mojo::DOM;
use DBI;

my $url = "http://www.sports.ru/fantasy/football/league/84024.html";
#save_league( $league );

my $ua = Mojo::UserAgent->new();
my $league_page_dom = $ua->get( $url )->res->dom;
my $stat_table = $league_page_dom->at( 'table[class~=stat-table]' );
my @teams = map make_team_from_stat_table_row( $_ ), @{ $stat_table->find( 'tbody tr' ) || [] };

#my $tournament_url = ( $league_page_dom->at( 'table[class~=profile-table]' )->find( 'tr' ) )[1]
#    ->find( 'td a' )->attr( 'href' );


my $users = {};
for my $team ( @teams ) {
    use Data::Dumper;
    say "TEAM: " . Dumper $team;
    #save_team( $team );
    #save_team_user( $team );
    my $team_page_dom = $ua->get( "www.sports.ru/" . $team->{url} );
    warn "1";
    my @tours = $team_page_dom->at( 'select[class~=tour-sel]' )->find( 'option' )->( 'attr', 'value' );
    for my $tour ( @tours ) {
        my $lineup = get_line_up( $team, $tour );
        say "TOUR: " . Dumper $tour;
        say "LINEUP: " . Dumper $lineup;
        #my $order = 0;
        #for my $player ( @{ $lineup->{players} } ) {
            #save_player( $player );
            #save_player_tour_result( $player, $tour );
            #save_team_tour_player( $team, $player, $tour, $order++ );
        #}
    }
}

sub make_team_from_stat_table_row {
    my $row = shift;
    my @td = @{ $row->find( 'td' ) || [] };
    my ( $league_id ) = ( $td[2]->at( 'a' )->attr( 'href' ) =~ /\/(\d+).html$/ );
    return {
        id => $league_id,
        name => $td[2]->at( 'a' )->all_text,
        url => $td[2]->at( 'a' )->attr( 'href' ),
        user_name => $td[3]->at( 'a' )->all_text,
    };
    say "Player " . $td[0]->all_text;
    say "Team name " . Encode::encode_utf8( $td[2]->at( 'a' )->all_text );
    say "User name " . Encode::encode_utf8( $td[3]->at( 'a' )->all_text );
}

sub get_line_up {
    my ( $team, $tour ) = @_;
    $url = "http://www.sports.ru/fantasy/football/team/points/" . $team->{id} . "/" . $tour . ".json";
    my $lineup = from_json( $ua->get( $url )->res );
    return $lineup;
}


sub save_line_up {
    my $lineup = shift;

}

__END__
my $url = 'http://www.sports.ru/fantasy/football/league/84024.html';





my $dbh = DBI->connect( 'dbi:SQLite:dbname=db/fantasy_stat.db', "", "" );

for my $player_row ( @{ $stat_table->find( 'tr' ) || [] } ) {
    my @td = @{ $player_row->find( 'td' ) || [] };
    say "Player " . $td[0]->all_text;
    say "Team name " . Encode::encode_utf8( $td[2]->at( 'a' )->all_text );
    say "User name " . Encode::encode_utf8( $td[3]->at( 'a' )->all_text );

};
