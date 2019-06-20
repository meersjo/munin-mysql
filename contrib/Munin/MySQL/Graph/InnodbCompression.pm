package Munin::MySQL::Graph::InnodbCompression;

use warnings;
use strict;

# Author <vegivamp@tuxera.be>
#
# This will graph a number of statistics regarding the InnoDB compression
# performance.
#
# See https://dev.mysql.com/doc/refman/5.5/en/innodb-compression.html for more
# information on the topic.

sub collect_data {
    my $self = shift;
    my ($dbh) = @_;
    my $data = {};

    my $query = 'SELECT cmp.page_size, compress_ops, compress_ops_ok, compress_time,'
              . '       uncompress_ops, uncompress_time, buffer_pool_instance,'
              . '        pages_used, pages_free, relocation_ops, relocation_time'
              . '  FROM information_schema.innodb_cmp cmp'
              . '    JOIN information_schema.innodb_cmpmem cmpmem'
              . '      ON cmp.page_size=cmpmem.page_size';

    my $sth = $dbh->prepare($query);
    $sth->execute();
    while (my $row = $sth->fetchrow_hashref) {
        $data->{'innodb_compression'}->{$row->{'buffer_pool_instance'}}->{$row->{'page_size'}} = $row;
        foreach $field (keys %{$row}) {
            $data->{'inno_cmp_bp_' . $row->{'buffer_pool_instance'} . '_' . $row->{'page_size'} . $field} = $row->{$field};
        }
    }

    $sth->finish();

    return $data;
}


