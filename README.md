Munin - MySQL
=============

Munin plugin for showing graphs of MySQL resource usage.


Installation
------------

1. Download zip file from Github and unzip (https://github.com/meersjo/munin-mysql/archive/master.zip)
2. Install dependencies 
    - munin-node
    - Perl modules: DBI, DBD::mysql, Module::Pluggable
3. Edit Makefile
4. Edit mysql.conf
5. Run `make install'


Alternative Installation Methods
--------------------------------

### Debian/Ubuntu Packages

yyuu provides a fork containing the packaging meta files for
Debian/Ubuntu systems. You can use these to build a Debian
package. The fork can be found at https://github.com/yyuu/munin-mysql/


Further Information
-------------------

The plugin documentation is contained in the plugin file as POD. View
it with perldoc.

The SchemaSize plugin performs a pretty heavy query on information_schema.tables.
Careful when using this on a large environment. Since it is SLOW, you may also 
need to set timeout in the plugin config. See http://munin-monitoring.org/wiki/plugin-conf.d
On 5.1.17+, there's a DIRTY HACK in the code that speeds it up for InnoDB tables.
Should have zero impact, but you may still want to read the official
documentation on the setting:
http://dev.mysql.com/doc/refman/5.1/en/innodb-parameters.html#sysvar_innodb_stats_on_metadata

I don't have a lower version to test on, but it should simply pass the hack and
work slowly.

There is a blog post with some general information and screenshots at
<http://oierud.name/bliki/ImprovedMuninGraphsForMySQL.html>

The information on
<http://code.google.com/p/mysql-cacti-templates/wiki/MySQLTemplates>
should be relevant (As these munin graphs are heavily inspired by
Xaprb's cacti graphs.)

### Wiki

There is a wiki at <https://github.com/kjellm/munin-mysql/wiki>

### Source code

The source is hosted at github:
<http://github.com/meersjo/munin-mysql/>


Troubleshooting
---------------

- If you get warnings saying "Output from SHOW ENGINE INNDOB STATUS
  was truncated" that means that a very large deadlock are causing the
  output to be truncated. The consequence is that data for many of the
  InnoDB related data sources will be missing. For solutions to this
  problem see
  http://www.xaprb.com/blog/2006/08/08/how-to-deliberately-cause-a-deadlock-in-mysql/

- You can find some tips for debugging munin plugin problems here:
  <http://munin.projects.linpro.no/wiki/Debugging_Munin_plugins>

- Bugs should be reported to the issue tracker on github
  <http://github.com/meersjo/munin-mysql/issues>


Authors
-------

Johan De Meersman &lt;vegivamp AT tuxera DOT be&gt;

Blatantly stolen, I mean forked off the code by Kjell-Magne Øierud &lt;kjellm AT oierud DOT net&gt;

Inspired by the cacti graphs made by Xaprb
http://code.google.com/p/mysql-cacti-templates/ as viewed on
http://www.xaprb.com/blog/2008/05/25/screenshots-of-improved-mysql-cacti-templates/.

