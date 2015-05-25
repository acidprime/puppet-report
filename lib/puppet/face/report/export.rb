require 'puppet/face'
require 'puppet/util/puppetdb'
require 'puppet/util/terminal'
require 'puppet/util/colors'
require 'puppet/network/http_pool'
require 'uri'
require 'time'
require 'json'

Puppet::Face.define(:report, '0.0.1') do
  extend Puppet::Util::Colors
  action :export do
    summary "Queries puppetdb for report" 
    arguments "<none>"

    option "--highlight" do
      summary "Enable colorized output"
      default_to { false }
    end

    option "--status RESOURCE" do
      summary "Filter reports by status {failed,unchanged,changed,noop}"
      default_to { 'failed' }
    end


    description <<-'EOT'
      This is a simple wrapper to connect to puppetdb for exported records
    EOT
    notes <<-'NOTES'
      Directly connects to the puppetdb server using your local certificate
    NOTES
    examples <<-'EOT'
      List all exported resources:

      $ puppet report export 
    EOT

    when_invoked do |options|
      output = [ {'certname' => 'end-time'} ]
      connection = Puppet::Network::HttpPool.http_instance(Puppet::Util::Puppetdb.server,Puppet::Util::Puppetdb.port)
      query = ["and",["=",["node","active"],true],["=","status",options[:status]]] 
      json_query = URI.escape(query.to_json)
      unless filtered = PSON.load(connection.request_get("/v4/reports/?query=#{json_query}", {"Accept" => 'application/json'}).body)
        raise "Error parsing json output of puppet search #{filtered}"
      end
      output << filtered.map { |report| Hash[report['certname'] => DateTime.parse(report['end-time']).rfc2822]}
      output.flatten
    end

    when_rendering :console do |output,options|
      if output.empty?
        Puppet.notice("No reports found")
      end
      padding = '  '
      headers = {
        'node_name'   => 'certname',
        'end_time'     => 'end-time',
      }

      min_widths = Hash[ *headers.map { |k,v| [k, v.length] }.flatten ]
      min_widths['node_name'] = min_widths['end_time'] = 40

      min_width = min_widths.inject(0) { |sum,pair| sum += pair.last } + (padding.length * (headers.length - 1))

      terminal_width = [Puppet::Util::Terminal.width, min_width].max

      highlight = proc do |color,s|
        c = colorize(color, s)
        c
      end
      n = 0
      output.collect do |results|

        columns = results.inject(min_widths) do |node_name,end_time|
          {
            'node_name'  => node_name.length,
            'end_time'   => end_time.length,
          }
        end

        flex_width = terminal_width - columns['node_name'] - columns['end_time'] - (padding.length * (headers.length - 1))

        format = %w{node_name end_time}.map do |k|
          "%-#{ [ columns[k], min_widths[k] ].max }s"
        end.join(padding)
        results.map do |node_name,end_time|
          n += 1
          Puppet.debug("#{options.inspect}")
          if n.odd?
            (options[:highlight] && highlight[ :hwhite,format % [ node_name, end_time ] ] || format % [ node_name, end_time ])
          else
            (options[:highlight] && highlight[ :white,format % [ node_name, end_time ] ] || format % [ node_name, end_time ])
          end
        end.join
      end
    end
  end
end
