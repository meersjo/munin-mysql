package Munin::MySQL::Graph::SchemaSize;

# Author <vegivamp@tuxera.be>
#
# Grabs the data_length and index_length grouped per schema.
#

sub collect_data {
    my $self = shift;
    my ($dbh) = @_;
    my $data = {};

    my $query = 'SELECT table_schema, sum(data_length) as data_size, sum(index_length) as index_size'
              . '  FROM information_schema.tables'
              . '  GROUP BY table_schema';

    my $sth = $dbh->prepare($query);
    $sth->execute();
    while (my $row = $sth->fetchrow_hashref) {
        $data->{'database_size'}->{$row->{'table_schema'}} = { 'data'  => $row->{'data_size'},
                                                               'index' => $row->{'index_size'}};
        $data->{'datasize_'  . $row->{'table_schema'}} = $row->{'data_size'};
        $data->{'indexsize_' . $row->{'table_schema'}} = $row->{'index_size'};
    }
    $sth->finish();

    return $data;
}


sub graphs { 
    my $self = shift;
    my ($data) = @_;
    $graph = {
        schema_size => {
            config => {
                global_attrs => {
                    title => 'Schema data- and index size',
                    vlabel => 'index/data size in byte',
                    args => '--base 1024',

                },
                data_source_attrs => {
                    draw => 'LINE1',
                    type => 'GAUGE',
                    min  => 'U',
                },
            },
            data_sources => [],
        }
    };

    foreach $schema (keys %{$data->{'database_size'}}) {
      if ( $schema eq 'information_schema' or
           $schema eq 'performance_schema' ) {
        next;
      }
      push(@{$graph->{'schema_size'}->{'data_sources'}}, ({'name'     => 'indexsize_' . $schema,
                                                           'label'    => 'indexsize_' . $schema,
                                                           'graph'    => 'no'},
                                                          {'name'     => 'datasize_'  . $schema,
                                                           'label'    => $schema,
                                                           'negative' => 'indexsize_' . $schema}));
    }
    return $graph;
}

1;