sub graphs {
    my $self = shift;
    my ($data) = @_;

    my $graphs = {};

    # -------------------------------------------------------------------------
    # Generate innodb_compressed_pages graphs for all buffer pools

    foreach $bpi (keys %{$data->{'innodb_compression'}}) {
        push(
          @{$graphs->{'innodb_compressed_pages_bp_' . $bpi}},
          (
              config => {
                  global_attrs => {
                      title => 'InnoDB Compressed Pages',
                      vlabel => 'Free/Used Count',
                      graph_args => '--base 1000 --lower-limit 0'
                  },
                  data_source_attrs => {
                      draw => 'LINE1',
                      type => 'GAUGE'
                  }
              }
            )
        );
        foreach $ps (keys %{$data->{'innodb_compression'}->{$bpi}}) {
            push(
                @{$graphs->{'innodb_compressed_pages_bp_' . $bpi}->{'data_sources'}},
                (
                        {
                            name => 'inno_cmpmem_bp_' . $bpi . '_' . $ps . '_pages_free',
                            label => '1k pages',
                            info  => 'Number of blocks of this size that are currently available for allocation. This column shows the external fragmentation in the memory pool. Ideally, these numbers should be at most 1.',
                            graph => 'no'
                        },
                        {
                            name => 'inno_cmpmem__bp_' . $bpi . '_' . $ps . '_pages_used',
                            label => '1k pages',
                            info  => 'Number of blocks of this size that are currently in use.',
                            negative => 'inno_cmpmem_bp_' . $bpi . '_' . $ps . '_pages_free'
                        }
                )
            );
        }
    }

    # -------------------------------------------------------------------------
    # Generate innodb_compression_effectiveness graphs for all buffer pools

    foreach $bpi (keys %{$data->{'innodb_compression'}}) {
        push(
          @{$graphs->{'innodb_compression_effectiveness_bp_' . $bpi}},
          (
              config => {
                  global_attrs => {
                      title => 'InnoDB de/compression effectiveness',
                      vlabel => '% Successful compressions',
                      graph_args => '--base 1000 --lower-limit 0'
                  },
                  data_source_attrs => {
                      draw => 'LINE1',
                      type => 'GAUGE'
                  }
              }
            )
        );
        foreach $ps (keys %{$data->{'innodb_compression'}->{$bpi}}) {
            push(
                @{$graphs->{'innodb_compression_effectiveness_bp_' . $bpi}->{'data_sources'}},
                (
                    # FIXME The sub can't use module-local variables...
                    #       We'll need to precalc them in collect_data.
                    {
                        name => 'eff_bp_' . $bpi . '_' . $ps,
                        label => '1k pages',
                        info => 'If the number of “successful” compression operations (COMPRESS_OPS_OK) is a high percentage of the total number of compression operations (COMPRESS_OPS), then the system is likely performing well. If the ratio is low, then InnoDB is reorganizing, recompressing, and splitting B-tree nodes more often than is desirable.',
                        value => sub {
                            ( $_[0]->{'inno_cmp_bp_1024_compress_ops} > 0 )
                                ? 100 * $_[0]->{inno_cmp_1024_compress_ops_ok} / $_[0]->{inno_cmp_1024_compress_ops}
                                : 0
                        }
                    },
                )
            );
        }
    }


        innodb_compression_operations => {
            config => {
                global_attrs => {
                    title => 'InnoDB de/compression operations',
                    vlabel => 'De/Compression ops/s',
                    graph_args => '--base 1000 --lower-limit 0'
                },
                data_source_attrs => {
                    draw => 'LINE1',
                    type => 'DERIVE'
                }
            },
            data_sources => [
            ]
        },

        innodb_compression_time => {
            config => {
                global_attrs => {
                    title => 'InnoDB Time Spent on De/Compression',
                    vlabel => 'seconds spent de/compressing',
                    graph_args => '--base 1000 --lower-limit 0'
                },
                data_source_attrs => {
                    draw => 'LINE1',
                    type => 'DERIVE'
                }
            },
            data_sources => [
            ]
        }
    }


    innodb_compressed_pages => {
        data_sources => [
            {
                name => 'inno_cmpmem_1024_pages_free',
                label => '1k pages',
                info  => 'Number of blocks of this size that are currently available for allocation. This column shows the external fragmentation in the memory pool. Ideally, these numbers should be at most 1.',
                graph => 'no'
            },
            {
                name => 'inno_cmpmem_1024_pages_used',
                label => '1k pages',
                info  => 'Number of blocks of this size that are currently in use.',
                negative => 'inno_cmpmem_1024_pages_free'
            },
            {
                name => 'inno_cmpmem_2048_pages_free',
                label => '2k pages',
                info  => 'Number of blocks of this size that are currently available for allocation. This column shows the external fragmentation in the memory pool. Ideally, these numbers should be at most 1.',
                graph => 'no'
            },
            {
                name => 'inno_cmpmem_2048_pages_used',
                label => '2k pages',
                info  => 'Number of blocks of this size that are currently in use.',
                negative => 'inno_cmpmem_2048_pages_free'
            },
            {
                name => 'inno_cmpmem_4096_pages_free',
                label => '4k pages',
                info  => 'Number of blocks of this size that are currently available for allocation. This column shows the external fragmentation in the memory pool. Ideally, these numbers should be at most 1.',
                graph => 'no'
            },
            {
                name => 'inno_cmpmem_4096_pages_used',
                label => '4k pages',
                info  => 'Number of blocks of this size that are currently in use.',
                negative => 'inno_cmpmem_4096_pages_free'
            },
            {
                name => 'inno_cmpmem_8192_pages_free',
                label => '8k pages',
                info  => 'Number of blocks of this size that are currently available for allocation. This column shows the external fragmentation in the memory pool. Ideally, these numbers should be at most 1.',
                graph => 'no'
            },
            {
                name => 'inno_cmpmem_8192_pages_used',
                label => '8k pages',
                info  => 'Number of blocks of this size that are currently in use.',
                negative => 'inno_cmpmem_8192_pages_free'
            },
            {
                name => 'inno_cmpmem_16384_pages_free',
                label => '16k pages',
                info  => 'Number of blocks of this size that are currently available for allocation. This column shows the external fragmentation in the memory pool. Ideally, these numbers should be at most 1.',
                graph => 'no'
            },
            {
                name => 'inno_cmpmem_16384_pages_used',
                label => '16k pages',
                info  => 'Number of blocks of this size that are currently in use.',
                negative => 'inno_cmpmem_16384_pages_free'
            }
        ]
    },

    innodb_compression_effectiveness => {
        data_sources => [
            {
                name => 'eff1k',
                label => '1k pages',
                info => 'If the number of “successful” compression operations (COMPRESS_OPS_OK) is a high percentage of the total number of compression operations (COMPRESS_OPS), then the system is likely performing well. If the ratio is low, then InnoDB is reorganizing, recompressing, and splitting B-tree nodes more often than is desirable.',
                value => sub {
                    ( $_[0]->{inno_cmp_1024_compress_ops} > 0 )
                        ? 100 * $_[0]->{inno_cmp_1024_compress_ops_ok} / $_[0]->{inno_cmp_1024_compress_ops}
                        : 0
                }
            },
            {
                name => 'eff2k',
                label => '2k pages',
                value => sub {
                    ( $_[0]->{inno_cmp_2048_compress_ops} > 0 )
                        ? 100 * $_[0]->{inno_cmp_2048_compress_ops_ok} / $_[0]->{inno_cmp_2048_compress_ops}
                        : 0
                }
            },
            {
                name => 'eff4k',
                label => '4k pages',
                value => sub {
                    ( $_[0]->{inno_cmp_4096_compress_ops} > 0 )
                        ? 100 * $_[0]->{inno_cmp_4096_compress_ops_ok} / $_[0]->{inno_cmp_4096_compress_ops}
                        : 0
                }
            },
            {
                name => 'eff8k',
                label => '8k pages',
                value => sub {
                    ( $_[0]->{inno_cmp_8192_compress_ops} > 0 )
                        ? 100 * $_[0]->{inno_cmp_8192_compress_ops_ok} / $_[0]->{inno_cmp_8192_compress_ops}
                        : 0
                }
            },
            {
                name => 'eff16k',
                label => '16k pages',
                value => sub {
                    ( $_[0]->{inno_cmp_16384_compress_ops} > 0 )
                        ? 100 * $_[0]->{inno_cmp_16384_compress_ops_ok} / $_[0]->{inno_cmp_16384_compress_ops}
                        : 0
                }
            }
        ]
    },

    innodb_compression_operations => {
        data_sources => [
            {
                name => 'inno_cmp_1024_uncompress_ops',
                label => '1k pages',
                graph => 'no'
            },
            {
                name => 'inno_cmp_1024_compress_ops',
                label => '1k pages',
                negative => 'inno_cmp_1024_uncompress_ops'
            },
            {
                name => 'inno_cmp_2048_uncompress_ops',
                label => '2k pages',
                graph => 'no'
            },
            {
                name => 'inno_cmp_2048_compress_ops',
                label => '2k pages',
                negative => 'inno_cmp_2048_uncompress_ops'
            },
            {
                name => 'inno_cmp_4096_uncompress_ops',
                label => '4k pages',
                graph => 'no'
            },
            {
                name => 'inno_cmp_4096_compress_ops',
                label => '4k pages',
                negative => 'inno_cmp_4096_uncompress_ops'
            },
            {
                name => 'inno_cmp_8192_uncompress_ops',
                label => '8k pages',
                graph => 'no'
            },
            {
                name => 'inno_cmp_8192_compress_ops',
                label => '8k pages',
                negative => 'inno_cmp_8192_uncompress_ops'
            },
            {
                name => 'inno_cmp_16384_uncompress_ops',
                label => '16k pages',
                graph => 'no'
            },
            {
                name => 'inno_cmp_16384_compress_ops',
                label => '16k pages',
                negative => 'inno_cmp_16384_uncompress_ops'
            }
        ]
    },

    innodb_compression_time => {
        data_sources => [
            {
                name => 'inno_cmp_1024_uncompress_time',
                label => '1k pages',
                graph => 'no'
            },
            {
                name => 'inno_cmp_1024_compress_time',
                label => '1k pages',
                negative => 'inno_cmp_1024_uncompress_time'
            },
            {
                name => 'inno_cmp_2048_uncompress_time',
                label => '2k pages',
                graph => 'no'
            },
            {
                name => 'inno_cmp_2048_compress_time',
                label => '2k pages',
                negative => 'inno_cmp_2048_uncompress_time'
            },
            {
                name => 'inno_cmp_4096_uncompress_time',
                label => '4k pages',
                graph => 'no'
            },
            {
                name => 'inno_cmp_4096_compress_time',
                label => '4k pages',
                negative => 'inno_cmp_4096_uncompress_time'
            },
            {
                name => 'inno_cmp_8192_uncompress_time',
                label => '8k pages',
                graph => 'no'
            },
            {
                name => 'inno_cmp_8192_compress_time',
                label => '8k pages',
                negative => 'inno_cmp_8192_uncompress_time'
            },
            {
                name => 'inno_cmp_16384_uncompress_time',
                label => '16k pages',
                graph => 'no'
            },
            {
                name => 'inno_cmp_16384_compress_time',
                label => '16k pages',
                negative => 'inno_cmp_16384_uncompress_time'
            }
        ]
    },

}}

1;
