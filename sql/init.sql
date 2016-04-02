CREATE TABLE leagues(
    id integer primary key,
    name text unique on conflict abort,
    external_id integer unique on conflict ignore,
    url text,
    tournament_name text,
    tournament_url text
);

CREATE TABLE teams(
    id integer primary key,
    name text unique on conflict abort,
    external_id integer unique on conflict ignore,
    url text,
    user_id integer,
    user_name text
);

CREATE TABLE league_team_links(
    league_id integer not null  references leagues(id) on delete cascade,
    team_id integer not null references teams(id) on delete cascade,
    unique ( league_id, team_id ) on conflict ignore
);
