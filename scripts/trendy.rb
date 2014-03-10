#!/usr/bin/env ruby
# # Trendy

# **trendy.rb** takes a series of statistics, applies some analysis, and
# spits out a report showing you (hopefully) when you will hit the wall.
# For now, I'm just focusing on disk statistics.

# Output is plain text, HTML table, and Ajax HTML.

# For now, the heavy lifting for the data analysis is in R.  Formatting is Ruby.

# # Usage

#     trendy.rb [--format=<html|htmljs|csv>]

# # Dependencies

# We use ERB for templates.  Not my first choice, but it's one less
# dependency.  (Since ERB is in standard library.)  And it's better than a jab
# in the eye with a sharp stick!

require 'erb'

@data = []

# # Functions

# `process_data` invokes R with "trendy.R" to process our
# `collected data and calculate the estimated exhaustion date.

# We look at the remaining time left (in hours) and mark estimated times
# less than 72 hours (3 days) as "error", and less than 168 hours (7 days) as "warning".
# The former should hopefully be sufficient to catch most out-of-space-over-weekend
# scenarios.
def process_data
	IO.popen("R --slave --vanilla --quiet < trendy.R") do |proc| 
		proc.each do |line|
			line.chomp!
			cols = [:server, :volume, :total, :used, :day_exhaustion, :time_left, :linear_exhaustion]
			rec = Hash[cols.zip(line.split(/,\s*/))]

			if !rec[:time_left].nil?
				time_left = rec[:time_left].to_f

				rec[:severity] = case 
									when time_left <= 72.0 then "error"
									when time_left <= 168.0 then "warning"
									else ""
								end
			end

			@data << rec
		end
	end
end

# `render_results` takes the data produced by `process_data` and formats it in one of several formats:

# * htmljs - Fancy Javascript-enabled HTML table.  All external assets are pulled from 
#            [CDNs](http://en.wikipedia.org/wiki/Content_delivery_network), so you don't
#            need to host anything besides the script output. 
#            Uses [DataTables](http://datatables.net/) for the rich Javascript-enabled table,
#            and [Twitter Bootstrap](http://twitter.github.com/bootstrap/) for layout, styling,
#            and some of the table classes.
# * html - just plain HTML table
# * csv - [comma separated file](http://en.wikipedia.org/wiki/Comma-separated_values).
def render_results(fmt="htmljs")
	puts case fmt
			when "htmljs"
				ERB.new(DATA.read).result
			when "html"
				"just plain HTML"
			when "csv"
				"some,c,s,v"
			else
				"huh!?"
		end
end

# # Main flow

# First we process the data, and then we render results.  That's it.

@start = Time.now

process_data

render_results

# # Wishlist

# It would be nice to run this hourly in an alert mode.

# We should be able to tweak the threshold parameters.  (For example, ...)

# # Templates

# We include the Javascript HTML report in the __END__ section.  It uses Twitter Bootstrap, 

# *Note*: we use NetDNA CDN for Twitter Bootstrap.  This is not an official CDN.

# *Todo*: class for rows.  "error", "warning"

__END__
<!DOCTYPE html>
<html lang="en">
	<head>
		<title></title>
		<link href="http://netdna.bootstrapcdn.com/twitter-bootstrap/2.3.1/css/bootstrap-combined.min.css" rel="stylesheet">
		<link rel="stylesheet" type="text/css" href="http://ajax.aspnetcdn.com/ajax/jquery.dataTables/1.9.4/css/jquery.dataTables.css">
		<style>
			div.dataTables_length label {
			    float: left;
			    text-align: left;
			}
			 
			div.dataTables_length select {
			    width: 75px;
			}
			 
			div.dataTables_filter label {
			    float: right;
			}
			 
			div.dataTables_info {
			    padding-top: 8px;
			}
			 
			div.dataTables_paginate {
			    float: right;
			    margin: 0;
			}
			 
			table.table {
			    margin-bottom: 6px !important;
			    clear: both;
				max-width: none !important;
			}

		</style>
	</head>
	<body>
		<div class="container">
			<div class="row">
				<h1>Trendy: disk depletion report</h1>

				<p class="well"><strong>Note:</strong> This is merely an estimate based on a probalistic 
					Monte Carlo simulation based on past disk usage patterns.
				</p>

				<table id="table-trendy" cellpadding="0" cellspacing="0" border="0" class="table table-striped table-bordered table-hover">
					<thead>
						<tr>
							<th>Server</th>
							<th>Volume</th>
							<th>Total Space (K)</th>
							<th>Used Space (K)</th>
							<th>% Used</th>
							<th>Estimated exhaustion (MC)</th>
							<th>Estimated exhaustion (Linear)</th>
							<th>Time left</th>
						</tr>
					</thead>
					<tbody>
						<% if @data.length > 0 %>
							<% @data.each do |r| %>
							<tr class="<%= r[:severity] %>">
								<td><%= r[:server] %></td>
								<td><%= r[:volume] %></td>
								<td><%= r[:total] %></td>
								<td><%= r[:used] %></td>
								<td><%= begin '%.1f' % (100.8 * r[:used].to_f / r[:total].to_f) rescue 'n/a' end %></td>
								<td><%= r[:day_exhaustion] %></td>
								<td><%= r[:linear_exhaustion] %></td>
								<td><%= r[:time_left] %></td>
							</tr>
							<% end %>
						<% else %>
							<tr class="warning">
								<td>Test Foo</td>
								<td>/</td>
								<td>100</td>
								<td>90</td>
								<td>2013-03-15</td>
								<td>48</td>
							</tr>
							<tr>
								<td>Server Bar</td>
								<td>/</td>
								<td>100</td>
								<td>80</td>
								<td>2014-03-15</td>
								<td>10000</td>
							</tr>
						<% end %>
					</tbody>
				</table>
			</div>
			<div class="row">
				<p>Report generated at <%= Time.now %> in <%= "%.1f" % (Time.now - @start) %> seconds</p>
			</div>
		</div>
		<script src="http://code.jquery.com/jquery.js"></script>
		<script src="http://netdna.bootstrapcdn.com/twitter-bootstrap/2.3.1/js/bootstrap.min.js"></script>
		<script type="text/javascript" charset="utf8" src="http://ajax.aspnetcdn.com/ajax/jquery.dataTables/1.9.4/jquery.dataTables.min.js"></script>
		<script type="text/javascript" src="http://www.datatables.net/media/blog/bootstrap/paging.js"></script>
		<script>
		  $(function() {
		  	// We turn on DataTables, and tweak it a bit for Twitter Bootstrap.
		  	$("#table-trendy").dataTable( {
		        "sDom": "<'row'<'span6'l><'span6'f>r>t<'row'<'span6'i><'span6'p>>",
		        "sPaginationType": "bootstrap",
		        "oLanguage": {
					"sLengthMenu": "_MENU_ records per page"
				},
				"aaSorting": [[5, "asc"]]
		    });
		    $.extend( $.fn.dataTableExt.oStdClasses, {
			    "sSortAsc": "header headerSortDown",
			    "sSortDesc": "header headerSortUp",
			    "sSortable": "header"
			} );
		    $.extend( $.fn.dataTableExt.oStdClasses, {
			    "sWrapper": "dataTables_wrapper form-inline"
			} );

		  });
		</script>
	</body>
</html>

