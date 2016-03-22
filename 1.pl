use strict;
use warnings;
use v5.22;


use Mojo::UserAgent;
use Mojo::DOM;

my $url = 'http://www.sports.ru/fantasy/football/league/84024.html';

my $ua = Mojo::UserAgent->new();

my $stat_table = $ua->get( $url )->res->dom->at( 'table[class~=stat-table]' );

for my $player_row ( @{ $stat_table->find( 'tr' ) || [] } ) {
    my @td = @{ $player_row->find( 'td' ) || [] };
    say "Player " . $td[0]->all_text;
    say "Team name " . Encode::encode_utf8( $td[2]->at( 'a' )->all_text );
    say "User name " . Encode::encode_utf8( $td[3]->at( 'a' )->all_text );

};
