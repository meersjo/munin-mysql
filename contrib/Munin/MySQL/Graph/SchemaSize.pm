package Munin::MySQL::Graph::SchemaSize;

# Author <vegivamp@tuxera.be>
#
# Grabs the data_length and index_length grouped per schema.
#

sub graphs { 
    my ($dbh) = @_;
    my @data_sources;
    my $query = 'SELECT table_schema, sum(data_length), sum(index_length)'
              . '  FROM information_schema.tables'
              . '  GROUP BY table_schema';

    my $sth = $dbh->prepare($query);
    $sth->execute();
    while (my $row = $sth->fetch) {
        $data->{'size_schema_data_' . $row->[0]} = $row->[1];
        $data->{'size_schema_index_' . $row->[0]} = $row->[2];
        push(@data_sources, {name => 'size_schema_index_' . $row->[0],  label => 'indexsize ' . $row->[0],
                                                                        graph => 'no',});
        push(@data_sources, {name => 'size_schema_data_' . $row->[0],   label => $row->[0],
                                                                        negative => 'size_schema_index_' . $row->[0]});
    }
    $sth->finish();
    
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
                },
            },
            data_sources => @data_sources,
        }
    };

    return $graph;
}

1;
